// cubit/refrigerator_cubit/refrigerator_state.dart
part of 'refrigerator_cubit.dart';

abstract class RefrigeratorCubitState extends Equatable {
  const RefrigeratorCubitState();

  @override
  List<Object?> get props => [];
}

class RefrigeratorInitial extends RefrigeratorCubitState {}

class RefrigeratorLoading extends RefrigeratorCubitState {}

class RefrigeratorLoaded extends RefrigeratorCubitState {
  final RefrigeratorState fridgeState; // Utilise le modèle que nous avons défini

  const RefrigeratorLoaded(this.fridgeState);

  @override
  List<Object?> get props => [fridgeState];

  // Méthode pour créer une copie avec des modifications (utile pour les mises à jour)
  RefrigeratorLoaded copyWith({
    String? deviceId,
    String? friendlyName,
    bool? isOn,
    String? currentStatusText,
    double? currentTemperature,
    double? targetTemperature,
    bool? isDoorOpen,
  }) {
    return RefrigeratorLoaded(
      RefrigeratorState( // Crée une nouvelle instance de RefrigeratorState
        deviceId: deviceId ?? this.fridgeState.deviceId,
        friendlyName: friendlyName ?? this.fridgeState.friendlyName,
        isOn: isOn ?? this.fridgeState.isOn,
        currentStatusText: currentStatusText ?? this.fridgeState.currentStatusText,
        currentTemperature: currentTemperature ?? this.fridgeState.currentTemperature,
        targetTemperature: targetTemperature ?? this.fridgeState.targetTemperature,
        isDoorOpen: isDoorOpen ?? this.fridgeState.isDoorOpen,
      )
      // Copier les contrôleurs de texte est délicat, il vaut mieux que le modèle les gère
      // ou les réinitialiser dans le modèle après la création de la nouvelle instance.
      // Pour l'instant, le constructeur RefrigeratorState réinitialise le targetTempController.
    );
  }
}

class RefrigeratorError extends RefrigeratorCubitState {
  final String message;

  const RefrigeratorError(this.message);

  @override
  List<Object?> get props => [message];
}