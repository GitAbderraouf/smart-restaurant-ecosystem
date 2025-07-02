// cubit/oven_cubit/oven_cubit.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Pour Timer
import 'package:flutter/foundation.dart'; // Pour debugPrint
import 'package:iot_simulator_app/config/app_config.dart'; // Utilisé dans votre code
import 'package:iot_simulator_app/models/oven_state_model.dart'; // Utilisé dans votre code

import '../../services/socket_service.dart'; // Ajustez le chemin si nécessaire

part 'oven_state.dart'; // Assurez-vous que ce fichier existe et définit OvenCubitState, OvenInitial, etc.

class OvenCubit extends Cubit<OvenCubitState> {
  final SocketService _socketService;
  Timer? _simulationTimer;

  // final String _baseUrl = "${AppConfig.baseUrl}/api/iot-devices"; //
  // Pour les tests, si AppConfig n'est pas prêt, utilisez une URL directe :
  final String _baseUrl = "${AppConfig.baseUrl}/api/iot-devices";


  OvenCubit(this._socketService) : super(OvenInitial()) {
    _socketService.listenToOvenCommands(_handleOvenCommandFromSocket);
    _socketService.listenToKitchenOrderForOven(_handleKitchenOrderForOven);
  }

  Future<void> fetchInitialOvenState(String deviceId) async {
    try {
      emit(OvenLoading());
      final response = await http.get(Uri.parse('$_baseUrl/ovens/$deviceId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final ovenStateModel = OvenState.fromJson(data); // Utilise le factory de votre modèle
        emit(OvenLoaded(ovenStateModel));
        _startSimulationLoop();
      } else {
        emit(OvenError("Erreur HTTP ${response.statusCode} (Four): ${response.body.isNotEmpty ? response.body : 'Aucun message'}"));
      }
    } catch (e) {
      emit(OvenError("Erreur de chargement de l'état initial du four: ${e.toString()}"));
    }
  }

  // Méthode pour créer une nouvelle instance de OvenState à partir d'un modèle existant
  // Ceci est utile pour s'assurer qu'Equatable détecte toujours un changement.
  OvenState _cloneOvenState(OvenState original) {
    OvenState cloned = OvenState(
      deviceId: original.deviceId,
      friendlyName: original.friendlyName,
      isOn: original.isOn,
      operationalStatus: original.operationalStatus,
      currentTemperature: original.currentTemperature,
      targetTemperature: original.targetTemperature,
      selectedMode: original.selectedMode,
      isLightOn: original.isLightOn,
      isDoorOpen: original.isDoorOpen,
      targetDurationSeconds: original.targetDurationSeconds,
      remainingTimeSeconds: original.remainingTimeSeconds,
      isTriggeredByKitchenOrder: original.isTriggeredByKitchenOrder,
    );
    // Les contrôleurs sont réinitialisés dans le constructeur de OvenState.
    // Si vous voulez préserver le texte des contrôleurs, vous devez le faire manuellement ici:
    // cloned.targetTempController.text = original.targetTempController.text;
    // cloned.durationController.text = original.durationController.text;
    // Cependant, il est généralement mieux que les méthodes updateTargetTemperature/DurationMinutes
    // du modèle s'occupent de synchroniser les contrôleurs.
    return cloned;
  }


  void _handleOvenCommandFromSocket(dynamic data) { //
    if (state is OvenLoaded && data is Map<String, dynamic>) {
      final currentLoadedState = state as OvenLoaded;
      OvenState newOvenModel = _cloneOvenState(currentLoadedState.ovenState); // Travailler sur une copie
      bool changed = false;

      if (data['deviceId'] == newOvenModel.deviceId) {
        if (data.containsKey('targetTemperature')) {
          final newTargetTemp = (data['targetTemperature'] as num).toDouble();
          newOvenModel.updateTargetTemperature(newTargetTemp); // La méthode du modèle met à jour le contrôleur aussi
          changed = true;
        }
        if (data.containsKey('mode')) {
          final modeString = data['mode'] as String?;
          newOvenModel.selectedMode = OvenState.parseOvenMode(modeString); // Appel statique correct
          changed = true;
        }
        if (data.containsKey('durationMinutes')) {
          final newDuration = (data['durationMinutes'] as num).toInt();
          newOvenModel.updateTargetDurationMinutes(newDuration);
          changed = true;
        }
        // Gérer d'autres paramètres comme 'isOn', 'isLightOn' s'ils sont envoyés par cette commande
        if (data.containsKey('isOn') && data['isOn'] is bool) {
            newOvenModel.isOn = data['isOn'];
            if (!newOvenModel.isOn) newOvenModel.isTriggeredByKitchenOrder = false;
            changed = true;
        }
         if (data.containsKey('isLightOn') && data['isLightOn'] is bool) {
            newOvenModel.isLightOn = data['isLightOn'];
            changed = true;
        }
      }

      if (changed) {
        newOvenModel.simulateInternalLogic(); // Recalculer le statut si des paramètres ont changé
        emit(OvenLoaded(newOvenModel));
      }
    }
  }

  void _handleKitchenOrderForOven(dynamic data) { //
     if (state is OvenLoaded && data is Map<String, dynamic>) {
        final currentLoadedState = state as OvenLoaded;
        OvenState newOvenModel = _cloneOvenState(currentLoadedState.ovenState);

        if (data['deviceId'] == newOvenModel.deviceId && data.containsKey('defaultParameters')) {
          final params = data['defaultParameters'] as Map<String, dynamic>;
          
          debugPrint("Four Cubit: Déclenchement par commande cuisine avec params: $params");

          newOvenModel.isTriggeredByKitchenOrder = true;
          newOvenModel.isOn = true; 
          newOvenModel.isLightOn = params['turnLightOn'] as bool? ?? true;
          newOvenModel.selectedMode = OvenState.parseOvenMode(params['mode'] as String?); // Appel statique correct
          newOvenModel.updateTargetTemperature((params['targetTemperature'] as num).toDouble());
          newOvenModel.updateTargetDurationMinutes((params['durationMinutes'] as num).toInt());
          newOvenModel.operationalStatus = OvenOperationalStatus.preheating;

          emit(OvenLoaded(newOvenModel));
          _emitStateToBackend(newOvenModel); 
        }
     }
  }

  void _startSimulationLoop() { //
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is OvenLoaded) {
        final currentLoadedState = state as OvenLoaded;
        OvenState newOvenModel = _cloneOvenState(currentLoadedState.ovenState); // Travailler sur une copie

        newOvenModel.simulateInternalLogic(); // Modifie newOvenModel en place
        
        emit(OvenLoaded(newOvenModel));
        _emitStateToBackend(newOvenModel);
      }
    });
  }

  void _emitStateToBackend(OvenState ovenState) { //
    if (_socketService.socket != null && _socketService.socket!.connected) {
      _socketService.socket!.emit('iot_oven_status_update', {
        'deviceId': ovenState.deviceId,
        'currentTemperature': ovenState.currentTemperature,
        'targetTemperature': ovenState.targetTemperature,
        'status': ovenState.operationalStatus.toString().split('.').last,
        'mode': ovenState.selectedMode.toString().split('.').last,
        'remainingTimeSeconds': ovenState.remainingTimeSeconds,
        'isLightOn': ovenState.isLightOn, // Ajouter ces états
        'isDoorOpen': ovenState.isDoorOpen, // Ajouter ces états
      });
    }
  }

  // Méthodes pour les interactions UI sur le simulateur
  void simulatorSetTargetTemperature(double newTarget) { //
    if (state is OvenLoaded) {
      final currentLoadedState = state as OvenLoaded;
      OvenState newOvenModel = _cloneOvenState(currentLoadedState.ovenState);
      newOvenModel.updateTargetTemperature(newTarget);
      emit(OvenLoaded(newOvenModel));
      // L'émission au backend se fera par le prochain tick de simulation ou par _emitStateToBackend si actionné par un bouton "appliquer"
    }
  }

  void simulatorSetMode(OvenMode newMode) { //
     if (state is OvenLoaded) {
      final currentLoadedState = state as OvenLoaded;
      OvenState newOvenModel = _cloneOvenState(currentLoadedState.ovenState);
      newOvenModel.selectedMode = newMode;
      if (newMode == OvenMode.off) {
        newOvenModel.isOn = false; 
        newOvenModel.isTriggeredByKitchenOrder = false;
      }
      newOvenModel.simulateInternalLogic();
      emit(OvenLoaded(newOvenModel));
    }
  }

  void simulatorSetDuration(int minutes) { //
    if (state is OvenLoaded) {
      final currentLoadedState = state as OvenLoaded;
      OvenState newOvenModel = _cloneOvenState(currentLoadedState.ovenState);
      newOvenModel.updateTargetDurationMinutes(minutes);
      emit(OvenLoaded(newOvenModel));
    }
  }
  
  void simulatorTogglePower(bool isOn) { //
    if (state is OvenLoaded) {
      final currentLoadedState = state as OvenLoaded;
      OvenState newOvenModel = _cloneOvenState(currentLoadedState.ovenState);
      newOvenModel.isOn = isOn;
      if (!isOn) newOvenModel.isTriggeredByKitchenOrder = false;
      newOvenModel.simulateInternalLogic();
      emit(OvenLoaded(newOvenModel));
      _emitStateToBackend(newOvenModel);
    }
  }

  void simulatorToggleLight(bool isLightOn) { //
     if (state is OvenLoaded) {
      final currentLoadedState = state as OvenLoaded;
      OvenState newOvenModel = _cloneOvenState(currentLoadedState.ovenState);
      newOvenModel.isLightOn = isLightOn;
      emit(OvenLoaded(newOvenModel));
      _emitStateToBackend(newOvenModel); // Émettre cet état spécifique rapidement
    }
  }
  
  void simulatorToggleDoor(bool isDoorOpen) { //
     if (state is OvenLoaded) {
      final currentLoadedState = state as OvenLoaded;
      OvenState newOvenModel = _cloneOvenState(currentLoadedState.ovenState);
      newOvenModel.isDoorOpen = isDoorOpen;
      newOvenModel.simulateInternalLogic();
      emit(OvenLoaded(newOvenModel));
      _emitStateToBackend(newOvenModel);
    }
  }

  void simulatorStartCycle() { //
    if (state is OvenLoaded) {
      final currentLoadedState = state as OvenLoaded;
      OvenState newOvenModel = _cloneOvenState(currentLoadedState.ovenState);

      if (!newOvenModel.isOn || newOvenModel.selectedMode == OvenMode.off) {
        debugPrint("Four non allumé ou aucun mode sélectionné pour démarrer le cycle.");
        // Optionnel : émettre un OvenError ou un état pour informer l'UI
        return;
      }
      // S'assurer que les valeurs des contrôleurs sont bien prises en compte avant de démarrer
      double? newTargetTemp = double.tryParse(newOvenModel.targetTempController.text);
      if (newTargetTemp != null && newTargetTemp >= 50 && newTargetTemp <= 300) {
          newOvenModel.targetTemperature = newTargetTemp; // Pas besoin d'updateTargetTemperature ici si on va emit
      }
      int? newDurationMin = int.tryParse(newOvenModel.durationController.text);
      if (newDurationMin != null && newDurationMin >= 0) {
          newOvenModel.targetDurationSeconds = newDurationMin * 60;
      }

      newOvenModel.remainingTimeSeconds = newOvenModel.targetDurationSeconds;
      newOvenModel.operationalStatus = OvenOperationalStatus.preheating;
      newOvenModel.isTriggeredByKitchenOrder = false; 
      
      emit(OvenLoaded(newOvenModel));
      _emitStateToBackend(newOvenModel);
    }
  }

  // NOUVELLE MÉTHODE (utilisée par le FAB de démo dans l'UI)
  void simulatorHandleKitchenOrderTrigger(Map<String, dynamic> demoParams) {
     if (state is OvenLoaded) {
      OvenState newOvenModel = _cloneOvenState((state as OvenLoaded).ovenState);

      newOvenModel.isTriggeredByKitchenOrder = true;
      newOvenModel.isOn = true; 
      newOvenModel.isLightOn = demoParams['turnLightOn'] as bool? ?? true;
      newOvenModel.selectedMode = OvenState.parseOvenMode(demoParams['mode'] as String?);
      newOvenModel.updateTargetTemperature((demoParams['targetTemperature'] as num).toDouble());
      newOvenModel.updateTargetDurationMinutes((demoParams['durationMinutes'] as num).toInt());
      newOvenModel.operationalStatus = OvenOperationalStatus.preheating;

      emit(OvenLoaded(newOvenModel));
      _emitStateToBackend(newOvenModel);
      // Pour le SnackBar, il vaut mieux gérer cela dans l'UI avec un BlocListener
      // écoutant un état spécifique ou un "side effect" du Cubit.
    } else if (state is OvenInitial || state is OvenLoading || state is OvenError) {
        // Si l'état n'est pas chargé, on pourrait essayer de l'initialiser avec ces params
        // Ceci est une gestion plus avancée, pour l'instant on suppose qu'il est déjà chargé
        debugPrint("OvenCubit: simulatorHandleKitchenOrderTrigger appelé mais l'état n'est pas OvenLoaded.");
    }
  }


  @override
  Future<void> close() { //
    _simulationTimer?.cancel();
    return super.close();
  }
}
