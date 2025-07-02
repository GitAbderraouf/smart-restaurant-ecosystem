// cubits/unpaid_bill_cubit/unpaid_bill_state.dart
part of 'unpaid_bill_cubit.dart';

abstract class UnpaidBillState extends Equatable {
  const UnpaidBillState();
  @override
  List<Object?> get props => [];
}

class UnpaidBillInitial extends UnpaidBillState {}

// Pour le chargement de la liste des factures
class UnpaidBillListLoading extends UnpaidBillState {}
class UnpaidBillListLoaded extends UnpaidBillState {
  final List<UnpaidBillModel> unpaidBills;
  const UnpaidBillListLoaded(this.unpaidBills);
  @override
  List<Object> get props => [unpaidBills];
}
class UnpaidBillListError extends UnpaidBillState {
  final String message;
  const UnpaidBillListError(this.message);
  @override
  List<Object> get props => [message];
}

// Pour le processus de paiement d'une facture spécifique
class BillPaymentProcessing extends UnpaidBillState { // Nom générique
  final String billId;
  const BillPaymentProcessing(this.billId);
  @override
  List<Object> get props => [billId];
}
class BillPaymentSuccess extends UnpaidBillState { // Nom générique
  final String billId;
  const BillPaymentSuccess(this.billId);
  @override
  List<Object> get props => [billId];
}
class BillPaymentFailure extends UnpaidBillState { // Nom générique
  final String billId;
  final String message;
  const BillPaymentFailure(this.billId, this.message);
  @override
  List<Object> get props => [billId, message];
}