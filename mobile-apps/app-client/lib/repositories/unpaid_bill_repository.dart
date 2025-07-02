// repositories/unpaid_bill_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hungerz/Config/app_config.dart';
import 'package:hungerz/models/unpaid_bill_model.dart';

class UnpaidBillRepository {
  final http.Client httpClient;
  final String _baseUrl = AppConfig.baseUrl;

  UnpaidBillRepository({required this.httpClient});

  Future<List<UnpaidBillModel>> fetchMyUnpaidBills(
      {required String token}) async {
    final unpaidBillsUrl = Uri.parse(
        '$_baseUrl/bills/my-unpaid'); // Endpoint pour récupérer les factures de l'utilisateur

    print(
        "UnpaidBillRepository: Appel GET (Mes Factures Impayées) -> $unpaidBillsUrl");
    try {
      final response = await httpClient.get(
        unpaidBillsUrl,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> responseData =
            json.decode(response.body) as List<dynamic>;
        return responseData
            .map((billJson) =>
                UnpaidBillModel.fromJson(billJson as Map<String, dynamic>))
            .toList();
      } else {
        // Gérer les erreurs (comme dans votre ReservationRepository)
        String errorMessage = "Erreur serveur";
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(
            'Échec récupération des factures: $errorMessage (Code: ${response.statusCode})');
      }
    } catch (e) {
      print(e);
      throw Exception('Erreur réseau ou autre (récupération factures): $e');
    }
  }

  // PAS DE MÉTHODES getClientSecretForBill ou confirmBackendBillPayment ICI
  // car tout le flux Stripe est géré localement par StripeService.
  // Vous aurez besoin d'une méthode sur votre backend pour marquer la facture comme payée
  // que le Cubit appellera APRÈS un paiement Stripe réussi côté client.

  Future<void> markBillAsPaidOnBackend({
    required String billId,
    required String token,
    String? paymentMethodInfo, // ex: "stripe_payment_intent_id_XYZ"
  }) async {
    final markAsPaidUrl = Uri.parse(
        '$_baseUrl/bills/$billId/mark-as-paid'); // NOUVEL ENDPOINT BACKEND REQUIS
    print(
        "UnpaidBillRepository: Appel POST (Marquer Facture Payée) -> $markAsPaidUrl");
    try {
      final response = await httpClient.post(
        markAsPaidUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'paymentMethod': 'stripe_mobile', // ou une info plus détaillée
          'transactionDetails': paymentMethodInfo,
        }),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        String errorMessage = "Erreur serveur";
        try {
          final errorData = json.decode(response.body);
          errorMessage = errorData['message'] ?? errorMessage;
        } catch (_) {}
        throw Exception(
            "Échec marquage facture payée: $errorMessage (Code: ${response.statusCode})");
      }
      // Succès si pas d'exception
    } catch (e) {
      throw Exception("Erreur réseau ou autre (marquage facture payée): $e");
    }
  }
}
