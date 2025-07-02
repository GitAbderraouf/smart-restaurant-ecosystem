import 'package:flutter/foundation.dart';

// Helper to safely parse dates from JSON
DateTime? _parseDateTime(String? dateStr) {
  if (dateStr == null) return null;
  return DateTime.tryParse(dateStr);
}

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final String? specialInstructions;
  final double price;
  final String? category;

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    this.specialInstructions,
    required this.price,
    this.category,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String? ?? 'unknown_product_id',
      name: json['name'] as String? ?? 'Unknown Item',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      specialInstructions: json['specialInstructions'] as String?,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String?,
    );
  }

  String get displayName {
    // Consistent with previous displayName logic
    String main = '$name x$quantity';
    if (specialInstructions != null && specialInstructions!.isNotEmpty) {
      return '$main ($specialInstructions)';
    }
    return main;
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String? userName;
  final List<OrderItem> items;
  final String orderType;
  final String? tableId; // Backend sends this directly, can be null
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readyAt;
  final double totalAmount;
  final String paymentStatus;
  final String? paymentMethod; // Can be null from backend
  final DateTime? servedAt; // Specific to served orders, can be null

  // Fields not present in getPendingAndReadyOrders/getServedOrders, made nullable
  // or removed if not used by other parts of the app that share this model.
  // For this rebuild, focusing only on what these two endpoints provide.
  final String? userId;
  final String? deviceId; // tableId is now the primary field from backend for this
  final double? subtotal;
  final double? deliveryFee;
  final DeliveryAddress? deliveryAddress;
  final String? deliveryInstructions;
  final String? rejectionReason;
  final String? userMobileNumber; // Added new field


  Order({
    required this.id,
    required this.orderNumber,
    this.userName,
    required this.items,
    required this.orderType,
    this.tableId,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.readyAt,
    required this.totalAmount,
    required this.paymentStatus,
    this.paymentMethod,
    this.servedAt,
    // Optional fields
    this.userId,
    this.deviceId,
    this.subtotal,
    this.deliveryFee,
    this.deliveryAddress,
    this.deliveryInstructions,
    this.rejectionReason,
    this.userMobileNumber, // Added to constructor
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List<dynamic>? ?? [];
    List<OrderItem> orderItems = rawItems
        .map((itemJson) => OrderItem.fromJson(itemJson as Map<String, dynamic>))
        .toList();

    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String? ?? json['id'].toString().substring(json['id'].toString().length - 6).toUpperCase(),
      userName: json['userName'] as String?,
      items: orderItems,
      orderType: json['orderType'] as String? ?? 'N/A',
      tableId: json['tableId'] as String?, // Directly from backend
      status: json['status'] as String? ?? 'unknown',
      createdAt: _parseDateTime(json['createdAt'] as String?) ?? DateTime.now(), // Fallback to now if null
      updatedAt: _parseDateTime(json['updatedAt'] as String?),
      readyAt: _parseDateTime(json['readyAt'] as String?),
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      paymentMethod: json['paymentMethod'] as String?, // Will be null if not sent
      servedAt: _parseDateTime(json['servedAt'] as String?),

      // Optional fields - not directly in pending-ready/served endpoints
      // If these are sent by other endpoints that use this model, they can be parsed here.
      // For now, they will be null when parsing pending-ready/served orders.
      userId: json['user'] as String?, // Backend sends userName, not userId in these specific routes
      deviceId: json['deviceId'] as String?, // Backend resolves tableId or deviceId into json['tableId']
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble(),
      deliveryAddress: json['deliveryAddress'] != null
          ? DeliveryAddress.fromJson(json['deliveryAddress'] as Map<String, dynamic>)
          : null,
      deliveryInstructions: json['deliveryInstructions'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      userMobileNumber: json['userMobileNumber'] as String?, // Added parsing
    );
  }

  String get customerNameToDisplay {
    // Prioritize tableId as per user request.
    // If tableId is valid, display it.
    if (tableId != null && tableId!.trim().isNotEmpty && tableId!.trim().toLowerCase() != 'n/a') {
      return "Table: ${tableId!.trim()}";
    }
    // If tableId is not suitable, display N/A.
    return 'N/A'; 
  }

  String get orderIdToDisplay {
    // Use orderNumber if available, otherwise fallback to a part of the ID
    return orderNumber.isNotEmpty ? orderNumber : id.substring(id.length - 6).toUpperCase();
  }
}

// DeliveryAddress class (kept for compatibility if other parts of the app use it)
// This is NOT part of the getPendingAndReadyOrders or getServedOrders responses.
class DeliveryAddress {
  final String? address;
  final String? apartment;
  final String? landmark;
  final double? latitude;
  final double? longitude;

  DeliveryAddress({
    this.address,
    this.apartment,
    this.landmark,
    this.latitude,
    this.longitude,
  });

  factory DeliveryAddress.fromJson(Map<String, dynamic> json) {
    return DeliveryAddress(
      address: json['address'] as String?,
      apartment: json['apartment'] as String?,
      landmark: json['landmark'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
} 