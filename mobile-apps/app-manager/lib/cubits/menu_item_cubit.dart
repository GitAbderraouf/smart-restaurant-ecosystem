import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/models/menu_item_model.dart';
import 'package:hungerz_store/services/menu_item_service.dart';

// --- States ---
abstract class MenuItemState extends Equatable {
  const MenuItemState();
  @override
  List<Object?> get props => [];
}

class MenuItemInitial extends MenuItemState {}

class MenuItemLoading extends MenuItemState {
  final List<String> categories;
  final String selectedCategory;
  const MenuItemLoading({required this.categories, required this.selectedCategory});
  @override
  List<Object?> get props => [categories, selectedCategory];
}

class MenuItemLoaded extends MenuItemState {
  final List<MenuItem> menuItems;
  final List<String> categories;
  final String selectedCategory;

  const MenuItemLoaded({
    required this.menuItems,
    required this.categories,
    required this.selectedCategory,
  });

  @override
  List<Object?> get props => [menuItems, categories, selectedCategory];
}

class MenuItemError extends MenuItemState {
  final String message;
  final List<String> categories;
  final String? selectedCategory;
  const MenuItemError(this.message, {required this.categories, this.selectedCategory});
  @override
  List<Object?> get props => [message, categories, selectedCategory];
}

// --- Cubit ---
class MenuItemCubit extends Cubit<MenuItemState> {
  final MenuItemService _menuItemService;

  final List<String> categoryDisplayNames = [
    'Burgers', 'Pizzas', 'Pates', 'Kebabs', 'Tacos', 'Poulet', 
    'Healthy', 'Traditional', 'Dessert', 'Sandwich'
  ];
  // For API calls, we might need lowercase or specific keys
  final List<String> categoryApiKeys = [
    'burgers', 'pizzas', 'pates', 'kebabs', 'tacos', 'poulet', 
    'healthy', 'traditional', 'dessert', 'sandwich'
  ];

  MenuItemCubit(this._menuItemService) : super(MenuItemInitial()) {
    // Load items for the first category by default
    if (categoryApiKeys.isNotEmpty) {
      fetchMenuItemsForCategory(categoryApiKeys.first, isInitialLoad: true);
    }
  }

  List<String> get categories => categoryDisplayNames;

  Future<void> fetchMenuItemsForCategory(String categoryApiKey, {bool isInitialLoad = false}) async {
    try {
      emit(MenuItemLoading(categories: categoryDisplayNames, selectedCategory: categoryApiKey));
      final items = await _menuItemService.getMenuItemsByCategory(categoryApiKey);
      emit(MenuItemLoaded(
        menuItems: items,
        categories: categoryDisplayNames,
        selectedCategory: categoryApiKey,
      ));
    } catch (e) {
      emit(MenuItemError(
        'Failed to fetch items for $categoryApiKey: ${e.toString()}',
        categories: categoryDisplayNames,
        selectedCategory: categoryApiKey,
      ));
    }
  }

  Future<void> toggleItemAvailability(String itemId, bool currentAvailability) async {
    final previousState = state;
    if (previousState is MenuItemLoaded) {
      // Optimistically update UI
      final updatedItems = previousState.menuItems.map((item) {
        if (item.id == itemId) {
          return MenuItem(
            id: item.id, name: item.name, price: item.price, category: item.category,
            image: item.image, description: item.description, dietaryInfo: item.dietaryInfo,
            healthInfo: item.healthInfo, isPopular: item.isPopular, preparationTime: item.preparationTime,
            isAvailable: !currentAvailability // Toggle availability
          );
        }
        return item;
      }).toList();
      emit(MenuItemLoaded(
        menuItems: updatedItems,
        categories: previousState.categories,
        selectedCategory: previousState.selectedCategory
      ));

      try {
        await _menuItemService.updateMenuItemAvailability(itemId, !currentAvailability);
        // If API call is successful, state is already updated. 
        // Optionally, refetch to ensure data consistency if backend returns the full updated item
        // final updatedItemFromApi = await _menuItemService.updateMenuItemAvailability(itemId, !currentAvailability);
        // final finalItems = previousState.menuItems.map((item) => item.id == itemId ? updatedItemFromApi : item).toList();
        // emit(MenuItemLoaded(menuItems: finalItems, categories: previousState.categories, selectedCategory: previousState.selectedCategory));

      } catch (e) {
        // Revert to previous state on error and show error message
        emit(previousState); // Revert optimistic update
        // Optionally, emit a specific error state or use a snackbar to show the error
        emit(MenuItemError(
          'Failed to update availability for item $itemId: ${e.toString()}',
          categories: previousState.categories,
          selectedCategory: previousState.selectedCategory
        ));
      }
    }
  }
} 