// File: waiter_app/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// import 'package:waiter_app/Pages/waitre_page.dart'; // No longer needed here directly if using routes
import 'package:waiter_app/Providers/order_provider.dart';
import 'package:waiter_app/Services/socket_service.dart'; 
import 'package:waiter_app/Services/api_service.dart';
import 'package:waiter_app/Themes/app_theme.dart';
import 'package:waiter_app/Config/app_config.dart';
import 'package:waiter_app/Routes/routes.dart'; // Import AppRoutes

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const WaiterApp());
}

class WaiterApp extends StatelessWidget {
  const WaiterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide ApiService first as OrderProvider might depend on it implicitly or explicitly.
        Provider<ApiService>(create: (_) => ApiService()), 
        ChangeNotifierProvider<SocketService>(
            create: (_) => SocketService(socketUrl: AppConfig.socketUrl), // Use AppConfig.socketUrl
            // dispose is not typically needed for ChangeNotifierProvider if the object handles its own disposal via a dispose method
        ),
        ChangeNotifierProvider<OrderProvider>(
          create: (context) {
            // Get the SocketService instance
            final socketService = Provider.of<SocketService>(context, listen: false);
            final apiService = Provider.of<ApiService>(context, listen: false); // Get ApiService
            // Create OrderProvider and pass/set SocketService and ApiService if needed by its constructor or a method
            final orderProvider = OrderProvider(socketService: socketService, apiService: apiService); 
            // orderProvider.setSocketService(socketService); // Alternative if using a setter
            return orderProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: AppConfig.appName, // Use AppConfig.appName for title
        theme: AppTheme.lightTheme,
        // home: const MaitrePage(), // Replaced by initialRoute and routes
        initialRoute: AppRoutes.serveurOrders, // Set initial route
        routes: AppRoutes.getRoutes(), // Define the routes
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}