import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:waiter_app/Models/order_model.dart';
import 'package:waiter_app/Config/app_config.dart'; // For socketUrl, assuming API base is similar
import 'package:flutter/foundation.dart'; // For debugPrint

class ApiService {
  // Attempt to derive API base URL from socketUrl.
  // This is a common pattern but might need adjustment if your API is hosted elsewhere.
  static String get _apiBaseUrl {
    try {
      Uri socketUri = Uri.parse(AppConfig.socketUrl);
      // Assuming API is at the same host and port, but with /api path
      // e.g., if socketUrl is http://10.0.2.2:5000, API might be http://10.0.2.2:5000/api
      // If your kitchen_app's api_service.dart uses "/api" prefix, this aligns.
      return '${socketUri.scheme}://${socketUri.host}:${socketUri.port}/api';
    } catch (e) {
      debugPrint('[ApiService] Error parsing socketUrl for API base URL: $e. Falling back to default.');
      // Fallback or throw error - adjust as needed. This is a common local dev setup.
      return 'http://10.0.2.2:5000/api';
    }
  }

  Future<List<Order>> fetchReadyDineInOrders() async {
    // Add a timestamp as a cache buster to ensure we get fresh results
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$_apiBaseUrl/orders/waiter/ready?t=$timestamp');
    debugPrint('[ApiService] Fetching ready dine-in orders from: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['orders'] != null && responseBody['orders'] is List) {
          final List<dynamic> ordersData = responseBody['orders'];
          final List<Order> orders = ordersData
              .map((data) => Order.fromJson(data as Map<String, dynamic>))
              .toList();
          debugPrint('[ApiService] Fetched ${orders.length} ready dine-in orders.');
          return orders;
        } else {
          debugPrint('[ApiService] Invalid orders data format received.');
          throw Exception('Invalid orders data format from server');
        }
      } else {
        debugPrint('[ApiService] Failed to fetch ready orders. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load ready orders from server');
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching ready dine-in orders: $e');
      throw Exception('Failed to connect to the server or process data: $e');
    }
  }

  Future<void> markOrderAsServedApi(String orderId) async {
    final url = Uri.parse('$_apiBaseUrl/orders/$orderId/mark-served');
    debugPrint('[ApiService] Marking order $orderId as served via API: $url');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        // body: json.encode({}), // No body needed if just updating status via path param
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        debugPrint('[ApiService] Order $orderId marked as served successfully via API.');
        // Optionally parse response if backend sends back the updated order and you need it
        // final responseBody = json.decode(response.body);
        // return Order.fromJson(responseBody['order']); 
      } else {
        debugPrint('[ApiService] Failed to mark order $orderId as served. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to mark order as served on server');
      }
    } catch (e) {
      debugPrint('[ApiService] Error marking order $orderId as served: $e');
      throw Exception('Failed to connect to the server or process data: $e');
    }
  }

  Future<List<Order>> fetchServedDineInOrders({int limit = 50}) async {
    final url = Uri.parse('$_apiBaseUrl/orders/waiter/served-dine-in?limit=$limit');
    debugPrint('[ApiService] Fetching SERVED dine-in orders from: $url');

    try {
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['orders'] != null && responseBody['orders'] is List) {
          final List<dynamic> ordersData = responseBody['orders'];
          final List<Order> orders = ordersData
              .map((data) => Order.fromJson(data as Map<String, dynamic>))
              .toList();
          debugPrint('[ApiService] Fetched ${orders.length} SERVED dine-in orders.');
          return orders;
        } else {
          debugPrint('[ApiService] Invalid SERVED orders data format received.');
          throw Exception('Invalid SERVED orders data format from server');
        }
      } else {
        debugPrint('[ApiService] Failed to fetch SERVED orders. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load SERVED orders from server');
      }
    } catch (e) {
      debugPrint('[ApiService] Error fetching SERVED dine-in orders: $e');
      throw Exception('Failed to connect to the server or process data: $e');
    }
  }

  // Placeholder for other API methods if needed in the future
  // Example: Future<void> markOrderAsServedApi(String orderId) async { ... }
}
