import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/cubits/ingredient_state.dart';
import 'package:hungerz_store/services/menu_item_service.dart';
import 'package:hungerz_store/models/menu_item_model.dart'; // For Ingredient model
import 'package:flutter/foundation.dart'; // For kDebugMode
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hungerz_store/Config/app_config.dart'; // For AppConfig.baseUrl

class IngredientCubit extends Cubit<IngredientState> {
  final MenuItemService _menuItemService;

  IngredientCubit(this._menuItemService) : super(IngredientInitial());

  Future<void> fetchAllMasterIngredients() async {
    emit(IngredientLoading());
    try {
      // Assuming MenuItemService has getAllMasterIngredients method
      final ingredients = await _menuItemService.getAllMasterIngredients();
      emit(IngredientLoaded(ingredients));
    } catch (e) {
      if (kDebugMode) {
        print('[IngredientCubit] Error fetching master ingredients: $e');
      }
      emit(IngredientError(e.toString()));
    }
  }
} 