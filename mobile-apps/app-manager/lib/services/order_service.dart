import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hungerz_store/Config/app_config.dart'; // Ensure this path is correct
import 'package:hungerz_store/models/order_model.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // Reverted: Removed import
import 'package:hungerz_store/services/api_service.dart'; // Import ApiService
// TODO: Import your auth service or token storage to get the token
// import 'package:hungerz_store/services/auth_service.dart';

class OrderService {
  final String _baseUrl = AppConfig.baseUrl;
  final ApiService _apiService; // Add ApiService field

  // Add constructor that accepts ApiService
  OrderService(this._apiService);

  // Private helper for headers, can be expanded if auth is needed later
  Future<Map<String, String>> _getHeaders() async {
    return {
      'Content-Type': 'application/json',
      // Example for future: 'Authorization': 'Bearer YOUR_TOKEN_HERE',
    };
  }

  Future<List<Order>> getNewOrders() async {
    final Uri uri = Uri.parse('$_baseUrl/orders/pending-ready');
    try {
      print('Fetching new orders from: $uri'); // For debugging
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        // print("DEBUG: Raw New Orders JSON: ${response.body}"); // Uncomment for deep debugging
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ordersData = responseData['orders'] as List<dynamic>? ?? [];
        return ordersData.map((data) => Order.fromJson(data as Map<String, dynamic>)).toList();
      } else {
        print('Failed to load new orders. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load new orders. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching new orders: $e');
      throw Exception('Error fetching new orders: $e');
    }
  }

  Future<List<Order>> getPastOrders() async {
    final Uri uri = Uri.parse('$_baseUrl/orders/served');
    try {
      print('Fetching past orders from: $uri'); // For debugging
      final response = await http.get(uri, headers: await _getHeaders());

      if (response.statusCode == 200) {
        // print("DEBUG: Raw Past Orders JSON: ${response.body}"); // Uncomment for deep debugging
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ordersData = responseData['orders'] as List<dynamic>? ?? [];
        return ordersData.map((data) => Order.fromJson(data as Map<String, dynamic>)).toList();
      } else {
        print('Failed to load past orders. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load past orders. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching past orders: $e');
      throw Exception('Error fetching past orders: $e');
    }
  }
  // Removed the old getStoreOrders method as it's no longer used by the cubit
} 