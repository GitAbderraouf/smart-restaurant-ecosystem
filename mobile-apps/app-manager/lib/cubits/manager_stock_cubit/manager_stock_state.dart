// cubits/manager_stock_cubit/manager_stock_state.dart
part of 'manager_stock_cubit.dart';

abstract class ManagerStockState extends Equatable {
  const ManagerStockState();

  @override
  List<Object?> get props => [];
}

class ManagerStockInitial extends ManagerStockState {}

class ManagerStockLoading extends ManagerStockState {}

class ManagerStockLoaded extends ManagerStockState {
  final List<Ingredient> allIngredients; // Une liste plate de tous les ingrédients
  final Map<String, List<Ingredient>> categorizedIngredients;
  final List<Ingredient> lowStockIngredients; // Ingrédients activement en stock bas
  final int totalIngredientsCount;
  final int lowStockIngredientsCount;

  const ManagerStockLoaded({
    required this.allIngredients,
    required this.categorizedIngredients,
    required this.lowStockIngredients,
    required this.totalIngredientsCount,
    required this.lowStockIngredientsCount,
  });

  @override
  List<Object?> get props => [allIngredients, categorizedIngredients, lowStockIngredients, totalIngredientsCount, lowStockIngredientsCount];

  // Helper pour faciliter les mises à jour
  ManagerStockLoaded copyWith({
    List<Ingredient>? allIngredients,
    Map<String, List<Ingredient>>? categorizedIngredients,
    List<Ingredient>? lowStockIngredients,
    int? totalIngredientsCount,
    int? lowStockIngredientsCount,
  }) {
    return ManagerStockLoaded(
      allIngredients: allIngredients ?? this.allIngredients,
      categorizedIngredients: categorizedIngredients ?? this.categorizedIngredients,
      lowStockIngredients: lowStockIngredients ?? this.lowStockIngredients,
      totalIngredientsCount: totalIngredientsCount ?? this.totalIngredientsCount,
      lowStockIngredientsCount: lowStockIngredientsCount ?? this.lowStockIngredientsCount,
    );
  }
}

class ManagerStockError extends ManagerStockState {
  final String message;

  const ManagerStockError(this.message);

  @override
  List<Object?> get props => [message];
}