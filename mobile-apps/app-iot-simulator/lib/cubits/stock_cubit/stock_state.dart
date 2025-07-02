// stock_state.dart (nouveau fichier)
part of 'stock_cubit.dart'; // Si vous séparez en deux fichiers



abstract class StockState extends Equatable {
  const StockState();
  @override
  List<Object> get props => [];
}

class StockInitial extends StockState {}
class StockLoading extends StockState {}
class StockLoaded extends StockState {
  // La structure de votre endpoint getAllStockInfo
  final Map<String, List<Ingredient>> categorizedIngredients;
  final List<Ingredient> lowStockIngredients;
  final int totalIngredients;
  final int lowStockCount;

  const StockLoaded({
    required this.categorizedIngredients,
    required this.lowStockIngredients,
    required this.totalIngredients,
    required this.lowStockCount,
  });

  @override
  List<Object> get props => [categorizedIngredients, lowStockIngredients, totalIngredients, lowStockCount];
}
class StockError extends StockState {
  final String message;
  const StockError(this.message);
  @override
  List<Object> get props => [message];
}