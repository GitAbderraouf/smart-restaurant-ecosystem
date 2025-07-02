// services/manager_socket_service.dart
import 'package:hungerz_store/Config/app_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart'; // Pour debugPrint
import 'dart:async'; // Pour StreamController

// Modèles de données que l'app Gérant pourrait utiliser pour structurer les données reçues
// Vous pouvez les définir plus en détail selon vos besoins.
// Par exemple, pour stock_level_changed:
class StockUpdateData {
  final String ingredientId;
  final String name;
  final double newStockLevel;
  final String unit;
  // Ajoutez d'autres champs si nécessaire (category, lowStockThreshold, etc.)

  StockUpdateData({
    required this.ingredientId,
    required this.name,
    required this.newStockLevel,
    required this.unit,
  });

  factory StockUpdateData.fromJson(Map<String, dynamic> json) {
    return StockUpdateData(
      ingredientId: json['ingredientId'],
      name: json['name'] ?? 'N/A', // Fournir une valeur par défaut
      newStockLevel: (json['stock'] as num).toDouble(),
      unit: json['unit'] ?? 'N/A',
    );
  }
}

// Exemple pour fridge_status_changed:
class FridgeStatusData {
  final String deviceId;
  final double currentTemperature;
  final double targetTemperature;
  final String status;
  // ... autres champs

  FridgeStatusData({
    required this.deviceId,
    required this.currentTemperature,
    required this.targetTemperature,
    required this.status,
  });

   factory FridgeStatusData.fromJson(Map<String, dynamic> json) {
    return FridgeStatusData(
      deviceId: json['deviceId'],
      currentTemperature: (json['currentTemperature'] as num).toDouble(),
      targetTemperature: (json['targetTemperature'] as num).toDouble(),
      status: json['status'],
    );
  }
}

// Exemple pour oven_status_changed:
class OvenStatusData {
  final String deviceId;
  final double currentTemperature;
  final double targetTemperature;
  final String status;
  final String mode;
  final int remainingTimeSeconds;
  // ... autres champs

  OvenStatusData({
    required this.deviceId,
    required this.currentTemperature,
    required this.targetTemperature,
    required this.status,
    required this.mode,
    required this.remainingTimeSeconds
  });

  factory OvenStatusData.fromJson(Map<String, dynamic> json) {
    return OvenStatusData(
      deviceId: json['deviceId'],
      currentTemperature: (json['currentTemperature'] as num).toDouble(),
      targetTemperature: (json['targetTemperature'] as num).toDouble(),
      status: json['status'],
      mode: json['mode'],
      remainingTimeSeconds: (json['remainingTimeSeconds'] as num).toInt(),
    );
  }
}


class ManagerSocketService {
  IO.Socket? _socket;
  static const String _serverUrl =AppConfig.socketUrl; 

  // StreamControllers pour diffuser les mises à jour aux Cubits/BLoCs de l'app Gérant
  final StreamController<StockUpdateData> _stockUpdateController = StreamController.broadcast();
  Stream<StockUpdateData> get stockUpdateStream => _stockUpdateController.stream;

  final StreamController<FridgeStatusData> _fridgeStatusController = StreamController.broadcast();
  Stream<FridgeStatusData> get fridgeStatusStream => _fridgeStatusController.stream;

  final StreamController<OvenStatusData> _ovenStatusController = StreamController.broadcast();
  Stream<OvenStatusData> get ovenStatusStream => _ovenStatusController.stream;
  
  final StreamController<Map<String, dynamic>> _commandAckController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get commandAckStream => _commandAckController.stream;


  static final ManagerSocketService _instance = ManagerSocketService._internal();
  factory ManagerSocketService() {
    return _instance;
  }
  ManagerSocketService._internal();

  IO.Socket? get socket => _socket;

  void connectAndListen() {
    if (_socket != null && _socket!.connected) {
      debugPrint('ManagerSocketService: Socket déjà connecté.');
      return;
    }

    _socket = IO.io(_serverUrl,
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        // L'application Gérant doit s'identifier avec son type.
        // Si vous réintroduisez l'authentification JWT pour le manager, vous ajouterez 'auth': {'token': 'VOTRE_JWT'} ici.
        .setQuery({'clientType': 'manager_app'})
        .build()
    );

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('ManagerSocketService: CONNECTÉ au backend ($_serverUrl) en tant que manager_app');
    });

    _socket!.on('manager_app_registered', (data) { // Événement de confirmation du backend
      if (data['success']) {
        debugPrint('ManagerSocketService: Enregistrement App Gérant confirmé par le serveur: ${data['message']}');
        // Maintenant, nous sommes prêts à écouter les autres événements
        _setupEventListeners();
      } else {
        debugPrint('ManagerSocketService: Échec de l\'enregistrement App Gérant: ${data['message']}');
      }
    });

    _socket!.onDisconnect((_) => debugPrint('ManagerSocketService: DÉCONNECTÉ du backend'));
    _socket!.onError((data) => debugPrint('ManagerSocketService: Erreur de connexion -> $data'));
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.on('stock_level_changed', (data) { // Reçu du backend
      debugPrint('ManagerSocketService: Reçu stock_level_changed <- $data');
      if (data is Map<String, dynamic>) {
        _stockUpdateController.add(StockUpdateData.fromJson(data));
      }
    });

    _socket!.on('fridge_status_changed', (data) { // Reçu du backend
      debugPrint('ManagerSocketService: Reçu fridge_status_changed <- $data');
       if (data is Map<String, dynamic>) {
        _fridgeStatusController.add(FridgeStatusData.fromJson(data));
      }
    });

    _socket!.on('oven_status_changed', (data) { // Reçu du backend
      debugPrint('ManagerSocketService: Reçu oven_status_changed <- $data');
      if (data is Map<String, dynamic>) {
        _ovenStatusController.add(OvenStatusData.fromJson(data));
      }
    });

    _socket!.on('manager_command_ack', (data) { // Reçu du backend
      debugPrint('ManagerSocketService: Reçu manager_command_ack <- $data');
       if (data is Map<String, dynamic>) {
        _commandAckController.add(data);
      }
    });
  }

  // Méthodes pour envoyer des commandes au backend
  void sendSetFridgeTargetTemp({
    required String fridgeId, // ex: "fridge_sim_1"
    required double targetTemperature,
  }) {
    if (_socket != null && _socket!.connected) {
      final commandData = {
        'fridgeId': fridgeId,
        'targetTemperature': targetTemperature,
      };
      _socket!.emit('manager_set_fridge_target_temp', commandData); // Émis au backend
      debugPrint("ManagerSocketService: Émis manager_set_fridge_target_temp -> $commandData");
    } else {
      debugPrint("ManagerSocketService: Impossible d'envoyer la commande, socket non connecté.");
    }
  }

  void sendSetOvenParameters({
    required String ovenId, // ex: "oven_sim_1"
    required double targetTemperature,
    required String mode, // ex: "bake", "grill"
    required int durationMinutes,
  }) {
    if (_socket != null && _socket!.connected) {
      final commandData = {
        'ovenId': ovenId,
        'targetTemperature': targetTemperature,
        'mode': mode,
        'durationMinutes': durationMinutes,
      };
      _socket!.emit('manager_set_oven_parameters', commandData); // Émis au backend
      debugPrint("ManagerSocketService: Émis manager_set_oven_parameters -> $commandData");
    } else {
      debugPrint("ManagerSocketService: Impossible d'envoyer la commande, socket non connecté.");
    }
  }

  void dispose() {
    _socket?.dispose();
    _stockUpdateController.close();
    _fridgeStatusController.close();
    _ovenStatusController.close();
    _commandAckController.close();
    _socket = null;
  }
}