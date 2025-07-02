import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:hungerz_ordering/models/allModels.dart';
import 'package:hungerz_ordering/Config/app_config.dart';
import 'package:hungerz_ordering/services/chef_socket_service.dart';

part 'tables_status_state.dart';

class TablesStatusCubit extends Cubit<TablesStatusState> {
  final ChefSocketService _socketService;
  StreamSubscription? _tableUpdatesSubscriptionFromSocket;
  final String _apiBaseUrl = "${AppConfig.baseUrl}/api/chef";

  TablesStatusCubit(this._socketService) : super(const TablesStatusInitial()) {
    fetchInitialTableStatuses(); // Renommé pour clarté
    _socketService.connectAndListen();
    _tableUpdatesSubscriptionFromSocket = _socketService.tableStatusUpdates
        .listen(_handleTableUpdateFromSocket, onError: (error) {
      debugPrint("TablesStatusCubit: Erreur sur le stream tableStatusUpdates: $error");
      if (!isClosed) {
        // Émettre un état d'erreur si la connexion socket est critique et échoue
        // Pour l'instant, on logue l'erreur. Un refresh manuel peut toujours être fait.
      }
    });
  }

  List<TableModel>? get _currentTablesFromState {
      return state.tables; // Accède à la liste de tables de l'état actuel (peut être null)
  }

  Future<void> _performFetchTableStatuses({bool isInitialLoad = false}) async {
    if (isClosed) return;

    // L'état de chargement est émis par les méthodes publiques (fetchInitial/refresh)
    // pour un meilleur contrôle du feedback UI.

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/tables'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (isClosed) return;

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('tables') && responseData['tables'] is List) {
          final List<dynamic> tablesData = responseData['tables'];
          final tables = tablesData
              .map((data) {
                try {
                  return TableModel.fromJson(data as Map<String, dynamic>);
                } catch (e, s) {
                  debugPrint("Erreur parsing table API: $e\nData: $data\n$s");
                  return null;
                }
              })
              .whereType<TableModel>()
              .toList();
          tables.sort((a, b) => a.displayName.compareTo(b.displayName));
          emit(TablesStatusLoaded(tables: tables));
        } else {
          debugPrint("_performFetchTableStatuses: Clé 'tables' manquante/invalide. Body: ${response.body}");
          emit(TablesStatusError("Réponse API invalide (tables).", previousTables: _currentTablesFromState));
        }
      } else {
        debugPrint("_performFetchTableStatuses: Erreur API ${response.statusCode}. Body: ${response.body}");
        emit(TablesStatusError("Erreur API (${response.statusCode}): ${response.reasonPhrase ?? 'Erreur inconnue'}", previousTables: _currentTablesFromState));
      }
    } on TimeoutException catch (e,s) {
        debugPrint("TimeoutException _performFetchTableStatuses: $e\n$s");
        if (!isClosed) {
            emit(TablesStatusError("Délai de connexion dépassé. Veuillez réessayer.", previousTables: _currentTablesFromState));
        }
    } catch (e, s) {
      debugPrint("Exception _performFetchTableStatuses: $e\n$s");
      if (!isClosed) {
        emit(TablesStatusError("Erreur communication: ${e.toString()}", previousTables: _currentTablesFromState));
      }
    }
  }

  void fetchInitialTableStatuses() async {
    if (isClosed) return;
    // Émettre Loading seulement si on est en état Initial ou Erreur, pour éviter clignotement si déjà chargé.
    if (state is TablesStatusInitial || state is TablesStatusError) {
      emit(const TablesStatusLoading()); // Pas de previousTables pour le tout premier chargement
    }
    await _performFetchTableStatuses(isInitialLoad: true);
  }

  void refreshTables() async {
    if (isClosed) return;
    debugPrint("refreshTables() appelé dans le Cubit.");
    // Émettre Loading en conservant les tables actuelles pour un refresh plus doux
    emit(TablesStatusLoading(previousTables: _currentTablesFromState));
    await _performFetchTableStatuses();
  }

  void _handleTableUpdateFromSocket(Map<String, dynamic> tableUpdateData) {
    if (isClosed) return;
    debugPrint("Cubit: _handleTableUpdateFromSocket pour tabletDeviceId: ${tableUpdateData['tableId']}");
    
    List<TableModel> currentTables = List.from(_currentTablesFromState ?? []);
    
    final String updatedTabletDeviceId = tableUpdateData['tableId'] as String? ?? '';
    final String updatedMongoId = tableUpdateData['_id'] as String? ?? '';

    if (updatedTabletDeviceId.isEmpty && updatedMongoId.isEmpty) {
      debugPrint("Cubit: ID manquant dans données socket pour update table.");
      return;
    }
    int tableIndex = -1;
    if (updatedTabletDeviceId.isNotEmpty) {
      tableIndex = currentTables.indexWhere((t) => t.tabletDeviceId == updatedTabletDeviceId);
    }
    if (tableIndex == -1 && updatedMongoId.isNotEmpty) {
      tableIndex = currentTables.indexWhere((t) => t.id == updatedMongoId);
    }
    
    TableModel updatedOrNewTable;
    try {
      updatedOrNewTable = TableModel.fromJson(tableUpdateData);
    } catch (e, s) {
      debugPrint("Cubit: Erreur parsing tableUpdateData (socket) avec fromJson: $e\nData: $tableUpdateData\n$s");
      return;
    }

    if (tableIndex != -1) {
      final existingTable = currentTables[tableIndex];
      currentTables[tableIndex] = updatedOrNewTable.copyWith(
          associatedReservations: updatedOrNewTable.associatedReservations.isEmpty 
                                  ? existingTable.associatedReservations 
                                  : updatedOrNewTable.associatedReservations,
          isLoadingReservations: existingTable.isLoadingReservations); // Conserver l'état de chargement des réservations
    } else {
      currentTables.add(updatedOrNewTable);
    }
    currentTables.sort((a, b) => a.displayName.compareTo(b.displayName));
    if (!isClosed) emit(TablesStatusLoaded(tables: currentTables));
  }

  Future<void> fetchReservationsForTable(String tableMongoId) async {
    if (isClosed) return;

    final currentTables = _currentTablesFromState;
    if (currentTables == null) return; // Ne peut pas charger si pas de tables de base

    final tableIndex = currentTables.indexWhere((t) => t.id == tableMongoId);
    if (tableIndex == -1) return;

    var tablesCopy = List<TableModel>.from(currentTables);
    tablesCopy[tableIndex] = tablesCopy[tableIndex].copyWith(isLoadingReservations: true);
    if (!isClosed) emit(TablesStatusLoaded(tables: tablesCopy)); // Émettre avec la liste mise à jour

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/tables/$tableMongoId/reservations'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (isClosed) return;

      // Récupérer l'état le plus récent des tables au cas où il aurait changé pendant l'appel async
      final freshTablesAfterAwait = _currentTablesFromState;
      if (freshTablesAfterAwait == null) return; // L'état a pu changer radicalement

      tablesCopy = List<TableModel>.from(freshTablesAfterAwait);
      final freshTableIndex = tablesCopy.indexWhere((t) => t.id == tableMongoId);
      if (freshTableIndex == -1) return; // La table a pu disparaître

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData.containsKey('reservations') && responseData['reservations'] is List) {
          final List<dynamic> reservationsData = responseData['reservations'];
          final reservations = reservationsData
              .map((data) => ReservationModel.fromJson(data as Map<String, dynamic>))
              .toList();
          tablesCopy[freshTableIndex] = tablesCopy[freshTableIndex].copyWith(associatedReservations: reservations, isLoadingReservations: false);
        } else {
           tablesCopy[freshTableIndex] = tablesCopy[freshTableIndex].copyWith(isLoadingReservations: false, associatedReservations: []);
        }
      } else {
         debugPrint("Erreur fetchReservations API ${response.statusCode}: ${response.body}");
        tablesCopy[freshTableIndex] = tablesCopy[freshTableIndex].copyWith(isLoadingReservations: false);
      }
       if (!isClosed) emit(TablesStatusLoaded(tables: tablesCopy));
    } on TimeoutException catch (e,s) {
        debugPrint("TimeoutException fetchReservations: $e\n$s");
        if (!isClosed) {
            final tablesOnError = _currentTablesFromState;
            if (tablesOnError != null) {
                var tablesCopyOnError = List<TableModel>.from(tablesOnError);
                final tableIndexOnError = tablesCopyOnError.indexWhere((t) => t.id == tableMongoId);
                if (tableIndexOnError != -1) {
                    tablesCopyOnError[tableIndexOnError] = tablesCopyOnError[tableIndexOnError].copyWith(isLoadingReservations: false);
                    if (!isClosed) emit(TablesStatusLoaded(tables: tablesCopyOnError));
                }
            }
        }
    } catch (e, s) {
      debugPrint("Exception fetchReservations: $e\n$s");
       if (!isClosed) {
            final tablesOnError = _currentTablesFromState;
            if (tablesOnError != null) {
                var tablesCopyOnError = List<TableModel>.from(tablesOnError);
                final tableIndexOnError = tablesCopyOnError.indexWhere((t) => t.id == tableMongoId);
                if (tableIndexOnError != -1) {
                    tablesCopyOnError[tableIndexOnError] = tablesCopyOnError[tableIndexOnError].copyWith(isLoadingReservations: false);
                    if (!isClosed) emit(TablesStatusLoaded(tables: tablesCopyOnError));
                }
            }
        }
    }
  }

  Future<void> verifyReservationQR(String qrDataContent) async {
    if (isClosed) return;
    final currentTablesForState = _currentTablesFromState;
    emit(ReservationValidationLoading(qrDataContent, currentTables: currentTablesForState));

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/reservations/verify-qr/$qrDataContent'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (isClosed) return;
      // Récupérer les tables actuelles au cas où elles auraient changé pendant l'appel
      final freshTablesForState = _currentTablesFromState;

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final reservationData = responseData['reservation'] as Map<String, dynamic>;
        final tableDataFromApi = responseData['table'] as Map<String, dynamic>?;
        
        final ReservationModel validatedReservation = ReservationModel.fromJson(reservationData);
        TableModel? associatedTableModelInState;

        if (freshTablesForState != null) {
            if (validatedReservation.tableMongoId != null) {
                associatedTableModelInState = freshTablesForState.firstWhereOrNull((t) => t.id == validatedReservation.tableMongoId);
            } else if (tableDataFromApi != null) {
                String tableMongoIdFromApi = tableDataFromApi['_id'] as String;
                associatedTableModelInState = freshTablesForState.firstWhereOrNull((t) => t.id == tableMongoIdFromApi);
            }
        }
        if (!isClosed) emit(ReservationValidated(validatedReservation, associatedTableModelInState, currentTables: freshTablesForState));
      } else {
        final errorData = json.decode(response.body);
        if (!isClosed) emit(ReservationValidationError(qrDataContent, errorData['message'] ?? 'Erreur validation QR', currentTables: freshTablesForState));
      }
    } on TimeoutException catch (e,s) {
        debugPrint("TimeoutException verify QR: $e\n$s");
        if (!isClosed) emit(ReservationValidationError(qrDataContent, "Délai de connexion dépassé.", currentTables: _currentTablesFromState));
    } catch (e, s) {
      debugPrint("Exception verify QR: $e\n$s");
      if (!isClosed) emit(ReservationValidationError(qrDataContent, "Erreur communication: ${e.toString()}", currentTables: _currentTablesFromState));
    }
  }

  Future<void> notifyKitchenOfPreOrder(ReservationModel reservation, String tableDisplayNameForKitchen) async {
    if (isClosed) return;
    final currentTablesForState = _currentTablesFromState;
    emit(KitchenNotificationLoading(reservation, currentTables: currentTablesForState));

    try {
      final List<Map<String, dynamic>> itemsPayload = reservation.preSelectedMenu.map((item) => item.toMap()).toList();
      final payload = {
        'reservationId': reservation.id,
        'tableDisplayName': tableDisplayNameForKitchen,
        'items': itemsPayload,
      };

      debugPrint('Payload pour notifyKitchenOfPreOrder: ${json.encode(payload)}');

      final response = await http.post(
        Uri.parse('$_apiBaseUrl/kitchen/notify-preorder'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(payload),
      ).timeout(const Duration(seconds: 15));

      if (isClosed) return;
      final freshTablesForStateAfterNotify = _currentTablesFromState; // Récupérer les tables au cas où

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        emit(KitchenNotificationSuccess(reservation, responseData['message'] ?? 'Cuisine notifiée avec succès.', currentTables: freshTablesForStateAfterNotify));
      } else {
        final errorData = json.decode(response.body);
        String errorMessage = 'Échec de la notification cuisine (code: ${response.statusCode}).';
        if (errorData != null && errorData['message'] is String) {
          errorMessage = errorData['message'];
        }
        emit(KitchenNotificationFailure(reservation, errorMessage, currentTables: freshTablesForStateAfterNotify));
      }
    } on TimeoutException catch (e,s) {
        debugPrint("TimeoutException notifyKitchen: $e\n$s");
        if (!isClosed) emit(KitchenNotificationFailure(reservation, "Délai de connexion dépassé lors de la notification cuisine.", currentTables: _currentTablesFromState));
    } catch (e, s) {
      debugPrint("Exception lors de la notification à la cuisine: $e\nStackTrace: $s");
      if (!isClosed) emit(KitchenNotificationFailure(reservation, "Erreur communication service cuisine: ${e.toString()}", currentTables: _currentTablesFromState));
    } finally {
        if(!isClosed) {
            debugPrint("Rafraîchissement des tables après tentative de notification cuisine.");
            // Le refreshTables émettra TablesStatusLoading(previousTables:...) puis TablesStatusLoaded(...)
            // donc la liste des tables sera préservée pendant le chargement du refresh.
            refreshTables();
        }
    }
  }

  @override
  Future<void> close() {
    _tableUpdatesSubscriptionFromSocket?.cancel();
    return super.close();
  }
}