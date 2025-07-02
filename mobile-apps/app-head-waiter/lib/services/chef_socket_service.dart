// services/chef_socket_service.dart
import 'package:flutter/foundation.dart';
import 'package:hungerz_ordering/Config/app_config.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';
 // Pour AppConfig.socketUrl
 // Pour TableModel si on parse ici

class ChefSocketService {
  IO.Socket? _socket;
  final String _socketUrl = AppConfig.baseUrl; // Assurez-vous que c'est la bonne URL

  // StreamController pour diffuser les mises à jour de table
  final StreamController<Map<String, dynamic>> _tableUpdatesController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get tableStatusUpdates => _tableUpdatesController.stream;

  // StreamController pour la confirmation d'enregistrement (optionnel mais utile)
  final StreamController<bool> _connectionStatusController = StreamController.broadcast();
  Stream<bool> get connectionStatus => _connectionStatusController.stream;


  static final ChefSocketService _instance = ChefSocketService._internal();
  factory ChefSocketService() {
    return _instance;
  }
  ChefSocketService._internal();

  bool get isConnected => _socket?.connected ?? false;

  void connectAndListen() {
    if (_socket != null && _socket!.connected) {
      debugPrint('ChefSocketService: Already connected.');
      _connectionStatusController.add(true);
      return;
    }

    _socket = IO.io(
        _socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            // L'application Chef s'identifie avec son type.
            // Si vous avez une authentification pour l'app Chef, ajoutez 'auth': {'token': 'VOTRE_JWT'} ici.
            .setQuery({'clientType': 'chef_app'}) 
            .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      debugPrint('ChefSocketService: CONNECTED to backend ($_socketUrl) as chef_app');
      _connectionStatusController.add(true);
    });

    _socket!.on('chef_app_registered', (data) {
      if (data is Map && data['success'] == true) {
        debugPrint('ChefSocketService: Chef App registration confirmed by server: ${data['message']}');
      } else {
        debugPrint('ChefSocketService: Chef App registration failed or unexpected data: $data');
      }
    });

    // Écouter l'événement de mise à jour du statut de la table
    _socket!.on('table_status_update', (data) {
      if (data is Map<String, dynamic>) {
        debugPrint('ChefSocketService: Received table_status_update <- $data');
        _tableUpdatesController.add(data);
      } else {
        debugPrint('ChefSocketService: Received non-map data for table_status_update: $data');
      }
    });

    _socket!.onDisconnect((reason) {
      debugPrint('ChefSocketService: DISCONNECTED from backend. Reason: $reason');
      _connectionStatusController.add(false);
    });

    _socket!.onError((data) {
      debugPrint('ChefSocketService: Connection ERROR -> $data');
      _connectionStatusController.add(false);
    });

     _socket!.onConnectError((data) {
      debugPrint('ChefSocketService: Connection Connect ERROR -> $data');
      _connectionStatusController.add(false);
    });
  }

  // Vous pourriez ajouter des méthodes pour émettre des événements du Chef vers le backend si nécessaire.
  // Par exemple: void markTableAsCleaning(String tableId) { ... _socket.emit(...) ... }

  void dispose() {
    _socket?.dispose();
    _tableUpdatesController.close();
    _connectionStatusController.close();
    debugPrint('ChefSocketService: Disposed.');
  }
}
