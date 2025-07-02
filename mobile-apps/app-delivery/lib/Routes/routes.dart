import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hungerz_delivery/Account/UI/ListItems/addtobank_page.dart';
import 'package:hungerz_delivery/Account/UI/ListItems/insight_page.dart';

import 'package:hungerz_delivery/Account/UI/ListItems/wallet_page.dart';
import 'package:hungerz_delivery/Account/UI/account_page.dart';
import 'package:hungerz_delivery/Auth/login_navigator.dart';
import 'package:hungerz_delivery/Chat/UI/chat_restaurant.dart';
import 'package:hungerz_delivery/Chat/UI/chat_user.dart';
import 'package:hungerz_delivery/DeliveryPartnerProfile/delivery_profile.dart';
import 'package:hungerz_delivery/OrderMap/UI/delivery_successful.dart';
import 'package:hungerz_delivery/OrderMap/UI/new_delivery.dart';
import 'package:hungerz_delivery/Pages/new_delivery_tasks_page.dart';
import 'package:hungerz_delivery/Pages/delivery_map_page.dart';

class PageRoutes {
  static const String accountPage = 'account_page';
  static const String tncPage = 'tnc_page';
  static const String supportPage = 'support_page';
  static const String loginNavigator = 'login_navigator';
  static const String chatPageRestaurant = 'chat_restaurant';
  static const String chatPageUser = 'chat_user';
  static const String deliverySuccessful = 'delivery_successful';
  static const String insightPage = 'insight_page';
  static const String walletPage = 'wallet_page';
  static const String addToBank = 'addtobank_page';
  static const String editProfile = 'store_profile';
  static const String newDeliveryPage = 'new_delivery_page';
  static const String newDeliveryTasksPage = NewDeliveryTasksPage.routeName;
  static const String deliveryMapPage = DeliveryMapPage.routeName;

  Map<String, WidgetBuilder> routes() {
    return {
      accountPage: (context) => AccountPage(),
    
      loginNavigator: (context) => LoginNavigator(),
      chatPageRestaurant: (context) => ChatPageRestaurant(),
      chatPageUser: (context) => ChatPageUser(),
      deliverySuccessful: (context) => DeliverySuccessful(),
      insightPage: (context) => InsightPage(),
      walletPage: (context) => WalletPage(),
      addToBank: (context) {
        final routeArgs = ModalRoute.of(context)?.settings.arguments;
        double availableBalance = 0.0;
        if (routeArgs is Map && routeArgs.containsKey('availableBalance') && routeArgs['availableBalance'] is double) {
          availableBalance = routeArgs['availableBalance'] as double;
        } else if (routeArgs is double) {
          // Allow passing double directly for convenience, though Map is safer for multiple args
          availableBalance = routeArgs;
        } else {
          print("[Routes] addToBank: 'availableBalance' argument not found or invalid. Defaulting to 0.0. Args: $routeArgs");
          // Optionally, you could navigate to an error page or show a dialog
        }
        return AddToBank(availableBalance: availableBalance);
      },
      editProfile: (context) => ProfilePage(),
      newDeliveryPage: (context) => NewDeliveryPage(),
      newDeliveryTasksPage: (context) => NewDeliveryTasksPage(),
      deliveryMapPage: (context) {
        print("############################################################################################");
        print("[Routes] deliveryMapPage ROUTE HANDLER INVOKED!");
        print("############################################################################################");
        final routeArgs = ModalRoute.of(context)?.settings.arguments;
        print("[Routes] deliveryMapPage arguments received: $routeArgs, Type: ${routeArgs?.runtimeType}"); 
        
        DeliveryTask? task;
        if (routeArgs is DeliveryTask) {
          task = routeArgs;
          print("[Routes] Arguments successfully cast to DeliveryTask. Order ID: ${task.orderId}");
        } else {
          print("[Routes] Arguments are NOT a DeliveryTask or are null. Type: ${routeArgs?.runtimeType}");
        }
        
        if (task != null) {
          print("[Routes] Task found (after casting check). NOW ATTEMPTING TO BUILD DeliveryMapPage with task ID: ${task.orderId}"); 
          return DeliveryMapPage(task: task);
        } else {
          print("[Routes] Task is NULL (after casting check). Showing error page."); 
          return Scaffold(
            appBar: AppBar(title: const Text("Error - Route Args")),
            body: const Center(child: Text("Delivery task argument not found or invalid after cast.")), 
          );
        }
      },
    };
  }
}
