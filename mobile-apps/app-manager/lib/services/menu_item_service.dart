import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hungerz_store/Config/app_config.dart';
import 'package:hungerz_store/models/menu_item_model.dart';
import 'package:flutter/foundation.dart';

class MenuItemService {
  final String _baseUrl = AppConfig.baseUrl;

  Future<List<MenuItem>> getMenuItemsByCategory(String categoryName) async {
    final encodedCategoryName = Uri.encodeComponent(categoryName);
    final url = '$_baseUrl/menu-items/admin/category/$encodedCategoryName';
    if (kDebugMode) {
      print('[MenuItemService] Fetching items for category: $categoryName from $url');
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> itemsJson = responseData['menuItems'] as List<dynamic>? ?? [];
        if (kDebugMode) {
          print('[MenuItemService] Received data: ${response.body}');
        }
        return itemsJson.map((json) => MenuItem.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        if (kDebugMode) {
          print('[MenuItemService] Failed to load menu items for $categoryName: ${response.statusCode} ${response.body}');
        }
        throw Exception('Failed to load menu items for $categoryName. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MenuItemService] Error fetching menu items for $categoryName: $e');
      }
      throw Exception('Error fetching menu items for $categoryName: $e');
    }
  }

  Future<MenuItem> getMenuItemDetails(String itemId) async {
    final url = '$_baseUrl/menu-items/$itemId';
    if (kDebugMode) {
      print('[MenuItemService] Fetching details for item: $itemId from $url');
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // The backend endpoint returns { "menuItem": { ... } }
        final Map<String, dynamic> itemJson = responseData['menuItem'] as Map<String, dynamic>; 
        if (kDebugMode) {
          print('[MenuItemService] Received details: ${response.body}');
        }
        return MenuItem.fromJson(itemJson);
      } else {
        if (kDebugMode) {
          print('[MenuItemService] Failed to load details for item $itemId: ${response.statusCode} ${response.body}');
        }
        throw Exception('Failed to load details for item $itemId. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MenuItemService] Error fetching details for item $itemId: $e');
      }
      throw Exception('Error fetching details for item $itemId: $e');
    }
  }

  Future<List<Ingredient>> getIngredientsForMenuItem(String itemId) async {
    final url = '$_baseUrl/menu-items/$itemId/ingredients';
    if (kDebugMode) {
      print('[MenuItemService] Fetching ingredients for item: $itemId from $url');
    }

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ingredientsJson = responseData['ingredients'] as List<dynamic>? ?? [];
        if (kDebugMode) {
          print('[MenuItemService] Received ingredients: ${response.body}');
        }
        return ingredientsJson.map((json) => Ingredient.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        if (kDebugMode) {
          print('[MenuItemService] Failed to load ingredients for item $itemId: ${response.statusCode} ${response.body}');
        }
        throw Exception('Failed to load ingredients for item $itemId. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MenuItemService] Error fetching ingredients for item $itemId: $e');
      }
      throw Exception('Error fetching ingredients for item $itemId: $e');
    }
  }

  Future<List<Ingredient>> getAllMasterIngredients() async {
    final url = '$_baseUrl/menu-items/ingredients/all-master';
    if (kDebugMode) {
      print('[MenuItemService] Fetching all master ingredients from $url');
    }
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> ingredientsJson = responseData['ingredients'] as List<dynamic>? ?? [];
        if (kDebugMode) {
          print('[MenuItemService] Received master ingredients: ${response.body}');
        }
        return ingredientsJson.map((json) => Ingredient.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        if (kDebugMode) {
          print('[MenuItemService] Failed to load master ingredients: ${response.statusCode} ${response.body}');
        }
        throw Exception('Failed to load master ingredients. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[MenuItemService] Error fetching master ingredients: $e');
      }
      throw Exception('Error fetching master ingredients: $e');
    }
  }

  // Placeholder for updating item availability
  Future<MenuItem> updateMenuItemAvailability(String itemId, bool isAvailable) async {
    final url = '$_baseUrl/menu-items/$itemId/availability'; // Endpoint to be created on backend
    if (kDebugMode) {
      print('[MenuItemService] Updating availability for item $itemId to $isAvailable at $url');
    }
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'isAvailable': isAvailable}),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('[MenuItemService] Update availability response: ${response.body}');
        }
        return MenuItem.fromJson(json.decode(response.body) as Map<String, dynamic>);
      } else {
         if (kDebugMode) {
          print('[MenuItemService] Failed to update availability: ${response.statusCode} ${response.body}');
        }
        throw Exception('Failed to update item availability. Status: ${response.statusCode}');
      }
    } catch (e) {
       if (kDebugMode) {
        print('[MenuItemService] Error updating availability: $e');
      }
      throw Exception('Error updating item availability: $e');
    }
  }

  Future<Map<String, dynamic>> getAllStockInfo() async {
    final url = '$_baseUrl/menu-items/ingredients/stock';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Failed to load stock info. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stock info: $e');
    }
  }
} 