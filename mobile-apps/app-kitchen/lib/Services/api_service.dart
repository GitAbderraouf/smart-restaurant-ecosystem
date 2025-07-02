import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:hungerz_kitchen/Config/app_config.dart';
import 'package:hungerz_kitchen/Models/order_model.dart';

class ApiService {
  // Use the correct backend base URL for your setup
  final String _baseUrl = "${AppConfig.apiBaseUrl}/api"; // Added /api prefix

  // --- ADDED: Fetch active orders for the main screen ---
  Future<List<Order>> fetchActiveKitchenOrders() async {
    final Uri uri = Uri.parse('$_baseUrl/kitchen/orders'); // Correct endpoint
    log('[ApiService] Fetching active kitchen orders from: $uri'); // Enhanced log

    try {
      log('[ApiService] Making HTTP GET request...'); // <-- ADD LOG
      // TODO: Add authentication headers if needed
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // 'Authorization': 'Bearer YOUR_TOKEN',
        },
      ).timeout(const Duration(seconds: 15)); // Add timeout
      log('[ApiService] HTTP GET request completed. Status: ${response.statusCode}'); // <-- ADD LOG

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('orders') &&
            responseData['orders'] is List) {
          final List<dynamic> ordersJson = responseData['orders'];
          final List<Order> orders = ordersJson
              .map((jsonItem) {
                try {
                  return Order.fromJson(jsonItem as Map<String, dynamic>);
                } catch (e) {
                  log('Error parsing active order item: $e\nJSON: $jsonItem');
                  return null; // Skip orders that fail parsing
                }
              })
              .whereType<Order>() // Filter out nulls
              .toList();
          log('Successfully fetched and parsed ${orders.length} active orders.');
          return orders;
        } else {
          log('Error: Active orders response missing "orders" list or is not a list.');
          throw Exception('Invalid response format for active orders');
        }
      } else {
        log('Error fetching active orders: Status code ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load active orders (Status code: ${response.statusCode})');
      }
    } catch (e) {
      log('Network or parsing error fetching active orders: $e');
      // Rethrow the exception to be handled by the caller (e.g., FutureBuilder)
      throw Exception('Failed to load active orders: $e');
    }
  }
  // --------------------------------------------------------

  // Fetch completed orders for the "Past Orders" screen
  Future<List<Order>> fetchCompletedOrders({int limit = 50}) async {
    // Corrected endpoint to match backend routes
    final Uri uri = Uri.parse('$_baseUrl/kitchen/completed?limit=$limit');
    log('Fetching completed orders from: $uri');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          // TODO: Add authentication headers if needed
        },
      ).timeout(const Duration(seconds: 15)); // Add timeout

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        if (responseData.containsKey('orders') &&
            responseData['orders'] is List) {
          final List<dynamic> ordersJson = responseData['orders'];
          final List<Order> orders = ordersJson
              .map((jsonItem) {
                try {
                  return Order.fromJson(jsonItem as Map<String, dynamic>);
                } catch (e) {
                  log('Error parsing completed order item: $e\nJSON: $jsonItem');
                  return null; // Skip orders that fail parsing
                }
              })
              .whereType<Order>() // Filter out nulls
              .toList();
          log('Successfully fetched and parsed ${orders.length} completed orders.');
          return orders;
        } else {
          log('Error: Completed orders response missing "orders" list or is not a list.');
          throw Exception('Invalid response format for completed orders');
        }
      } else {
        log('Error fetching completed orders: Status code ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to load completed orders (Status code: ${response.statusCode})');
      }
    } catch (e) {
      log('Network or parsing error fetching completed orders: $e');
      throw Exception('Failed to load completed orders: $e');
    }
  }

  // Method to update the status of an order
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    final Uri uri = Uri.parse('$_baseUrl/orders/$orderId/status');
    log('Updating order $orderId status to $newStatus via: $uri');

    try {
      final response = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'status': newStatus}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        log('Successfully updated order $orderId status to $newStatus.');
        return true;
      } else {
        log('Error updating order $orderId status: Status code ${response.statusCode}, Body: ${response.body}');
        throw Exception(
            'Failed to update order status (Status code: ${response.statusCode})');
      }
    } catch (e) {
      log('Network or parsing error updating order status: $e');
      throw Exception('Failed to update order status: $e');
    }
  }

  // TODO: Add other API methods if needed (e.g., update order status)
}
