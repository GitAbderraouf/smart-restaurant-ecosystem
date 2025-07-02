// cubit/stock_cubit/stock_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Pour debugPrint
import 'package:iot_simulator_app/config/app_config.dart';

import '../../models/ingredient_model.dart'; // Ajustez le chemin
import '../../services/socket_service.dart';   // NOUVEAU: Importer SocketService

part 'stock_state.dart';

class StockCubit extends Cubit<StockState> { // Renommé pour clarté si StockState est aussi utilisé pour le modèle
  final SocketService _socketService; // NOUVEAU: Dépendance à SocketService

  // Remplacez par l'URL de votre backend
  final String _baseUrl = "${AppConfig.baseUrl}/api/menu-items"; 

  StockCubit(this._socketService) : super(StockInitial()) { // NOUVEAU: Injecter SocketService
    // Écouter les mises à jour de stock venant du backend
    _socketService.listenToStockSync(_handleStockSyncFromSocket);
  }

  Future<void> fetchInitialStock() async {
    // ... (votre logique fetchInitialStock existante reste la même) ...
    // (s'assure d'émettre StockLoaded avec la structure Map<String, List<Ingredient>>)
     try {
      emit(StockLoading());
      final response = await http.get(Uri.parse('$_baseUrl/ingredients/stock'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        final Map<String, List<Ingredient>> categorizedIngredients = {};
        (data['categorizedIngredients'] as Map<String, dynamic>).forEach((category, ingredientsJson) {
          categorizedIngredients[category] = (ingredientsJson as List)
              .map((jsonItem) => Ingredient.fromJson(jsonItem as Map<String, dynamic>))
              .toList();
        });

        final List<Ingredient> lowStockIngredients = (data['lowStockIngredients'] as List)
            .map((jsonItem) => Ingredient.fromJson(jsonItem as Map<String, dynamic>))
            .toList();

        emit(StockLoaded(
          categorizedIngredients: categorizedIngredients,
          lowStockIngredients: lowStockIngredients,
          totalIngredients: data['totalIngredients'] as int,
          lowStockCount: data['lowStockCount'] as int,
        ));
      } else {
        emit(StockError("Erreur HTTP ${response.statusCode} (Stock): ${response.body.isNotEmpty ? response.body : 'Aucun message'}"));
      }
    } catch (e) {
      emit(StockError("Erreur de chargement du stock: ${e.toString()}"));
    }
  }

  // Appelée quand le simulateur modifie un stock via son UI
  void simulatorUpdateStock(String ingredientId, double newStockLevel) {
    if (state is StockLoaded) {
      final currentLoadedState = state as StockLoaded;

      // 1. Mettre à jour l'état localement (pour réactivité UI)
      final updatedCategorizedIngredients = Map<String, List<Ingredient>>.from(currentLoadedState.categorizedIngredients);
      bool foundAndUpdated = false;

      for (var category in updatedCategorizedIngredients.keys) {
        final ingredientsInCategory = updatedCategorizedIngredients[category]!;
        for (var i = 0; i < ingredientsInCategory.length; i++) {
          if (ingredientsInCategory[i].id == ingredientId) {
            // Important: Créez une nouvelle instance si Ingredient est immuable,
            // ou appelez une méthode de mise à jour si Ingredient est mutable.
            // Notre Ingredient a une méthode updateStockValue et stockController.
            ingredientsInCategory[i].updateStockValue(newStockLevel);
            foundAndUpdated = true;
            break;
          }
        }
        if (foundAndUpdated) break;
      }

      if (foundAndUpdated) {
        // TODO: Recalculer lowStockIngredients, totalIngredients, lowStockCount si nécessaire
        // Pour l'instant, on se concentre sur la mise à jour de la liste principale
         emit(StockLoaded(
          categorizedIngredients: updatedCategorizedIngredients,
          lowStockIngredients: currentLoadedState.lowStockIngredients, // À recalculer
          totalIngredients: currentLoadedState.totalIngredients,
          lowStockCount: currentLoadedState.lowStockCount // À recalculer
        ));

        // 2. Émettre la mise à jour au backend via SocketService
        _socketService.sendStockUpdate(
          deviceId: SocketService.stockManagerDeviceId, // Utiliser l'ID statique défini dans SocketService
          ingredientId: ingredientId,
          newStockLevel: newStockLevel,
        );
      }
    }
  }

  // Appelée par SocketService quand un événement 'stock_level_sync' est reçu
  void _handleStockSyncFromSocket(dynamic data) {
    if (state is StockLoaded && data is Map<String, dynamic>) {
      final currentLoadedState = state as StockLoaded;
      debugPrint("StockCubit: Reçu _handleStockSyncFromSocket avec data: $data");

      final String ingredientId = data['ingredientId'];
      final double newStock = (data['stock'] as num).toDouble(); // Le backend envoie 'stock' après la mise à jour
      // Le payload de stock_level_sync contient aussi name, unit, etc.
      // que vous pouvez utiliser pour créer/mettre à jour l'objet Ingredient complet.

      final updatedCategorizedIngredients = Map<String, List<Ingredient>>.from(currentLoadedState.categorizedIngredients);
      bool found = false;

      for (var category in updatedCategorizedIngredients.keys) {
        final ingredientsInCategory = updatedCategorizedIngredients[category]!;
        for (var i = 0; i < ingredientsInCategory.length; i++) {
          if (ingredientsInCategory[i].id == ingredientId) {
            ingredientsInCategory[i].updateStockValue(newStock);
            // Optionnel: Mettre à jour d'autres champs si le payload de sync les contient
            ingredientsInCategory[i].name = data['name'] ?? ingredientsInCategory[i].name;
            ingredientsInCategory[i].unit = data['unit'] ?? ingredientsInCategory[i].unit;
            // ...
            found = true;
            break;
          }
        }
        if (found) break;
      }

      // Si l'ingrédient n'existait pas localement (peu probable si fetchInitialStock a fonctionné)
      // vous pourriez avoir une logique pour l'ajouter.

      if (found) {
        // TODO: Recalculer lowStockIngredients, totalIngredients, lowStockCount
         emit(StockLoaded(
          categorizedIngredients: updatedCategorizedIngredients,
          lowStockIngredients: currentLoadedState.lowStockIngredients, // À recalculer
          totalIngredients: currentLoadedState.totalIngredients,
          lowStockCount: currentLoadedState.lowStockCount // À recalculer
        ));
         debugPrint("StockCubit: État mis à jour après sync pour $ingredientId");
      } else {
        debugPrint("StockCubit: Ingrédient $ingredientId non trouvé pour la synchronisation.");
        // Peut-être re-fetcher tout le stock si un ingrédient est manquant ?
        // fetchInitialStock();
      }
    }
  }
}