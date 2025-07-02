// user_app/lib/cubits/table_session_cubit/table_session_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hungerz/services/socket_service.dart'; // UserAppSocketService
import 'package:hungerz/cubits/cart_cubit/cart_cubit.dart';
import 'package:hungerz/main.dart'; // For global navigatorKey

part 'table_session_state.dart';

class TableSessionCubit extends Cubit<TableSessionState> {
  final UserAppSocketService _socketService;
  final CartCubit _cartCubit;

  StreamSubscription? _sessionJoinedSub;
  StreamSubscription? _cartUpdateSub; // Toujours non utilisé pour onTableSessionCartUpdated ici
  StreamSubscription? _orderFinalizedSub;
  StreamSubscription? _socketErrorSub;
  StreamSubscription? _socketConnectionSub;
  // NOUVEAU: Subscription pour la fin de session initiée par le serveur
  StreamSubscription? _sessionEndedByServerSub;


  String? _activeSessionId;
  String? get activeSessionId => _activeSessionId;

  String? _activeKioskDeviceId;
  String? get activeKioskDeviceId => _activeKioskDeviceId;

  TableSessionCubit({
    required UserAppSocketService socketService,
    required CartCubit cartCubit,
  })  : _socketService = socketService,
        _cartCubit = cartCubit,
        super(TableSessionInitial()) {
    _listenToSocketEvents();
  }

  void _listenToSocketEvents() {
    _sessionJoinedSub = _socketService.onSessionJoined.listen((sessionData) { //
      print("TableSessionCubit: Event 'onSessionJoined' received: $sessionData");
      _activeSessionId = sessionData['sessionId'] as String?;
      _activeKioskDeviceId = sessionData['tableId'] as String?; //

      if (_activeSessionId != null && _activeKioskDeviceId != null) {
        final List<Map<String, dynamic>> initialItems =
            List<Map<String, dynamic>>.from(sessionData['items'] ?? []);
        
        _cartCubit.replaceCartWithSessionItems(initialItems); //

        if (navigatorKey.currentState?.canPop() == true) {
          navigatorKey.currentState!.pop();
          print("TableSessionCubit: Popped QRScannerPage.");
        }

        emit(TableSessionJoined( //
          sessionId: _activeSessionId!,
          kioskDeviceId: _activeKioskDeviceId!,
          initialCartItems: initialItems,
        ));

        emit(TableSessionActive( //
          sessionId: _activeSessionId!,
          kioskDeviceId: _activeKioskDeviceId!,
        ));

      } else {
        print("TableSessionCubit: Failed to join session, critical data missing.");
        emit(const TableSessionError("Échec de la connexion à la session : Données manquantes du serveur.")); //
      }
    }, onError: (error) {
      print("TableSessionCubit: Error on onSessionJoined stream: $error");
      emit(TableSessionError("Erreur lors de la connexion à la session : ${error.toString()}")); //
    });

    // Gestion de la fin de session via la finalisation de commande (Kiosk ou UserApp)
    _orderFinalizedSub = _socketService.onTableOrderFinalized.listen((orderData) { //
      print("TableSessionCubit: Event 'onTableOrderFinalized' received: $orderData");
      if (state is TableSessionActive && orderData['sessionId'] == _activeSessionId) {
        // _cartCubit.clearCart(); // Effacer le panier si nécessaire
        emit(TableSessionEnded(closingData: orderData)); //
        _resetSessionDetails();
      }
    });

    // NOUVEAU: Écouter l'événement de fin de session initié explicitement par le serveur/kiosk
    _sessionEndedByServerSub = _socketService.onSessionEndedByServer.listen((sessionEndData) {
      print("TableSessionCubit: Event 'onSessionEndedByServer' received: $sessionEndData");
      // Vérifier si la session active correspond ou si l'ID de session correspond même si l'état n'est plus TableSessionActive
      // (par exemple, si une erreur de connexion a mis l'état en TableSessionError juste avant)
      if (sessionEndData['sessionId'] == _activeSessionId && _activeSessionId != null) {
        if (!(state is TableSessionEnded)) { // Pour éviter d'émettre plusieurs fois si déjà terminé
             _cartCubit.clearCart(); // Effacer le panier localement car la session est terminée
            emit(TableSessionEnded(closingData: sessionEndData)); // Utiliser les données reçues
            _resetSessionDetails();
            // Le SnackBar devrait maintenant s'afficher car l'état TableSessionEnded est émis.
        }
      }
    });


    _socketErrorSub = _socketService.onError.listen((errorData) { //
        print("TableSessionCubit: Received socket error from service: $errorData");
        if (state is TableSessionActive) {
            emit(TableSessionError("Socket error during active session: ${errorData.toString()}")); //
            // Vous pourriez envisager de réinitialiser la session ici si l'erreur est critique
            // _resetSessionDetails();
            // emit(TableSessionInitial());
        }
    });

    _socketConnectionSub = _socketService.onConnected.listen((isConnected) { //
        print("TableSessionCubit: Socket connection status: $isConnected");
        if (!isConnected && state is TableSessionActive) {
            emit(TableSessionError("Lost connection during active table session. Please check your internet.")); //
            // Optionnel: réinitialiser ou inviter l'utilisateur à agir.
            // Pour une fin de session plus "propre" en cas de déconnexion :
            // _resetSessionDetails();
            // emit(TableSessionInitial()); // ou TableSessionEnded()
        }
    });
  }

  void _resetSessionDetails() {
    _activeSessionId = null;
    _activeKioskDeviceId = null;
  }

  void userManuallyLeftSession() { //
    if (_activeSessionId != null && _socketService.isConnected) {
      print("TableSessionCubit: User manually left session $_activeSessionId.");
    }
    _cartCubit.clearCart(); //
    _resetSessionDetails();
    emit(TableSessionInitial()); //
  }

  @override
  Future<void> close() {
    print("TableSessionCubit: Disposing and cancelling subscriptions.");
    _sessionJoinedSub?.cancel();
    _cartUpdateSub?.cancel(); // Non utilisé dans le code fourni pour onTableSessionCartUpdated
    _orderFinalizedSub?.cancel();
    _socketErrorSub?.cancel();
    _socketConnectionSub?.cancel();
    _sessionEndedByServerSub?.cancel(); // NOUVEAU: Annuler la nouvelle subscription
    return super.close();
  }
}
