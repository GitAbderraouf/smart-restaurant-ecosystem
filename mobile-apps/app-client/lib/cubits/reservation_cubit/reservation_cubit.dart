import 'package:equatable/equatable.dart';
import 'package:hungerz/models/reservation_model.dart';

// lib/cubits/reservation_cubit/reservation_cubit.dart

import 'package:bloc/bloc.dart';
import 'package:hungerz/models/cart_item_model.dart'; // Pour les items pré-sélectionnés
// Si besoin pour le contexte resto?
import 'package:hungerz/common/enums.dart'; // Si besoin d'enums ici
import 'package:hungerz/repositories/reservation_repository.dart'; // Adaptez chemin
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart'; // Pour le token/userId

part 'reservation_state.dart';

// lib/cubits/reservation_cubit/reservation_cubit.dart

class ReservationCubit extends Cubit<ReservationState> {
  final ReservationRepository reservationRepository;
  final AuthCubit authCubit;

  // Plus besoin de _restaurantId ici
  // final String _restaurantId = "VOTRE_RESTAURANT_ID_UNIQUE"; // <-- Supprimé

  ReservationCubit(
      {required this.reservationRepository, required this.authCubit})
      : super(ReservationInitial());

  // --- Méthode pour vérifier la disponibilité (sans restaurantId) ---
  Future<void> checkAvailability({
    // required String restaurantId, // <-- Supprimé
    required DateTime date,
    required int guests,
  }) async {
    final currentAuthState = authCubit.state;
    if (currentAuthState is! Authenticated) {
      emit(AvailabilityError("Authentification requise."));
      return;
    }
    final token = currentAuthState.token;

    emit(AvailabilityLoading());
    try {
      // Appel au Repository SANS restaurantId
      final slots = await reservationRepository.getAvailability(
        // restaurantId: _restaurantId, // <-- Supprimé
        date: date,
        guests: guests,
        token: token,
      );
      print("ReservationCubit: Dispo reçue: ${slots.length} créneaux");
      emit(AvailabilityLoaded(
          availableSlots: slots, date: date, guests: guests));
    } catch (e) {
      print("ReservationCubit: Erreur checkAvailability - ${e.toString()}");
      emit(AvailabilityError(
          "Impossible de charger les disponibilités: ${e.toString().replaceFirst('Exception: ', '')}"));
    }
  }

  // --- Méthode pour soumettre la réservation (sans restaurantId) ---
  Future<void> submitReservation({
    // required String restaurantId, // <-- Supprimé
    required DateTime date,
    required String timeSlot,
    required int guests,
    required PaymentMethod paymentMethod,
    required List<CartItem> items,
    String? specialRequests,
  }) async {
    final currentAuthState = authCubit.state;
    if (currentAuthState is! Authenticated) {
      emit(ReservationFailure("Utilisateur non authentifié."));
      return;
    }
    final token = currentAuthState.token;

    if (items.isEmpty) {
      emit(ReservationFailure("Le panier est vide."));
      return;
    }

    emit(ReservationSubmitting());
    try {
      // Appel au Repository SANS restaurantId
      final createdReservation = await reservationRepository.createReservation(
        token: token,
        // restaurantId: _restaurantId, // <-- Supprimé
        date: date,
        timeSlot: timeSlot,
        guests: guests,
        paymentMethod: paymentMethod,
        preselectedItems: items,
        specialRequests: specialRequests,
      );
      print(
          "ReservationCubit: Réservation réussie ! ID: ${createdReservation}");
      emit(ReservationSuccess());
    } catch (e) {
      print("ReservationCubit: Erreur submitReservation - ${e.toString()}");
      emit(ReservationFailure(
          "Échec de la réservation: ${e.toString().replaceFirst('Exception: ', '')}"));
    }
  }

  // Réinitialiser l'état
  void resetState() {
    print("ReservationCubit: Réinitialisation vers Initial");
    emit(ReservationInitial());
  }

  // ... (propriétés et constructeur existants) ...

  // --- AJOUT : Méthode pour charger l'historique des réservations ---
  Future<void> fetchMyReservations() async {
    final currentAuthState = authCubit.state;
    if (currentAuthState is! Authenticated) {
      // Ne devrait pas arriver si l'accès à la page est protégé
      emit(ReservationHistoryError(
          "Utilisateur non authentifié pour voir les réservations."));
      return;
    }
    final token = currentAuthState.token;

    // Émettre un état de chargement pour l'historique
    // Pour ne pas écraser un état de disponibilité ou de soumission en cours,
    // on peut émettre l'état de chargement seulement si l'état actuel est Initial ou Loaded
    // ou si vous voulez un indicateur de chargement distinct pour cette action.
    // Pour simplifier, on émet directement.
    print("ReservationCubit: Début chargement historique des réservations...");
    emit(ReservationHistoryLoading());
    try {
      final reservations =
          await reservationRepository.getUserReservations(token);
      print(
          "ReservationCubit: Historique réservations chargé: ${reservations.length} éléments.");
      emit(ReservationHistoryLoaded(reservations));
    } catch (e) {
      print("ReservationCubit: Erreur fetchMyReservations - ${e.toString()}");
      emit(ReservationHistoryError(
          "Impossible de charger l'historique des réservations: ${e.toString().replaceFirst('Exception: ', '')}"));
    }
  }

  // N'oubliez pas la méthode close si vous avez des StreamSubscription (pas le cas ici)
  // @override
  // Future<void> close() {
  //   // Nettoyage
  //   return super.close();
  // }
}
