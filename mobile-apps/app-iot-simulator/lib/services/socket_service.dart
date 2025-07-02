// services/socket_service.dart
import 'package:iot_simulator_app/config/app_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart'; // Pour debugPrint

class SocketService {
  IO.Socket? _socket; // Le ? indique que _socket peut être null

  // URL de votre backend Socket.IO
  // Remplacez par votre adresse IP locale et port si vous testez localement
  // Pour un émulateur Android, ce sera souvent http://10.0.2.2:PORT
  // Pour un simulateur iOS ou un appareil physique sur le même réseau, utilisez l'IP de votre machine.
  static const String _serverUrl =
      AppConfig
          .baseUrl; // EX: 'http://192.168.1.10:3000' ou 'http://10.0.2.2:3000'

  // IDs des appareils simulés (vous les utiliserez pour l'enregistrement)
  static const String stockManagerDeviceId = "stock_manager_sim_1";
  static const String fridgeDeviceId = "fridge_sim_1";
  static const String ovenDeviceId = "oven_sim_1";

  // Singleton pattern pour s'assurer qu'il n'y a qu'une instance de SocketService
  static final SocketService _instance = SocketService._internal();
  factory SocketService() {
    return _instance;
  }
  SocketService._internal();

  IO.Socket? get socket =>
      _socket; // Getter pour accéder au socket depuis l'extérieur

  void connectAndListen() {
    if (_socket != null && _socket!.connected) {
      debugPrint('Socket déjà connecté.');
      return;
    }

    _socket = IO.io(
      _serverUrl,
      IO.OptionBuilder()
          .setTransports(['websocket']) // Utiliser uniquement WebSockets
          .disableAutoConnect() // On se connectera manuellement
          .setQuery({
            'clientType': 'iot_simulator_app',
          }) // Identification du client
          .build(),
    );

    _socket!.connect(); // Connexion manuelle

    _socket!.onConnect((_) {
      debugPrint('Flutter IoT Simulator: CONNECTÉ au backend ($_serverUrl)');
      // Écouter la confirmation de connexion du serveur
      _socket!.on('iot_simulator_connected', (data) {
        if (data['success']) {
          debugPrint(
            'Confirmation de connexion du serveur reçue: ${data['message']}',
          );
          // Une fois connecté et confirmé, enregistrer les appareils
          _registerSimulatedDevices();
        }
      });
    });

    _socket!.onDisconnect(
      (_) => debugPrint('Flutter IoT Simulator: DÉCONNECTÉ du backend'),
    );
    _socket!.onError(
      (data) =>
          debugPrint('Flutter IoT Simulator: Erreur de connexion -> $data'),
    );

    // Listener pour les accusés de réception d'enregistrement des appareils
    _socket!.on('iot_device_registration_ack', (data) {
      if (data['success'] == true) {
        debugPrint(
          'Appareil ${data['deviceId']} (type: ${data['deviceType']}) enregistré avec succès dans la room: ${data['room']}',
        );
      } else {
        debugPrint(
          'Échec de l\'enregistrement pour ${data['deviceId']}: ${data['message']}',
        );
      }
    });

    // Ajoutez d'autres listeners globaux ici si nécessaire
    // Par exemple, pour les commandes génériques si vous aviez choisi cette option
  }

  void _registerSimulatedDevices() {
    if (_socket == null || !_socket!.connected) {
      debugPrint(
        "Impossible d'enregistrer les appareils : socket non connecté.",
      );
      return;
    }
    // Enregistrer chaque appareil simulé
    _socket!.emit('register_iot_simulator_device', {
      'deviceId': stockManagerDeviceId,
      'deviceType': 'stock_manager',
    });
    _socket!.emit('register_iot_simulator_device', {
      'deviceId': fridgeDeviceId,
      'deviceType': 'refrigerator',
    });
    _socket!.emit('register_iot_simulator_device', {
      'deviceId': ovenDeviceId,
      'deviceType': 'oven',
    });
  }

  // Méthodes pour émettre des événements (à ajouter plus tard)
  // Exemple:
  // void sendStockUpdate(Map<String, dynamic> stockData) {
  //   if (_socket != null && _socket!.connected) {
  //     // Inclure le deviceId du gestionnaire de stock
  //     stockData['deviceId'] = stockManagerDeviceId;
  //     _socket!.emit('iot_stock_update', stockData);
  //   }
  // }
  // void sendFridgeStatus(Map<String, dynamic> fridgeData) { ... }
  // void sendOvenStatus(Map<String, dynamic> ovenData) { ... }

  // Méthodes pour s'abonner à des événements spécifiques pour chaque simulateur
  // Elles seront appelées par les BLoCs/Cubits ou State de vos écrans de simulation
  void listenToFridgeCommands(Function(dynamic) handler) {
    _socket?.on('set_fridge_target_temp_command', handler);
  }

  void listenToOvenCommands(Function(dynamic) handler) {
    _socket?.on('set_oven_parameters_command', handler);
  }

  void listenToKitchenOrderForOven(Function(dynamic) handler) {
    _socket?.on('kitchen_new_order_for_oven', handler);
  }

  // Pensez à des méthodes pour se désabonner (off) si le widget est détruit

  void dispose() {
    _socket?.dispose();
    _socket = null;
  }

    void sendStockUpdate({
    required String deviceId, // ex: "stock_manager_sim_1"
    required String ingredientId,
    required double newStockLevel,
  }) {
    if (_socket != null && _socket!.connected) {
      final Map<String, dynamic> stockData = {
        'deviceId': deviceId,
        'ingredientId': ingredientId,
        'newStockLevel': newStockLevel,
      };
      _socket!.emit('iot_stock_update', stockData);
      debugPrint("SocketService: Émis iot_stock_update -> $stockData");
    } else {
      debugPrint("SocketService: Impossible d'envoyer iot_stock_update, socket non connecté.");
    }
  }

  // La méthode pour écouter les synchronisations de stock (déjà esquissée)
  void listenToStockSync(Function(dynamic data) handler) {
    _socket?.on('stock_level_sync', (data) {
      debugPrint("SocketService: Reçu stock_level_sync <- $data");
      handler(data);
    });
  }
}
