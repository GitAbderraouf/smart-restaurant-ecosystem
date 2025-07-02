// screens/refrigerator_simulator_screen.dart
// screens/refrigerator_simulator_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Importer flutter_bloc
import 'package:iot_simulator_app/cubits/refrigerator_cubit/refrigerator_cubit.dart';
import '../models/refrigerator_state_model.dart'; 
 // Importer le Cubit
import '../services/socket_service.dart'; // Pour accéder au deviceId statique

class RefrigeratorSimulatorScreen extends StatefulWidget {
  const RefrigeratorSimulatorScreen({super.key});

  @override
  State<RefrigeratorSimulatorScreen> createState() => _RefrigeratorSimulatorScreenState();
}

class _RefrigeratorSimulatorScreenState extends State<RefrigeratorSimulatorScreen> {
  // Le Timer pour la simulation interne est maintenant géré par le Cubit.
  // Le RefrigeratorState est aussi géré par le Cubit.

  @override
  void initState() {
    super.initState();
    // Demander au Cubit de charger les données initiales si ce n'est pas déjà fait dans main.dart
    // Si c'est déjà fait dans main.dart au moment de la création du BlocProvider, cette ligne peut être optionnelle
    // ou servir de rafraîchissement si l'écran est revisité.
    // Pour s'assurer qu'il est appelé une fois que le contexte est prêt :
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Vérifier si l'état est initial avant de fetch pour éviter les appels multiples si déjà chargé.
      if (context.read<RefrigeratorCubit>().state is RefrigeratorInitial) {
        context.read<RefrigeratorCubit>().fetchInitialRefrigeratorState(SocketService.fridgeDeviceId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // L'AppBar est dans MainSimulatorScreen, donc pas besoin ici.
      body: BlocConsumer<RefrigeratorCubit, RefrigeratorCubitState>( // Utiliser BlocConsumer si vous voulez aussi écouter
        listener: (context, state) {
          if (state is RefrigeratorError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Erreur Réfrigérateur: ${state.message}"), backgroundColor: Colors.red),
            );
          }
        },
        builder: (context, state) {
          if (state is RefrigeratorInitial || state is RefrigeratorLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is RefrigeratorLoaded) {
            // Accéder au modèle RefrigeratorState depuis l'état du Cubit
            final fridgeModel = state.fridgeState;
            
            // Synchroniser le contrôleur de texte si la valeur du modèle a changé
            // (par exemple, suite à une commande socket)
            // Le modèle RefrigeratorState met déjà à jour son propre contrôleur via updateTargetTemperature.
            // Si vous voulez être extra sûr ou si le contrôleur était géré ici:
            // if (fridgeModel.targetTempController.text != fridgeModel.targetTemperature.toStringAsFixed(1)) {
            //   WidgetsBinding.instance.addPostFrameCallback((_) { // Pour éviter les erreurs de build
            //      fridgeModel.targetTempController.text = fridgeModel.targetTemperature.toStringAsFixed(1);
            //   });
            // }


            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Card(
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fridgeModel.friendlyName,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text("Device ID: ${fridgeModel.deviceId}", style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Contrôle Général", style: Theme.of(context).textTheme.titleLarge),
                          SizedBox(height: 10),
                          SwitchListTile(
                            title: Text("État de l'appareil:"),
                            value: fridgeModel.isOn,
                            onChanged: (bool value) {
                              context.read<RefrigeratorCubit>().simulatorTogglePower(value);
                            },
                          ),
                          SwitchListTile(
                            title: Text("Porte Ouverte:"),
                            value: fridgeModel.isDoorOpen,
                            onChanged: (bool value) {
                               context.read<RefrigeratorCubit>().simulatorToggleDoor(value);
                            },
                          ),
                          SizedBox(height: 10),
                          Text("Statut Actuel: ${fridgeModel.currentStatusText}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Card(
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text("Gestion de la Température", style: Theme.of(context).textTheme.titleLarge),
                          SizedBox(height: 20),
                          Center(
                            child: Text(
                              "${fridgeModel.currentTemperature.toStringAsFixed(1)} °C",
                              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                            ),
                          ),
                          Text("Température Actuelle", textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
                          SizedBox(height: 20),
                          Text("Température Cible: ${fridgeModel.targetTemperature.toStringAsFixed(1)} °C", style: TextStyle(fontSize: 16)),
                          Slider(
                            value: fridgeModel.targetTemperature,
                            min: -5, max: 15, divisions: 40,
                            label: fridgeModel.targetTemperature.toStringAsFixed(1) + " °C",
                            onChanged: (double value) {
                              // Mise à jour de l'UI immédiate pour le slider
                              // Le Cubit sera appelé sur onChangeEnd ou via le bouton appliquer
                              // Pour une réactivité directe du slider:
                              context.read<RefrigeratorCubit>().simulatorSetTargetTemperature(value);
                            },
                            // onChangeEnd: (double value) {
                            //   context.read<RefrigeratorCubit>().simulatorSetTargetTemperature(value);
                            // },
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: fridgeModel.targetTempController, // Utilise le contrôleur du modèle
                                  keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true),
                                  decoration: InputDecoration(
                                    labelText: 'T° Cible Précise (°C)',
                                    border: OutlineInputBorder(),
                                  ),
                                  onSubmitted: (value) {
                                     double? newTarget = double.tryParse(value);
                                     if (newTarget != null && newTarget >= -5 && newTarget <= 15) {
                                       context.read<RefrigeratorCubit>().simulatorSetTargetTemperature(newTarget);
                                     } else {
                                       fridgeModel.targetTempController.text = fridgeModel.targetTemperature.toStringAsFixed(1);
                                     }
                                  },
                                ),
                              ),
                              SizedBox(width: 10),
                              ElevatedButton(
                                onPressed: (){
                                   FocusScope.of(context).unfocus();
                                   double? newTarget = double.tryParse(fridgeModel.targetTempController.text);
                                   if (newTarget != null && newTarget >= -5 && newTarget <= 15) {
                                     context.read<RefrigeratorCubit>().simulatorSetTargetTemperature(newTarget);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Demande de T° cible envoyée.')),
                                      );
                                   } else {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(content: Text('Valeur de T° cible invalide.')),
                                     );
                                     fridgeModel.targetTempController.text = fridgeModel.targetTemperature.toStringAsFixed(1);
                                   }
                                },
                                child: Text("Appliquer")
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else if (state is RefrigeratorError) {
            return Center(child: Text("Erreur Réfrigérateur: ${state.message}"));
          }
          return Center(child: Text("État inconnu du réfrigérateur."));
        },
      ),
    );
  }
}