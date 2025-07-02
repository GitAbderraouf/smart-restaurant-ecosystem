import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:hungerz_delivery/Account/UI/account_page.dart';
import 'package:hungerz_delivery/Pages/new_delivery_tasks_page.dart';
import 'package:hungerz_delivery/Routes/routes.dart';
import 'package:hungerz_delivery/language_cubit.dart';
import 'package:hungerz_delivery/services/socket_service.dart';
import 'package:hungerz_delivery/theme_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mb;

import 'map_utils.dart';

// Your color definitions
Color kMainColor = Color(0xfffbaf03);
Color kDisabledColor = Color(0xff616161);
Color kWhiteColor = Colors.white;
Color kLightTextColor = Colors.grey;
Color kCardBackgroundColor = Color(0xfff8f9fd);
Color kTransparentColor = Colors.transparent;
Color kMainTextColor = Color(0xff000000);
Color kIconColor = Color(0xffc4c8c1);
Color kHintColor = Color(0xff999e93);
Color kTextColor = Color(0xff6a6c74);
Color secondaryColor = Color(0xff45BD9C);

// Callback for new delivery orders from SocketService
void _handleNewDeliveryOrder(Map<String, dynamic> orderPayload) {
  print("New Delivery Order Received in main.dart: $orderPayload");
  // Call the global function from new_delivery_tasks_page.dart to handle the new task
  receiveNewDeliveryTask(orderPayload);

  // Optionally, navigate to the NewDeliveryTasksPage or show a persistent notification
  // This uses the global navigatorKey defined in new_delivery_tasks_page.dart
  if (navigatorKey.currentState != null) {
    // Check if the current route is already the tasks page to avoid pushing multiple times
    bool isAlreadyOnTasksPage = false;
    Navigator.popUntil(navigatorKey.currentState!.context, (route) {
      if (route.settings.name == NewDeliveryTasksPage.routeName) {
        isAlreadyOnTasksPage = true;
      }
      return true; // Continue popping, we are just checking
    });

    if (!isAlreadyOnTasksPage) {
       // Consider showing a SnackBar or a less intrusive notification first
      ScaffoldMessenger.of(navigatorKey.currentState!.context).showSnackBar(
        SnackBar(
          content: NewTaskNotificationCard(
            orderNumber: orderPayload['orderNumber'] ?? 'N/A',
            customerName: orderPayload['customerName'] ?? 'Customer',
            estimatedTime: orderPayload['estimatedTime'] ?? '15 min',
            onViewTaskPressed: () {
              ScaffoldMessenger.of(navigatorKey.currentState!.context).hideCurrentSnackBar();
              navigatorKey.currentState!.pushNamedAndRemoveUntil(NewDeliveryTasksPage.routeName, (route) => route.isFirst);
            },
            onDismissPressed: () {
              ScaffoldMessenger.of(navigatorKey.currentState!.context).hideCurrentSnackBar();
            },
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.transparent,
          elevation: 0, 
          duration: const Duration(seconds: 10),
          margin: const EdgeInsets.all(16.0),
        )
      );
    }
  }
}

// Enhanced custom widget for the SnackBar content
class NewTaskNotificationCard extends StatelessWidget {
  final String orderNumber;
  final String customerName;
  final String estimatedTime;
  final VoidCallback onViewTaskPressed;
  final VoidCallback onDismissPressed;

  const NewTaskNotificationCard({
    Key? key, 
    required this.orderNumber, 
    required this.onViewTaskPressed,
    required this.onDismissPressed,
    this.customerName = 'Customer',
    this.estimatedTime = '15 min',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            kMainColor.withOpacity(0.9),
            kMainColor.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: kMainColor.withOpacity(0.3),
            blurRadius: 12.0,
            offset: const Offset(0, 4),
            spreadRadius: 2.0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background pattern/decoration
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and dismiss button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        Icons.delivery_dining,
                        color: Colors.white,
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "New Delivery Task!",
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2.0),
                          Text(
                            "Tap to view details",
                            style: TextStyle(
                              fontSize: 12.0,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: onDismissPressed,
                      child: Container(
                        padding: const EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16.0,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16.0),
                
                // Order details section
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 18.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            "Order #$orderNumber",
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: Colors.white.withOpacity(0.9),
                            size: 16.0,
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            customerName,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.access_time,
                            color: Colors.white.withOpacity(0.9),
                            size: 16.0,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            "~$estimatedTime",
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16.0),
                
                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onViewTaskPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kMainColor,
                      elevation: 4.0,
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.visibility,
                          size: 18.0,
                          color: kMainColor,
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          "VIEW TASK",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                            color: kMainColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Mapbox Access Token FIRST
  mb.MapboxOptions.setAccessToken("pk.eyJ1IjoiZHVrZXBhbiIsImEiOiJjbWI3NzdkM2YwMWxyMmtyMWl3a3BoaHMxIn0.m2NX96ioOrsJnz6YNpNd5w"); // Corrected method and Replace with your actual token

  try {
    await Firebase.initializeApp();
    print("Firebase initialized successfully");
  } catch (e) {
    print("Error initializing Firebase: $e");
  }
  SocketService().initSocketConnection(
    newDeliveryOrderCallback: _handleNewDeliveryOrder,
  );
  await MapUtils.getMarkerPic();
  runApp(Phoenix(child: HungerzDelivery(appNavigatorKey: navigatorKey)));
}

class HungerzDelivery extends StatelessWidget {
  final GlobalKey<NavigatorState> appNavigatorKey;

  const HungerzDelivery({Key? key, required this.appNavigatorKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
       providers: [
          BlocProvider<LanguageCubit>(
            create: (context) => LanguageCubit()..getCurrentLanguage(),
          ),
          BlocProvider<ThemeCubit>(
            create: (context) => ThemeCubit()..getCurrentTheme(),
          ),
        ],
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (_, theme) {
          return BlocBuilder<LanguageCubit, Locale>(
            builder: (_, locale) {
              return MaterialApp(
                navigatorKey: appNavigatorKey,
                localizationsDelegates: [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: [
                  const Locale('en'),
                ],
                locale: locale,
                theme: theme,
                home: AccountPage(),
                routes: PageRoutes().routes(),
              );
            },
          );
        },
      ),
    );
  }
}