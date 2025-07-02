// cubit/refrigerator_cubit/refrigerator_cubit.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:iot_simulator_app/config/app_config.dart';
import 'dart:convert';
import 'dart:async'; // Pour Timer

import '../../models/refrigerator_state_model.dart'; // Ajustez le chemin
// Assurez-vous que SocketService est accessible, par exemple via un singleton ou get_it
import '../../services/socket_service.dart'; // Ajustez le chemin

part 'refrigerator_state.dart';

class RefrigeratorCubit extends Cubit<RefrigeratorCubitState> {
  final SocketService _socketService;
  Timer? _simulationTimer;

  // Remplacez par l'URL de votre backend et le préfixe de l'API
  final String _baseUrl = "${AppConfig.baseUrl}/api/iot-devices"; 

  RefrigeratorCubit(this._socketService) : super(RefrigeratorInitial()) {
    // Écouter les commandes du backend pour le réfrigérateur
    _socketService.listenToFridgeCommands(_handleFridgeCommandFromSocket);
  }

  Future<void> fetchInitialRefrigeratorState(String deviceId) async {
    try {
      emit(RefrigeratorLoading());
      final response = await http.get(Uri.parse('$_baseUrl/refrigerators/$deviceId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final fridgeStateModel = RefrigeratorState.fromJson(data);
        emit(RefrigeratorLoaded(fridgeStateModel));
        _startSimulationLoop(); // Démarrer la simulation après le chargement
      } else {
        emit(RefrigeratorError("Erreur HTTP ${response.statusCode} (Réfrigérateur): ${response.body.isNotEmpty ? response.body : 'Aucun message'}"));
      }
    } catch (e) {
      emit(RefrigeratorError("Erreur de chargement de l'état initial du réfrigérateur: ${e.toString()}"));
    }
  }

  void _handleFridgeCommandFromSocket(dynamic data) {
    if (state is RefrigeratorLoaded && data is Map<String, dynamic>) {
      final currentLoadedState = state as RefrigeratorLoaded;
      final fridgeModel = currentLoadedState.fridgeState;
      bool changed = false;

      // Exemple pour 'set_fridge_target_temp_command'
      if (data['deviceId'] == fridgeModel.deviceId && data.containsKey('targetTemperature')) {
        final newTargetTemp = (data['targetTemperature'] as num).toDouble();
        debugPrint("Réfrigérateur Cubit: Commande reçue - nouvelle température cible: $newTargetTemp");
        fridgeModel.updateTargetTemperature(newTargetTemp); // Le modèle met à jour son propre contrôleur
        changed = true;
      }
      // Ajoutez d'autres types de commandes ici si nécessaire

      if (changed) {
        // Pas besoin de simuler immédiatement, la boucle de simulation le fera.
        // Émettre l'état pour refléter le changement de cible.
        emit(RefrigeratorLoaded(fridgeModel)); 
        // Pas besoin d'appeler copyWith ici si le modèle lui-même est mis à jour
        // et que RefrigeratorLoaded prend juste la référence.
        // Si RefrigeratorState était immuable, on utiliserait copyWith sur le modèle.
      }
    }
  }

 void _startSimulationLoop() {
    _simulationTimer?.cancel(); 
    _simulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (state is RefrigeratorLoaded) {
        final currentLoadedState = state as RefrigeratorLoaded;
        // Obtenir l'instance actuelle du modèle (qui va être mutée)
        final RefrigeratorState mutableFridgeModel = currentLoadedState.fridgeState; 
        
        mutableFridgeModel.simulateInternalLogic(); // La logique de simulation met à jour l'état interne de mutableFridgeModel

        // CRÉER UNE NOUVELLE INSTANCE de RefrigeratorState avec les valeurs mises à jour
        // C'est crucial pour qu'Equatable détecte un changement.
        final RefrigeratorState newStateForEmission = RefrigeratorState(
          deviceId: mutableFridgeModel.deviceId,
          friendlyName: mutableFridgeModel.friendlyName,
          isOn: mutableFridgeModel.isOn,
          currentStatusText: mutableFridgeModel.currentStatusText,
          currentTemperature: mutableFridgeModel.currentTemperature, // Valeur mise à jour
          targetTemperature: mutableFridgeModel.targetTemperature,
          isDoorOpen: mutableFridgeModel.isDoorOpen,
          // Les contrôleurs seront réinitialisés par le constructeur de RefrigeratorState.
          // Nous aborderons la gestion des contrôleurs séparément si cela pose problème.
        );

        // Émettre un nouvel état RefrigeratorLoaded contenant la NOUVELLE instance de RefrigeratorState
        emit(RefrigeratorLoaded(newStateForEmission));

        // Émettre l'état actuel (maintenant newStateForEmission) au backend
        _emitStateToBackend(newStateForEmission);
      }
    });
  }

  // Les autres méthodes du Cubit (fetchInitial, _handleFridgeCommandFromSocket, _emitStateToBackend, 
  // simulatorSetTargetTemperature, simulatorTogglePower, simulatorToggleDoor)
  // doivent également s'assurer qu'elles émettent un RefrigeratorLoaded contenant une NOUVELLE
  // instance de RefrigeratorState si l'état du modèle a changé.

  // Exemple pour simulatorSetTargetTemperature:
  void simulatorSetTargetTemperature(double newTarget) {
    if (state is RefrigeratorLoaded) {
      final currentFridgeModel = (state as RefrigeratorLoaded).fridgeState;
      // La méthode updateTargetTemperature du modèle met à jour la valeur ET le contrôleur
      currentFridgeModel.updateTargetTemperature(newTarget); 

      // Créer une nouvelle instance pour l'émission
      final RefrigeratorState newStateForEmission = RefrigeratorState(
          deviceId: currentFridgeModel.deviceId,
          friendlyName: currentFridgeModel.friendlyName,
          isOn: currentFridgeModel.isOn,
          currentStatusText: currentFridgeModel.currentStatusText, // Peut avoir changé si la logique de sim est appelée
          currentTemperature: currentFridgeModel.currentTemperature,
          targetTemperature: currentFridgeModel.targetTemperature, // C'est la valeur mise à jour
          isDoorOpen: currentFridgeModel.isDoorOpen,
      );
      emit(RefrigeratorLoaded(newStateForEmission));
      // L'appel à _emitStateToBackend peut être fait ici ou attendre la prochaine simulationTick
      // Si vous voulez une réactivité immédiate vers le backend :
      // _emitStateToBackend(newStateForEmission); 
    }
  }

  // Idem pour simulatorTogglePower
    void simulatorTogglePower(bool isOn) {
    if (state is RefrigeratorLoaded) {
      final currentFridgeModel = (state as RefrigeratorLoaded).fridgeState;
      currentFridgeModel.isOn = isOn;
      currentFridgeModel.simulateInternalLogic(); // Mettre à jour currentStatusText

      final RefrigeratorState newStateForEmission = RefrigeratorState( /* ... copier toutes les valeurs ... */ 
          deviceId: currentFridgeModel.deviceId, friendlyName: currentFridgeModel.friendlyName,
          isOn: currentFridgeModel.isOn, currentStatusText: currentFridgeModel.currentStatusText,
          currentTemperature: currentFridgeModel.currentTemperature, targetTemperature: currentFridgeModel.targetTemperature,
          isDoorOpen: currentFridgeModel.isDoorOpen
      );
      emit(RefrigeratorLoaded(newStateForEmission));
      _emitStateToBackend(newStateForEmission);
    }
  }
  
  void simulatorToggleDoor(bool isDoorOpen) {
    if (state is RefrigeratorLoaded) {
      final currentFridgeModel = (state as RefrigeratorLoaded).fridgeState;
      currentFridgeModel.isDoorOpen = isDoorOpen;
      currentFridgeModel.simulateInternalLogic();

      final RefrigeratorState newStateForEmission = RefrigeratorState( /* ... copier toutes les valeurs ... */ 
          deviceId: currentFridgeModel.deviceId, friendlyName: currentFridgeModel.friendlyName,
          isOn: currentFridgeModel.isOn, currentStatusText: currentFridgeModel.currentStatusText,
          currentTemperature: currentFridgeModel.currentTemperature, targetTemperature: currentFridgeModel.targetTemperature,
          isDoorOpen: currentFridgeModel.isDoorOpen
      );
      emit(RefrigeratorLoaded(newStateForEmission));
      _emitStateToBackend(newStateForEmission);
    }
  }



  void _emitStateToBackend(RefrigeratorState fridgeState) {
    // Assurez-vous que socketService est disponible et que le socket est connecté
    if (_socketService.socket != null && _socketService.socket!.connected) {
      _socketService.socket!.emit('iot_fridge_status_update', {
        'deviceId': fridgeState.deviceId,
        'currentTemperature': fridgeState.currentTemperature,
        'targetTemperature': fridgeState.targetTemperature,
        'status': fridgeState.currentStatusText, // Ou un champ 'status' plus structuré si vous préférez
      });
    }
  }

  @override
  Future<void> close() {
    _simulationTimer?.cancel();
    return super.close();
  }
}