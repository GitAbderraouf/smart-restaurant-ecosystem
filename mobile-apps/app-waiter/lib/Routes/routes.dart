import 'package:flutter/material.dart';
import 'package:waiter_app/Screens/Orders/serveur_orders_screen.dart';
import 'package:waiter_app/Screens/Orders/served_orders_screen.dart';
import 'package:waiter_app/Pages/waitre_page.dart'; // Assuming MaitrePage is the initial page

class AppRoutes {
  static const String maitrePage = '/'; // Or whatever you want the initial route to be
  static const String serveurOrders = ServeurOrdersScreen.routeName;
  static const String servedOrders = ServedOrdersScreen.routeName;

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      maitrePage: (context) => const MaitrePage(),
      serveurOrders: (context) => const ServeurOrdersScreen(),
      servedOrders: (context) => const ServedOrdersScreen(),
    };
  }
}