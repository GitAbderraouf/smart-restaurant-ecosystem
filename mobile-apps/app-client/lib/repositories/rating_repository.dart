// lib/repositories/rating_repository.dart (Nouveau fichier)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hungerz/Config/app_config.dart'; // Pour AppConfig.baseUrl

class RatingRepository {
  final http.Client httpClient;
  final String _baseUrl = AppConfig.baseUrl;

  RatingRepository({required this.httpClient});

  Future<void> submitOrderRatings({
    required String token,
    required String orderId,
    required Map<String, double> itemRatings, // Clé: menuItemId, Valeur: notation
  }) async {
    // Construire l'URL de l'endpoint. Adaptez ceci à votre API.
    // Exemple: /api/orders/12345/rate-items
    final Uri submitRatingsUrl = Uri.parse('$_baseUrl/orders/$orderId/rate-items');

    // Transformer le map de notations en la structure attendue par le backend.
    // Exemple: une liste d'objets [{ "menuItemId": "id1", "rating": 4.0 }, ...]
    final List<Map<String, dynamic>> ratingsData = itemRatings.entries.map((entry) {
      return {
        'menuItemId': entry.key,
        'ratingValue': entry.value, // ou simplement 'rating' selon votre API
      };
    }).toList();

    // Le corps de la requête pourrait être directement la liste, ou un objet la contenant.
    // Adaptez selon votre API. Exemple: { "ratings": ratingsData }
    final Map<String, dynamic> body = {
      'itemRatings': ratingsData,
    };

    print("RatingRepository: Appel POST $submitRatingsUrl");
    print("RatingRepository: Body: ${json.encode(body)}");
    print("RatingRepository: Token: $token");


    try {
      final response = await httpClient.post(
        submitRatingsUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Succès
        print("RatingRepository: Notations soumises avec succès pour la commande $orderId.");
        // Vous pouvez parser la réponse si le backend renvoie des données utiles.
        // final responseData = json.decode(response.body);
        return; // Indique le succès
      } else {
        // Gérer les erreurs HTTP
        String errorMessage = "Erreur lors de la soumission des notations.";
        try {
          final responseData = json.decode(response.body);
          errorMessage = responseData['message'] ?? "Erreur serveur (Code: ${response.statusCode})";
        } catch (e) {
          // Si le corps de la réponse n'est pas du JSON ou est vide
          errorMessage = "Réponse inattendue du serveur (Code: ${response.statusCode}) - ${response.body}";
        }
        print("RatingRepository: Erreur - $errorMessage");
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Gérer les erreurs réseau ou autres exceptions
      print("RatingRepository: Exception lors de la soumission des notations - $e");
      throw Exception('Erreur de communication avec le serveur: ${e.toString()}');
    }
  }
}
