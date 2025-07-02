// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iot_simulator_app/cubits/oven_cubit/oven_cubit.dart';
import 'package:iot_simulator_app/cubits/refrigerator_cubit/refrigerator_cubit.dart';
import 'package:iot_simulator_app/cubits/stock_cubit/stock_cubit.dart';
import 'package:iot_simulator_app/screens/oven_simulator_screen.dart';
import 'package:iot_simulator_app/screens/refrigerator_simulator_screen.dart';
import 'package:iot_simulator_app/screens/stock_simulator_screen.dart';
import 'package:iot_simulator_app/services/socket_service.dart';


SocketService socketService = SocketService(); // Obtenir/créer l'instance

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Important si vous initialisez des choses avant runApp
  socketService.connectAndListen(); 
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<StockCubit>(
          create: (context) => StockCubit(socketService), 
          // fetchInitialStock est appelé dans initState de StockSimulatorScreen ou ici directement :
          // ..fetchInitialStock(), // Optionnel de le faire ici
        ),
        BlocProvider<RefrigeratorCubit>(
          create: (context) => RefrigeratorCubit(socketService)
                                ..fetchInitialRefrigeratorState(SocketService.fridgeDeviceId),
        ),
        BlocProvider<OvenCubit>(
          create: (context) => OvenCubit(socketService)
                                ..fetchInitialOvenState(SocketService.ovenDeviceId),
        ),
      ],
      child: IoTSimulatorApp(),
    ),
  );
}

class IoTSimulatorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IoT Restaurant Simulator',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // Ou une autre couleur de votre choix
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainSimulatorScreen(),
    );
  }
}

class MainSimulatorScreen extends StatefulWidget {
  @override
  _MainSimulatorScreenState createState() => _MainSimulatorScreenState();
}

class _MainSimulatorScreenState extends State<MainSimulatorScreen> {
  int _selectedIndex = 0;
  static final List<Widget> _widgetOptions = <Widget>[
    // Remplacez par vos vrais écrans
    StockSimulatorScreen(), // Placeholder pour l'écran de stock
    RefrigeratorSimulatorScreen(), // Placeholder pour l'écran du réfrigérateur
    OvenSimulatorScreen(), // Placeholder pour l'écran du four
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('IoT Restaurant Simulator'),
        // Vous pouvez ajouter un indicateur de statut de connexion Socket ici plus tard
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen_outlined), // kitchen icon often represents fridge
            label: 'Réfrigérateur',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.outdoor_grill_outlined), // grill icon for oven
            label: 'Four',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

// Placeholders pour les écrans - à remplacer par vos vrais fichiers/widgets
class StockSimulatorScreenPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Simulateur de Stock - UI à venir'));
  }
}

class RefrigeratorSimulatorScreenPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Simulateur de Réfrigérateur - UI à venir'));
  }
}

class OvenSimulatorScreenPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Simulateur de Four - UI à venir'));
  }
}