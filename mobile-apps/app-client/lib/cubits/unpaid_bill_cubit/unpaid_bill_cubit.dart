// cubits/unpaid_bill_cubit/unpaid_bill_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/models/unpaid_bill_model.dart';
import 'package:hungerz/repositories/unpaid_bill_repository.dart';
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart';
import 'package:hungerz/services/stripe_service.dart'; // Votre StripeService client-side
import 'package:equatable/equatable.dart';
// StripeException est dans flutter_stripe.dart, StripeService devrait gérer les exceptions Stripe et retourner bool
// import 'package:flutter_stripe/flutter_stripe.dart';

part 'unpaid_bill_state.dart'; // Vos états (Initial, ListLoading, ListLoaded, ListError, PaymentProcessing, PaymentSuccess, PaymentFailure)

class UnpaidBillCubit extends Cubit<UnpaidBillState> {
  final UnpaidBillRepository _unpaidBillRepository;
  final AuthCubit authCubit;
  final StripeService _stripeService; // Votre StripeService local

  UnpaidBillCubit({
    required UnpaidBillRepository unpaidBillRepository,
    required this.authCubit,
    required StripeService stripeService, // Injectez-le
  })  : _unpaidBillRepository = unpaidBillRepository,
        _stripeService = stripeService,
        super(UnpaidBillInitial());

  Future<void> fetchMyUnpaidBills() async {
    final currentAuthState = authCubit.state;
    if (currentAuthState is! Authenticated) {
      emit(UnpaidBillListError("Utilisateur non authentifié."));
      return;
    }
    final token = currentAuthState.token;

    emit(UnpaidBillListLoading());
    try {
      final bills = await _unpaidBillRepository.fetchMyUnpaidBills(token: token);
      emit(UnpaidBillListLoaded(bills));
    } catch (e) {
      emit(UnpaidBillListError("Cubit: Erreur chargement factures - ${e.toString().replaceFirst('Exception: ', '')}"));
    }
  }

  Future<void> payBill(UnpaidBillModel bill) async { // Renommé pour plus de clarté
    final currentAuthState = authCubit.state;
    if (currentAuthState is! Authenticated) {
      emit(BillPaymentFailure(bill.id, "Authentification requise pour le paiement."));
      return;
    }
    final token = currentAuthState.token;

    emit(BillPaymentProcessing(bill.id));
    try {
      // 1. Effectuer le paiement Stripe en utilisant StripeService (qui a la clé secrète)
      // La méthode makePayment de StripeService devrait gérer la création du PaymentIntent
      // et l'affichage du PaymentSheet. Elle prend le montant en unité principale (ex: DZD).
      bool paymentSuccessful = await _stripeService.makePayment(bill.total.toInt());

      if (paymentSuccessful) {
        // 2. Si le paiement Stripe est réussi côté client, marquer la facture comme payée sur votre backend
        await _unpaidBillRepository.markBillAsPaidOnBackend(
          billId: bill.id,
          token: token,
          paymentMethodInfo: "Stripe Mobile (Client-Side Flow)", // Ou un ID de transaction si StripeService le retourne
        );
        emit(BillPaymentSuccess(bill.id));
        fetchMyUnpaidBills(); // Rafraîchir la liste
      } else {
        // StripeService.makePayment a retourné false, ce qui signifie que le paiement a échoué ou a été annulé
        // StripeService devrait avoir loggué l'erreur Stripe spécifique.
        emit(BillPaymentFailure(bill.id, "Le processus de paiement Stripe a échoué ou a été annulé."));
      }
    }
    // StripeService devrait gérer ses propres StripeExceptions et retourner false en cas d'échec/annulation.
    // Si StripeService propage des exceptions, vous pouvez les attraper ici.
    // on StripeException catch (e) { ... }
    catch (e) { // Erreurs du Repository ou autres exceptions inattendues
      emit(BillPaymentFailure(bill.id, "Échec: ${e.toString().replaceFirst('Exception: ', '')}"));
    }
  }

  void resetUnpaidBillState() {
    emit(UnpaidBillInitial());
  }
}