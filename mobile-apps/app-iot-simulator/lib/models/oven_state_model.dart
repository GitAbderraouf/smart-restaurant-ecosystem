// models/oven_state_model.dart (créez ce fichier)
// models/oven_state_model.dart
import 'package:flutter/material.dart';

enum OvenMode { bake, grill, convection, defrost, keepWarm, off }
enum OvenOperationalStatus { off, idle, preheating, heating, cookingComplete, coolingDown, error }

class OvenState {
  String deviceId;
  String friendlyName;
  bool isOn; // Interrupteur principal du four
  OvenOperationalStatus operationalStatus;
  double currentTemperature;
  double targetTemperature;
  OvenMode selectedMode;
  bool isLightOn;
  bool isDoorOpen;
  int targetDurationSeconds; // Durée de cuisson totale souhaitée
  int remainingTimeSeconds; // Compte à rebours
  bool isTriggeredByKitchenOrder;

  TextEditingController targetTempController;
  TextEditingController durationController; // Pour la saisie en minutes

  OvenState({
    required this.deviceId,
    required this.friendlyName,
    this.isOn = false,
    this.operationalStatus = OvenOperationalStatus.off,
    this.currentTemperature = 20.0, // Température ambiante
    this.targetTemperature = 180.0,
    this.selectedMode = OvenMode.off,
    this.isLightOn = false,
    this.isDoorOpen = false,
    this.targetDurationSeconds = 0,
    this.remainingTimeSeconds = 0,
    this.isTriggeredByKitchenOrder = false,
  }) : targetTempController = TextEditingController(text: targetTemperature.toStringAsFixed(0)),
       durationController = TextEditingController(text: (targetDurationSeconds / 60).toStringAsFixed(0));

  // Getters pour le texte (déjà présents dans votre version)
  String get operationalStatusText {
    switch (operationalStatus) {
      case OvenOperationalStatus.off: return "Éteint";
      case OvenOperationalStatus.idle: return "Prêt (Au repos)";
      case OvenOperationalStatus.preheating: return "Préchauffage...";
      case OvenOperationalStatus.heating: return "En Cuisson...";
      case OvenOperationalStatus.cookingComplete: return "Cuisson Terminée";
      case OvenOperationalStatus.coolingDown: return "Refroidissement...";
      case OvenOperationalStatus.error: return "Erreur";
      default: return "Inconnu";
    }
  }

  String get selectedModeText { // Ce getter est pour le mode actuellement sélectionné dans l'instance
    return OvenState.getTextForMode(selectedMode); // Utilise la méthode statique
  }
  
  String get remainingTimeFormatted {
    if (remainingTimeSeconds <= 0) return "00:00";
    int minutes = remainingTimeSeconds ~/ 60;
    int seconds = remainingTimeSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  // Méthodes statiques pour obtenir le texte et parser depuis une chaîne
  static String getTextForMode(OvenMode mode) {
    switch (mode) {
      case OvenMode.bake: return "Chaleur Traditionnelle";
      case OvenMode.grill: return "Gril";
      case OvenMode.convection: return "Chaleur Tournante";
      case OvenMode.defrost: return "Décongélation";
      case OvenMode.keepWarm: return "Maintien au Chaud";
      case OvenMode.off: return "Aucun (Éteint)";
      default: return "Inconnu";
    }
  }

  // NOUVELLE MÉTHODE STATIQUE (ou celle qui manquait) :
  static OvenMode parseOvenMode(String? modeString) {
    if (modeString == null) return OvenMode.off;
    // Recherche insensible à la casse
    return OvenMode.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == modeString.trim().toLowerCase(),
      orElse: () {
        debugPrint("Mode de four inconnu reçu: '$modeString', retour à 'off'");
        return OvenMode.off;
      }
    );
  }

  // NOUVELLE MÉTHODE STATIQUE :
  static OvenOperationalStatus parseOperationalStatus(String? statusString) {
    if (statusString == null) return OvenOperationalStatus.off;
    return OvenOperationalStatus.values.firstWhere(
      (e) => e.toString().split('.').last.toLowerCase() == statusString.trim().toLowerCase(),
      orElse: () {
        debugPrint("Statut opérationnel de four inconnu reçu: '$statusString', retour à 'off'");
        return OvenOperationalStatus.off;
      }
    );
  }

  // Constructeur Factory pour créer depuis JSON (maintenant utilise les parseurs)
  factory OvenState.fromJson(Map<String, dynamic> json) {
    OvenState newState = OvenState(
      deviceId: json['deviceId'] as String? ?? 'unknown_device', // Fournir une valeur par défaut
      friendlyName: json['friendlyName'] as String? ?? 'Four Inconnu', // Fournir une valeur par défaut
      isOn: json['isOn'] as bool? ?? false,
      // Utilisation des parseurs statiques :
      operationalStatus: parseOperationalStatus(json['operationalStatus'] as String?),
      currentTemperature: (json['currentTemperature'] as num? ?? 20.0).toDouble(),
      targetTemperature: (json['targetTemperature'] as num? ?? 180.0).toDouble(),
      selectedMode: parseOvenMode(json['selectedMode'] as String?),
      isLightOn: json['isLightOn'] as bool? ?? false,
      isDoorOpen: json['isDoorOpen'] as bool? ?? false,
      targetDurationSeconds: json['targetDurationSeconds'] as int? ?? 0,
      remainingTimeSeconds: json['remainingTimeSeconds'] as int? ?? 0,
      isTriggeredByKitchenOrder: json['isTriggeredByKitchenOrder'] as bool? ?? false,
    );
    // Assurer que les contrôleurs sont initialisés avec les valeurs parsées
    newState.targetTempController.text = newState.targetTemperature.toStringAsFixed(0);
    newState.durationController.text = (newState.targetDurationSeconds / 60).toStringAsFixed(0);
    return newState;
  }

  // Méthodes de mise à jour (déjà présentes)
  void updateTargetTemperature(double newTarget) {
    targetTemperature = newTarget;
    String formattedTarget = newTarget.toStringAsFixed(0);
    if (targetTempController.text != formattedTarget) {
      targetTempController.text = formattedTarget;
      targetTempController.selection = TextSelection.fromPosition(
        TextPosition(offset: targetTempController.text.length),
      );
    }
  }

  void updateTargetDurationMinutes(int minutes) {
    targetDurationSeconds = minutes * 60;
    remainingTimeSeconds = targetDurationSeconds;
    String formattedMinutes = minutes.toStringAsFixed(0);
    if (durationController.text != formattedMinutes) {
      durationController.text = formattedMinutes;
      durationController.selection = TextSelection.fromPosition(
        TextPosition(offset: durationController.text.length),
      );
    }
  }
  
  // Logique de simulation interne (déjà présente)
  void simulateInternalLogic() {
    // ... (votre logique existante ici)
    if (!isOn) {
      if (currentTemperature > 25) {
          currentTemperature -= 1; 
          operationalStatus = OvenOperationalStatus.coolingDown;
      } else {
          currentTemperature = 20; 
          operationalStatus = OvenOperationalStatus.off;
          selectedMode = OvenMode.off;
          remainingTimeSeconds = 0;
      }
      isLightOn = false;
      isTriggeredByKitchenOrder = false; 
      return;
    }

    if (isDoorOpen) {
        operationalStatus = OvenOperationalStatus.idle; 
        if (currentTemperature > 25) currentTemperature -= 0.5;
        isTriggeredByKitchenOrder = false; 
        return;
    }

    if (selectedMode != OvenMode.off) {
        if (currentTemperature < targetTemperature -1) { 
            operationalStatus = OvenOperationalStatus.preheating;
            currentTemperature += 5; 
            if (currentTemperature > targetTemperature) currentTemperature = targetTemperature;
        } else {
            currentTemperature = targetTemperature; 
            if (remainingTimeSeconds > 0) {
                operationalStatus = OvenOperationalStatus.heating;
                remainingTimeSeconds--;
                if (remainingTimeSeconds == 0) {
                  operationalStatus = OvenOperationalStatus.cookingComplete;
                  isTriggeredByKitchenOrder = false; 
                }
            } else {
                operationalStatus = operationalStatus == OvenOperationalStatus.cookingComplete
                                    ? OvenOperationalStatus.cookingComplete
                                    : OvenOperationalStatus.idle;
            }
        }
    } else { 
        operationalStatus = OvenOperationalStatus.idle;
    }
  }
}