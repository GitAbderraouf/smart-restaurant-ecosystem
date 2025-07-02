// user_app/lib/cubits/cart_cubit/cart_cubit.dart
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:equatable/equatable.dart'; // For CartState
import 'package:hungerz/models/cart_item_model.dart';
import 'package:hungerz/models/menu_item_model.dart'; 
// Removed: import 'package:hungerz/services/user_app_socket_service.dart'; - Not used directly in CartCubit logic

part 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  final List<CartItem> _items = [];

  CartCubit() : super(CartInitial()) {
     _emitCartUpdated(); // Emit initial empty cart state for listeners
  }

  // Existing methods: addItem, removeItem, incrementItem, decrementItem, clearCart
  void addItem(MenuItemModel dish) {
    final existingItem = _items.firstWhereOrNull((item) => item.dish.id == dish.id);
    if (existingItem != null) {
      existingItem.quantity++;
    } else {
      // Ensure dish has an ID, otherwise CartItem might be problematic
      if (dish.id == null) {
        print("CartCubit: Attempted to add dish without an ID: ${dish.name}");
        return; // Or handle error appropriately
      }
      _items.add(CartItem(dish: dish, quantity: 1));
    }
    _emitCartUpdated();
  }

  void removeItem(String dishId) {
    _items.removeWhere((item) => item.dish.id == dishId);
    _emitCartUpdated();
  }

  void incrementItem(String dishId) {
    final item = _items.firstWhereOrNull((item) => item.dish.id == dishId);
    if (item != null) {
      item.quantity++;
      _emitCartUpdated();
    }
  }

  void decrementItem(String dishId) {
    final item = _items.firstWhereOrNull((item) => item.dish.id == dishId);
    if (item != null) {
      item.quantity--;
      if (item.quantity <= 0) {
        _items.remove(item);
      }
      _emitCartUpdated();
    }
  }

  void clearCart() {
    _items.clear();
    _emitCartUpdated();
  }
  // End Existing methods

  // ***** NEW METHOD for session cart synchronization *****
  void replaceCartWithSessionItems(List<Map<String, dynamic>> itemsDataFromServer) {
    _items.clear(); // Clear the current local cart
    print("CartCubit: Replacing cart with ${itemsDataFromServer.length} items from server session.");

    for (var itemJson in itemsDataFromServer) {
      try {
        // This assumes your MenuItemModel.fromJson can handle the structure
        // sent by the backend in 'session_created' and 'table_session_cart_updated' events.
        // The backend should ideally send enough data to reconstruct a meaningful MenuItemModel.
        // Payload from backend for each item in the list:
        // { menuItemId: "...", name: "...", price: ..., quantity: ..., image: "..." (optional), category: "..." (optional) }
        
        // Attempt to create MenuItemModel. If backend sends full item details, this is easier.
        // If backend only sends IDs, you might need to fetch full details or use placeholder MenuItemModel.
        // For this example, we assume enough data is sent to construct a displayable MenuItemModel.
        final menuItem = MenuItemModel(
          id: itemJson['menuItemId'] as String?,
          name: itemJson['name'] as String? ?? 'Unknown Item', // Default if name is missing
          price: (itemJson['price'] as num?)?.toDouble() ?? 0.0, // Default if price is missing
          image: itemJson['image'] as String?, // Optional
          category: itemJson['category'] as String? ?? 'Uncategorized', // Optional, default
          // Initialize other MenuItemModel fields to defaults or null as appropriate
          // e.g., description: null, dietaryInfo: null, healthInfo: null, isAvailable: true, isPopular: false, etc.
        );

        final quantity = (itemJson['quantity'] as num?)?.toInt() ?? 0;

        if (quantity > 0 && menuItem.id != null) { // Only add if quantity > 0 and ID is present
            _items.add(CartItem(dish: menuItem, quantity: quantity));
        } else if (menuItem.id == null) {
            print("CartCubit: Skipping item due to missing menuItemId in replaceCart: $itemJson");
        }
      } catch (e, s) {
        print("Error parsing session item in CartCubit.replaceCartWithSessionItems: $e - Stack: $s - Item JSON: $itemJson");
      }
    }
    _emitCartUpdated(); // Update cart state and UI
  }
  // ***** END NEW METHOD *****

  void _emitCartUpdated() {
    final double totalPrice = _calculateTotalPrice();
    // Ensure to emit a new list instance for Equatable to detect change
    emit(CartUpdated(items: List.from(_items), totalPrice: totalPrice));
  }

  double _calculateTotalPrice() {
    return _items.fold(0.0, (sum, item) => sum + (item.dish.price * item.quantity));
  }
}
