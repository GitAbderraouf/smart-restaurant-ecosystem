
part of 'order_cubit.dart';

abstract class OrderState extends Equatable {
  const OrderState();
  @override List<Object?> get props => [];
}

class OrderInitial extends OrderState {}

class OrderPlacementInProgress extends OrderState {}

class OrderPlacementSuccess extends OrderState {
  final OrderDetailsModel orderDetails;
  const OrderPlacementSuccess(this.orderDetails);
  @override List<Object?> get props => [orderDetails];
}

class OrderPlacementSuccessNavigateToOrders extends OrderState {
  final OrderDetailsModel orderDetails;
  const OrderPlacementSuccessNavigateToOrders(this.orderDetails);
  @override List<Object?> get props => [orderDetails];
}

class OrderPlacementFailure extends OrderState {
  final String error;
  const OrderPlacementFailure(this.error);
  @override List<Object?> get props => [error];
}

class OrderHistoryLoading extends OrderState {}

class OrderHistoryLoaded extends OrderState {
  final List<OrderDetailsModel> orders;
  const OrderHistoryLoaded(this.orders);
  @override List<Object?> get props => [orders];
}

class OrderHistoryError extends OrderState {
  final String message;
  const OrderHistoryError(this.message);
  @override List<Object?> get props => [message];
}