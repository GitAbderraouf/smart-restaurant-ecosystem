// lib/cubits/reservation_cubit/reservation_state.dart


// Adaptez chemin
part of 'reservation_cubit.dart';

abstract class ReservationState extends Equatable {
  const ReservationState();

  @override
  List<Object?> get props => [];
}

// État initial
class ReservationInitial extends ReservationState {}

// --- États pour la vérification de disponibilité ---

// Chargement de la disponibilité des créneaux horaires
class AvailabilityLoading extends ReservationState {}

// Erreur lors du chargement de la disponibilité
class AvailabilityError extends ReservationState {
  final String message;
  const AvailabilityError(this.message);
  @override List<Object?> get props => [message];
}

// Disponibilité chargée avec succès
class AvailabilityLoaded extends ReservationState {
  final List<TimeSlotAvailabilityModel> availableSlots;
  // Garder la date et le nombre de personnes pour lesquels ces slots sont valides
  final DateTime date;
  final int guests;

  const AvailabilityLoaded({required this.availableSlots, required this.date, required this.guests});
  @override List<Object?> get props => [availableSlots, date, guests];
}

// --- États pour la soumission de la réservation ---

// La réservation est en cours d'envoi au backend
class ReservationSubmitting extends ReservationState {}

// Erreur lors de la soumission de la réservation
class ReservationFailure extends ReservationState {
  final String error;
  const ReservationFailure(this.error);
  @override List<Object?> get props => [error];
}

// Réservation effectuée avec succès
class ReservationSuccess extends ReservationState {
  // final ReservationModel reservation; // Détails de la réservation créée
  // const ReservationSuccess(this.reservation);
  // @override List<Object?> get props => [reservation];
}

class ReservationHistoryLoading extends ReservationState {}

class ReservationHistoryError extends ReservationState {
  final String message;
  const ReservationHistoryError(this.message);
  @override List<Object?> get props => [message];
}

class ReservationHistoryLoaded extends ReservationState {
  final List<ReservationModel> reservations;
  const ReservationHistoryLoaded(this.reservations);
  @override List<Object?> get props => [reservations];
}