import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:hungerz_store/Config/app_config.dart'; // Import AppConfig

class PaymentService {
  final Dio _dio = Dio();
  // Use the baseUrl from AppConfig
  final String _baseUrl = AppConfig.baseUrl;

  PaymentService() {
    // Add any common Dio options here, like base URL, headers, interceptors
    _dio.options.baseUrl = _baseUrl;
    // Example for adding an interceptor (e.g., for auth tokens)
    // _dio.interceptors.add(InterceptorsWrapper(
    //   onRequest: (options, handler) async {
    //     // TODO: Get your auth token (e.g., from shared preferences)
    //     String? token = await getAuthToken(); 
    //     if (token != null) {
    //       options.headers['Authorization'] = 'Bearer $token';
    //     }
    //     return handler.next(options);
    //   },
    // ));
  }

  // TODO: Implement a function to retrieve your auth token if needed
  // Future<String?> getAuthToken() async {
  //   // SharedPreferences prefs = await SharedPreferences.getInstance();
  //   // return prefs.getString('authToken');
  //   return null; // Replace with actual token retrieval
  // }

  Future<Map<String, dynamic>> createStripePaymentIntent({
    required double amount,
    String paymentMethod = 'stripe', // 'stripe' or 'card' as per your backend
  }) async {
    try {
      final response = await _dio.post(
        '/payments/add-to-wallet', // Endpoint from your backend payment.routes.js
        data: {
          'amount': amount,
          'paymentMethod': paymentMethod, 
        },
        // TODO: Add options for headers if auth token is not handled by an interceptor
        // options: Options(headers: {'Authorization': 'Bearer YOUR_TOKEN'})
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to create payment intent: ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      // Log the error or handle it as per your app's error handling strategy
      print('DioError creating payment intent: ${e.response?.data ?? e.message}');
      throw Exception('Error creating payment intent: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('Unexpected error creating payment intent: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  Future<Map<String, dynamic>> confirmWalletTopUp({
    required String paymentIntentId,
    required double amount, // The original amount of the top-up
    String paymentMethod = 'stripe', // 'stripe' or 'card' as per your backend
  }) async {
    try {
      final response = await _dio.post(
        '/payments/confirm-wallet-topup', // Endpoint from your backend
        data: {
          'paymentIntentId': paymentIntentId,
          'amount': amount.toString(), // Backend expects amount as string here
          'paymentMethod': paymentMethod,
        },
        // TODO: Add options for headers if auth token is not handled by an interceptor
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to confirm wallet top-up: ${response.statusCode}',
          type: DioExceptionType.badResponse,
        );
      }
    } on DioException catch (e) {
      print('DioError confirming wallet top-up: ${e.response?.data ?? e.message}');
      throw Exception('Error confirming wallet top-up: ${e.response?.data?['message'] ?? e.message}');
    } catch (e) {
      print('Unexpected error confirming wallet top-up: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }
} 