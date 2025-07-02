// screens/oven_simulator_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iot_simulator_app/cubits/oven_cubit/oven_cubit.dart';
import '../models/oven_state_model.dart';
import '../services/socket_service.dart';

class OvenSimulatorScreen extends StatefulWidget {
  const OvenSimulatorScreen({super.key});

  @override
  State<OvenSimulatorScreen> createState() => _OvenSimulatorScreenState();
}

class _OvenSimulatorScreenState extends State<OvenSimulatorScreen> {
  // Timer et état sont gérés par OvenCubit

  @override
  void initState() {
    super.initState();
     WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<OvenCubit>().state is OvenInitial) {
         context.read<OvenCubit>().fetchInitialOvenState(SocketService.ovenDeviceId);
      }
    });
  }

  // La méthode _triggerByKitchenOrder pour la simulation UI est déplacée vers le Cubit,
  // ou le Cubit expose une méthode que l'UI peut appeler si le bouton FAB doit rester.
  // Pour l'instant, le FAB simulera l'arrivée de l'événement via le Cubit.

  // La méthode _applySettingsAndStart est aussi déplacée vers le Cubit.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Simule la réception d'une commande cuisine via le Cubit
          // Le payload 'defaultParameters' serait typiquement construit par le SocketService
          // ou le Cubit lui-même sur la base d'un événement socket.
          // Ici, pour le bouton de démo, on utilise des valeurs fixes.
          final demoParams = {
            "targetTemperature": 190.0,
            "mode": "bake",
            "durationMinutes": 20,
            "turnLightOn": true
          };
          // On a besoin d'une méthode dans le cubit pour cela, qui sera appelée par le socket listener
          // Par exemple: context.read<OvenCubit>().handleKitchenOrderEvent(demoParams);
          // Pour le FAB actuel, on peut appeler la méthode qui traite les données du socket
          // C'est un peu un hack pour le FAB, car le payload est plus complet normalement.
          // Mieux : avoir une méthode dédiée dans le Cubit pour ce bouton de démo.
          // Pour l'instant, la méthode _handleKitchenOrderForOven dans le Cubit prend un payload plus large.
          // Appelons une nouvelle méthode dans le cubit:
          context.read<OvenCubit>().simulatorHandleKitchenOrderTrigger(demoParams);


        },
        label: Text("Simuler Commande Cuisine"),
        icon: Icon(Icons.restaurant_menu),
      ),
      body: BlocConsumer<OvenCubit, OvenCubitState>(
        listener: (context, state) {
          if (state is OvenError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur Four: ${state.message}"), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is OvenInitial || state is OvenLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is OvenLoaded) {
            final ovenModel = state.ovenState;

            // ovenModel.targetTempController.text = ovenModel.targetTemperature.toStringAsFixed(0);
            // ovenModel.durationController.text = (ovenModel.targetDurationSeconds / 60).toStringAsFixed(0);
            // Ceci est déjà géré par les méthodes updateTargetTemperature et updateTargetDurationMinutes
            // dans le modèle OvenState lui-même.

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card( /* ... Titre et Device ID ... */ 
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ovenModel.friendlyName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text("Device ID: ${ovenModel.deviceId}", style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 15),

                  // Indicateur Visuel et Statut principal
                  Card( /* ... Couleur et Icône basées sur ovenModel.isTriggeredByKitchenOrder et ovenModel.isOn ... */ 
                     elevation: 4.0,
                      color: ovenModel.isTriggeredByKitchenOrder 
                          ? Colors.orange[100] 
                          : (ovenModel.isOn && ovenModel.selectedMode != OvenMode.off && (ovenModel.operationalStatus == OvenOperationalStatus.heating || ovenModel.operationalStatus == OvenOperationalStatus.preheating) 
                              ? Colors.red[300] 
                              : Colors.grey[300]),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              ovenModel.isOn && ovenModel.selectedMode != OvenMode.off && (ovenModel.operationalStatus == OvenOperationalStatus.heating || ovenModel.operationalStatus == OvenOperationalStatus.preheating)
                                  ? Icons.fireplace_rounded
                                  : Icons.fireplace_outlined,
                              size: 50,
                              color: ovenModel.isOn && ovenModel.selectedMode != OvenMode.off && (ovenModel.operationalStatus == OvenOperationalStatus.heating || ovenModel.operationalStatus == OvenOperationalStatus.preheating)
                                  ? Colors.redAccent
                                  : Colors.black54,
                            ),
                            SizedBox(height: 8),
                            Text(
                              ovenModel.operationalStatusText,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            if (ovenModel.isTriggeredByKitchenOrder)
                              Text("(Déclenché par commande cuisine)", style: TextStyle(color: Colors.orange[800])),
                          ],
                        ),
                      ),
                  ),
                  SizedBox(height: 15),

                  // Contrôles Généraux
                  _buildGeneralControlsCard(context, ovenModel),
                  SizedBox(height: 15),

                  // Gestion Température
                  _buildTemperatureCard(context, ovenModel),
                  SizedBox(height: 15),
                  
                  // Gestion Mode et Durée
                  _buildModeDurationCard(context, ovenModel),
                  SizedBox(height: 15),

                  ElevatedButton.icon(
                    icon: Icon(Icons.play_circle_outline),
                    label: Text("Appliquer & Démarrer", style: TextStyle(fontSize: 16)), // Changé le texte
                    onPressed: () {
                      context.read<OvenCubit>().simulatorStartCycle();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                  SizedBox(height: 70),
                ],
              ),
            );
          } else if (state is OvenError) {
            return Center(child: Text("Erreur Four: ${state.message}"));
          }
          return Center(child: Text("État inconnu du four."));
        },
      ),
    );
  }

  // Les méthodes _build...Card prennent maintenant (BuildContext context, OvenState ovenModel)
  Widget _buildGeneralControlsCard(BuildContext context, OvenState ovenModel) {
     return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Contrôles Généraux", style: Theme.of(context).textTheme.titleMedium),
            SwitchListTile(
              title: Text("Alimentation Four"),
              value: ovenModel.isOn,
              onChanged: (bool value) => context.read<OvenCubit>().simulatorTogglePower(value),
            ),
            SwitchListTile(
              title: Text("Lumière du Four"),
              value: ovenModel.isLightOn,
              onChanged: ovenModel.isOn ? (bool value) => context.read<OvenCubit>().simulatorToggleLight(value) : null,
            ),
            SwitchListTile(
              title: Text("Porte Ouverte"),
              value: ovenModel.isDoorOpen,
               onChanged: ovenModel.isOn ? (bool value) => context.read<OvenCubit>().simulatorToggleDoor(value) : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemperatureCard(BuildContext context, OvenState ovenModel) {
    return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Température", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 10),
            Center( /* ... Affichage température actuelle ... */ 
               child: Text(
                "${ovenModel.currentTemperature.toStringAsFixed(0)} °C",
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.secondary),
              ),
            ),
            Text("Actuelle", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            SizedBox(height: 10),
            Text("Cible: ${ovenModel.targetTemperature.toStringAsFixed(0)} °C"),
            Slider(
              value: ovenModel.targetTemperature,
              min: 50, max: 300, divisions: 25,
              label: "${ovenModel.targetTemperature.toStringAsFixed(0)} °C",
              onChanged: ovenModel.isOn ? (double val) => context.read<OvenCubit>().simulatorSetTargetTemperature(val.roundToDouble()) : null,
            ),
            TextField(
              controller: ovenModel.targetTempController,
              enabled: ovenModel.isOn,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "T° Cible Précise (°C)", border: OutlineInputBorder()),
              onSubmitted: (val) {
                double? newT = double.tryParse(val);
                if (newT != null && newT >= 50 && newT <= 300) {
                  context.read<OvenCubit>().simulatorSetTargetTemperature(newT);
                } else {
                  ovenModel.targetTempController.text = ovenModel.targetTemperature.toStringAsFixed(0);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeDurationCard(BuildContext context, OvenState ovenModel) {
     return Card(
      elevation: 2.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Mode & Durée", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 10),
            DropdownButtonFormField<OvenMode>(
              decoration: InputDecoration(labelText: "Mode de Cuisson", border: OutlineInputBorder()),
              value: ovenModel.selectedMode,
              items: OvenMode.values.map((OvenMode mode) {
                return DropdownMenuItem<OvenMode>(
                  value: mode,
                  child: Text(OvenState.getTextForMode(mode)), // Utilise la méthode statique
                );
              }).toList(),
              onChanged: ovenModel.isOn ? (OvenMode? newValue) {
                if (newValue != null) {
                  context.read<OvenCubit>().simulatorSetMode(newValue);
                }
              } : null,
            ),
            SizedBox(height: 15),
            TextField(
              controller: ovenModel.durationController,
              enabled: ovenModel.isOn,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: "Durée de Cuisson (minutes)", border: OutlineInputBorder()),
               onSubmitted: (val) {
                int? newDur = int.tryParse(val);
                if (newDur != null && newDur >=0) {
                   context.read<OvenCubit>().simulatorSetDuration(newDur);
                } else {
                  ovenModel.durationController.text = (ovenModel.targetDurationSeconds / 60).toStringAsFixed(0);
                }
              },
            ),
            SizedBox(height: 10),
            Text(
              "Temps Restant: ${ovenModel.remainingTimeFormatted}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}