import 'package:equatable/equatable.dart';
import 'package:hungerz_store/models/menu_item_model.dart';

abstract class IngredientState extends Equatable {
  const IngredientState();

  @override
  List<Object> get props => [];
}

class IngredientInitial extends IngredientState {}

class IngredientLoading extends IngredientState {}

class IngredientLoaded extends IngredientState {
  final List<Ingredient> ingredients;

  const IngredientLoaded(this.ingredients);

  @override
  List<Object> get props => [ingredients];
}

class IngredientError extends IngredientState {
  final String message;

  const IngredientError(this.message);

  @override
  List<Object> get props => [message];
} 