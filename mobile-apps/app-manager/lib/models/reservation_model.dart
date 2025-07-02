import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class Reservation {
  final String id;
  final DateTime reservationTime;
  final int guests;
  final String status;
  final String? paymentMethod;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime? completedAt;
  final TableInfo? table;
  final Customer? customer;
  final List<MenuItem> preSelectedMenu;
  final double? revenue;

  Reservation({
    required this.id,
    required this.reservationTime,
    required this.guests,
    required this.status,
    this.paymentMethod,
    this.specialRequests,
    required this.createdAt,
    this.completedAt,
    this.table,
    this.customer,
    this.preSelectedMenu = const [],
    this.revenue,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('[Reservation.fromJson] Processing reservation: ${json['_id'] ?? json['id']}');
    }
 
    final customerData = json['customer'];
    Customer? customerObj;
    
    if (customerData != null) {
      try {
        customerObj = Customer.fromJson(customerData);
      } catch (e) {
        if (kDebugMode) {
          print('[Reservation.fromJson] Error parsing customer: $e for customerData: $customerData');
        }
        customerObj = null; 
      }
    }

    List<MenuItem> menuItems = [];
    if (json['preSelectedMenu'] != null && json['preSelectedMenu'] is List) {
      try {
        menuItems = (json['preSelectedMenu'] as List)
            .map((itemJson) {
              if (itemJson is Map<String, dynamic>) {
                return MenuItem.fromJson(itemJson);
              } else {
                if (kDebugMode) {
                  print('[Reservation.fromJson] Warning: preSelectedMenu item is not a Map: $itemJson');
                }
                return null; 
              }
            })
            .whereType<MenuItem>() 
            .toList();
      } catch (e) {
        if (kDebugMode) {
          print('[Reservation.fromJson] Error parsing preSelectedMenu: $e for preSelectedMenuData: ${json['preSelectedMenu']}');
        }
        menuItems = [];
      }
    }

    // --- Detailed Table Parsing Debug ---
    if (kDebugMode) {
      final reservationIdForLog = json['_id']?.toString() ?? json['id']?.toString() ?? 'UNKNOWN_ID';
      print('[Reservation.fromJson] ResId: $reservationIdForLog - Checking table data from json key "tableId".');
      final tableValue = json['tableId'];
      print('[Reservation.fromJson] ResId: $reservationIdForLog - raw json["tableId"] type is ${tableValue?.runtimeType}. Is null? ${tableValue == null}');
      if (tableValue != null && tableValue is! Map<String, dynamic>) {
         print('[Reservation.fromJson] ResId: $reservationIdForLog - WARNING: json["tableId"] is not a Map, actual value: $tableValue');
      }
    }

    final dynamic tableData = json['tableId'];
    TableInfo? tableInfo;

    if (tableData != null && tableData is Map<String, dynamic>) {
      try {
        tableInfo = TableInfo.fromJson(tableData);
      } catch (e) {
        if (kDebugMode) {
          final reservationIdForLog = json['_id']?.toString() ?? json['id']?.toString() ?? 'UNKNOWN_ID';
          print('[Reservation.fromJson] ResId: $reservationIdForLog - Error parsing TableInfo: $e for tableData in json["tableId"]: $tableData');
        }
        tableInfo = null;
      }
    } else if (tableData != null) {
        // This case handles if backend sends just an ObjectId string for tableId (i.e. populate failed or not used)
        // or if it's some other non-map type.
         if (kDebugMode) {
            final reservationIdForLog = json['_id']?.toString() ?? json['id']?.toString() ?? 'UNKNOWN_ID';
            print('[Reservation.fromJson] ResId: $reservationIdForLog - json["tableId"] was present but not a Map: $tableData. Cannot create TableInfo.');
        }
    }
    
    double? revenue;
    if (json['revenue'] != null) {
      if (json['revenue'] is num) {
        revenue = (json['revenue'] as num).toDouble();
      } else if (json['revenue'] is String) {
        revenue = double.tryParse(json['revenue'] as String);
      }
    }
    
    return Reservation(
      id: json['_id'] ?? json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      reservationTime: DateTime.tryParse(json['reservationTime'] ?? '') ?? DateTime.now(),
      guests: (json['guests'] as num?)?.toInt() ?? 0,
      status: json['status'] ?? 'pending',
      customer: customerObj,
      table: tableInfo,
      preSelectedMenu: menuItems,
      paymentMethod: json['paymentMethod'] as String?,
      specialRequests: json['specialRequests'] as String?,
      revenue: revenue,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      completedAt: json['completedAt'] != null 
          ? DateTime.tryParse(json['completedAt'] as String? ?? '') 
          : null,
    );
  }

  String get reservationDateDisplay {
    return DateFormat('EEE, MMM d, yyyy').format(reservationTime);
  }

  String get reservationTimeDisplay {
    return DateFormat('h:mm a').format(reservationTime);
  }

  String get occasionDisplay {
    return specialRequests?.isNotEmpty == true ? specialRequests! : 'N/A';
  }
  
  // Calculate total revenue from menu items if not provided directly
  double get totalRevenue {
    if (revenue != null) return revenue!;
    return preSelectedMenu.fold(
      0, 
      (sum, item) => sum + ((item.price ?? 0) * item.quantity)
    );
  }
  
  // Format reservation time relative to now
  String get timeRelativeToNow {
    final now = DateTime.now();
    final difference = reservationTime.difference(now);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr';
    } else if (difference.inHours >= 24 && difference.inHours < 48) {
      return 'tomorrow'; // Handle "tomorrow" specifically
    } else {
      return '${difference.inDays} days';
    }
  }
  
  @override
  String toString() {
    return 'Reservation{id: $id, time: $reservationTime, guests: $guests, status: $status, customer: $customer, table: $table, preSelectedMenu: ${preSelectedMenu.length} items, revenue: $revenue}';
  }
}

class Customer {
  final String id;
  final String? name;
  final String? email;
  final String? phone;

  Customer({
    required this.id,
    this.name,
    this.email,
    this.phone,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    // Debug print to see what's coming from the backend
    if (kDebugMode) {
      print('[Customer.fromJson] Customer JSON: $json');
    }
    
    // Try to handle different field names that might be coming from the backend
    String? customerName;
    String? customerPhone;
    String customerId = json['_id'] ?? json['id'] ?? '';
    
    // Check for name field with different possible keys
    if (json.containsKey('name') && json['name'] != null) {
      customerName = json['name'] as String?;
    } else if (json.containsKey('fullName') && json['fullName'] != null) {
      customerName = json['fullName'] as String?;
    }
    
    // Check for phone field with different possible keys
    if (json.containsKey('phone') && json['phone'] != null) {
      customerPhone = json['phone'] as String?;
    } else if (json.containsKey('mobileNumber') && json['mobileNumber'] != null) {
      customerPhone = json['mobileNumber'] as String?;
    }
    
    final customer = Customer(
      id: customerId,
      name: customerName,
      email: json['email'] as String?,
      phone: customerPhone,
    );
    
    if (kDebugMode) {
      print('[Customer.fromJson] Created customer: $customer');
    }
    
    return customer;
  }

  String get displayName {
    if (name != null && name!.isNotEmpty) {
      return name!;
    }
    return 'Guest';
  }
  
  @override
  String toString() {
    return 'Customer{id: $id, name: $name, email: $email, phone: $phone}';
  }
}

class TableInfo {
  final String id;
  final String? tableNumber; // This will store the display ID, e.g., "T1"
  final String? status;

  TableInfo({
    required this.id,
    this.tableNumber,
    this.status,
  });

  factory TableInfo.fromJson(Map<String, dynamic> json) {
    if (kDebugMode) {
      print('[TableInfo.fromJson] Table JSON: $json');
    }
    return TableInfo(
      id: json['_id'] ?? json['id'] ?? '',
      // Prioritize 'tableId' from backend populate, then 'tableNumber' as fallback
      tableNumber: json['tableId'] as String? ?? json['tableNumber'] as String?,
      status: json['status'] as String?,
    );
  }
  
  String get tableId {
    return tableNumber ?? 'N/A';
  }
  
  @override
  String toString() {
    return 'TableInfo{id: $id, tableNumber: $tableNumber, status: $status}';
  }
}

class MenuItem {
  final String id;
  final String? name;
  final double? price;
  final String? category;
  final String? image;
  final int quantity;
  final String? specialInstructions;

  MenuItem({
    required this.id,
    this.name,
    this.price,
    this.category,
    this.image,
    required this.quantity,
    this.specialInstructions,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      category: json['category'] as String?,
      image: json['image'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      specialInstructions: json['specialInstructions'] as String?,
    );
  }
  
  @override
  String toString() {
    return 'MenuItem{id: $id, name: $name, quantity: $quantity}';
  }
}

extension ReservationExtension on Reservation {
  String get reservationDateDisplay {
    return DateFormat('EEE, MMM d, yyyy').format(reservationTime);
  }
  
  String get reservationTimeDisplay {
    return DateFormat('h:mm a').format(reservationTime);
  }
  
  String get timeRelativeToNow {
    final now = DateTime.now();
    final difference = reservationTime.difference(now);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr';
    } else if (difference.inHours >= 24 && difference.inHours < 48) {
      return 'tomorrow'; // Handle "tomorrow" specifically
    } else {
      return '${difference.inDays} days';
    }
  }
}