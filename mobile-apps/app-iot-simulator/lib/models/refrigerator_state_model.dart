// models/refrigerator_state_model.dart (créez ce fichier)
import 'package:flutter/material.dart';

class RefrigeratorState {
  String deviceId;
  String friendlyName;
  bool isOn;
  String currentStatusText; // Ex: "En refroidissement", "Au repos", "Éteint", "Porte ouverte"
  double currentTemperature;
  double targetTemperature;
  bool isDoorOpen; // Ajout pour simuler une porte ouverte

  // Contrôleurs pour les champs de texte si vous en utilisez pour la température cible
  TextEditingController targetTempController;

  RefrigeratorState({
    required this.deviceId,
    required this.friendlyName,
    this.isOn = true, // Par défaut allumé pour la simulation
    this.currentStatusText = "Au repos",
    this.currentTemperature = 4.0,
    this.targetTemperature = 4.0,
    this.isDoorOpen = false,
  }) : targetTempController = TextEditingController(text: targetTemperature.toStringAsFixed(1));

factory RefrigeratorState.fromJson(Map<String, dynamic> json) {
    return RefrigeratorState(
      deviceId: json['deviceId'] as String,
      friendlyName: json['friendlyName'] as String,
      isOn: json['isOn'] as bool? ?? true, // Valeur par défaut si non fourni
      currentStatusText: json['currentStatusText'] as String? ?? "Inconnu",
      currentTemperature: (json['currentTemperature'] as num? ?? 4.0).toDouble(),
      targetTemperature: (json['targetTemperature'] as num? ?? 4.0).toDouble(),
      isDoorOpen: json['isDoorOpen'] as bool? ?? false,
    );
  }


  // Méthode pour mettre à jour la température cible et synchroniser le contrôleur
  void updateTargetTemperature(double newTarget) {
    targetTemperature = newTarget;
    String formattedTarget = newTarget.toStringAsFixed(1);
    if (targetTempController.text != formattedTarget) {
      targetTempController.text = formattedTarget;
      targetTempController.selection = TextSelection.fromPosition(
        TextPosition(offset: targetTempController.text.length),
      );
    }
  }

  // Simuler la logique interne du réfrigérateur (très basique)
  void simulateInternalLogic() {
    if (!isOn) {
      currentStatusText = "Éteint";
      // La température pourrait lentement remonter vers l'ambiante (non simulé ici pour la simplicité)
      return;
    }

    if (isDoorOpen) {
      currentStatusText = "Porte Ouverte !";
      currentTemperature += 0.2; // La température monte si la porte est ouverte
      if (currentTemperature > 15) currentTemperature = 15; // Limite haute
      return; // Pas de refroidissement actif si porte ouverte
    }

    if (currentTemperature > targetTemperature + 0.2) {
      currentStatusText = "En refroidissement";
      currentTemperature -= 0.1; // Refroidit lentement
      if (currentTemperature < targetTemperature) currentTemperature = targetTemperature;
    } else if (currentTemperature < targetTemperature - 0.2) {
      currentStatusText = "Remontée légère"; // Un peu trop froid, remonte vers la cible
      currentTemperature += 0.05;
      if (currentTemperature > targetTemperature) currentTemperature = targetTemperature;
    } else {
      currentStatusText = "Au repos";
      currentTemperature = targetTemperature; // Stabilisé
    }
  }
}