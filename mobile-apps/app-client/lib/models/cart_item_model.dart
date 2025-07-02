// models/cart_item.dart ou cart/models/cart_item.dart

import 'menu_item_model.dart'; // Assurez-vous d'importer votre modèle Dish

class CartItem {
  final MenuItemModel dish; // Le plat ajouté
  int quantity;    // La quantité de ce plat dans le panier

  CartItem({required this.dish, required this.quantity});

  // Méthode pratique pour calculer le prix total pour cet item
  double get totalPrice => dish.price * quantity;

  // Vous pourriez ajouter d'autres méthodes ou propriétés si nécessaire
  // (ex: pour l'égalité, la copie, etc., mais gardons simple pour l'instant)
}

