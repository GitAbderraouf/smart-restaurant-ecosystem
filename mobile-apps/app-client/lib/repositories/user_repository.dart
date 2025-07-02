// lib/repositories/user_repository.dart

 // Pour json.decode
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:hungerz/Config/app_config.dart';
import 'package:hungerz/models/address_model.dart';
import 'package:hungerz/models/user_model.dart';

// Importer le modèle User (adaptez le chemin)

// Importer potentiellement une source pour le token (ou le passer en argument)
// import 'package:shared_preferences/shared_preferences.dart'; // Exemple

class UserRepository {
  final http.Client httpClient;
  // Définissez l'URL de base de votre API (à mettre dans un fichier de constantes idéalement)
  final String _baseUrl = AppConfig.baseUrl; // exemple: "http://10.0.2.2:3000" ou "https://api.votresite.com"

  // Le constructeur reçoit le client HTTP pour faciliter les tests
  UserRepository({required this.httpClient});

  // --- Méthode pour récupérer le profil utilisateur (incluant les favoris) ---
  

  // --- Méthode pour ajouter un favori ---
  Future<void> addFavorite(String token, String dishId) async {
    final addFavoriteUrl = Uri.parse('$_baseUrl/users/favorites/$dishId'); // Adaptez l'endpoint
    print("UserRepository: Appel POST $addFavoriteUrl");

    try {
       final response = await httpClient.post(
         addFavoriteUrl,
         headers: {
           'Content-Type': 'application/json', // Important même si pas de body parfois
           'Authorization': 'Bearer $token',
         },
         // Ajoutez un body si votre API le requiert: body: json.encode({'some_data': 'value'}),
       );

        // Vérifier les codes de succès (ex: 200 OK, 201 Created)
       if (response.statusCode < 200 || response.statusCode >= 300) {
           print("UserRepository: Erreur addFavorite - ${response.statusCode}: ${response.body}");
          throw Exception('Échec de l\'ajout du favori (Code: ${response.statusCode})');
       }
       print("UserRepository: Favori $dishId ajouté avec succès.");
     } catch (e) {
       print("UserRepository: Exception addFavorite - $e");
       throw Exception('Erreur réseau ou autre lors de l\'ajout du favori: $e');
     }
  }

  // --- Méthode pour supprimer un favori ---
  Future<void> removeFavorite(String token, String dishId) async {
    final removeFavoriteUrl = Uri.parse('$_baseUrl/users/favorites/$dishId'); // Adaptez l'endpoint
    print("UserRepository: Appel DELETE $removeFavoriteUrl");

     try {
       final response = await httpClient.delete(
         removeFavoriteUrl,
         headers: {
           'Authorization': 'Bearer $token',
         },
       );

       // Vérifier les codes de succès (ex: 200 OK, 204 No Content)
       if (response.statusCode < 200 || response.statusCode >= 300) {
           print("UserRepository: Erreur removeFavorite - ${response.statusCode}: ${response.body}");
           throw Exception('Échec de la suppression du favori (Code: ${response.statusCode})');
       }
        print("UserRepository: Favori $dishId supprimé avec succès.");
     } catch (e) {
        print("UserRepository: Exception removeFavorite - $e");
        throw Exception('Erreur réseau ou autre lors de la suppression du favori: $e');
     }
  }

    Future<UserModel?> saveUserAddress(String token, AddressModel address) async {
    // Adaptez l'endpoint: ex: '/api/user/addresses' pour POST une nouvelle adresse
    final saveAddressUrl = Uri.parse('$_baseUrl/users/addresses');
    print("UserRepository: Appel POST $saveAddressUrl");
    try {
      final response = await httpClient.post(
        saveAddressUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(address.toJson()), // Convertit AddressModel en JSON
      );

      if (response.statusCode == 200 || response.statusCode == 201) { // 201 Created est courant
        print("UserRepository: Adresse sauvegardée avec succès.");
        // Si votre API renvoie l'objet User mis à jour (avec la nouvelle liste d'adresses) :
        // final data = json.decode(response.body);
        // return User.fromJson(data['user']); // Adaptez la structure de la réponse API
        // Si l'API ne renvoie rien d'utile (juste succès), retournez null:
        return null;
      } else {
         print("UserRepository: Erreur saveUserAddress - ${response.statusCode}: ${response.body}");
        throw Exception('Échec sauvegarde adresse (Code: ${response.statusCode})');
      }
    } catch (e) {
       print("UserRepository: Exception saveUserAddress - $e");
       throw Exception('Erreur réseau ou autre (sauvegarde adresse): $e');
    }
  }

  // --- Méthode (Exemple) pour récupérer le token stocké ---
  // Vous pourriez avoir cette logique ici ou dans un service séparé


}
