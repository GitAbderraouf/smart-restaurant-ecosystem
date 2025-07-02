import 'package:flutter/material.dart';
import 'Routes/routes.dart';
import 'Theme/style.dart';
import 'package:flutter/services.dart';
import 'package:hungerz_kitchen/Screens/kitchen_screen.dart';
import 'package:hungerz_kitchen/Services/api_service.dart';
import 'package:hungerz_kitchen/Services/socket_service.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(HungerzKitchen());
}

class HungerzKitchen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    return MultiProvider(
      providers: [
        Provider<ApiService>(create: (_) => ApiService()),
        ChangeNotifierProvider<SocketService>(create: (_) => SocketService()),
      ],
      child: MaterialApp(
      debugShowCheckedModeBanner: false,
            theme: appTheme,
      home: const KitchenScreen(),
            routes: PageRoutes().routes(),
    ),
    );
  }
}
