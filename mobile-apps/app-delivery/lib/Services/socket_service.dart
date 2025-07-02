import 'package:flutter/foundation.dart'; // For @required and debugging
import 'package:hungerz_delivery/Config/app_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

// Define the callback type at the top level
typedef NewDeliveryOrderCallback = void Function(Map<String, dynamic> orderPayload);

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal();

  IO.Socket? _socket;
  
  // Use the IP address from your kitchen_with_kiosk-main configuration
  // Ensure this is accessible from the device/emulator running livriha-main
  static const String _socketUrl = AppConfig.baseUrl; 

  NewDeliveryOrderCallback? _onNewDeliveryOrder;

  // Notifier for connection status
  final ValueNotifier<bool> connectionStatusNotifier = ValueNotifier<bool>(false);

  void initSocketConnection({
    NewDeliveryOrderCallback? newDeliveryOrderCallback,
  }) {
    if (_socket != null && _socket!.connected) {
      if (kDebugMode) {
        print('[SocketService] Already connected.');
      }
      connectionStatusNotifier.value = true; // Ensure status is correct if already connected
      if (newDeliveryOrderCallback != null && _onNewDeliveryOrder != newDeliveryOrderCallback) {
          _onNewDeliveryOrder = newDeliveryOrderCallback;
           if (kDebugMode) {
             print('[SocketService] Updated onNewDeliveryOrder callback.');
           }
      }
      return;
    }

    _onNewDeliveryOrder = newDeliveryOrderCallback;
    connectionStatusNotifier.value = false; // Initial status before attempting connection

    if (kDebugMode) {
      print('[SocketService] Initializing connection to $_socketUrl...');
    }
    _socket = IO.io(_socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true, 
      'forceNew': true, 
      'query': {
        'clientType': 'delivery_dispatcher_app'
      },
    });

    _socket!.onConnect((_) {
      if (kDebugMode) {
        print('[SocketService] Connected to backend. Socket ID: ${_socket?.id}. Client Type: delivery_dispatcher_app');
      }
      connectionStatusNotifier.value = true;
    });

    _socket!.onConnectError((data) {
      if (kDebugMode) {
        print('[SocketService] Connection Error: $data');
      }
      connectionStatusNotifier.value = false;
    });

    _socket!.onConnectTimeout((data) {
       if (kDebugMode) {
        print('[SocketService] Connection Timeout: $data');
      }
      connectionStatusNotifier.value = false;
    });

    _socket!.onError((data) {
      if (kDebugMode) {
        print('[SocketService] Error: $data');
      }
      // Note: onError doesn't necessarily mean disconnected. 
      // Connection status is more reliably tracked by onConnect and onDisconnect.
    });

    _socket!.onDisconnect((reason) {
      if (kDebugMode) {
        print('[SocketService] Disconnected: $reason');
      }
      connectionStatusNotifier.value = false;
    });

    _socket!.on('new_delivery_order_for_dispatch', (data) {
      if (kDebugMode) {
        print('[SocketService] Received new_delivery_order_for_dispatch: $data');
      }
      if (_onNewDeliveryOrder != null) {
        try {
          if (data is Map<String, dynamic>) {
             _onNewDeliveryOrder!(data);
          } else {
            if (kDebugMode) {
              print('[SocketService] Received data is not of type Map<String, dynamic>. Data: $data');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('[SocketService] Error processing new_delivery_order_for_dispatch payload: $e');
            print('[SocketService] Received data: $data');
          }
        }
      } else {
        if (kDebugMode) {
          print('[SocketService] onNewDeliveryOrder callback is not set. Ignoring event.');
        }
      }
    });
  }

  IO.Socket? get socket {
    if (_socket == null) {
       if (kDebugMode) {
        print("[SocketService] Socket not initialized. Call initSocketConnection first.");
      }
    }
    return _socket;
  }

  void disconnectSocket() {
    if (_socket != null) {
      _socket!.disconnect();
       if (kDebugMode) {
        print("[SocketService] Manually disconnected.");
      }
      connectionStatusNotifier.value = false; // Ensure status is updated on manual disconnect
    }
  }

  // Optional: A method to dispose the service if needed, e.g., when app closes
  void dispose() {
    disconnectSocket();
    _onNewDeliveryOrder = null; 
    connectionStatusNotifier.dispose(); // Dispose the notifier
  }
}

// Example of a simple OrderPayload model (you should tailor this to your actual data structure)
// You would then parse the dynamic 'data' into this model in the event handler.
/*
class OrderPayload {
  final String orderId;
  final String orderNumber;
  final List<OrderItemPayload> items;
  final double total;
  final DeliveryAddressPayload deliveryAddress;
  final CustomerDetailsPayload customerDetails;
  // Add other fields as per your backend payload...

  OrderPayload({
    required this.orderId,
    required this.orderNumber,
    required this.items,
    required this.total,
    required this.deliveryAddress,
    required this.customerDetails,
  });

  factory OrderPayload.fromJson(Map<String, dynamic> json) {
    // Implement fromJson logic, including for nested objects
    return OrderPayload(
      orderId: json['orderId'],
      orderNumber: json['orderNumber'],
      items: (json['items'] as List).map((itemJson) => OrderItemPayload.fromJson(itemJson)).toList(),
      total: (json['total'] as num).toDouble(),
      deliveryAddress: DeliveryAddressPayload.fromJson(json['deliveryAddress']),
      customerDetails: CustomerDetailsPayload.fromJson(json['customerDetails']),
    );
  }
}

class OrderItemPayload {
  final String? menuItemId;
  final String name;
  final int quantity;
  final double price;
  // ...
  OrderItemPayload({this.menuItemId, required this.name, required this.quantity, required this.price});
  factory OrderItemPayload.fromJson(Map<String, dynamic> json) {
    return OrderItemPayload(
      menuItemId: json['menuItemId'],
      name: json['name'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
    );
  }
}

class DeliveryAddressPayload {
  final String address;
  // ...
  DeliveryAddressPayload({required this.address});
  factory DeliveryAddressPayload.fromJson(Map<String, dynamic> json) {
    return DeliveryAddressPayload(address: json['address']);
  }
}

class CustomerDetailsPayload {
  final String userId;
  final String name;
  final String phoneNumber;
  // ...
  CustomerDetailsPayload({required this.userId, required this.name, required this.phoneNumber});
  factory CustomerDetailsPayload.fromJson(Map<String, dynamic> json) {
    return CustomerDetailsPayload(
      userId: json['userId'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
    );
  }
}
*/ 