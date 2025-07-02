// File: waiter_app/lib/Routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:waiter_app/Pages/waitre_page.dart';// Import other pages here as you create them
// import 'package:maitre_app/pages/settings_page.dart';

class AppRoutes {
  static const String maitrePage = '/'; // Initial route
  static const String settingsPage = '/settings';
  // Add other route names here

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      maitrePage: (context) => const MaitrePage(),
      // settingsPage: (context) => const SettingsPage(),
      // Add other routes here
    };
  }

  // Optional: A helper for named navigation with arguments
  // static Future<T?>? navigateTo<T extends Object?>(BuildContext context, String routeName, {Object? arguments}) {
  //   return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  // }
}