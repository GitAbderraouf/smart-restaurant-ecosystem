import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/models/order_model.dart';
import 'package:hungerz_store/services/order_service.dart';
import 'package:meta/meta.dart';
import 'package:flutter/foundation.dart'; // For listEquals used in OrdersLoaded state

part 'orders_state.dart';

class OrdersCubit extends Cubit<OrdersState> {
  final OrderService _orderService;

  // Keep track of loaded orders to allow partial updates if needed
  List<Order> _currentNewOrders = [];
  List<Order> _currentPastOrders = [];

  OrdersCubit(this._orderService) : super(OrdersInitial());

  Future<void> fetchAllOrdersData() async {
    emit(OrdersLoading());
    try {
      // Fetch both new and past orders concurrently
      final results = await Future.wait([
        _orderService.getNewOrders(),
        _orderService.getPastOrders(),
      ]);
      _currentNewOrders = results[0];
      _currentPastOrders = results[1];
      emit(OrdersLoaded(newOrders: _currentNewOrders, pastOrders: _currentPastOrders));
    } catch (e) {
      emit(OrdersError("Failed to load order data: ${e.toString()}"));
    }
  }

 Future<void> fetchNewOrdersDataOnly() async {
    // If past orders are already loaded, show loading only for the new orders part conceptually.
    // Emitting general OrdersLoading for simplicity here.
    emit(OrdersLoading()); 
    try {
      _currentNewOrders = await _orderService.getNewOrders();
      // Emit with potentially stale past orders, or re-fetch them if strict consistency is paramount.
      emit(OrdersLoaded(newOrders: _currentNewOrders, pastOrders: _currentPastOrders));
    } catch (e) {
      emit(OrdersError("Failed to load new orders: ${e.toString()}", isFetchingNewOrdersError: true));
    }
  }

  Future<void> fetchPastOrdersDataOnly() async {
    emit(OrdersLoading());
    try {
      _currentPastOrders = await _orderService.getPastOrders();
      emit(OrdersLoaded(newOrders: _currentNewOrders, pastOrders: _currentPastOrders));
    } catch (e) {
      emit(OrdersError("Failed to load past orders: ${e.toString()}", isFetchingPastOrdersError: true));
    }
  }

  // No longer need client-side filtering getters as backend provides filtered lists
  // List<Order> get newOrders => ...
  // List<Order> get pastOrders => ...
} 