import 'package:http/http.dart' as http;
import 'package:hungerz_store/Config/app_config.dart';
import 'dart:convert';

class ApiService {
  final String baseUrl = AppConfig.baseUrl;

  Future<http.Response> get(String endpoint) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    // You might want to add headers here, e.g., for authentication
    final response = await http.get(uri);
    return response;
  }

  // Add other methods like post, put, delete as needed
} 