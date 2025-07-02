part of 'appliance_status_cubit.dart';



abstract class ApplianceStatusState extends Equatable {
  const ApplianceStatusState();

  @override
  List<Object?> get props => [];
}

class ApplianceStatusInitial extends ApplianceStatusState {}

class ApplianceStatusLoading extends ApplianceStatusState {}

class ApplianceStatusLoaded extends ApplianceStatusState {
  // Supposons pour l'instant un seul frigo et un seul four pour simplifier.
  // Si vous en avez plusieurs, ce seraient des Map<String, FridgeStatusData> par deviceId.
  final FridgeStatusData? fridgeStatus;
  final OvenStatusData? ovenStatus;
  // Ajoutez ici d'autres équipements si nécessaire

  const ApplianceStatusLoaded({
    this.fridgeStatus,
    this.ovenStatus,
  });

  // Méthode copyWith pour faciliter les mises à jour d'état partielles
  ApplianceStatusLoaded copyWith({
    FridgeStatusData? fridgeStatus,
    OvenStatusData? ovenStatus,
  }) {
    return ApplianceStatusLoaded(
      fridgeStatus: fridgeStatus ?? this.fridgeStatus,
      ovenStatus: ovenStatus ?? this.ovenStatus,
    );
  }

  @override
  List<Object?> get props => [fridgeStatus, ovenStatus];
}

class ApplianceStatusError extends ApplianceStatusState {
  final String message;
  const ApplianceStatusError(this.message);
  @override
  List<Object?> get props => [message];
}