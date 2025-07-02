// user_app/lib/services/socket_service.dart
import 'dart:async';
//import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:hungerz/Config/app_config.dart'; // User App's AppConfig
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart';

class UserAppSocketService {
  static UserAppSocketService? _nullableInstance;
  
  static void initialize(AuthCubit authCubit) {
    _nullableInstance ??= UserAppSocketService._internal(authCubit);
  }
  
  factory UserAppSocketService() {
    if (_nullableInstance == null) {
      throw Exception("UserAppSocketService not initialized. Call initialize() first.");
    }
    return _nullableInstance!;
  }

  IO.Socket? _socket;
  final AuthCubit _authCubit;
  String? _currentToken;

  // Stream Controllers
  final _onConnectedController = StreamController<bool>.broadcast();
  final _onErrorController = StreamController<dynamic>.broadcast();
  final _onSessionJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _onTableSessionCartUpdatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _onTableOrderFinalizedController = StreamController<Map<String, dynamic>>.broadcast();
  final _onMyOrderStatusUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  // NOUVEAU: StreamController pour la fin de session initiée par le serveur/kiosk
  final _onSessionEndedByServerController = StreamController<Map<String, dynamic>>.broadcast();


  Stream<bool> get onConnected => _onConnectedController.stream;
  Stream<dynamic> get onError => _onErrorController.stream;
  Stream<Map<String, dynamic>> get onSessionJoined => _onSessionJoinedController.stream;
  Stream<Map<String, dynamic>> get onTableSessionCartUpdated => _onTableSessionCartUpdatedController.stream;
  Stream<Map<String, dynamic>> get onTableOrderFinalized => _onTableOrderFinalizedController.stream;
  Stream<Map<String, dynamic>> get onMyOrderStatusUpdate => _onMyOrderStatusUpdateController.stream;
  // NOUVEAU: Stream exposé pour la fin de session
  Stream<Map<String, dynamic>> get onSessionEndedByServer => _onSessionEndedByServerController.stream;


  bool get isConnected => _socket?.connected ?? false;
  String? _currentUserId;
  String? _activeTableSessionId;
  String? _activeKioskDeviceId;
  String? _pendingTableDeviceIdToJoin;

  UserAppSocketService._internal(this._authCubit) { //
    _authCubit.stream.listen((authState) {
      if (authState is Authenticated) {
        _currentUserId = authState.user.id;
        final newToken = authState.token;
        
        if (_socket == null || _socket!.disconnected) {
          print("UserAppSocketService: AuthState is Authenticated. Connecting socket with token.");
          _connectAndAuthenticate(newToken);
        } else if (_socket!.connected && _currentToken != newToken) {
          print("UserAppSocketService: Auth token changed. Reconnecting socket.");
          disconnect();
          _connectAndAuthenticate(newToken);
        }
      } else if (authState is Unauthenticated) {
        print("UserAppSocketService: AuthState is Unauthenticated. Disconnecting socket.");
        disconnect();
        _currentUserId = null;
        _currentToken = null;
      }
    });
    
    final initialState = _authCubit.state;
    if (initialState is Authenticated) {
      _currentUserId = initialState.user.id;
      _connectAndAuthenticate(initialState.token);
    }
  }

  void _connectAndAuthenticate(String token) {
    if (_socket?.connected == true && token == _currentToken) return;

    _currentToken = token;

    String socketUrl = AppConfig.baseUrl.startsWith('http')
        ? AppConfig.baseUrl.replaceFirst('/api', '')
        : 'http://${AppConfig.baseUrl.replaceFirst('/api', '')}';
    
    print("UserAppSocketService: Connecting to $socketUrl with token.");

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'auth': {
        'token': token,
      },
    });

    _setupSocketListeners();
    _socket!.connect();
  }

  void _setupSocketListeners() {
    _socket?.onConnect((_) {
      print('UserAppSocketService: Connected. Socket ID: ${_socket?.id}');
      _onConnectedController.add(true);
      if (_pendingTableDeviceIdToJoin != null && _currentUserId != null) {
          initiateTableSession(_pendingTableDeviceIdToJoin!);
          _pendingTableDeviceIdToJoin = null; 
      }
    });

    _socket?.onConnectError((error) {
      print('UserAppSocketService: Connection Error: $error');
      _onErrorController.add({'type': 'ConnectionError', 'data': error.toString()});
      _onConnectedController.add(false);
    });

    _socket?.onDisconnect((reason) {
      print('UserAppSocketService: Disconnected. Reason: $reason');
      _onConnectedController.add(false);
      _activeTableSessionId = null;
      _activeKioskDeviceId = null;
    });

    _socket?.onError((error) {
      print('UserAppSocketService: General Socket Error: $error');
      _onErrorController.add({'type': 'SocketError', 'data': error.toString()});
    });

    _socket?.on('session_created', (data) {
      print('UserAppSocketService: Received session_created: $data');
      if (data is Map<String, dynamic> && data['sessionId'] != null) {
        _activeTableSessionId = data['sessionId'];
        _activeKioskDeviceId = data['tableId'];
        _onSessionJoinedController.add(data);
      }
    });
    
    _socket?.on('table_session_cart_updated', (data) { //
      print('UserAppSocketService: Received table_session_cart_updated: $data');
      if (data is Map<String, dynamic>) {
        // Pour désactiver la propagation de la mise à jour du panier, commentez la ligne suivante :
        _onTableSessionCartUpdatedController.add(data);
        // Si commenté: print('UserAppSocketService: table_session_cart_updated event received but propagation is disabled.');
      }
    });

    _socket?.on('table_order_finalized', (data) { //
      print('UserAppSocketService: Received table_order_finalized: $data');
      if (data is Map<String, dynamic>) {
        _onTableOrderFinalizedController.add(data);
      }
    });
    
    _socket?.on('my_order_status_update', (data){ //
        print('UserAppSocketService: Received my_order_status_update: $data');
        if(data is Map<String, dynamic>){
            _onMyOrderStatusUpdateController.add(data);
        }
    });

    // NOUVEAU: Écouteur pour l'événement 'session_ended' du serveur
    _socket?.on('session_ended', (data) {
      print('UserAppSocketService: Received session_ended: $data');
      if (data is Map<String, dynamic>) {
        _onSessionEndedByServerController.add(data);
      }
    });

    _socket?.on('error', (data){ //
        print('UserAppSocketService: Received custom server error: $data');
        if (data is Map<String, dynamic> && data['message'] != null) {
            _onErrorController.add({'type': 'ServerError', 'data': data['message']});
        } else {
            _onErrorController.add({'type': 'ServerError', 'data': data.toString()});
        }
    });
  }

  void initiateTableSession(String tableDeviceId) {
    if (_currentUserId == null) {
      _onErrorController.add("User not authenticated to start session.");
      print("UserAppSocketService: User not authenticated.");
      return;
    }
    if (_socket == null || _socket!.disconnected) {
       _onErrorController.add("Socket not connected. Trying to connect first...");
       print("UserAppSocketService: Socket not connected. Will attempt to join session after connect.");
       _pendingTableDeviceIdToJoin = tableDeviceId;
       final authState = _authCubit.state;
       if (authState is Authenticated) {
         _connectAndAuthenticate(authState.token);
       }
       return;
    }

    print('UserAppSocketService: Emitting initiate_session for table: $tableDeviceId, user: $_currentUserId');
    _socket!.emit('initiate_session', {
      'tableDeviceId': tableDeviceId,
      'userId': _currentUserId,
    });
  }

  void updateItemInSharedCart(String menuItemId, String name, double price, int newQuantity) {
      // Pour désactiver l'envoi de mises à jour du panier, décommentez les lignes suivantes :
      // print("UserAppSocketService: updateItemInSharedCart disabled. No update sent.");
      // return;

      if (isConnected && _activeTableSessionId != null && _activeKioskDeviceId != null && _currentUserId != null) { //
          _socket!.emit('update_table_session_item', { //
              'sessionId': _activeTableSessionId,
              'tableId': _activeKioskDeviceId,
              'menuItemId': menuItemId,
              'name': name,
              'price': price,
              'quantity': newQuantity,
              'action': newQuantity > 0 ? 'update' : 'remove',
          });
          print("UserAppSocketService: Emitted update_table_session_item for $menuItemId to quantity $newQuantity");
      } else {
          print("UserAppSocketService: Cannot update shared cart. Conditions not met. Session: $_activeTableSessionId, Kiosk: $_activeKioskDeviceId");
           _onErrorController.add("Cannot update shared cart. Not in an active table session.");
      }
  }

  void disconnect() {
    print("UserAppSocketService: Disconnecting socket.");
    _socket?.disconnect();
  }

  void dispose() {
    print("UserAppSocketService: Disposing.");
    _socket?.off('connect');
    _socket?.off('connect_error');
    _socket?.off('disconnect');
    _socket?.off('error');
    _socket?.off('session_created');
    _socket?.off('table_session_cart_updated');
    _socket?.off('table_order_finalized');
    _socket?.off('my_order_status_update');
    _socket?.off('session_ended'); // NOUVEAU: off pour session_ended
    _socket?.dispose();

    _onConnectedController.close();
    _onErrorController.close();
    _onSessionJoinedController.close();
    _onTableSessionCartUpdatedController.close();
    _onTableOrderFinalizedController.close();
    _onMyOrderStatusUpdateController.close();
    _onSessionEndedByServerController.close(); // NOUVEAU: close pour le nouveau controller
  }
}