import 'dart:async';
import 'dart:convert'; // For jsonDecode
import 'package:flutter/foundation.dart'; // For debugPrint
import 'package:socket_io_client/socket_io_client.dart' as IO;
// import 'package:waiter_app/Config/app_config.dart'; // socketUrl will be passed in constructor
import 'package:waiter_app/Models/order_model.dart';

class SocketService with ChangeNotifier {
  IO.Socket? _socket;
  final String socketUrl;

  // Stream for ready orders (waiter needs to act on these)
  final StreamController<Order> _readyOrderController = StreamController<Order>.broadcast(); // RESTORED
  Stream<Order> get readyOrderStream => _readyOrderController.stream; // RESTORED

  // Stream for orders that have been marked as served (for UI updates, e.g., moving to a "served" list)
  final StreamController<Order> _servedOrderController = StreamController<Order>.broadcast(); // New stream
  Stream<Order> get orderServedStream => _servedOrderController.stream; // New stream getter

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Constructor updated to accept socketUrl
  SocketService({required this.socketUrl});

  void connect() {
    if (_socket != null && _socket!.connected) {
      debugPrint('[SocketService] Already connected.');
      return;
    }

    try {
      // Use the passed socketUrl
      _socket = IO.io(socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'query': {'clientType': 'waiter_app'}
      });

      _socket!.onConnect((_) {
        _isConnected = true;
        debugPrint('[SocketService] Connected to server. Socket ID: ${_socket?.id}');
        notifyListeners();
      });

      _socket!.on('dine_in_order_ready', (data) {
        debugPrint('[SocketService] Received dine_in_order_ready: $data');
        try {
          final eventData = data as Map<String, dynamic>;
          // Assuming 'data' itself is the Order object as per backend emit
          final Order order = Order.fromJson(eventData);
          _readyOrderController.add(order);
        } catch (e) {
          debugPrint('[SocketService] Error processing dine_in_order_ready data: $e. Raw data: $data');
        }
      });

      // New listener for when an order status is updated to 'served' by backend broadcast
      _socket!.on('order_status_updated_to_served', (data) {
        debugPrint('[SocketService] Received order_status_updated_to_served: $data');
        try {
          // Backend sends { orderId: string, status: string, order: OrderObject }
          final eventData = data as Map<String, dynamic>;
          if (eventData.containsKey('order')) {
            final Order servedOrder = Order.fromJson(eventData['order'] as Map<String, dynamic>);
            _servedOrderController.add(servedOrder);
          } else {
            debugPrint('[SocketService] Invalid data for order_status_updated_to_served: missing \'order\' field. Data: $data');
          }
        } catch (e) {
          debugPrint('[SocketService] Error processing order_status_updated_to_served data: $e. Raw data: $data');
        }
      });

      _socket!.onDisconnect((_) {
        _isConnected = false;
        debugPrint('[SocketService] Disconnected from server.');
        notifyListeners();
      });

      _socket!.onConnectError((data) {
        _isConnected = false;
        debugPrint('[SocketService] Connection Error: $data');
        notifyListeners();
      });

      _socket!.onError((data) {
        debugPrint('[SocketService] Socket Error: $data');
      });

    } catch (e) {
      _isConnected = false;
      debugPrint('[SocketService] Error initializing socket: $e');
      notifyListeners();
    }
  }
  
  // This method is likely no longer needed as OrderProvider uses an API call, 
  // and the backend emits 'order_status_updated_to_served' globally.
  /* 
  void emitOrderServed(String orderId, String tableId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('waiter_marked_order_served', {'orderId': orderId, 'tableId': tableId});
      debugPrint('[SocketService] Emitted waiter_marked_order_served for order $orderId table $tableId');
    } else {
      debugPrint('[SocketService] Cannot emit waiter_marked_order_served, socket not connected.');
    }
  }
  */

  void disconnect() {
    _socket?.disconnect();
    // _socket?.dispose(); // dispose is called on disconnect by the library
    _socket = null;
    _isConnected = false;
    debugPrint('[SocketService] Manually disconnected.');
    notifyListeners();
  }

  @override
  void dispose() {
    _readyOrderController.close(); // RESTORED
    _servedOrderController.close(); // Close the new stream controller
    disconnect(); 
    super.dispose();
  }
}
