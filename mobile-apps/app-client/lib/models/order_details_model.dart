import 'package:hungerz/models/address_model.dart';
import 'package:equatable/equatable.dart';



class AddonModel extends Equatable {
  final String? name;
  final double? price;

  const AddonModel({
    this.name,
    this.price,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    return AddonModel(
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
    };
  }

  @override
  List<Object?> get props => [name, price];
}

class OrderItemModel extends Equatable {
  final String menuItemId; 
  final String name;       
  final double price;      
  final int quantity;
  final double total;      
  final String? specialInstructions;
  final List<AddonModel>? addons;
  final String? image; 
  final double? currentUserRating; // CHAMP AJOUTÉ: Note actuelle de l'utilisateur pour cet article

  const OrderItemModel({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.total,
    this.specialInstructions,
    this.addons,
    this.image,
    this.currentUserRating, // Ajouté au constructeur
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> menuItemData = {};
    // Tente de lire les détails du menuItem s'ils sont populés
    if (json['menuItem'] is Map<String, dynamic>) {
      menuItemData = json['menuItem'] as Map<String, dynamic>;
    } else if (json['menuItemId'] is Map<String, dynamic>) {
      // Fallback si la clé est menuItemId et qu'elle est populée (moins courant pour une liste d'items)
      menuItemData = json['menuItemId'] as Map<String, dynamic>;
    }

    return OrderItemModel(
      menuItemId: menuItemData['_id']?.toString() ?? json['menuItem']?.toString() ?? json['menuItemId']?.toString() ?? '',
      name: menuItemData['name']?.toString() ?? json['name']?.toString() ?? 'Plat inconnu',
      price: (menuItemData['price'] as num?)?.toDouble() ?? (json['price'] as num?)?.toDouble() ?? 0.0,
      image: menuItemData['image']?.toString() ?? json['image']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      specialInstructions: json['specialInstructions'] as String?,
      addons: (json['addons'] as List<dynamic>?)
          ?.map((addonJson) => AddonModel.fromJson(addonJson as Map<String, dynamic>))
          .toList(),
      currentUserRating: (json['currentUserRating'] as num?)?.toDouble(), // Parser la note existante
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItem': menuItemId, 
      'name': name,
      'price': price,
      'quantity': quantity,
      'total': total,
      'specialInstructions': specialInstructions,
      'addons': addons?.map((addon) => addon.toJson()).toList(),
      'image': image,
      'currentUserRating': currentUserRating,
    };
  }

  @override
  List<Object?> get props => [
        menuItemId,
        name,
        price,
        quantity,
        total,
        specialInstructions,
        addons,
        image,
        currentUserRating, // Ajouté aux props
      ];
}


// models/order_details_model.dart (Mis à jour)
 // Importer OrderItemModel

class OrderDetailsModel extends Equatable {
  final String id; // Correspond à _id de Mongoose
  final String? userId; // Référence à User
  final List<OrderItemModel> items;
  final String? tableId; // Référence à Table
  final double subtotal;
  final double deliveryFee;
  final double total;
  final String orderType; // "Take Away", "Delivery", "Dine In"
  final String status;    // "pending", "confirmed", etc.
  final String paymentStatus; // "pending", "paid", "failed"
  final String paymentMethod; // "card", "cash", "wallet"
  final String? paymentId;
  final AddressModel? deliveryAddress; // Nullable, car pas toujours présent
  final String? deliveryInstructions;
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;
  final String? driverId; // Référence à Staff
  final DateTime createdAt;
  final DateTime? updatedAt; // Mongoose `timestamps: true` ajoute aussi `updatedAt`

  const OrderDetailsModel({
    required this.id,
    this.userId,
    required this.items,
    this.tableId,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.orderType,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.paymentId,
    this.deliveryAddress,
    this.deliveryInstructions,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
    this.driverId,
    required this.createdAt,
    this.updatedAt,
  });

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailsModel(
      id: json['_id'] as String,
      userId: json['user'] as String?, // Peut être un objet populé ou juste l'ID
      items: (json['items'] as List<dynamic>)
          .map((itemJson) => OrderItemModel.fromJson(itemJson as Map<String, dynamic>))
          .toList(),
      tableId: json['TableId'] as String?,
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      orderType: json['orderType'] as String,
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String? ?? 'cash',
      paymentId: json['paymentId'] as String?,
      deliveryAddress: json['deliveryAddress'] != null
          ? AddressModel.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
          : null,
      deliveryInstructions: json['deliveryInstructions'] as String?,
      estimatedDeliveryTime: json['estimatedDeliveryTime'] != null
          ? DateTime.tryParse(json['estimatedDeliveryTime'] as String)
          : null,
      actualDeliveryTime: json['actualDeliveryTime'] != null
          ? DateTime.tryParse(json['actualDeliveryTime'] as String)
          : null,
      driverId: json['driverId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // toJson n'est généralement pas nécessaire pour un modèle de "détails" affiché,
  // mais peut être utile pour d'autres opérations.
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'user': userId,
      'items': items.map((item) => item.toJson()).toList(),
      'TableId': tableId,
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'orderType': orderType,
      'status': status,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'deliveryAddress': deliveryAddress?.toJson(),
      'deliveryInstructions': deliveryInstructions,
      'estimatedDeliveryTime': estimatedDeliveryTime?.toIso8601String(),
      'actualDeliveryTime': actualDeliveryTime?.toIso8601String(),
      'driverId': driverId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        items,
        tableId,
        subtotal,
        deliveryFee,
        total,
        orderType,
        status,
        paymentStatus,
        paymentMethod,
        paymentId,
        deliveryAddress,
        deliveryInstructions,
        estimatedDeliveryTime,
        actualDeliveryTime,
        driverId,
        createdAt,
        updatedAt,
      ];
}
