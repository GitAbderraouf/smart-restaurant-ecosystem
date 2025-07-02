// File: waiter_app/lib/Providers/order_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:waiter_app/Models/order_model.dart';
import 'package:waiter_app/Services/socket_service.dart';
import 'package:waiter_app/Services/api_service.dart'; // Import ApiService
import 'dart:developer'; // For log
// You might need an APIService to fetch full order details if event is minimal
// import 'package:waiter_app/services/api_service.dart';

class OrderProvider with ChangeNotifier {
  List<Order> _readyForServingOrders = []; // RESTORED
  List<Order> _servedOrders = []; // New list for served orders
  bool _isLoading = false;
  final ApiService _apiService; // Added ApiService instance
  SocketService? _socketService; // To emit events

  // Updated constructor to accept ApiService
  OrderProvider({SocketService? socketService, required ApiService apiService})
      : _socketService = socketService,
        _apiService = apiService {
    _socketService?.connect(); // Ensure the socket connection is initiated
    _listenToSocketEvents(); // Consolidated listener setup
  }

  List<Order> get readyForServingOrders => _readyForServingOrders; // RESTORED
  List<Order> get servedOrders => _servedOrders; // Getter for served orders
  bool get isLoading => _isLoading;

  void setSocketService(SocketService socketService) {
    _socketService?.dispose(); // Changed from disposeListeners to dispose
    _socketService = socketService;
    _listenToSocketEvents(); // Re-initialize listeners
    // Call with this. to ensure proper reference
    this.fetchInitialReadyOrders();
    // fetchServedDineInOrders(); // Might want to fetch served orders too on new socket
  }

  void _listenToSocketEvents() {
    _socketService?.readyOrderStream.listen((order) { // RESTORED Block
      debugPrint('[OrderProvider] Received ready order via stream: ${order.id} for table ${order.tableId}');
      _addOrUpdateReadyOrder(order); // Directly use the Order object
    }, onError: (error) {
      debugPrint('[OrderProvider] Error in ready order stream: $error');
    });
    
    _socketService?.orderServedStream.listen((order) {
      debugPrint('[OrderProvider] Received served order via stream: ${order.id}');
      _handleServedOrderEvent(order); // Directly use the Order object
    }, onError: (error) {
      debugPrint('[OrderProvider] Error in served order stream: $error');
    });
  }
  
  void _handleServedOrderEvent(Order servedOrder) {
    // Remove from ready list if present
    _readyForServingOrders.removeWhere((o) => o.id == servedOrder.id); // RESTORED
    
    // Add to served list or update if already there (e.g. if details changed)
    final index = _servedOrders.indexWhere((o) => o.id == servedOrder.id);
    if (index != -1) {
      _servedOrders[index] = servedOrder;
      log("[OrderProvider] Updated served order from socket: ${servedOrder.id}");
    } else {
      _servedOrders.insert(0, servedOrder); // Add to top
      log("[OrderProvider] Added new served order from socket: ${servedOrder.id}");
    }
    _servedOrders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // Sort by most recently served
    notifyListeners();
  }

  void _addOrUpdateReadyOrder(Order order) { // RESTORED Method
    // Check if order already exists and update, or add as new
    final index = _readyForServingOrders.indexWhere((o) => o.id == order.id);
    
    // Ensure readyAt is set for ready_for_pickup orders
    Order orderWithReadyTime = order;
    if (order.status == 'ready_for_pickup') {
      // If readyAt is null or looks invalid, set it to current time
      if (order.readyAt == null ||
          order.readyAt!.isBefore(DateTime(2000)) ||
          order.readyAt!.isAfter(DateTime.now().add(const Duration(days: 1)))) {
        orderWithReadyTime = order.copyWith(readyAt: DateTime.now());
        log("[OrderProvider] Fixed missing or invalid readyAt time for order: ${order.id}");
      }
    }
    
    if (index != -1) {
      _readyForServingOrders[index] = orderWithReadyTime;
      log("[OrderProvider] Updated ready order: ${order.id}");
    } else {
      _readyForServingOrders.insert(0, orderWithReadyTime);
      log("[OrderProvider] Added new ready order: ${order.id}");
    }
    _readyForServingOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    notifyListeners();
  }

  Future<void> markOrderAsServed(String orderId, String tableId) async {
    log("[OrderProvider] Marking order $orderId (Table: $tableId) as served.");
    
    // final originalReadyOrders = List<Order>.from(_readyForServingOrders); // This line is fine for backup, but not strictly needed for the revert if the next lines are correct.
    final orderIndex = _readyForServingOrders.indexWhere((o) => o.id == orderId); // RESTORED
    Order? orderThatWasServed;

    if (orderIndex != -1) { // RESTORED
      orderThatWasServed = _readyForServingOrders[orderIndex];
      _readyForServingOrders.removeAt(orderIndex); 
      notifyListeners(); 
    }

    try {
      await _apiService.markOrderAsServedApi(orderId);
      log("[OrderProvider] Successfully marked order $orderId as served via API.");
      
      // Socket emission is now handled by the backend controller directly.
      // The client (this app and other waiter apps) will receive 'order_status_updated_to_served'
      // which is handled by _handleServedOrderEvent.

      // If the order was successfully marked served, and we have the order object,
      // we can also manually trigger the local state update for _servedOrders
      // to ensure it's reflected even if the socket event is delayed or missed.
      // The socket event handler (_handleServedOrderEvent) is designed to be idempotent.
      if (orderThatWasServed != null) {
         // Create a new order object with status 'served' and current time for updatedAt
         // This ensures that if the socket event is delayed, this local update happens first.
         final servedOrderForLocalUpdate = orderThatWasServed.copyWith(status: 'served', updatedAt: DateTime.now());
         _handleServedOrderEvent(servedOrderForLocalUpdate); 
         // No need for an extra notifyListeners() here as _handleServedOrderEvent calls it.
      }

    } catch (e) {
      log("[OrderProvider] Failed to mark order $orderId as served via API: $e. Reverting UI.");
      // Revert optimistic update if API call fails
      if (orderThatWasServed != null && orderIndex != -1) { // RESTORED
        _readyForServingOrders.insert(orderIndex, orderThatWasServed);
        _readyForServingOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        notifyListeners();
      }
    }
  }

  void removeOrder(String orderId) { // This might be redundant if markOrderAsServed handles removal
    _readyForServingOrders.removeWhere((order) => order.id == orderId); // RESTORED
    log("[OrderProvider] Removed order $orderId from ready list."); // RESTORED Log
    notifyListeners();
  }

  Future<void> fetchInitialReadyOrders() async { // RESTORED Method
    log("[OrderProvider] Fetching initial ready for serving orders via API...");
    _isLoading = true;
    notifyListeners();
    try {
      final List<Order> fetchedOrders = await _apiService.fetchReadyDineInOrders();
      
      // Ensure all orders have valid readyAt timestamps
      List<Order> validatedOrders = fetchedOrders.map((order) {
        if (order.status == 'ready_for_pickup' && 
            (order.readyAt == null || 
            order.readyAt!.isBefore(DateTime(2000)) ||
            order.readyAt!.isAfter(DateTime.now().add(const Duration(days: 1))))) {
          // Fix missing or invalid readyAt timestamp
          return order.copyWith(readyAt: DateTime.now());
        }
        return order;
      }).toList();
      
      _readyForServingOrders = validatedOrders;
      _readyForServingOrders.sort((a, b) => a.createdAt.compareTo(b.createdAt)); 
      log("[OrderProvider] Fetched ${_readyForServingOrders.length} initial ready orders via API.");
    } catch (e) {
      log("[OrderProvider] Error fetching initial ready orders: $e");
      _readyForServingOrders = []; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method to fetch served orders
  Future<void> fetchServedDineInOrders() async {
    log("[OrderProvider] Fetching served dine-in orders via API...");
    _isLoading = true;
    notifyListeners();
    try {
      final List<Order> fetchedOrders = await _apiService.fetchServedDineInOrders(limit: 50);
      _servedOrders = fetchedOrders;
      // Sort by updateAt (presumably when it was served), most recent first
      _servedOrders.sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); 
      log("[OrderProvider] Fetched ${_servedOrders.length} served dine-in orders via API.");
    } catch (e) {
      log("[OrderProvider] Error fetching served dine-in orders: $e");
      _servedOrders = []; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _socketService?.dispose(); // Changed from disposeListeners to dispose
    super.dispose();
  }
} 