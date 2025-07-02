// lib/dishes/cubit/dishes_cubit.dart (Adaptez le chemin)

import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:hungerz/Config/app_config.dart';
// Importer le modèle et l'état AuthCubit (pour le token)
import 'package:hungerz/models/menu_item_model.dart'; // !! ADAPTEZ LE CHEMIN !!
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart'; // !! ADAPTEZ LE CHEMIN !!

part 'dishes_state.dart'; // Lie les états définis précédemment

class DishesCubit extends Cubit<DishesState> {
  // Injecter le client HTTP et AuthCubit pour l'accès au token
  final http.Client httpClient;
  final AuthCubit authCubit; // Pour obtenir le token si nécessaire
  final String _apiBaseUrl = AppConfig.baseUrl;
  DishesCubit({required this.httpClient, required this.authCubit})
      : super(DishesInitial());

  // Méthode pour charger les plats depuis le backend
  Future<void> fetchDishes() async {
    // Vérifier si on est déjà en chargement pour éviter appels multiples
    if (state is DishesLoading) return;

    print("DishesCubit: Début fetchDishes...");
    emit(DishesLoading()); // Émettre l'état de chargement

    // Récupérer le token JWT si la route est protégée
    String? token;
    final currentAuthState = authCubit.state;
    if (currentAuthState is Authenticated) {
      token = currentAuthState.token;
    }

    // !! TODO: Définir l'URL de votre API pour récupérer les plats !!
    // Exemple
    // Ou '/api/menu', '/api/restaurants/ID/menu' etc.

    // Préparer les headers (inclure le token si nécessaire)
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      if (token != null)
        'Authorization': 'Bearer $token', // Ajouter si route protégée
    };

    try {
      print("DishesCubit: Appel GET $_apiBaseUrl");
      final response = await httpClient.get(
        Uri.parse('$_apiBaseUrl/menu-items'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print("DishesCubit: Réponse reçue - Statut ${response.statusCode}");
        // print("DishesCubit: Données reçues: $responseData");

        final List<dynamic>? jsonList = responseData['menuItems'] as List<dynamic>?;

      if (jsonList == null) {
        print("DishesCubit: Erreur - Clé 'menuItems' manquante ou invalide dans la réponse API.");
        emit(DishesLoadFailure("Format de réponse API incorrect (menuItems)."));
        return;
      }
      print("DishesCubit: Parsing de ${jsonList.length} éléments dans 'menuItems'.");
      final List<MenuItemModel> dishes = jsonList
          .where((item) => item is Map<String, dynamic>)
          .map((jsonItem) => MenuItemModel.fromJson(jsonItem as Map<String, dynamic>))
          .toList();

        print("DishesCubit: ${dishes.length} plats parsés avec succès.");
      
        emit(DishesLoadSuccess(dishes)); // Émettre l'état de succès
      } else {
        // Gérer les erreurs HTTP (4xx, 5xx)
        print(
            "DishesCubit: Erreur API - Statut ${response.statusCode}, Body: ${response.body}");
        // Essayer de parser un message d'erreur
        String errorMessage = "Erreur ${response.statusCode}";
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['error'] ?? errorData['message'] ?? errorMessage;
        } catch (_) {}
        emit(DishesLoadFailure(errorMessage)); // Émettre l'état d'échec
      }
    } catch (e, s) {
      // Gérer les erreurs réseau ou autres exceptions
      print("DishesCubit: Erreur Catch dans fetchDishes: $e\n$s");
      emit(DishesLoadFailure(e.toString())); // Émettre l'état d'échec
    }
  }
}
