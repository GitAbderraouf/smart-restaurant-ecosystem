// cubits/manager_stock_cubit/manager_stock_cubit.dart
import 'dart:async';
import 'dart:collection'; // Import pour LinkedHashMap
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hungerz_store/Config/app_config.dart';

import '../../models/ingredient_model.dart'; // Votre modèle Ingredient existant
import '../../services/manager_socket_service.dart'; // Le service socket pour l'app Gérant

part 'manager_stock_state.dart';

class ManagerStockCubit extends Cubit<ManagerStockState> {
  final ManagerSocketService _managerSocketService;
  StreamSubscription? _stockUpdateSubscription;

  final _lowStockAlertController = StreamController<Ingredient>.broadcast();
  Stream<Ingredient> get lowStockAlertStream => _lowStockAlertController.stream;

  final String _baseUrl = "${AppConfig.baseUrl}/menu-items";

  ManagerStockCubit(this._managerSocketService) : super(ManagerStockInitial()) {
    _stockUpdateSubscription =
        _managerSocketService.stockUpdateStream.listen((stockUpdateData) {
      _handleStockUpdateFromSocket(stockUpdateData);
    });
  }

  // Modifié pour retourner un LinkedHashMap trié par nom de catégorie
  Map<String, List<Ingredient>> _groupIngredients(
      List<Ingredient> ingredients) {
    final Map<String, List<Ingredient>> groupedUnsorted = {};
    for (var ingredient in ingredients) {
      if (!groupedUnsorted.containsKey(ingredient.category)) {
        groupedUnsorted[ingredient.category] = [];
      }
      groupedUnsorted[ingredient.category]!.add(ingredient);
    }

    // Trier les ingrédients dans chaque catégorie par nom
    groupedUnsorted.forEach((category, ingredientList) {
      ingredientList.sort((a, b) => a.name.compareTo(b.name));
    });

    // Trier les catégories par nom
    final sortedCategoryKeys = groupedUnsorted.keys.toList()..sort();
    final LinkedHashMap<String, List<Ingredient>> sortedGrouped =
        LinkedHashMap();
    for (var key in sortedCategoryKeys) {
      sortedGrouped[key] = groupedUnsorted[key]!;
    }
    return sortedGrouped;
  }

  List<Ingredient> _getLowStockIngredients(List<Ingredient> ingredients) {
    return ingredients
        .where((ing) =>
            ing.lowStockThreshold > 0 && ing.stock <= ing.lowStockThreshold)
        .toList();
  }

  Future<void> fetchInitialStock() async {
    if (state is ManagerStockLoading) return;
    try {
      emit(ManagerStockLoading());
      final response =
          await http.get(Uri.parse('$_baseUrl/ingredients/stock'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        List<Ingredient> allIngredients = [];
        // Utiliser LinkedHashMap pour conserver l'ordre après tri
        final LinkedHashMap<String, List<Ingredient>>
            categorizedIngredientsFromApi = LinkedHashMap();

        final rawCategorizedIngredients =
            data['categorizedIngredients'] as Map<String, dynamic>;

        // Trier les clés de catégorie avant de peupler la map
        final sortedCategoryKeys = rawCategorizedIngredients.keys.toList()
          ..sort();

        for (var categoryKey in sortedCategoryKeys) {
          List<Ingredient> ingredientsForCategory =
              (rawCategorizedIngredients[categoryKey] as List)
                  .map((jsonItem) =>
                      Ingredient.fromJson(jsonItem as Map<String, dynamic>))
                  .toList();
          // Trier les ingrédients dans chaque catégorie par nom
          ingredientsForCategory.sort((a, b) => a.name.compareTo(b.name));
          categorizedIngredientsFromApi[categoryKey] = ingredientsForCategory;
          allIngredients.addAll(ingredientsForCategory);
        }

        // Trier la liste globale aussi, pour la cohérence si elle est utilisée ailleurs
        allIngredients.sort((a, b) => a.name.compareTo(b.name));

        final List<Ingredient> lowStockIngredients =
            _getLowStockIngredients(allIngredients);

        emit(ManagerStockLoaded(
          allIngredients: allIngredients,
          categorizedIngredients: categorizedIngredientsFromApi, // C'est maintenant un LinkedHashMap trié
          lowStockIngredients: lowStockIngredients,
          totalIngredientsCount: data['totalIngredients'] as int,
          lowStockIngredientsCount: lowStockIngredients.length,
        ));
      } else {
        emit(ManagerStockError(
            "Erreur HTTP ${response.statusCode} (Stock Gérant): ${response.body.isNotEmpty ? response.body : 'Aucun message'}"));
      }
    } catch (e) {
      emit(ManagerStockError(
          "Erreur de chargement du stock (Gérant): ${e.toString()}"));
    }
  }

  void _handleStockUpdateFromSocket(StockUpdateData stockUpdateData) {
    if (state is ManagerStockLoaded) {
      final currentLoadedState = state as ManagerStockLoaded;
      debugPrint(
          "ManagerStockCubit: Reçu stockUpdate pour ${stockUpdateData.name} -> ${stockUpdateData.newStockLevel}");

      List<Ingredient> updatedAllIngredients =
          List.from(currentLoadedState.allIngredients);
      int foundIndex =
          updatedAllIngredients.indexWhere((ing) => ing.id == stockUpdateData.ingredientId);

      Ingredient? updatedIngredient;

      if (foundIndex != -1) {
        Ingredient oldIngredient = updatedAllIngredients[foundIndex];
        updatedIngredient = Ingredient(
          id: oldIngredient.id,
          name: stockUpdateData.name,
          unit: stockUpdateData.unit,
          stock: stockUpdateData.newStockLevel,
          lowStockThreshold: oldIngredient.lowStockThreshold,
          category: oldIngredient.category, // Assurez-vous que la catégorie est correcte ou mise à jour si elle est dans StockUpdateData
          createdAt: oldIngredient.createdAt,
          updatedAt: DateTime.now(),
        );
        updatedAllIngredients[foundIndex] = updatedIngredient;
      } else {
        debugPrint(
            "ManagerStockCubit: Ingrédient ${stockUpdateData.ingredientId} non trouvé dans la liste locale pour mise à jour socket.");
        // Optionnel: Créer un nouvel ingrédient s'il n'existe pas et que les données sont suffisantes
        // Pour l'instant, nous allons simplement retourner pour éviter les erreurs si l'ingrédient n'est pas trouvé.
        // Si vous souhaitez l'ajouter, assurez-vous d'avoir toutes les informations nécessaires (comme la catégorie, le seuil, etc.)
        // ou re-fetcher tout le stock.
        // Exemple d'ajout (si vous avez la catégorie dans stockUpdateData):
        /*
        if (stockUpdateData.category != null) { // Supposons que category est dans StockUpdateData
            updatedIngredient = Ingredient(
              id: stockUpdateData.ingredientId,
              name: stockUpdateData.name,
              unit: stockUpdateData.unit,
              stock: stockUpdateData.newStockLevel,
              lowStockThreshold: stockUpdateData.lowStockThreshold ?? 0.0, // Supposons que lowStockThreshold est dans StockUpdateData
              category: stockUpdateData.category!,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            updatedAllIngredients.add(updatedIngredient);
        } else {
          debugPrint("ManagerStockCubit: Impossible d'ajouter le nouvel ingrédient sans catégorie.");
          return;
        }
        */
         return; // Retourner si non trouvé et pas de logique d'ajout
      }


      final Map<String, List<Ingredient>> newCategorizedIngredients =
          _groupIngredients(updatedAllIngredients); // _groupIngredients trie maintenant les catégories et les items
      final List<Ingredient> newLowStockIngredients =
          _getLowStockIngredients(updatedAllIngredients);

      bool wasLowStockBefore = currentLoadedState.lowStockIngredients
          .any((ing) => ing.id == updatedIngredient!.id);
      bool isLowStockNow = updatedIngredient!.lowStockThreshold > 0 &&
          updatedIngredient.stock <= updatedIngredient.lowStockThreshold;

      if (isLowStockNow && !wasLowStockBefore) {
        _lowStockAlertController.add(updatedIngredient);
        debugPrint(
            "ManagerStockCubit: ALERTE STOCK BAS pour ${updatedIngredient.name}");
      }

      emit(ManagerStockLoaded(
        allIngredients: updatedAllIngredients, // Conservez-la triée par nom si nécessaire pour d'autres usages
        categorizedIngredients: newCategorizedIngredients, // C'est maintenant un LinkedHashMap trié
        lowStockIngredients: newLowStockIngredients,
        totalIngredientsCount: updatedAllIngredients.length,
        lowStockIngredientsCount: newLowStockIngredients.length,
      ));
    } else {
      debugPrint(
          "ManagerStockCubit: Reçu stockUpdate mais l'état n'est pas ManagerStockLoaded. Fetching initial stock...");
      fetchInitialStock();
    }
  }

  @override
  Future<void> close() {
    _stockUpdateSubscription?.cancel();
    _lowStockAlertController.close();
    return super.close();
  }
}
