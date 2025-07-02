import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hungerz_store/services/manager_socket_service.dart'; // Ajustez le chemin
import 'package:flutter/foundation.dart';

part 'appliance_status_state.dart';

class ApplianceStatusCubit extends Cubit<ApplianceStatusState> {
  final ManagerSocketService _managerSocketService;
  StreamSubscription? _fridgeSubscription;
  StreamSubscription? _ovenSubscription;

  // Remplacez par les ID de vos équipements si vous en ciblez des spécifiques,
  // sinon, le premier événement reçu mettra à jour l'état.
  // Pour une gestion multi-équipements, la structure de l'état serait une Map.
  // static const String _targetFridgeId = "fridge_sim_1";
  // static const String _targetOvenId = "oven_sim_1";


  ApplianceStatusCubit(this._managerSocketService) : super(ApplianceStatusInitial()) {
    // Pour l'instant, on suppose un seul équipement de chaque type ou le premier reçu.
    // Si vous avez plusieurs équipements, vous filtreriez par deviceId ici
    // et stockeriez les états dans une Map<String, EquipementData> dans ApplianceStatusLoaded.

    _fridgeSubscription = _managerSocketService.fridgeStatusStream.listen((fridgeData) {
      debugPrint("ApplianceStatusCubit: Reçu FridgeStatus pour ${fridgeData.deviceId}");
      if (state is ApplianceStatusLoaded) {
        final currentStatus = state as ApplianceStatusLoaded;
        // Pour l'instant, on écrase le statut du frigo avec le dernier reçu
        // Si multi-frigos: currentStatus.fridges[fridgeData.deviceId] = fridgeData;
        emit(currentStatus.copyWith(fridgeStatus: fridgeData));
      } else {
        emit(ApplianceStatusLoaded(fridgeStatus: fridgeData));
      }
    });

    _ovenSubscription = _managerSocketService.ovenStatusStream.listen((ovenData) {
      debugPrint("ApplianceStatusCubit: Reçu OvenStatus pour ${ovenData.deviceId}");
      if (state is ApplianceStatusLoaded) {
        final currentStatus = state as ApplianceStatusLoaded;
        // Pour l'instant, on écrase le statut du four
        // Si multi-fours: currentStatus.ovens[ovenData.deviceId] = ovenData;
        emit(currentStatus.copyWith(ovenStatus: ovenData));
      } else {
        emit(ApplianceStatusLoaded(ovenStatus: ovenData));
      }
    });
  }

  // Optionnel: une méthode pour un fetch initial si vous avez un endpoint API pour l'état actuel
  // Future<void> fetchInitialApplianceStatuses() async {
  //   emit(ApplianceStatusLoading());
  //   // ... logique d'appel API ...
  //   // emit(ApplianceStatusLoaded(fridgeStatus: ..., ovenStatus: ...));
  // }


  @override
  Future<void> close() {
    _fridgeSubscription?.cancel();
    _ovenSubscription?.cancel();
    return super.close();
  }
}