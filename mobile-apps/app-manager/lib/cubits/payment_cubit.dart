import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hungerz_store/services/payment_service.dart';
import 'payment_state.dart';

class PaymentCubit extends Cubit<PaymentState> {
  final PaymentService _paymentService;

  PaymentCubit(this._paymentService) : super(PaymentInitial());

  Future<void> createPaymentIntent(double amount) async {
    emit(PaymentLoading());
    try {
      // The backend expects amount in currency units (e.g., dollars)
      // It will convert to cents internally for Stripe.
      final response = await _paymentService.createStripePaymentIntent(amount: amount);
      final clientSecret = response['clientSecret'];
      // The backend sends amount in cents, convert it back for consistency if needed or use as is
      // final responseAmount = (response['amount'] as num).toDouble(); 

      if (clientSecret != null) {
        // Pass the original amount (not cents) to the state for later confirmation
        emit(PaymentIntentCreated(clientSecret: clientSecret, amount: amount));
      } else {
        emit(const PaymentIntentError('Failed to get client secret from backend.'));
      }
    } catch (e) {
      emit(PaymentIntentError(e.toString()));
    }
  }

  Future<void> confirmPayment({
    required String paymentIntentId,
    required double amount, // This is the original top-up amount
  }) async {
    emit(PaymentConfirmationLoading());
    try {
      final response = await _paymentService.confirmWalletTopUp(
        paymentIntentId: paymentIntentId,
        amount: amount, // Send the original amount
      );
      // Assuming backend sends back a message and the new balance
      final message = response['message'] as String? ?? 'Payment confirmed successfully.';
      final newBalance = (response['balance'] as num?)?.toDouble() ?? 0.0;
      emit(PaymentConfirmationSuccess(message: message, newBalance: newBalance));
    } catch (e) {
      emit(PaymentConfirmationError(e.toString()));
    }
  }
} 