import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:hungerz_store/Auth/login_navigator.dart';
import 'package:hungerz_store/Chat/UI/chat_page.dart';
import 'package:hungerz_store/Maps/UI/location_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/addtobank_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/insight_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/reviews.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/settings_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/support_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/tnc_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/wallet_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/account_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Order/UI/order_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Order/UI/orderinfo_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Order/UI/track_order.dart';
import 'package:hungerz_store/OrderTableItemAccount/StoreProfile/store_profile.dart';
import 'package:hungerz_store/OrderTableItemAccount/order_table_item_account.dart';
import 'package:hungerz_store/Pages/additem.dart';
import 'package:hungerz_store/Pages/edititem.dart';
import 'package:hungerz_store/Pages/items.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/authentication.dart';
import 'package:hungerz_store/models/menu_item_model.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/stock.dart';

class PageRoutes {
  static const String locationPage = 'location_page';
  static const String OrderTableItemAccountPage = 'order_item_account';
  static const String accountPage = 'account_page';
  static const String orderPage = 'order_page';
  static const String orderInfoPage = 'orderinfo_page';
  static const String tncPage = 'tnc_page';
  static const String savedAddressesPage = 'saved_addresses_page';
  static const String supportPage = 'support_page';
  static const String walletPage = 'wallet_page';
  static const String loginNavigator = 'login_navigator';
  static const String chatPage = 'chat_page';
  static const String insightPage = 'insight_page';
  static const String storeProfile = 'store_profile';
  static const String addItem = 'additem';
  static const String editItem = 'edititem';
  static const String Items = 'items';
  static const String addToBank = 'addtobank_page';
  static const String review = 'reviews';
  static const String setting = 'settings_page';
  static const String track = 'track_order';
  static const String authentication = 'authentication_list';
  static const String stockPage = 'stock_page';

  Map<String, WidgetBuilder> routes() {
    return {
      track: (context) => TrackOrderPage(),
      locationPage: (context) => LocationPage(),
      orderPage: (context) => OrderPage(),
      orderInfoPage: (context) => OrderInfo(),
      accountPage: (context) => AccountPage(),
      // tncPage: (context) => TncPage(),
      // supportPage: (context) => SupportPage(),
      loginNavigator: (context) => LoginNavigator(),
      walletPage: (context) => WalletPage(),
      chatPage: (context) => ChatPage(),
      insightPage: (context) => Insight(),
      storeProfile: (context) => ProfilePage(),
      addItem: (context) => AddItem(),
      editItem: (context) => EditItem(itemId: ModalRoute.of(context)!.settings.arguments as String),
      addToBank: (context) {
        return AddToBank();
      },
      Items: (context) => ItemsPage(),
      OrderTableItemAccountPage: (context) => OrderItemAccount(),
      // review: (context) => ReviewPage(),
      // setting: (context) => Settings(),
      // authentication: (context) => AuthenticationList(),
      stockPage: (context) => StockPage(),
    };
  }
}
