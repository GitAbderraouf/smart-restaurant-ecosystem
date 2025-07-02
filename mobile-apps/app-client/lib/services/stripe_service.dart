import 'dart:async';
import 'dart:core';
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:hungerz/Config/app_config.dart';
import 'package:hungerz/Themes/colors.dart';

class StripeService {
  StripeService._();
  static final StripeService instance = StripeService._();
  Future<bool> makePayment(int amount) async {
    // Initialize Stripe with the publishable key
    try {
      String? paymentIntentClientSecret = await _createPaymentIntent(amount);
      if (paymentIntentClientSecret != null) {
        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentClientSecret,
            style: ThemeMode.dark,
            merchantDisplayName: 'USTHB',
            appearance: PaymentSheetAppearance(
              colors: PaymentSheetAppearanceColors(
                primaryText: Colors.black,
                secondaryText: Colors.black,
                primary: Colors.blue,
                background:Colors.white,// Colors.white,
                componentText: Colors.black,
                componentBackground: Colors.white,
                componentBorder: Colors.grey,
                componentDivider: Colors.grey,
              ),
              shapes: PaymentSheetShape(
                borderRadius: 10,
              ),
              
            )
    ),
        );
        final success= await _processPayment();
        print('Payment Intent Client Secret: $paymentIntentClientSecret');
        return success;
        
      } else {
        print('Failed to create payment intent.');
        return false;
      }
    } catch (e) {
      print('Error initializing Stripe: $e');
      return false;
    }
  }

  Future<String?> _createPaymentIntent(int amount) async {
    try {
      // Call your backend to create a payment intent
      final Dio dio = Dio();
      final response = await dio.post('https://api.stripe.com/v1/payment_intents',
          data: {'amount': _calculateAmount(amount), 'currency': 'DZD'},
          options:
              Options(contentType: Headers.formUrlEncodedContentType, headers: {
            'content-type': 'application/x-www-form-urlencoded',
            'Authorization': 'Bearer ${AppConfig.stripeSecretKey}',
          }));
      if (response.data != null) {
        return response.data['client_secret'];
      } else {
        print('Error creating payment intent: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error creating payment intent: $e');
      return null;
    }
    return null;
  }

  Future<bool> _processPayment() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      print('Payment successful!');
      return true;
    } on StripeException catch (e) {
      print('Error confirming payment: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      print('Error confirming payment: $e');
      return false;
    }
  }

  String _calculateAmount(int amount) {
    // Convert the amount to the smallest currency unit (e.g., cents)
    return '${amount * 100}';
  }
}
