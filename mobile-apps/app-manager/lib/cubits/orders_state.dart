part of 'orders_cubit.dart';

@immutable
abstract class OrdersState {}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> newOrders;
  final List<Order> pastOrders;

  OrdersLoaded({required this.newOrders, required this.pastOrders});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrdersLoaded &&
          runtimeType == other.runtimeType &&
          listEquals(newOrders, other.newOrders) &&
          listEquals(pastOrders, other.pastOrders);

  @override
  int get hashCode => newOrders.hashCode ^ pastOrders.hashCode;
}

class OrdersError extends OrdersState {
  final String message;
  // Optional: to differentiate which part of the fetch failed if needed for UI
  final bool? isFetchingNewOrdersError;
  final bool? isFetchingPastOrdersError;

  OrdersError(this.message, {this.isFetchingNewOrdersError, this.isFetchingPastOrdersError});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrdersError &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          isFetchingNewOrdersError == other.isFetchingNewOrdersError &&
          isFetchingPastOrdersError == other.isFetchingPastOrdersError;

  @override
  int get hashCode => message.hashCode ^ isFetchingNewOrdersError.hashCode ^ isFetchingPastOrdersError.hashCode;
} 