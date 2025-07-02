// lib/repositories/reservation_repository.dart

import 'dart:convert'; // Pour json.decode / json.encode
import 'package:http/http.dart' as http; // Pour les appels HTTP
import 'package:hungerz/Config/app_config.dart';
import 'package:hungerz/common/enums.dart';
import 'package:hungerz/models/reservation_model.dart';
import 'package:intl/intl.dart'; // Pour formater la date

// --- Importer vos modèles ---
// Assurez-vous que les chemins sont corrects
// Contient TimeSlotAvailabilityModel et ReservationModel
import 'package:hungerz/models/cart_item_model.dart'; // Pour mapper le panier

class ReservationRepository {
  final http.Client httpClient;
  // --- !!! ADAPTEZ VOTRE URL DE BASE API !!! ---
  final String _baseUrl = AppConfig.baseUrl; // Ex: "http://192.168.1.XX:3000"

  ReservationRepository({required this.httpClient});

  // --- Méthode pour vérifier la disponibilité des créneaux horaires ---
  Future<List<TimeSlotAvailabilityModel>> getAvailability({
    // L'ID du restaurant dont on vérifie la dispo
    required DateTime date, // La date sélectionnée
    required int guests, // Le nombre de personnes
    required String token, // Le token JWT pour l'authentification
  }) async {
    // Formater la date en YYYY-MM-DD pour l'API
    final String formattedDate = DateFormat('yyyy-MM-dd').format(date);

    // Construire l'URL avec les paramètres query
    // !!! ADAPTEZ L'ENDPOINT EXACT DE VOTRE API !!!
    final availabilityUrl = Uri.parse('$_baseUrl/reservations/availability')
        .replace(queryParameters: {
      'date': formattedDate,
      'guests': guests.toString(), // Envoyer comme String
    });

    print(
        "ReservationRepository: Appel GET (Disponibilité) -> $availabilityUrl");

    try {
      final response = await httpClient.get(
        availabilityUrl,
        headers: {
          // 'Content-Type': 'application/json', // Pas nécessaire pour GET sans body
          'Authorization': 'Bearer $token', // Authentification
        },
      );

      if (response.statusCode == 200) {
        // Décoder la réponse JSON, qui doit être une liste d'objets
        final Map<String, dynamic> responseData = json.decode(response.body);
        print(
            "ReservationRepository: Disponibilités reçues (brut): $responseData");
        final List<dynamic> data =
            responseData['availableSlots'] as List<dynamic>;
        // Mapper chaque objet JSON en TimeSlotAvailabilityModel
        final List<TimeSlotAvailabilityModel> slots = data
            .map((slotJson) => TimeSlotAvailabilityModel.fromJson(
                slotJson as Map<String, dynamic>))
            .toList();

        print(
            "ReservationRepository: Disponibilités parsées: ${slots.length} créneaux");
        print(slots);
        return slots;
      } else {
        // Gérer les erreurs HTTP (4xx, 5xx)
        print(
            "ReservationRepository: Erreur getAvailability - ${response.statusCode}: ${response.body}");
        throw Exception(
            'Échec de la récupération des disponibilités (Code: ${response.statusCode})');
      }
    } catch (e) {
      // Gérer les erreurs réseau ou de parsing JSON
      print("ReservationRepository: Exception getAvailability - $e");
      throw Exception(
          'Erreur réseau ou autre lors de la récupération des disponibilités: $e');
    }
  }

  // --- Méthode pour créer une réservation ---
  // Retourne le modèle de la réservation créée si l'API le fournit
  Future<String> createReservation({
    required String token, // ID du restaurant (si nécessaire pour l'API)
    required DateTime date, // Date sélectionnée
    required String timeSlot, // Créneau horaire sélectionné (ex: "19:30")
    required int guests, // Nombre de personnes
    required PaymentMethod paymentMethod,
    required List<CartItem> preselectedItems, // Articles du panier
    String? specialRequests, // Instructions spéciales optionnelles
    // Ajoutez d'autres paramètres si votre API les requiert (ex: tableId si connu ?)
  }) async {
    // !!! ADAPTEZ L'ENDPOINT POST DE VOTRE API !!!
    final reservationUrl = Uri.parse('$_baseUrl/reservations');

    // 1. Mapper les CartItem au format attendu par preSelectedMenu
    final mappedItems = preselectedItems
        .map((item) => {
              'menuItemId':
                  item.dish.id, // Assurez-vous que dish.id existe et est String
              'quantity': item.quantity,
              // Ajoutez 'specialInstructions' ici si vous le gérez par item
              // 'specialInstructions': item.specialInstruction ?? null
            })
        .toList();

    // 2. Combiner date et timeSlot en une date/heure complète (format ISO8601)
    // (Utilise la date sélectionnée et l'heure du créneau)
    DateTime reservationDateTime;
    try {
      List<String> timeParts = timeSlot.split(':');
      reservationDateTime = DateTime(date.year, date.month, date.day,
          int.parse(timeParts[0]), int.parse(timeParts[1]));
    } catch (e) {
      print("Erreur formatage date/heure: $e");
      throw Exception("Format d'heure invalide: $timeSlot");
    }
    String formattedReservationTime = reservationDateTime.toIso8601String();

    // 3. Construire le corps JSON de la requête
    final Map<String, dynamic> body = {
      // Si votre API a besoin de l'ID du resto
      'reservationTime': formattedReservationTime, // La date+heure combinées
      'guests': guests, // Le nombre de convives
      'preSelectedMenu': mappedItems,
      'paymentMethod': paymentMethod.name, // La liste des plats/qté
      if (specialRequests != null && specialRequests.isNotEmpty)
        'specialRequests': specialRequests, // Instructions si présentes
      // Ajoutez 'tableId' ici UNIQUEMENT si votre logique frontend
      // est capable de présélectionner/connaître une tableId spécifique.
      // Sinon, le backend devrait l'assigner.
      // Le 'userId' est généralement extrait du 'token' côté backend.
    };

    print(
        "ReservationRepository: Appel POST (Création Résa) -> $reservationUrl");
    print("ReservationRepository: Body -> ${json.encode(body)}");

    try {
      final response = await httpClient.post(
        reservationUrl,
        headers: {
          'Content-Type':
              'application/json; charset=UTF-8', // Spécifier charset
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      // Vérifier le code de statut (201 Created est idéal)
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
            "ReservationRepository: Réservation créée avec succès. Réponse: $data");
        // Parser la réponse JSON en utilisant ReservationModel.fromJson
        // Adaptez la clé ('reservation'?) si l'objet n'est pas à la racine
        return data['reservation']["_id"];
        //ReservationModel.fromJson(data['reservation'] ?? data);
      } else {
        // Gérer les erreurs HTTP
        print(
            "ReservationRepository: Erreur createReservation - ${response.statusCode}: ${response.body}");
        String errorMessage = "Erreur serveur";
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(
            'Échec création réservation: $errorMessage (Code: ${response.statusCode})');
      }
    } catch (e) {
      // Gérer les erreurs réseau ou de parsing JSON
      print("ReservationRepository: Exception createReservation - $e");
      throw Exception('Erreur réseau ou autre (création réservation): $e');
    }
  }

  Future<List<ReservationModel>> getUserReservations(String token) async {
    // !!! ADAPTEZ L'ENDPOINT EXACT DE VOTRE API !!!
    final reservationsUrl =
        Uri.parse('$_baseUrl/reservations'); // Ou juste /api/reservations (GET)

    print(
        "ReservationRepository: Appel GET (Mes Réservations) -> $reservationsUrl");

    try {
      final response = await httpClient.get(
        reservationsUrl,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print(
            "ReservationRepository: Mes Réservations reçues (brut): $responseData");
        final List<dynamic> data =
            responseData['reservations'] as List<dynamic>;
        // Mapper la liste JSON en liste de modèles
        // Assurez-vous que votre backend retourne une liste directement ou adaptez le parsing

        final List<ReservationModel> reservations = data
            .map((reservationJson) => ReservationModel.fromJson(
                reservationJson as Map<String, dynamic>))
            .toList();

        print(
            "ReservationRepository: Mes Réservations parsées: ${reservations.length}");
        return reservations;
      } else {
        print(
            "ReservationRepository: Erreur getUserReservations - ${response.statusCode}: ${response.body}");
        throw Exception(
            "Échec récupération de l'historique des réservations (Code: ${response.statusCode})");
      }
    } catch (e) {
      print("ReservationRepository: Exception getUserReservations - $e");
      throw Exception('Erreur réseau ou autre (historique réservations): $e');
    }
  }

  // --- Ajoutez ici d'autres méthodes si nécessaire ---
  // Future<List<ReservationModel>> getUserReservations(String token) async { ... }
  // Future<void> cancelReservation(String token, String reservationId) async { ... }
  // --------------------------------------------------
}
