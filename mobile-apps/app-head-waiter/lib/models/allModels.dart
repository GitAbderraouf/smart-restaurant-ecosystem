// models/chef_app_models.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Pour debugPrint

// Énumération pour le statut des tables dans l'UI Flutter
enum TableStatus { free, occupied, reserved, needsAttention, unknown }

class TableModel extends Equatable {
  final String id; // Correspond à _id de Mongoose Table (ObjectId converti en String)
  final String tabletDeviceId; // Correspond à tableId (String unique) de Mongoose Table
  final String displayName;    // Nom affiché (ex: "Table 1", ou le tableId si pas de nom)
  final TableStatus status;
  final bool isActive;
  final String? currentSessionId; // Correspond à Mongoose TableSession._id (ObjectId en String)
  final String? currentCustomerId; // Correspond à Mongoose TableSession.clientId (User._id en String)
  final String? currentCustomerName; // Dénormalisé depuis User.fullName via TableSession
  final DateTime? sessionStartTime;  // Dénormalisé depuis TableSession.startTime
  final List<ReservationModel> associatedReservations;
  final bool isLoadingReservations;

  const TableModel({
    required this.id,
    required this.tabletDeviceId,
    required this.displayName,
    required this.status,
    required this.isActive,
    this.currentSessionId,
    this.currentCustomerId,
    this.currentCustomerName,
    this.sessionStartTime,
    this.associatedReservations = const [],
    this.isLoadingReservations = false,
  });

  // Constructeur Factory pour parser les données JSON de votre API/Socket
  factory TableModel.fromJson(Map<String, dynamic> json) {
    TableStatus determineStatus(String? statusStringApi, String? currentSessionApi_Id) {
      if (currentSessionApi_Id != null && statusStringApi?.toLowerCase() == 'occupied') {
        return TableStatus.occupied;
      }
      switch (statusStringApi?.toLowerCase()) {
        case 'available':
          return TableStatus.free;
        case 'occupied':
          return TableStatus.occupied;
        case 'reserved':
          return TableStatus.reserved;
        case 'cleaning':
          return TableStatus.needsAttention;
        default:
          debugPrint("TableModel.fromJson: Statut inconnu reçu '$statusStringApi' pour tableId '${json['tableId']}', défaut sur 'unknown'.");
          return TableStatus.unknown;
      }
    }
    
    // Le backend devrait idéalement envoyer les détails de la session dénormalisés
    // si la table est occupée.
    // Structure attendue si currentSession est peuplé et ses détails sont envoyés :
    // json['currentSessionDetails'] = { 
    //   '_id': 'sessionObjectId', 
    //   'clientId': {'_id': 'userObjectId', 'fullName': 'Nom Client'}, 
    //   'startTime': 'ISODateString' 
    // }
    // OU les champs peuvent être directement au premier niveau de 'json' s'ils sont dénormalisés par le backend.
    final currentSessionDetailsData = json['currentSessionDetails'] as Map<String, dynamic>?;
    final clientDetailsData = currentSessionDetailsData?['clientId'] as Map<String, dynamic>?;

    return TableModel(
      id: json['_id'] as String, // Mongoose Table._id (String)
      tabletDeviceId: json['tableId'] as String, // Mongoose Table.tableId (String unique de la tablette)
      displayName: json['name'] as String? ?? 
                   'Table ${ (json['tableId'] as String?)?.isNotEmpty == true ? (json['tableId'] as String).substring((json['tableId'] as String).length > 4 ? (json['tableId'] as String).length - 4 : 0) : json['_id']?.substring((json['_id'] as String).length > 4 ? (json['_id'] as String).length - 4 : 0) ?? 'N/A'}',
      status: determineStatus(json['status'] as String?, json['currentSession'] as String?), // json['currentSession'] est l'ID de la session Mongoose (String)
      isActive: json['isActive'] as bool? ?? false,
      currentSessionId: json['currentSession'] as String? ?? currentSessionDetailsData?['_id'] as String?, 
      currentCustomerId: clientDetailsData?['_id'] as String? ?? json['currentCustomerId'] as String?, // Fallback si envoyé directement
      currentCustomerName: clientDetailsData?['fullName'] as String? ?? json['currentCustomerName'] as String?, // Fallback
      sessionStartTime: json['sessionStartTime'] != null // Si le backend envoie ce champ dénormalisé au premier niveau
          ? DateTime.tryParse(json['sessionStartTime'] as String)
          : (currentSessionDetailsData?['startTime'] != null
              ? DateTime.tryParse(currentSessionDetailsData!['startTime'] as String)
              : null),
      associatedReservations: [], // Sera chargé à la demande
    );
  }

  TableModel copyWith({
    String? id,
    String? tabletDeviceId,
    String? displayName,
    TableStatus? status,
    bool? isActive,
    String? currentSessionId,
    ValueGetter<String?>? currentCustomerId,
    ValueGetter<String?>? currentCustomerName,
    ValueGetter<DateTime?>? sessionStartTime,
    List<ReservationModel>? associatedReservations,
    bool? isLoadingReservations,
  }) {
    return TableModel(
      id: id ?? this.id,
      tabletDeviceId: tabletDeviceId ?? this.tabletDeviceId,
      displayName: displayName ?? this.displayName,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      currentSessionId: currentSessionId ?? this.currentSessionId,
      currentCustomerId: currentCustomerId != null ? currentCustomerId() : this.currentCustomerId,
      currentCustomerName: currentCustomerName != null ? currentCustomerName() : this.currentCustomerName,
      sessionStartTime: sessionStartTime != null ? sessionStartTime() : this.sessionStartTime,
      associatedReservations: associatedReservations ?? this.associatedReservations,
      isLoadingReservations: isLoadingReservations ?? this.isLoadingReservations,
    );
  }

  @override
  List<Object?> get props => [
        id, tabletDeviceId, displayName, status, isActive, currentSessionId,
        currentCustomerId, currentCustomerName, sessionStartTime,
        associatedReservations, isLoadingReservations,
      ];
}

class ReservationModel extends Equatable {
  final String id; // Mongoose Reservation._id (String)
  final String userId; // Mongoose User._id (String)
  final String customerName; // Dénormalisé depuis User.fullName
  final String? tableMongoId; // Mongoose Reservation.tableId (ObjectId du doc Table, en String)
  final DateTime reservationTime;
  final int guestCount;
  final String status; // "confirmed", "cancelled", "completed", "no-show", "seated"
  final List<OrderItemModel> preSelectedMenu;
  final String? specialRequests;

  const ReservationModel({
    required this.id,
    required this.userId,
    required this.customerName,
    this.tableMongoId,
    required this.reservationTime,
    required this.guestCount,
    required this.status,
    this.preSelectedMenu = const [],
    this.specialRequests,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    // Le backend doit s'assurer que 'user' (ou 'userId' si c'est un objet peuplé)
    // et 'menuItemId' dans preSelectedMenu sont bien peuplés avec les détails nécessaires.
    
    final userDataFromApi = json['userId']; // Ou json['user'] si c'est le nom du champ peuplé
    String finalUserId = '';
    String finalCustomerName = 'Client Inconnu';

    if (userDataFromApi is Map<String, dynamic>) { // Si userId est un objet User peuplé
      finalUserId = userDataFromApi['_id'] as String? ?? '';
      finalCustomerName = userDataFromApi['fullName'] as String? ?? 'Client (Peuplé)';
    } else if (userDataFromApi is String) { // Si userId est juste un String (ID)
      finalUserId = userDataFromApi;
      // Le nom du client pourrait être dans un champ séparé si le backend le dénormalise
      finalCustomerName = json['customerName'] as String? ?? 'Client (ID Seul)';
    }


    return ReservationModel(
      id: json['_id'] as String,
      userId: finalUserId,
      customerName: finalCustomerName,
      tableMongoId: json['tableId'] as String?, // Mongoose Reservation.tableId (ObjectId de Table)
      reservationTime: DateTime.parse(json['reservationTime'] as String), // Attend une chaîne ISO 8601
      guestCount: json['guests'] as int? ?? 0,
      status: json['status'] as String? ?? 'confirmed',
      preSelectedMenu: (json['preSelectedMenu'] as List<dynamic>? ?? [])
          .map((itemData) {
              final item = itemData as Map<String, dynamic>;
              // Supposer que menuItemId est un objet MenuItem peuplé par le backend
              // avec au moins _id, name, price.
              final menuItemDetails = item['menuItemId'] as Map<String, dynamic>?; 
              
              if (menuItemDetails == null) {
                // Cas où menuItemId est juste un ID String (moins idéal, le backend devrait peupler)
                 debugPrint("ReservationModel.fromJson: menuItemId non peuplé pour l'item: ${item['menuItemId']}");
                return OrderItemModel(
                  menuItemId: item['menuItemId'] as String? ?? '',
                  name: item['name'] as String? ?? 'Plat (ID seul)', 
                  quantity: item['quantity'] as int? ?? 1,
                  price: (item['price'] as num?)?.toDouble() ?? 0.0,
                );
              }
              // Cas idéal où menuItemId est un objet peuplé
              return OrderItemModel(
                menuItemId: menuItemDetails['_id'] as String,
                name: menuItemDetails['name'] as String? ?? 'Plat API',
                quantity: item['quantity'] as int? ?? 1,
                price: (menuItemDetails['price'] as num?)?.toDouble() ?? 0.0,
              );
          }).toList(),
      specialRequests: json['specialRequests'] as String?,
    );
  }
  
  Map<String, dynamic> toJsonForApi() { // Pour envoyer à une API
    return {
      'reservationId': id,
      'userId': userId,
      'customerName': customerName,
      'tableMongoId': tableMongoId,
      'reservationTime': reservationTime.toIso8601String(),
      'guestCount': guestCount,
      'status': status,
      'preSelectedMenu': preSelectedMenu.map((item) => item.toMap()).toList(),
      'specialRequests': specialRequests,
    };
  }

  @override
  List<Object?> get props => [
        id, userId, customerName, tableMongoId, reservationTime, guestCount,
        status, preSelectedMenu, specialRequests,
      ];
}

class OrderItemModel extends Equatable {
  final String menuItemId; // Mongoose MenuItem._id (String)
  final String name;
  final int quantity;
  final double price; // Prix au moment de la réservation

  const OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  // Ce constructeur est utilisé si le backend envoie les détails du plat déjà structurés.
  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      menuItemId: map['menuItemId'] as String, // Doit être l'ID du MenuItem
      name: map['name'] as String? ?? 'Plat Inconnu', // Nom du plat, fourni par le backend
      quantity: map['quantity'] as int? ?? 1,
      price: (map['price'] as num?)?.toDouble() ?? 0.0, // Prix du plat, fourni par le backend
    );
  }

  Map<String, dynamic> toMap() { // Utilisé pour envoyer les données à l'API (ex: notifyKitchenOfPreOrder)
    return {
      'menuItemId': menuItemId,
      'name': name, 
      'quantity': quantity,
      'price': price, 
    };
  }

  @override
  List<Object?> get props => [menuItemId, name, quantity, price];
}
