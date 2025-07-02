import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart'; // Added for UniqueKey

import '../Config/app_config.dart';
import '../Services/api_service.dart'; // Import ApiService

class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isInitialized = false;
  String? _tableId; // Unique ID for this device/table (usually the device ID)
  String? _dbTableId; // MongoDB _id for the table entry in the backend
  String? _sessionId; // Current active session ID
  bool _isConnecting = false; // Prevent multiple initialization attempts
  Timer? _reconnectTimer;

  // Stream controllers for various events
  final _onConnectedController = StreamController<bool>.broadcast();
  final _onErrorController = StreamController<String>.broadcast();
  final _onTableRegisteredController = StreamController<Map<String, dynamic>>.broadcast();
  final _onSessionStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _onNewOrderController = StreamController<Map<String, dynamic>>.broadcast(); // For potential future use
  final _onSessionEndedController = StreamController<Map<String, dynamic>>.broadcast();
  final _onTableSessionCartUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  // Streams
  Stream<bool> get onConnected => _onConnectedController.stream;
  Stream<String> get onError => _onErrorController.stream;
  Stream<Map<String, dynamic>> get onTableRegistered => _onTableRegisteredController.stream;
  Stream<Map<String, dynamic>> get onSessionStarted => _onSessionStartedController.stream;
  Stream<Map<String, dynamic>> get onNewOrder => _onNewOrderController.stream; // For potential future use
  Stream<Map<String, dynamic>> get onSessionEnded => _onSessionEndedController.stream;
  Stream<Map<String, dynamic>> get onTableSessionCartUpdated => _onTableSessionCartUpdatedController.stream;

  // Getters for current state
  String? get tableId => _tableId; // Device's unique ID used for registration
  String? get dbTableId => _dbTableId; // Backend MongoDB _id
  String? get sessionId => _sessionId;
  bool get isConnected => _socket?.connected ?? false;
  bool get isConnecting => _isConnecting; // Expose the connecting state

  // Initialize socket connection and register device
  Future<void> initialize() async {
    if (_isInitialized || _isConnecting) {
        print('SocketService_DEBUG: Already initialized or initializing.');
        return;
    }
    _isConnecting = true;
    print('SocketService_DEBUG: Initializing...');

    try {
      // 1. Get Device ID (used as tableId for registration)
      print('SocketService_DEBUG: About to call _getTableOrDeviceId.');
      _tableId = await _getTableOrDeviceId();
      print('SocketService_DEBUG: _getTableOrDeviceId returned: $_tableId');

      if (_tableId == null || _tableId!.isEmpty) {
        print('SocketService_DEBUG: Critical error - _tableId is null or empty. Cannot proceed.');
        _onErrorController.add('Device/Table ID generation failed.');
        _isConnecting = false;
        return;
      }

      // 2. Register Device with Backend API
      final apiService = ApiService();
      print('SocketService_DEBUG: About to call apiService.registerDeviceWithTable with _tableId: $_tableId');
      final registrationResponse = await apiService.registerDeviceWithTable(_tableId!);
      print('SocketService_DEBUG: API Registration Response: $registrationResponse');

      bool registrationConsideredSuccessful = false;

      if (registrationResponse.containsKey('success') && registrationResponse['success'] == false) {
        // Error handled and returned by ApiService
        String errorMessage = registrationResponse['message'] ?? 'Unknown registration error from API.';
        print('SocketService: API Device Registration reported failure: $errorMessage.');
        _onErrorController.add('API Registration failed: $errorMessage');
        // Depending on the error, you might still want to attempt socket connection
        // or stop here. For now, we'll allow it to proceed to socket connection attempt.
      } else if (registrationResponse.containsKey('table') &&
                 registrationResponse['table'] is Map &&
                 registrationResponse['table']['id'] != null) {
        // Successful registration indicated by backend
        _dbTableId = registrationResponse['table']['id'];
        print('SocketService: Stored DB Table ID: $_dbTableId');
        registrationConsideredSuccessful = true;

        if (registrationResponse.containsKey('session') &&
            registrationResponse['session'] != null &&
            registrationResponse['session'] is Map &&
            registrationResponse['session']['id'] != null) {
            _sessionId = registrationResponse['session']['id'];
            print('SocketService: Session automatically started/joined via API registration. Session ID: $_sessionId');
            _onSessionStartedController.add(Map<String, dynamic>.from(registrationResponse['session']));
        } else {
            print('SocketService: No session automatically started/joined during API registration.');
            _sessionId = null;
        }
      } else {
        // Unexpected response structure from ApiService (neither explicit failure nor expected success)
        String rawResponseForError = registrationResponse.toString();
        if (rawResponseForError.length > 200) rawResponseForError = rawResponseForError.substring(0, 200) + "...";
        print('SocketService: API Device Registration returned an unexpected response structure: $rawResponseForError');
        _onErrorController.add('API Registration failed: Unexpected response structure.');
      }

      // 3. Connect to Socket Server
      print('SocketService: Connecting to Socket Server: ${AppConfig.socketServerUrl}');
      if (_socket != null) { // Ensure any existing socket is disposed if re-initializing
        _socket!.dispose();
        _socket = null;
      }
      _socket = IO.io(AppConfig.socketServerUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false, // We manually connect
        'reconnection': true,
        'reconnectionDelay': 2000,
        'reconnectionAttempts': 5,
        'query': {'clientType': 'kiosk_app'}
      });

      _setupSocketListeners();
      if (!_socket!.connected) { // Connect if not already trying to connect
           _socket!.connect();
      }

      _isInitialized = true; // Mark as initialized (connection happens async)

    } catch (e) { // Catch any other synchronous errors during initialization
      _onErrorController.add('Failed to initialize SocketService: $e');
      print('SocketService: Initialization error: $e');
       _scheduleReconnect(); // Schedule reconnect on initial failure
    } finally {
       _isConnecting = false;
    }
  }

  // Get existing table/device ID from storage or generate a new one
  Future<String> _getTableOrDeviceId() async {
      print("SocketService_DEBUG: _getTableOrDeviceId called.");
      final prefs = await SharedPreferences.getInstance();
      String? storedId = prefs.getString('tableDeviceId'); // Use a specific key

      if (storedId != null && storedId.isNotEmpty) {
          print("SocketService_DEBUG: Found stored tableDeviceId: $storedId");
          return storedId;
      } else {
          print("SocketService_DEBUG: No stored tableDeviceId found. Generating new device ID.");
          String deviceId = await _generateDeviceId();
          await prefs.setString('tableDeviceId', deviceId);
          print("SocketService_DEBUG: Generated and stored new device ID: $deviceId");
          return deviceId;
      }
  }


  // Generate a unique device ID based on platform
  Future<String> _generateDeviceId() async {
    print("SocketService_DEBUG: _generateDeviceId called.");
    final deviceInfoPlugin = DeviceInfoPlugin();
    String uniqueId = 'unknown_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString()}'; // Fallback
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        String? webId = prefs.getString('webDeviceId');
        if (webId == null) {
          webId = 'web_${DateTime.now().millisecondsSinceEpoch}_${UniqueKey().toString()}';
          await prefs.setString('webDeviceId', webId);
        }
        uniqueId = webId;
      } else if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        uniqueId = "android_${androidInfo.id}"; // Use Android ID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        uniqueId = "ios_${iosInfo.identifierForVendor ?? '${UniqueKey().toString()}'}"; // Use identifierForVendor
      } else if (Platform.isLinux) {
         final linuxInfo = await deviceInfoPlugin.linuxInfo;
         uniqueId = "linux_${linuxInfo.machineId ?? '${UniqueKey().toString()}'}";
      } else if (Platform.isMacOS) {
           final macInfo = await deviceInfoPlugin.macOsInfo;
           uniqueId = "macos_${macInfo.systemGUID ?? '${UniqueKey().toString()}'}";
      } else if (Platform.isWindows) {
          final windowsInfo = await deviceInfoPlugin.windowsInfo;
          // windowsInfo.deviceId might require specific permissions or registry access
          // Using computerName as a fallback if deviceId is empty
          uniqueId = "windows_${windowsInfo.deviceId.isNotEmpty ? windowsInfo.deviceId : windowsInfo.computerName}";
      }
    } catch (e) {
      print("SocketService: Error getting device ID: $e");
      // Keep the fallback ID
    }
    print("SocketService: Generated Device ID: $uniqueId");
    return uniqueId;
  }


  // Setup event listeners for socket events
  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('SocketService: Connected successfully. Socket ID: ${_socket?.id}');
      _onConnectedController.add(true);
      _cancelReconnect(); // Cancel any pending reconnect timers

      // Register table with the backend via socket event
      if (_tableId != null) {
        _registerTableWithSocket(_tableId!);
      } else {
         print("SocketService: Error - Table ID is null, cannot register with socket.");
         _onErrorController.add("Table ID missing, cannot register.");
      }
    });

    _socket?.onConnectError((error) {
      print('SocketService_CONNECTION_ERROR: Connection Error: $error'); // More specific log
      _onErrorController.add('Connection Failed: $error');
      _onConnectedController.add(false);
      _scheduleReconnect();
    });

    _socket?.onConnectTimeout((timeout) {
      print('SocketService_CONNECTION_TIMEOUT: Connection Timeout: $timeout'); // More specific log
      _onErrorController.add('Connection Timeout');
      _onConnectedController.add(false);
      _scheduleReconnect();
    });

    _socket?.onDisconnect((reason) {
      print('SocketService: Disconnected. Reason: $reason');
      _onConnectedController.add(false);
      _onErrorController.add('Disconnected');
       // Only schedule reconnect if it wasn't a manual disconnect
      if (reason != 'io client disconnect') {
           _scheduleReconnect();
      }
    });

    _socket?.onError((error) { // General errors
      print('SocketService_SOCKET_ERROR: General Socket Error: $error'); // More specific log
      _onErrorController.add('Socket Error: $error');
    });

    // Listen for backend confirmation of table registration via socket
    _socket?.on('table_registered', (data) {
      print('SocketService: Received table_registered: $data');
      if (data is Map) {
         final eventData = Map<String, dynamic>.from(data);
         // Store/Update the MongoDB _id if provided
         if (eventData.containsKey('tableData') && eventData['tableData'] is Map && eventData['tableData'].containsKey('id')) {
            _dbTableId = eventData['tableData']['id'];
            print('SocketService: Stored DB Table ID via socket event: $_dbTableId');
         }
        _onTableRegisteredController.add(eventData);
      }
    });

    // Listen for session started event (when a user app initiates session with this table)
    _socket?.on('session_started', (data) {
      print('SocketService_DEBUG --- EVENT RECEIVED ---: session_started: $data'); // More prominent log
      if (data is Map) {
        final sessionData = Map<String, dynamic>.from(data);
        if (sessionData['sessionId'] != null) {
          _sessionId = sessionData['sessionId'];
        }
        print('SocketService_DEBUG --- ADDING TO STREAM ---: _onSessionStartedController');
        _onSessionStartedController.add(sessionData);
      } else {
        print('SocketService_DEBUG --- session_started data is NOT a Map ---: $data');
      }
    });

    _socket?.on('session_ended', (data) {
      print('SocketService: Received session_ended: $data');
      if (data is Map) {
        final eventData = Map<String, dynamic>.from(data);
        // Clear local session ID if it matches the one ended
        if (eventData['sessionId'] == _sessionId) {
          _sessionId = null;
        }
        _onSessionEndedController.add(eventData);
      }
    });

    // <<< ADDED LISTENER FOR CART UPDATES >>>
    _socket?.on('table_session_cart_updated', (data) {
      print('SocketService: Received table_session_cart_updated: $data');
      if (data is Map) {
        _onTableSessionCartUpdatedController.add(Map<String, dynamic>.from(data));
      }
    });
    // <<< END ADDED LISTENER >>>

    _socket?.on('error', (data) { // For custom errors from backend
      print('SocketService: Received custom backend error: $data');
      if (data is Map && data['message'] != null) {
          _onErrorController.add(data['message']);
      } else if (data is String) {
          _onErrorController.add(data);
      } else {
          _onErrorController.add('An unknown error occurred from the server.');
      }
    });
  }

  // Emit table registration event to the socket server
  void _registerTableWithSocket(String tableIdToRegister) {
    if (!isConnected) {
      _onErrorController.add('Socket not connected, cannot register');
      print('SocketService: Cannot register table, socket not connected.');
      return;
    }
    print('SocketService: Emitting register_table event for tableId: $tableIdToRegister');
    _socket?.emit('register_table', {
      'tableId': tableIdToRegister, 
      // If your backend 'register_table' listener expects the DB ID, you might need
      // to wait for the API call to finish and store _dbTableId first, or adjust the backend.
      // For now, assuming backend uses the provided tableId (device ID) to find/link.
    });

    // Kiosk explicitly asks to join its room
    final String roomName = 'table_$tableIdToRegister';
    print('SocketService: Emitting join_table_room for room: $roomName');
    _socket?.emit('join_table_room', {'roomName': roomName});
  }

   // --- Reconnection Logic ---
   void _scheduleReconnect() {
       // Don't schedule if already connecting or timer is active
       if (_isConnecting || (_reconnectTimer != null && _reconnectTimer!.isActive)) return; 

       print("SocketService: Scheduling reconnect attempt in 5 seconds...");
       _reconnectTimer = Timer(Duration(seconds: 5), () {
           print("SocketService: Attempting to reconnect...");
           if (_socket != null && !_socket!.connected) {
               _isConnecting = true; // Mark as connecting during the attempt
               _socket!.connect(); // Try connecting again
               // Reset connecting flag after a short delay, assuming connect() is async 
               // This is a simplification; robust logic might use connection events.
               Future.delayed(Duration(seconds: 2), () => _isConnecting = false);
           }
            _reconnectTimer = null; // Allow scheduling again after attempt
       });
   }

    void _cancelReconnect() {
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
         print("SocketService: Reconnect timer cancelled.");
    }

  // --- Public Methods ---

  // Method called by UI to end the current session
  void endCurrentSession() {
    if (!isConnected) {
      _onErrorController.add('Socket not connected, cannot end session');
       print('SocketService: Cannot end session, socket not connected.');
      return;
    }
    if (_sessionId == null) {
      _onErrorController.add('No active session to end');
       print('SocketService: Cannot end session, no active session ID.');
      // Maybe show a message to the user
      return;
    }
    if (_tableId == null) {
       _onErrorController.add('Table ID missing, cannot end session');
        print('SocketService: Cannot end session, table ID is null.');
       return;
    }

    print('SocketService: Emitting end_session for sessionId: $_sessionId, tableId: $_tableId');
    _socket?.emit('end_session', {
      'sessionId': _sessionId,
      'tableId': _tableId, // Send the table's unique ID (device ID)
    });
    // The actual clearing of _sessionId happens when the 'session_ended' event is received
  }

  // Method to potentially notify backend explicitly after order creation (using API).
  // Currently redundant if backend's createOrder emits to kitchen.
  void notifyOrderPlaced(String orderId) {
     if (!isConnected) {
         _onErrorController.add('Socket not connected, cannot notify order placed');
         print('SocketService: Cannot notify order placed, socket not connected.');
         return;
     }
     if (_sessionId == null || _tableId == null) {
         print('SocketService: Skipping order_placed emit - session or table ID missing.');
         return; // Cannot notify without session context
     }
     print('SocketService: Emitting order_placed for orderId: $orderId, sessionId: $_sessionId, tableId: $_tableId');
     // Note: Ensure your backend 'order_placed' listener handles this correctly if used.
     _socket?.emit('order_placed', {
         'orderId': orderId,
         'sessionId': _sessionId,
         'tableId': _tableId, // Device ID
     });
  }


  // Reinitialize connection manually (e.g., from UI button)
  Future<void> manualReconnect() async {
     print("SocketService: Manual reconnect requested.");
     _cancelReconnect();
     if (_socket != null && _socket!.connected) {
         print("SocketService: Already connected.");
         _onErrorController.add("Already connected");
         return;
     }
     if (_isConnecting) {
         print("SocketService: Already attempting to connect.");
          _onErrorController.add("Connection attempt in progress...");
         return;
     }

     _onErrorController.add("Attempting manual reconnect...");
     // If socket exists but isn't connected, try connecting it
     if (_socket != null) {
          _isConnecting = true;
          print("SocketService: Attempting manual connect...");
          _socket!.connect();
           // Reset connecting flag after a delay
           Future.delayed(Duration(seconds: 3), () => _isConnecting = false);
     } else {
         // If socket is null, try full re-initialization
         print("SocketService: Socket instance is null, attempting full re-initialization...");
         _isInitialized = false; // Reset initialization flag
          await initialize(); // Try full initialization again
     }
  }

  // Disconnect and clean up resources
  void dispose() {
     print("SocketService: Disposing...");
    _cancelReconnect();
    _socket?.off('connect');
    _socket?.off('connect_error');
    _socket?.off('disconnect');
    _socket?.off('error');
    _socket?.off('table_registered');
    _socket?.off('session_started');
    _socket?.off('new_order');
    _socket?.off('session_ended');
    _socket?.off('table_session_cart_updated');
    _socket?.disconnect(); // Manually disconnect
    _socket?.dispose();
    _socket = null; // Ensure socket is nullified

    // Close stream controllers if they haven't been already
    if (!_onConnectedController.isClosed) _onConnectedController.close();
    if (!_onErrorController.isClosed) _onErrorController.close();
    if (!_onTableRegisteredController.isClosed) _onTableRegisteredController.close();
    if (!_onSessionStartedController.isClosed) _onSessionStartedController.close();
    if (!_onNewOrderController.isClosed) _onNewOrderController.close();
    if (!_onSessionEndedController.isClosed) _onSessionEndedController.close();
    if (!_onTableSessionCartUpdatedController.isClosed) _onTableSessionCartUpdatedController.close();

     _isInitialized = false; // Mark as not initialized
     _isConnecting = false;
     print("SocketService: Disposed.");
  }
}
