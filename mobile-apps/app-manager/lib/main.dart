import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc for RepositoryProvider
import 'package:firebase_core/firebase_core.dart'; // Import Firebase Core
// import 'package:flutter_bloc/flutter_bloc.dart'; // Not used
import 'package:flutter_phoenix/flutter_phoenix.dart';
// import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/settings_page.dart'; // Not the home page
// import 'package:hungerz_store/OrderTableItemAccount/Order/UI/order_page.dart'; // Not the home page
import 'package:hungerz_store/OrderTableItemAccount/order_table_item_account.dart'; // THIS IS THE HOME PAGE
import 'package:hungerz_store/Routes/routes.dart';
import 'package:hungerz_store/cubits/appliance_status_cubit/appliance_status_cubit.dart';
import 'package:hungerz_store/cubits/manager_stock_cubit/manager_stock_cubit.dart';
import 'package:hungerz_store/map_utils.dart';
import 'package:hungerz_store/services/api_service.dart'; // Import ApiService
import 'package:hungerz_store/services/manager_socket_service.dart';
import 'package:hungerz_store/services/order_service.dart'; // Import OrderService
import 'package:hungerz_store/services/reservation_service.dart'; // Import ReservationService
import 'package:hungerz_store/services/menu_item_service.dart'; // Import MenuItemService
import 'package:hungerz_store/cubits/ingredient_cubit.dart'; // Make sure this import is present
import 'package:hungerz_store/cubits/orders_cubit.dart'; // Import OrdersCubit
import 'package:hungerz_store/cubits/analytics_cubit.dart';
 // Import AnalyticsCubit
// Import other cubits if you have them, e.g.:
// import 'package:hungerz_store/cubits/menu_item_cubit.dart';

ManagerSocketService managerSocketService = ManagerSocketService();
Future<void> main() async { // Make main async
  WidgetsFlutterBinding.ensureInitialized();
  managerSocketService.connectAndListen(); // Initialize the socket service
  await Firebase.initializeApp(); // Initialize Firebase
  MapUtils.getMarkerPic();
  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiService>(create: (context) => ApiService()), // Add ApiService
        RepositoryProvider<OrderService>(create: (context) => OrderService(context.read<ApiService>())), // Update OrderService to use ApiService
        RepositoryProvider<ReservationService>(create: (context) => ReservationService()),
        RepositoryProvider<MenuItemService>(create: (context) => MenuItemService()),
      ],
      child: MultiBlocProvider( // Wrap Phoenix with MultiBlocProvider
        providers: [
          // Example: If you have other cubits that depend on services
          // BlocProvider<MenuItemCubit>(
          //   create: (context) => MenuItemCubit(context.read<MenuItemService>()),
          // ),
          // Add other Blocs/Cubits here if needed
          BlocProvider<IngredientCubit>(
            create: (context) => IngredientCubit(context.read<MenuItemService>()),
          ),
          BlocProvider<OrdersCubit>(
            create: (context) => OrdersCubit(context.read<OrderService>()),
          ),
          BlocProvider<AnalyticsCubit>(
            create: (context) => AnalyticsCubit(ordersCubit: context.read<OrdersCubit>()),
          ),
          BlocProvider<ManagerStockCubit>(
            create: (context) => ManagerStockCubit(managerSocketService)..fetchInitialStock()
          ),
          BlocProvider<ApplianceStatusCubit>(
            create: (context) => ApplianceStatusCubit(managerSocketService),
          ),
        ],
        child: Phoenix(child: HungerzStore()),
      ),
    ),
  );
}

class HungerzStore extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
      // theme: theme, // Use default theme or specify one directly e.g. ThemeData.light()
      home: OrderItemAccount(), // Corrected class name
              routes: PageRoutes().routes(),
    );
  }
}
