import 'package:flutter/foundation.dart';

class OrderItem {
  final String productId;
  final String name;
  final int quantity;
  final double price;
  final String category;
  final String specialInstructions;
  // Add other item details if needed, e.g., price

  OrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.category,
    this.specialInstructions = '',
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String? ?? 'N/A',
      name: json['name'] as String? ?? 'Unknown Item',
      quantity: json['quantity'] as int? ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] as String? ?? 'Uncategorized',
      specialInstructions: json['specialInstructions'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'quantity': quantity,
    'price': price,
    'category': category,
    'specialInstructions': specialInstructions,
  };
}

class Order {
  final String id;
  final String orderNumber;
  final List<OrderItem> items;
  final String orderType;
  final String tableId; // For Dine In, this would be the table identifier
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? readyAt; // When the order became ready_for_pickup
  final double totalAmount;
  final String paymentStatus;
  // final String? kitchenStaffId; // Optional
  // final String? waiterId; // Optional

  Order({
    required this.id,
    required this.orderNumber,
    required this.items,
    required this.orderType,
    required this.tableId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.readyAt,
    required this.totalAmount,
    required this.paymentStatus,
    // this.kitchenStaffId,
    // this.waiterId,
  });

  Order copyWith({
    String? id,
    String? orderNumber,
    List<OrderItem>? items,
    String? orderType,
    String? tableId,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? readyAt,
    double? totalAmount,
    String? paymentStatus,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      items: items ?? this.items,
      orderType: orderType ?? this.orderType,
      tableId: tableId ?? this.tableId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      readyAt: readyAt ?? this.readyAt,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<OrderItem> orderItems = itemsList.map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList();

    return Order(
      id: json['id'] as String? ?? 'N/A',
      orderNumber: json['orderNumber'] as String? ?? 'N/A',
      items: orderItems,
      orderType: json['orderType'] as String? ?? 'Unknown',
      tableId: json['tableId'] as String? ?? 'N/A',
      status: json['status'] as String? ?? 'Unknown',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now() : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now() : DateTime.now(),
      readyAt: json['readyAt'] != null ? DateTime.tryParse(json['readyAt'] as String) : null,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      // kitchenStaffId: json['kitchenStaffId'] as String?,
      // waiterId: json['waiterId'] as String?,
    );
  }

   Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'items': items.map((item) => item.toJson()).toList(),
    'orderType': orderType,
    'tableId': tableId,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'readyAt': readyAt?.toIso8601String(),
    'totalAmount': totalAmount,
    'paymentStatus': paymentStatus,
    // 'kitchenStaffId': kitchenStaffId,
    // 'waiterId': waiterId,
  };

  // Helper for debugging or display
  @override
  String toString() {
    return 'Order{id: $id, orderNumber: $orderNumber, table: $tableId, items: ${items.length}, status: $status, total: $totalAmount}';
  }
} 