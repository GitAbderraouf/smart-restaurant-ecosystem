import 'package:equatable/equatable.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentIntentCreated extends PaymentState {
  final String clientSecret;
  final double amount; // Store amount for confirmation step

  const PaymentIntentCreated({required this.clientSecret, required this.amount});

  @override
  List<Object> get props => [clientSecret, amount];
}

class PaymentIntentError extends PaymentState {
  final String error;

  const PaymentIntentError(this.error);

  @override
  List<Object> get props => [error];
}

class PaymentConfirmationLoading extends PaymentState {}

class PaymentConfirmationSuccess extends PaymentState {
  final String message;
  final double newBalance;

  const PaymentConfirmationSuccess({required this.message, required this.newBalance});

  @override
  List<Object> get props => [message, newBalance];
}

class PaymentConfirmationError extends PaymentState {
  final String error;

  const PaymentConfirmationError(this.error);

  @override
  List<Object> get props => [error];
} 