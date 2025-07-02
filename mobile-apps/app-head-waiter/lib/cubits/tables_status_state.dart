part of 'tables_status_cubit.dart';

abstract class TablesStatusState extends Equatable {
  final List<TableModel>? tables; // Attribut optionnel pour toutes les états

  const TablesStatusState({this.tables});

  @override
  List<Object?> get props => [tables];
}

class TablesStatusInitial extends TablesStatusState {
  const TablesStatusInitial() : super(tables: const []); // Initialiser avec une liste vide
}

class TablesStatusLoading extends TablesStatusState {
  // Peut transporter les tables précédentes pendant le chargement d'un refresh
  const TablesStatusLoading({List<TableModel>? previousTables}) : super(tables: previousTables);
}

class TablesStatusLoaded extends TablesStatusState {
  // 'tables' ici est non-nullable et surcharge celui de la classe de base (via le constructeur super)
  @override
  final List<TableModel> tables;

  const TablesStatusLoaded({required this.tables}) : super(tables: tables);

  // copyWith n'est plus nécessaire ici si on ne modifie que les tables via de nouveaux états.
  // Si vous avez besoin de copier d'autres propriétés spécifiques à TablesStatusLoaded, ajoutez-le.
}

class TablesStatusError extends TablesStatusState {
  final String message;
  // Peut transporter les tables précédentes pour ne pas vider l'UI en cas d'erreur de refresh
  const TablesStatusError(this.message, {List<TableModel>? previousTables}) : super(tables: previousTables);

  @override
  List<Object?> get props => [message, tables];
}

// --- États pour la validation des réservations ---
// Ces états peuvent maintenant aussi transporter la liste des tables actuelles si besoin.

class ReservationValidationLoading extends TablesStatusState {
  final String qrData;
  const ReservationValidationLoading(this.qrData, {List<TableModel>? currentTables}) : super(tables: currentTables);
  @override List<Object?> get props => [qrData, tables];
}

class ReservationValidated extends TablesStatusState {
  final ReservationModel reservation;
  final TableModel? associatedTable;
  const ReservationValidated(this.reservation, this.associatedTable, {List<TableModel>? currentTables}) : super(tables: currentTables);
  @override List<Object?> get props => [reservation, associatedTable, tables];
}

class ReservationValidationError extends TablesStatusState {
  final String qrData;
  final String errorMessage;
  const ReservationValidationError(this.qrData, this.errorMessage, {List<TableModel>? currentTables}) : super(tables: currentTables);
  @override List<Object?> get props => [qrData, errorMessage, tables];
}

// --- États pour la notification de la cuisine ---

class KitchenNotificationLoading extends TablesStatusState {
  final ReservationModel reservation;
  const KitchenNotificationLoading(this.reservation, {List<TableModel>? currentTables}) : super(tables: currentTables);
   @override List<Object?> get props => [reservation, tables];
}

class KitchenNotificationSuccess extends TablesStatusState {
  final ReservationModel reservation;
  final String successMessage;
  const KitchenNotificationSuccess(this.reservation, this.successMessage, {List<TableModel>? currentTables}) : super(tables: currentTables);
   @override List<Object?> get props => [reservation, successMessage, tables];
}

class KitchenNotificationFailure extends TablesStatusState {
  final ReservationModel reservation;
  final String errorMessage;
  const KitchenNotificationFailure(this.reservation, this.errorMessage, {List<TableModel>? currentTables}) : super(tables: currentTables);
  @override List<Object?> get props => [reservation, errorMessage, tables];
}