import 'package:equatable/equatable.dart';
// Importez vos autres modèles si nécessaire (ex: pour les items pré-sélectionnés)
// import 'package:hungerz/models/menu_item_model.dart';

// Modèle pour un créneau horaire et sa disponibilité
class TimeSlotAvailabilityModel extends Equatable {
  final String time; // Ex: "19:00", "19:30"
  final bool available; // true si des tables sont libres, false sinon

  const TimeSlotAvailabilityModel({required this.time, required this.available});

  // Factory pour créer depuis un JSON (adaptez les clés si besoin)
  factory TimeSlotAvailabilityModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotAvailabilityModel(
      time: json['time'] as String? ?? '00:00', // Clé 'time' attendue
      available: json['available'] as bool? ?? false, // Clé 'available' attendue
    );
  }

  @override
  List<Object?> get props => [time, available];
}


// Modèle pour représenter une réservation effectuée
// Adaptez les champs selon ce que votre API retourne après création
// ou lors de la récupération de l'historique
class ReservationModel extends Equatable {
  final String id;
  final String userId;
  final String tableId;
  final DateTime reservationTime;
  final int guests;
  final String status;
  final List<Map<String, dynamic>>? preselectedItems;
  final String? specialRequests;
  final String? paymentMethod; // <-- AJOUT (peut être String ou votre enum PaymentMethod)

  const ReservationModel({
    required this.id,
    required this.userId,
    required this.tableId,
    required this.reservationTime,
    required this.guests,
    required this.status,
    this.preselectedItems,
    this.specialRequests,
    this.paymentMethod, // <-- AJOUT
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    // ... (logique de parsing pour les autres champs comme avant) ...
    return ReservationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? 'error_id',
      userId: json['userId']?.toString() ?? 'error_userId',
      tableId: json['tableId']?.toString() ?? 'error_tableId',
      reservationTime: DateTime.tryParse(json['reservationTime']?.toString() ?? '') ?? DateTime.now(),
      guests: (json['guests'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'unknown',
      preselectedItems: (json['preSelectedMenu'] as List<dynamic>?)
    ?.map((itemData) {
        final itemMap = itemData as Map<String, dynamic>;
        // Extraire les infos du plat populé
        final menuItemDetails = itemMap['menuItemId'] as Map<String, dynamic>?;
        return {
            'menuItemId': menuItemDetails?['_id']?.toString() ?? itemMap['menuItemId']?.toString(), // Fallback si pas populé
            'name': menuItemDetails?['name']?.toString() ?? 'Plat inconnu', // <-- Utiliser le nom populé
            'price': (menuItemDetails?['price'] as num?)?.toDouble(), // <-- Utiliser le prix populé
            'image': menuItemDetails?['image'] as String?, // <-- Utiliser l'image populée
            'quantity': (itemMap['quantity'] as num?)?.toInt() ?? 1,
            'specialInstructions': itemMap['specialInstructions'] as String?,
        };
    })
    .toList(),
      specialRequests: json['specialRequests'] as String?,
      paymentMethod: json['paymentMethod'] as String?, // <-- AJOUT
    );
  }

  @override
  List<Object?> get props => [id, userId, tableId, reservationTime, guests, status, preselectedItems, specialRequests, paymentMethod]; // <-- AJOUT
}