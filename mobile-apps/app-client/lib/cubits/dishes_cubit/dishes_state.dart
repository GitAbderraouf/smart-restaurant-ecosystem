// lib/dishes/cubit/dishes_state.dart (Adaptez le chemin)

 // Lie l'état au Cubit

// Utiliser Equatable pour faciliter la comparaison des états

 // !! ADAPTEZ LE CHEMIN !!
part of 'dishes_cubit.dart';
// Classe de base abstraite pour les états
abstract class DishesState extends Equatable {
  const DishesState();

  @override
  List<Object> get props => [];
}

// État initial, avant tout chargement
final class DishesInitial extends DishesState {}

// État pendant le chargement des données depuis l'API
final class DishesLoading extends DishesState {}

// État lorsque les plats ont été chargés avec succès
final class DishesLoadSuccess extends DishesState {
  // Contient la liste des plats chargés
  final List<MenuItemModel> dishes;

  const DishesLoadSuccess(this.dishes);

  @override
  List<Object> get props => [dishes]; // Important pour Equatable
}

// État en cas d'erreur lors du chargement
final class DishesLoadFailure extends DishesState {
  // Contient le message d'erreur
  final String error;

  const DishesLoadFailure(this.error);

  @override
  List<Object> get props => [error]; // Important pour Equatable
}