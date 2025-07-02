import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hungerz/models/order_details_model.dart';
import 'package:hungerz/repositories/order_repository.dart'; // Importer Repo
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart'; // Pour lire AuthState/Token
import 'package:hungerz/models/cart_item_model.dart';
import 'package:hungerz/models/address_model.dart';
import 'package:hungerz/common/enums.dart';
part 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderRepository orderRepository;
  final AuthCubit authCubit; // Pour obtenir le token

  OrderCubit({required this.orderRepository, required this.authCubit})
      : super(OrderInitial());

  Future<void> placeOrder({
    required List<CartItem> items,
    required AddressModel? deliveryAddress,
    required DeliveryMethod deliveryMethod,
    required PaymentMethod paymentMethod,
    String? deliveryInstructions,
  }) async {
    // 1. Vérifier l'authentification et obtenir le token
    final currentAuthState = authCubit.state;
    if (currentAuthState is! Authenticated) {
      emit(OrderPlacementFailure("Utilisateur non authentifié."));
      return;
    }
    final token = currentAuthState.token;
    final userId =
        currentAuthState.user.id; // Assurez-vous que userId est dans AuthState
    // 2. Émettre l'état de chargement
    emit(OrderPlacementInProgress());

    // 3. Appeler le Repository
    try {
      final orderDetails = await orderRepository.createOrder(
        token: token,
        userId: userId!, // Assurez-vous que userId est dans AuthState
        items: items,
        deliveryAddress: deliveryAddress,
        deliveryMethod: deliveryMethod,
        paymentMethod: paymentMethod,
        deliveryInstructions: deliveryInstructions,
      );
      // 4. Émettre l'état de succès avec les détails reçus
      emit(OrderPlacementSuccessNavigateToOrders(orderDetails));
    } catch (e) {
      // 5. Émettre l'état d'échec
      emit(OrderPlacementFailure(e.toString()));
    }
  }

  Future<void> fetchOrderHistory() async {
    final currentAuthState = authCubit.state;
    if (currentAuthState is! Authenticated) {
      emit(OrderHistoryError(
          "Utilisateur non authentifié pour récupérer l'historique."));
      return;
    }
    final token = currentAuthState.token;
    // Assurez-vous que votre modèle User dans AuthState a un 'id'
    final userId = currentAuthState.user.id;
    if (userId == null) {
      emit(OrderHistoryError(
          "ID utilisateur non trouvé pour récupérer l'historique."));
      return;
    }

    // Émettre l'état de chargement uniquement si on n'est pas déjà en train de charger
    // ou si on n'a pas déjà des données (pour éviter le clignotement du loader sur un refresh)
    // Toutefois, pour un premier chargement ou un refresh explicite, on veut le loader.
    // On peut affiner cela dans le BlocBuilder de l'UI.
    // Pour l'instant, on émet toujours Loading.
    emit(OrderHistoryLoading());

    try {
      final orders =
          await orderRepository.getOrderHistory(token: token, userId: userId);
     
      emit(OrderHistoryLoaded(orders));
    } catch (e) {
      emit(OrderHistoryError(e.toString().replaceFirst("Exception: ", "")));
    }
  }
}
