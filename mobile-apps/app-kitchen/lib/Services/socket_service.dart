import 'package:hungerz_kitchen/Config/app_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart'; // For kDebugMode and debugPrint
import 'package:hungerz_kitchen/Models/order_model.dart'; // Corrected import path

class SocketService with ChangeNotifier {
  IO.Socket? _socket;
  // TODO: Replace with your actual backend URL
  final String _socketUrl =
     AppConfig.apiBaseUrl; // Use PC's network IP and correct port
  List<Order> _orders = []; // Changed to List<Order>

  List<Order> get orders => _orders; // Changed return type

  // Expose the socket instance for potential direct use (optional)
  IO.Socket? get socket => _socket;

  // Expose connection status (optional)
  bool get isConnected => _socket?.connected ?? false;

  SocketService() {
    _initializeSocket();
  }

  void _initializeSocket() {
    try {
      _socket = IO.io(_socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false, // Connect manually after setup
        'query': {'clientType': 'kitchen_app'} // Add clientType to query
      });

      _socket!.connect();

      _socket!.onConnect((_) {
        debugPrint('Kitchen connected to socket server: ${_socket?.id}');
        _registerKitchen(); // Register this client as the kitchen
        notifyListeners(); // Notify listeners about connection change
      });

      _socket!.on('new_kitchen_order', (data) {
        debugPrint('New kitchen order received');
        _handleNewOrder(data);
      });

      _socket!.on('kitchen_registered', (data) {
        debugPrint('Kitchen registration confirmed by server.');
        // Can add logic here if needed upon confirmation
      });

      _socket!.on('order_status_updated', (data) {
        debugPrint('Order status update received: $data');
        _handleOrderStatusUpdate(data); // Use updated handler
      });

      _socket!.onDisconnect((_) {
        debugPrint('Kitchen disconnected from socket server');
        _orders = []; // Clear orders on disconnect? Or handle differently?
        notifyListeners(); // Notify listeners about connection change & cleared orders
        // TODO: Implement reconnection logic if needed
      });

      _socket!.onError((error) {
        debugPrint('Socket Error: $error');
        // Consider notifying UI about errors
      });

      _socket!.onConnectError((error) {
        debugPrint('Socket Connection Error: $error');
        notifyListeners(); // Notify listeners about connection change
      });
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }

  void _registerKitchen() {
    if (_socket != null && _socket!.connected) {
      debugPrint('Registering kitchen...');
      // Backend doesn't require payload anymore
      _socket!.emit('register_kitchen');
    } else {
      debugPrint('Cannot register kitchen: Socket not connected.');
    }
  }

  void _handleNewOrder(dynamic orderData) {
    try {
      if (orderData is Map<String, dynamic>) {
        final newOrder = Order.fromJson(orderData);
        // Avoid adding duplicates if the order somehow already exists
        if (!_orders.any((order) => order.id == newOrder.id)) {
          _orders.insert(0, newOrder); // Add new order to the top
          notifyListeners();
          debugPrint('Added new order ${newOrder.id} to list.');
        } else {
          debugPrint('Received duplicate new order ${newOrder.id}, ignored.');
        }
      } else {
        debugPrint(
            'Received new order data is not in expected format: ${orderData.runtimeType}');
      }
    } catch (e, stackTrace) {
      debugPrint(
          'Error parsing new order: $e\nStack: $stackTrace\nReceived data: $orderData');
    }
  }

  // --- ADDED: Method to set initial orders after API fetch ---
  void setInitialActiveOrders(List<Order> initialOrders) {
    _orders = initialOrders;
    notifyListeners();
    debugPrint(
        'Set initial active orders from API: ${initialOrders.length} orders');
  }
  // --------------------------------------------------------

  // --- UPDATED handler for order status updates ---
  void _handleOrderStatusUpdate(dynamic data) {
    try {
      if (data is Map<String, dynamic>) {
        // Use 'id' key from backend
        final String? orderId = data['id']?.toString();
        final String? newStatus = data['status']?.toString();

        if (orderId != null && newStatus != null) {
          final index = _orders.indexWhere((order) => order.id == orderId);

          if (index != -1) {
            // Define statuses that mean the order is no longer active for the kitchen
            const inactiveStatuses = {
              'ready_for_pickup',
              'cancelled',
              'delivered',
              'completed',
              'rejected'
            };

            if (inactiveStatuses.contains(newStatus)) {
              // Remove from the active list
              _orders.removeAt(index);
              notifyListeners();
              debugPrint(
                  'Order $orderId removed from active list due to status change to $newStatus.');
            } else {
              // Update the status of the existing order object in the list
              _orders[index] = _orders[index].copyWith(status: newStatus);
              notifyListeners();
              debugPrint(
                  'Order $orderId status updated to $newStatus (still active).');
            }
          } else {
            debugPrint('Received status update for unknown order ID: $orderId');
          }
        } else {
          debugPrint(
              'Received invalid order status update data format (missing id or status).');
        }
      } else {
        debugPrint(
            'Received order status update data is not a Map: ${data.runtimeType}');
      }
    } catch (e, stackTrace) {
      debugPrint(
          'Error handling order status update: $e\nStack: $stackTrace\nReceived data: $data');
    }
  }
  // -------------------------------------------

  // Method to clear all orders (e.g., for testing or specific UI actions)
  void clearOrders() {
    _orders = [];
    notifyListeners();
  }

  // Method to manually attempt reconnection (optional)
  void reconnect() {
    if (_socket != null && !_socket!.connected) {
      debugPrint('Attempting to reconnect socket...');
      _socket!.connect();
    }
  }

  @override
  void dispose() {
    debugPrint('Disposing SocketService');
    _socket?.dispose();
    super.dispose();
  }
}
