// cart/cubit/cart_state.dart ou blocs/cart/cart_state.dart

part of 'cart_cubit.dart';

// Classe de base abstraite pour tous les états du panier
abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object> get props => []; // Nécessaire pour Equatable
}

// État initial: Le panier est vide et rien n'a encore été chargé/modifié.
class CartInitial extends CartState {}

// État principal: Le panier a été mis à jour (chargé, item ajouté/modifié/supprimé).
// Cet état contient la liste actuelle des articles et le prix total calculé.
class CartUpdated extends CartState {
  final List<CartItem> items;
  final double totalPrice;

  const CartUpdated({required this.items, required this.totalPrice});

  // On inclut items et totalPrice dans props pour qu'Equatable puisse
  // détecter si l'état a réellement changé.
  @override
  List<Object> get props => [items, totalPrice];

  // Méthode pratique pour obtenir le nombre total d'unités (somme des quantités)
  int get totalItemsQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  // Méthode pratique pour obtenir le nombre de lignes/types d'articles différents
  int get distinctItemsCount => items.length;
}

// Optionnel: État d'erreur si une opération échoue (moins courant pour un panier local simple)
// class CartError extends CartState {
//   final String message;
//   const CartError(this.message);
//   @override
//   List<Object> get props => [message];
// }