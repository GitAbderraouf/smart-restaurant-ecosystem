// lib/repositories/order_repository.dart (Nouveau fichier)

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hungerz/Config/app_config.dart';
import 'package:hungerz/models/cart_item_model.dart'; // Pour CartItem
import 'package:hungerz/models/address_model.dart'; // Pour AddressModel
import 'package:hungerz/common/enums.dart'; // Pour DeliveryMethod, PaymentMethod
// --- AJOUT: Modèle pour les détails de la commande retournée ---
import 'package:hungerz/models/order_details_model.dart'; // À créer

class OrderRepository {
  final http.Client httpClient;
  final String _baseUrl = AppConfig.baseUrl; // Adaptez

  OrderRepository({required this.httpClient});

  Future<OrderDetailsModel> createOrder({
    required String token,
    required String userId,
    required List<CartItem> items,
    required AddressModel? deliveryAddress, // Peut être null pour TakeAway
    required DeliveryMethod deliveryMethod,
    required PaymentMethod paymentMethod,
    String? deliveryInstructions, // Optionnel
    // Ajoutez sessionId, TableId si nécessaire
  }) async {
    final orderUrl = Uri.parse('$_baseUrl/orders/'); // Adaptez l'endpoint POST

    // 1. Mapper les CartItem au format attendu par l'API
    final mappedItems = items.map((item) => {
      'menuItemId': item.dish.id, // Assurez-vous que dish.id existe et est non-null
      'quantity': item.quantity,
    }).toList();

    // 2. Convertir les enums en String attendus par l'API
    //    (Attention à la casse: "Delivery" vs "delivery")
    String orderTypeString = (deliveryMethod == DeliveryMethod.delivery) ? "Delivery" : "Take Away";
    String paymentMethodString = paymentMethod.name; // Utilise le nom de l'enum ('cash', 'wallet', 'card')

    // 3. Construire le corps de la requête
    final Map<String, dynamic> body = {
      'userId': userId,
      'items': mappedItems,
      'orderType': orderTypeString,
      'paymentMethod': paymentMethodString,
      // Inclure l'adresse seulement si c'est une livraison et si elle existe
      if (deliveryMethod == DeliveryMethod.delivery && deliveryAddress != null)
         'deliveryAddress': deliveryAddress.toJson(), // Utilise toJson du modèle
      if (deliveryInstructions != null && deliveryInstructions.isNotEmpty)
         'deliveryInstructions': deliveryInstructions,
      // Ajoutez sessionId, TableId ici si besoin
    };

    print("OrderRepository: Appel POST $orderUrl");
    print("OrderRepository: Body: ${json.encode(body)}"); // Log pour déboguer

    try {
      final response = await httpClient.post(
        orderUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 201) { // Created
        final data = json.decode(response.body);
        print("OrderRepository: Commande créée avec succès. Réponse: $data");
        // Parser la réponse (qui contient les détails de la commande)
        // en utilisant un modèle OrderDetailsModel.fromJson
        return OrderDetailsModel.fromJson(data['order']); // Adaptez la clé 'order' si besoin
      } else {
        print("OrderRepository: Erreur createOrder - ${response.statusCode}: ${response.body}");
        // Essayer de parser un message d'erreur du backend
        String errorMessage = "Erreur serveur";
        try {
           final errorData = json.decode(response.body);
           errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception('Échec création commande: $errorMessage (Code: ${response.statusCode})');
      }
    } catch (e) {
      print("OrderRepository: Exception createOrder - $e");
      throw Exception('Erreur réseau ou autre (création commande): $e');
    }
  }

  Future<List<OrderDetailsModel>> getOrderHistory({required String token, required String userId}) async {
    final historyUrl = Uri.parse('$_baseUrl/orders/'); // Updated to use the correct endpoint

    print("OrderRepository getOrderHistory: Appel GET $historyUrl");

    try {
      final response = await httpClient.get(
        historyUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
       // final Map<String, dynamic> responseData = json.decode(response.body);
      // print("OrderRepository getOrderHistory: Commandes récupérées: $responseData");
        // The backend returns { orders: [...] }
        final List<dynamic> ordersData = json.decode(response.body) as List<dynamic>;
        return ordersData.map((data) => OrderDetailsModel.fromJson(data)).toList();
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = errorData['message'] ?? "Erreur serveur lors de la récupération de l'historique.";
        print("OrderRepository getOrderHistory: Erreur ${response.statusCode}: $errorMessage");
        throw Exception('Échec de récupération de l\'historique des commandes: $errorMessage (Code: ${response.statusCode})');
      }
    } catch (e) {
      print("OrderRepository getOrderHistory: Exception: $e");
      throw Exception('Erreur réseau ou autre (récupération historique): $e');
    }
  }
}


