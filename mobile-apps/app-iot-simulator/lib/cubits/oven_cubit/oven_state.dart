// cubit/oven_cubit/oven_state.dart
part of 'oven_cubit.dart';

abstract class OvenCubitState extends Equatable {
  const OvenCubitState();

  @override
  List<Object?> get props => [];
}

class OvenInitial extends OvenCubitState {}

class OvenLoading extends OvenCubitState {}

class OvenLoaded extends OvenCubitState {
  final OvenState ovenState; // Utilise le modèle OvenState que nous avons défini

  const OvenLoaded(this.ovenState);

  @override
  List<Object?> get props => [ovenState];

  // Pas besoin de copyWith si le modèle OvenState est mutable et gère ses contrôleurs.
  // Si OvenState était immuable, un copyWith serait nécessaire ici.
}

class OvenError extends OvenCubitState {
  final String message;

  const OvenError(this.message);

  @override
  List<Object?> get props => [message];
}