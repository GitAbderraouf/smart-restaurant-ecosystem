// lib/HomeOrderAccount/Order/UI/order_page.dart

// lib/HomeOrderAccount/Order/UI/order_page.dart

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Pages/order_detail_page.dart';
import 'package:hungerz/Pages/reservation_detail_page.dart'; // Pour la navigation des réservations
// --- AJOUTS POUR LES COMMANDES ---
import 'package:hungerz/cubits/order_cubit/order_cubit.dart';
import 'package:hungerz/models/order_details_model.dart'; // Utilisé dans OrderDetailsModel
import 'package:hungerz/cubits/unpaid_bill_cubit/unpaid_bill_cubit.dart'; // NOUVEL IMPORT
import 'package:hungerz/models/unpaid_bill_model.dart'; // NOUVEL IMPORT
import 'package:hungerz/Pages/unpaid_bill_detail_page.dart'; // NOUVELLE PAGE DE DÉTAIL FACTURE
// -----------------------------------------
// TODO: Créez et importez OrderDetailsPage pour la navigation des commandes (déjà fait dans le code original)
// import 'package:hungerz/Pages/order_details_page.dart';
// ----------------------------------
import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/cubits/reservation_cubit/reservation_cubit.dart';
import 'package:hungerz/models/reservation_model.dart';
import 'package:intl/intl.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  @override
  void initState() {
    super.initState();
    // Charger l'historique des réservations
    print(
        "OrderPage (Réservations Tab): initState - Appel de fetchMyReservations.");
    context.read<ReservationCubit>().fetchMyReservations();

    // Charger l'historique des commandes
    print("OrderPage (Commandes Tab): initState - Appel de fetchOrderHistory.");
    context.read<OrderCubit>().fetchOrderHistory();

    // Charger les factures impayées
    print("OrderPage (À Payer Tab): initState - Appel de fetchMyUnpaidBills.");
    context.read<UnpaidBillCubit>().fetchMyUnpaidBills();
  }

  // --- Méthodes de rafraîchissement ---
  Future<void> _refreshReservations() async {
    print(
        "OrderPage (Réservations Tab): Pull-to-refresh - Appel de fetchMyReservations.");
    await context.read<ReservationCubit>().fetchMyReservations();
  }

  Future<void> _refreshOrders() async {
    print(
        "OrderPage (Commandes Tab): Pull-to-refresh - Appel de fetchOrderHistory.");
    await context.read<OrderCubit>().fetchOrderHistory();
  }

  Future<void> _refreshUnpaidBills() async {
    print(
        "OrderPage (À Payer Tab): Pull-to-refresh - Appel de fetchMyUnpaidBills.");
    await context.read<UnpaidBillCubit>().fetchMyUnpaidBills();
  }

  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          flexibleSpace: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                indicatorColor: kMainColor,
                labelColor: kMainColor,
                unselectedLabelColor: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.7) ??
                    Colors.grey,
                indicatorWeight: 3.0,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 15),
                tabs: [
                  Tab(text: locale.orderText!), // "COMMANDES"
                  Tab(text: locale.tabletext!), // "RÉSERVATIONS"
                  Tab(text: "À PAYER"), // "À PAYER" - Localiser si possible
                ],
              ),
            ],
          ),
          automaticallyImplyLeading: false,
        ),
        body: TabBarView(
          children: [
            _buildOrdersHistoryTab(context, locale),
            _buildReservationsHistoryTab(context, locale),
            _buildUnpaidBillsTab(context, locale),
          ],
        ),
      ),
    );
  }

  // --- Onglet 1: Historique des COMMANDES ---
  Widget _buildOrdersHistoryTab(BuildContext context, AppLocalizations locale) {
    return BlocBuilder<OrderCubit, OrderState>(
      builder: (context, state) {
        List<OrderDetailsModel> currentOrders = [];
        bool showFullScreenLoader = false;
        String? fullScreenError;

        if (state is OrderInitial) {
          showFullScreenLoader = true;
        } else if (state is OrderHistoryLoading) {
          // If props are empty or not a non-empty list of orders, show full loader
          if (state.props.isEmpty ||
              !(state.props.first is List) ||
              (state.props.first as List).isEmpty) {
            showFullScreenLoader = true;
          } else {
            // Loading, but has existing data from props
            currentOrders = (state.props.first as List)
                .whereType<OrderDetailsModel>()
                .toList();
          }
        } else if (state is OrderHistoryError) {
          if (state.props.isEmpty ||
              !(state.props.first is List) ||
              (state.props.first as List).isEmpty) {
            fullScreenError = state.message;
          } else {
            // Error, but has existing data from props
            currentOrders = (state.props.first as List)
                .whereType<OrderDetailsModel>()
                .toList();
            // Error message will be shown above the list by _buildOrdersList
          }
        } else if (state is OrderHistoryLoaded) {
          currentOrders = state.orders;
        }

        if (showFullScreenLoader) {
          return Center(child: CircularProgressIndicator(color: kMainColor));
        }
        if (fullScreenError != null) {
          return _buildGenericErrorState(
              context,
              fullScreenError,
              _refreshOrders,
              Icons.receipt_long_outlined,
              locale.orderText ?? "Erreur Commandes");
        }

        if (currentOrders.isEmpty && state is OrderHistoryLoaded) {
          return _buildGenericEmptyState(
              context,
              "Aucune commande pour le moment.", // Utiliser locale si disponible
              _refreshOrders,
              Icons.receipt_long_outlined);
        }

        return RefreshIndicator(
          onRefresh: _refreshOrders,
          color: kMainColor,
          backgroundColor: Colors.white,
          child: _buildOrdersList(context, locale, currentOrders, state),
        );
      },
    );
  }

  Widget _buildOrdersList(BuildContext context, AppLocalizations locale,
      List<OrderDetailsModel> orders, OrderState currentState) {
    List<OrderDetailsModel> ongoingOrders = orders
        .where((o) => [
              "pending",
              "confirmed",
              "preparing",
              "out_for_delivery","accepted"
            ].contains(o.status.toLowerCase()))
        .toList();
    List<OrderDetailsModel> pastOrders = orders
        .where((o) =>
            ["delivered", "cancelled","ready_for_pickup"].contains(o.status.toLowerCase()))
        .toList();

    ongoingOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    pastOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (orders.isEmpty &&
        currentState is OrderHistoryLoaded) { // Already handled by _buildOrdersHistoryTab, but as a fallback
      return _buildGenericEmptyState(
          context,
          "Aucune commande pour le moment.",
          _refreshOrders,
          Icons.receipt_long_outlined);
    }
     if (orders.isEmpty && currentState is! OrderHistoryLoading && currentState is! OrderHistoryLoaded) {
        // If list is empty and it's an error state (that wasn't caught as fullScreenError) or other unexpected state
        // This shouldn't typically be hit if _buildOrdersHistoryTab logic is correct
        return _buildGenericEmptyState(
            context,
            "Aucune commande à afficher.",
            _refreshOrders,
            Icons.receipt_long_outlined);
    }


    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      children: [
        if (currentState is OrderHistoryLoading && orders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
                child: CircularProgressIndicator(
                    color: kMainColor, strokeWidth: 2.5)),
          ),
        if (currentState is OrderHistoryError && orders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
                child: Text(
                    "${"Erreur de rafraîchissement"}: ${currentState.message}", // Utiliser locale
                    style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w500))),
          ),
        if (ongoingOrders.isNotEmpty) ...[
          _buildSectionTitle(context, "Commandes en cours"), // Utiliser locale
          ...ongoingOrders
              .map((order) => _buildOrderCard(context, locale, order, true))
              .toList(),
          SizedBox(height: 20),
        ],
        if (pastOrders.isNotEmpty) ...[
          _buildSectionTitle(context, "Commandes passées"), // Utiliser locale
          ...pastOrders
              .map((order) => _buildOrderCard(context, locale, order, false))
              .toList(),
        ],
         // If, after filtering, both lists are empty but the original 'orders' might not have been,
         // (e.g. orders contained statuses not in ongoing/past)
         // or if orders itself was empty and it's not a loading state.
        if (ongoingOrders.isEmpty && pastOrders.isEmpty && orders.isNotEmpty && currentState is OrderHistoryLoaded)
           Center(child: Padding(
             padding: const EdgeInsets.all(16.0),
             child: Text("Aucune commande active ou passée trouvée.", style: TextStyle(color: Colors.grey[600])),
           )),
        if (orders.isEmpty && currentState is! OrderHistoryLoading && currentState is! OrderHistoryError) // Final check if everything is empty
           _buildGenericEmptyState(
            context,
            "Aucune commande pour le moment.",
            _refreshOrders,
            Icons.receipt_long_outlined),
      ],
    );
  }

  Widget _buildOrderCard(BuildContext context, AppLocalizations locale,
      OrderDetailsModel order, bool isOngoing) {
    String? firstItemImage;
    if (order.items.isNotEmpty) {
      firstItemImage = order.items[0].image;
    }

    return Card(
      color: Colors.white,
      elevation: isOngoing ? 3.5 : 2.0,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.grey.withOpacity(isOngoing ? 0.4 : 0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final result = await Navigator.push( // Capture result
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsPage(order: order),
            ),
          );
          // Check if result indicates refresh needed
            print(
                "Retour de OrderDetailsPage, rafraîchissement de l'historique des commandes.");
            _refreshOrders();
          
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: FadedScaleAnimation(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: firstItemImage != null &&
                                firstItemImage.isNotEmpty
                            ? Image.network(
                                firstItemImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                        width: 70,
                                        height: 70,
                                        color: Colors.grey[200],
                                        child: Icon(Icons.fastfood_outlined,
                                            color: Colors.grey[400], size: 30)),
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey[200],
                                child: Icon(Icons.receipt_long_outlined,
                                    color: Colors.grey[400], size: 30)),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Commande #${order.id.substring(0, 6)}... (${order.orderType})",
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(
                                  fontWeight: FontWeight.bold, fontSize: 16.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('d MMM yy, HH:mm', // Shorter year
                                  locale.locale.languageCode)
                              .format(order.createdAt.toLocal()),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(color: Colors.grey[600], fontSize: 13),
                        ),
                        SizedBox(height: 6),
                        Text(
                          "${order.total.toStringAsFixed(2)} ${'DA'}",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium!
                              .copyWith(
                                  fontWeight: FontWeight.w700, // Bolder total
                                  color: kMainColor,
                                  fontSize: 15.5),
                        )
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      _getOrderStatusText(context, order.status),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5, // Slightly larger chip text
                          fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: _getOrderStatusColor(context, order.status),
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4), // Adjusted padding
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  )
                ],
              ),
              if (order.items.isNotEmpty) ...[
                Divider(height: 28, thickness: 0.9, color: Colors.grey[200]), // Slightly thicker divider
                Text(
                  "${'Articles'}: ${order.items.length}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600, color: Colors.black87), // Darker text
                ),
                SizedBox(height: 6),
                ...order.items.take(2).map((item) => Padding(
                      padding: const EdgeInsets.only(
                          left: 8.0, top: 2.0, bottom: 2.0), // Increased top/bottom padding
                      child: Text(
                        "• ${item.quantity}x ${item.name}",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall!
                            .copyWith(fontSize: 13.5, color: Colors.grey[800]), // Darker item text
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                if (order.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 3.0), // Increased top padding
                    child: Text(
                      "et ${order.items.length - 2} autre(s)...",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: 12.5, // Slightly larger
                          color: Colors.grey[700], // Darker
                          fontStyle: FontStyle.italic),
                    ),
                  ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // --- Onglet 2: Historique des RÉSERVATIONS ---
  Widget _buildReservationsHistoryTab(
      BuildContext context, AppLocalizations locale) {
    return BlocBuilder<ReservationCubit, ReservationState>(
      builder: (context, state) {
        if (state is ReservationInitial ||
            (state is ReservationHistoryLoading &&
                (state.props.isEmpty || !(state.props.first is List) || (state.props.first as List).isEmpty))) {
          return Center(child: CircularProgressIndicator(color: kMainColor));
        } else if (state is ReservationHistoryError &&
            (state.props.isEmpty || !(state.props.first is List) || (state.props.first as List).isEmpty)) {
          return _buildGenericErrorState(
              context,
              state.message,
              _refreshReservations,
              Icons.event_busy_outlined,
              locale.tabletext ?? "Erreur Réservations");
        } else if (state is ReservationHistoryLoaded) {
          if (state.reservations.isEmpty) {
            return _buildGenericEmptyState(
                context,
                "Aucune réservation pour le moment.", // Utiliser locale
                _refreshReservations,
                Icons.event_note_outlined); // Changed icon
          }
          return RefreshIndicator(
            onRefresh: _refreshReservations,
            color: kMainColor,
            backgroundColor: Colors.white,
            child: _buildReservationsList(
                context, locale, state.reservations, state),
          );
        } else if ((state is ReservationHistoryLoading || state is ReservationHistoryError) &&
                   state.props.isNotEmpty && state.props.first is List && (state.props.first as List).isNotEmpty) {
          // Handle loading/error with existing data
          List<ReservationModel> currentReservations = (state.props.first as List)
              .whereType<ReservationModel>()
              .toList();
          return RefreshIndicator(
            onRefresh: _refreshReservations,
            color: kMainColor,
            backgroundColor: Colors.white,
            child: _buildReservationsList(
                context, locale, currentReservations, state),
          );
        }
        return Center(
            child: Text("État de réservation inattendu.",
                style: TextStyle(color: Colors.orange.shade700))); // More expressive color
      },
    );
  }

  Widget _buildReservationsList(BuildContext context, AppLocalizations locale,
      List<ReservationModel> reservations, ReservationState currentState) {
    final now = DateTime.now();
    List<ReservationModel> upcomingReservations = [];
    List<ReservationModel> pastReservations = [];

    for (var reservation in reservations) {
      bool isConsideredPast =
          reservation.reservationTime.add(Duration(hours: 2)).isBefore(now);
      bool isStatusPast = ['completed', 'cancelled', 'no-show']
          .contains(reservation.status.toLowerCase());

      if (isConsideredPast || isStatusPast) {
        pastReservations.add(reservation);
      } else {
        upcomingReservations.add(reservation);
      }
    }

    upcomingReservations
        .sort((a, b) => a.reservationTime.compareTo(b.reservationTime));
    pastReservations
        .sort((a, b) => b.reservationTime.compareTo(a.reservationTime));

    if (reservations.isEmpty && currentState is ReservationHistoryLoaded) {
        return _buildGenericEmptyState(
            context,
            "Aucune réservation pour le moment.",
            _refreshReservations,
            Icons.event_note_outlined);
    }
     if (reservations.isEmpty && currentState is! ReservationHistoryLoading && currentState is! ReservationHistoryLoaded) {
        return _buildGenericEmptyState(
            context,
            "Aucune réservation à afficher.",
            _refreshReservations,
            Icons.event_note_outlined);
    }


    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
      physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      children: [
        if (currentState is ReservationHistoryLoading &&
            reservations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
                child: CircularProgressIndicator(
                    color: kMainColor, strokeWidth: 2.5)),
          ),
        if (currentState is ReservationHistoryError && reservations.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
                child: Text(
                    "${"Erreur de rafraîchissement"}: ${currentState.message}",
                    style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.w500))),
          ),
        if (upcomingReservations.isNotEmpty) ...[
          _buildSectionTitle(
              context, "Réservations à venir/en cours"), // Utiliser locale
          ...upcomingReservations
              .map((res) => _buildReservationCard(context, res, locale, true))
              .toList(),
          SizedBox(height: 20),
        ],
        if (pastReservations.isNotEmpty) ...[
          _buildSectionTitle(context, "Réservations passées"), // Utiliser locale
          ...pastReservations
              .map((res) => _buildReservationCard(context, res, locale, false))
              .toList(),
        ],
        if (reservations.isEmpty && currentState is! ReservationHistoryLoading && currentState is! ReservationHistoryError)
          _buildGenericEmptyState(
              context,
              "Aucune réservation pour le moment.",
              _refreshReservations,
              Icons.event_note_outlined),
      ],
    );
  }

  Widget _buildReservationCard(BuildContext context,
      ReservationModel reservation, AppLocalizations locale, bool isUpcoming) {
    Color cardColor = isUpcoming ? Colors.white : Color(0xFFF8F9FA); // Slightly off-white for past
    double elevation = isUpcoming ? 3.5 : 1.5;

    return Card(
      elevation: elevation,
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      shadowColor: Colors.grey.withOpacity(isUpcoming ? 0.4 : 0.25),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      ReservationDetailPage(reservation: reservation)));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text(
                           "Restaurant Réservation", // Utiliser le nom du restaurant
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isUpcoming
                                      ? (Theme.of(context).brightness == Brightness.dark ? kMainColor : Colors.black87) // Use kMainColor for upcoming if theme appropriate
                                      : Colors.black54,
                                  fontSize: 17),
                          overflow: TextOverflow.ellipsis)),
                  Chip(
                    label: Text(
                        _getReservationStatusText(context, reservation.status),
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                    backgroundColor:
                        _getReservationStatusColor(context, reservation.status, isUpcoming),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ],
              ),
              SizedBox(height: 12),
              _buildDetailRow(
                  context,
                  Icons.calendar_today_outlined,
                  DateFormat('EEE, d MMM yy', // Shorter year
                          locale.locale.languageCode)
                      .format(reservation.reservationTime.toLocal())),
              SizedBox(height: 6), // Increased spacing
              _buildDetailRow(
                  context,
                  Icons.access_time_outlined,
                  DateFormat('HH:mm', locale.locale.languageCode)
                      .format(reservation.reservationTime.toLocal())),
              SizedBox(height: 6), // Increased spacing
              _buildDetailRow(context, Icons.people_alt_outlined,
                  "${reservation.guests} ${reservation.guests > 1 ? ('personnes') : ('personne')}"), // Utiliser locale
              if (reservation.preselectedItems != null &&
                  reservation.preselectedItems!.isNotEmpty) ...[
                SizedBox(height: 12), // Increased spacing
                _buildExpansionDetail(
                  context: context,
                  title: "Pré-commande", // Utiliser locale
                  icon: Icons.shopping_bag_outlined,
                  children: reservation.preselectedItems!
                      .map((item) => Padding(
                            padding: const EdgeInsets.only(
                                left: 16.0, top: 3.0, bottom: 3.0), // Adjusted padding
                            child: Text(
                                "• ${item['quantity']}x ${item['menuItemNameFromData'] ?? item['name'] ?? ('Article inconnu')}", // Utiliser locale
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey[800], fontSize: 14)), // Darker text
                          ))
                      .toList(),
                ),
              ],
              if (reservation.specialRequests != null &&
                  reservation.specialRequests!.isNotEmpty) ...[
                SizedBox(height: 10),
                _buildExpansionDetail(
                    context: context,
                    title: "Demandes spéciales", // Utiliser locale
                    icon: Icons.notes_outlined,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 16.0, top: 3.0, bottom: 3.0), // Adjusted padding
                        child: Text(reservation.specialRequests!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.grey[800], fontSize: 14)), // Darker text
                      )
                    ]),
              ]
            ],
          ),
        ),
      ),
    );
  }

  // --- Onglet 3: Factures impayées ---
Widget _buildUnpaidBillsTab(BuildContext context, AppLocalizations locale) {
  return BlocConsumer<UnpaidBillCubit, UnpaidBillState>(
    listener: (context, state) {
      if (state is BillPaymentSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Paiement de la facture #${state.billId.substring(0, 6)} réussi !"), // Utiliser locale
              backgroundColor: Colors.green.shade700),
        );
        _refreshUnpaidBills(); // Rafraîchit la liste des factures impayées
        _refreshOrders(); // Rafraîchit aussi les commandes (au cas où)
      } else if (state is BillPaymentFailure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Échec du paiement pour la facture #${state.billId.substring(0, 6)}: ${state.message}"), // Utiliser locale
              backgroundColor: Colors.red.shade700),
        );
      }
    },
    buildWhen: (previous, current) {
      // Ne reconstruire la vue de la liste que pour les états affectant la liste entière.
      // Les états spécifiques au paiement d'un élément (BillPaymentProcessing, etc.)
      // ne devraient pas provoquer une reconstruction complète de la liste ici,
      // car ils sont gérés par le listener ou la carte elle-même.
      if (current is BillPaymentProcessing ||
          current is BillPaymentSuccess ||
          current is BillPaymentFailure) {
        // Si la liste elle-même doit changer (par exemple, un élément est retiré après paiement),
        // le rafraîchissement déclenché par le listener (`_refreshUnpaidBills()`)
        // émettra des états comme `UnpaidBillListLoading` puis `UnpaidBillListLoaded`,
        // qui SONT gérés par le builder.
        return false;
      }
      // Reconstruire pour les états initiaux, de chargement de liste, de liste chargée, ou d'erreur de liste.
      return true;
    },
    builder: (context, state) {
      // Le code du builder existant ici.
      // Grâce au `buildWhen` ci-dessus, ce builder ne recevra plus
      // les états BillPaymentProcessing, BillPaymentSuccess, BillPaymentFailure,
      // évitant ainsi le message "État inattendu".

      if (state is UnpaidBillInitial ||
          (state is UnpaidBillListLoading &&
              (state.props.isEmpty ||
                  !(state.props.first is List) ||
                  (state.props.first as List).isEmpty))) {
        return Center(child: CircularProgressIndicator(color: kMainColor));
      } else if (state is UnpaidBillListError &&
          (state.props.isEmpty ||
              !(state.props.first is List) ||
              (state.props.first as List).isEmpty)) {
        return _buildGenericErrorState(
            context,
            state.message,
            _refreshUnpaidBills,
            Icons.receipt_long_outlined,
            "Erreur Factures à Payer"); // Utiliser locale
      } else if (state is UnpaidBillListLoaded) {
        if (state.unpaidBills.isEmpty) {
          return _buildGenericEmptyState(
              context,
              "Aucune facture à payer.", // Utiliser locale
              _refreshUnpaidBills,
              Icons.price_check_sharp);
        }
        return RefreshIndicator(
          onRefresh: _refreshUnpaidBills,
          color: kMainColor,
          backgroundColor: Colors.white,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            itemCount: state.unpaidBills.length,
            itemBuilder: (context, index) {
              final bill = state.unpaidBills[index];
              return _buildUnpaidBillCard(context, locale, bill);
            },
          ),
        );
      } else if ((state is UnpaidBillListLoading ||
              state is UnpaidBillListError) &&
          state.props.isNotEmpty &&
          state.props.first is List &&
          (state.props.first as List).isNotEmpty) {
        List<UnpaidBillModel> currentBills = (state.props.first as List)
            .whereType<UnpaidBillModel>()
            .toList();
        return RefreshIndicator(
          onRefresh: _refreshUnpaidBills,
          color: kMainColor,
          backgroundColor: Colors.white,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
            itemCount: currentBills.length,
            itemBuilder: (context, index) {
              final bill = currentBills[index];
              // Optionnellement, afficher un indicateur de chargement/erreur en haut de la liste
              // si c'est un chargement/erreur affectant la liste pendant qu'elle a des données existantes.
              if (index == 0 && state is UnpaidBillListLoading) {
                return Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kMainColor))),
                  _buildUnpaidBillCard(context, locale, bill)
                ]);
              }
              if (index == 0 && state is UnpaidBillListError) {
                return Column(children: [
                  Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                          child: Text(
                              "Erreur rafraîchissement: ${state.message}",
                              style:
                                  TextStyle(color: Colors.red.shade700)))),
                  _buildUnpaidBillCard(context, locale, bill)
                ]);
              }
              return _buildUnpaidBillCard(context, locale, bill);
            },
          ),
        );
      }
      // Ce fallback devrait être atteint beaucoup moins fréquemment maintenant.
      // Il est conservé pour les cas véritablement non gérés.
      print("OrderPage Unpaid Bills Tab: État non géré dans le builder principal: ${state.runtimeType}");
      return Center(
          child: Text("État de la liste des factures non géré: ${state.runtimeType}", // Message plus descriptif pour le débogage
              style: TextStyle(color: Colors.orange.shade700)));
    },
  );
}

  Widget _buildUnpaidBillCard(
      BuildContext context, AppLocalizations locale, UnpaidBillModel bill) {
    final sessionDetails = bill.tableSessionDetails;
    return Card(
      color: Colors.white,
      elevation: 3.0, // Slightly more elevation
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      shadowColor: Colors.black.withOpacity(0.15), // Softer shadow
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UnpaidBillDetailPage(bill: bill),
            ),
          ).then((paymentSuccessful) {
            if (paymentSuccessful == true && mounted) {
              _refreshUnpaidBills();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      // Utiliser locale
                      "Facture Table: ${sessionDetails.tableDisplayName}",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, fontSize: 16.5),
                    ),
                  ),
                  Chip(
                    label: Text(
                      "À PAYER", // Utiliser locale
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600),
                    ),
                    backgroundColor: Colors.red.shade600, // More urgent color
                    padding: EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                // Utiliser locale
                "Session du: ${DateFormat('d MMM yy, HH:mm', locale.locale.languageCode).format(sessionDetails.startTime.toLocal())}",
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[700], fontSize: 13),
              ),
              SizedBox(height: 10), // Increased spacing
              Text(
                "Total: ${bill.total.toStringAsFixed(2)} DA",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: kMainColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (sessionDetails.items.isNotEmpty) ...[
                Divider(height: 26, thickness: 0.9, color: Colors.grey[200]),
                Text(
                  "Articles (Résumé):", // Utiliser locale
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600, color: Colors.black87, fontSize: 13.5),
                ),
                SizedBox(height: 5),
                ...sessionDetails.items.take(2).map((item) => Padding(
                      padding:
                          const EdgeInsets.only(top: 2.5, left: 4.0, bottom: 1.5),
                      child: Text(
                        "• ${item.quantity}x ${item.name}",
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 13.5, color: Colors.grey[800]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                if (sessionDetails.items.length > 2)
                  Padding(
                    padding: const EdgeInsets.only(top: 2.5, left: 4.0),
                    child: Text(
                        "et ${sessionDetails.items.length - 2} autre(s)...", // Utiliser locale
                        style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey[700],
                            fontStyle: FontStyle.italic)),
                  ),
              ],
              SizedBox(height: 18), // Increased spacing
              BlocBuilder<UnpaidBillCubit, UnpaidBillState>(
                // Ensure this BlocBuilder only rebuilds this specific part if needed
                // by using buildWhen if states are too frequent.
                buildWhen: (previous, current) {
                   if (current is BillPaymentProcessing && current.billId == bill.id) return true;
                   if (previous is BillPaymentProcessing && previous.billId == bill.id && (current is! BillPaymentProcessing || current.billId != bill.id)) return true; // Rebuild when processing for this bill stops
                   if (current is BillPaymentSuccess && current.billId == bill.id) return true; // Potentially hide button or show success
                   if (current is BillPaymentFailure && current.billId == bill.id) return true; // Re-enable button
                   return false; // Only rebuild for relevant bill and states
                },
                builder: (context, state) {
                  bool isProcessingThisBill =
                      (state is BillPaymentProcessing && state.billId == bill.id);
                  return Align(
                    alignment: Alignment.centerRight,
                    child: isProcessingThisBill
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: SizedBox(
                              width: 24, height: 24, // Define size for CircularProgressIndicator
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.5, color: kMainColor),
                            ),
                          )
                        : ElevatedButton.icon(
                            icon: Icon(Icons.payment, size: 18, color: Colors.white),
                            label: Text("Payer Maintenant", // Utiliser locale
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            onPressed: () {
                              // Consider showing a confirmation dialog here
                              context.read<UnpaidBillCubit>().payBill(bill);
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600, // Positive action color
                                padding: EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 12), // Adjusted padding
                                textStyle: TextStyle(fontSize: 14.5)), // Adjusted font size
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Widgets génériques et helpers ---
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding:
          const EdgeInsets.only(left: 4.0, right: 4.0, top: 8.0, bottom: 12.0),
      child: Text(title, // Utiliser locale si possible
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black.withOpacity(0.8), // Slightly softer black
              fontSize: 18.5)), // Slightly larger
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5), // Adjusted padding
      child: Row(children: [
        Icon(icon, size: 19, color: Colors.grey[700]), // Slightly larger icon
        SizedBox(width: 12),
        Expanded(
            child: Text(text,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontSize: 14.5, color: Colors.black.withOpacity(0.85)))), // Slightly softer black
      ]),
    );
  }

  Widget _buildExpansionDetail(
      {required BuildContext context,
      required String title,
      required IconData icon,
      required List<Widget> children}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: Icon(icon, size: 21, color: Colors.grey[600]), // Slightly larger icon
        title: Text(title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.75), // Softer black
                fontSize: 15)), // Adjusted font size
        childrenPadding: EdgeInsets.only(left: 16, bottom: 8, top: 4), // Added top padding
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        iconColor: kMainColor,
        collapsedIconColor: Colors.grey[600],
        children: children,
      ),
    );
  }

  Widget _buildGenericEmptyState(BuildContext context, String message,
      Future<void> Function() onRefresh, IconData icon) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0), // Increased padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 65, color: Colors.grey[400]), // Larger icon
                  SizedBox(height: 20), // Increased spacing
                  Text(message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey[600], fontSize: 16.5)), // Larger text
                  SizedBox(height: 24), // Increased spacing
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text("Rafraîchir", // Utiliser locale
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    onPressed: onRefresh,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Increased padding
                        textStyle: TextStyle(fontSize: 16.5)), // Larger text
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildGenericErrorState(
      BuildContext context,
      String errorMessage,
      Future<void> Function() onRefresh,
      IconData icon,
      String title) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0), // Increased padding
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 65, color: Colors.red.shade300), // Larger icon
                  SizedBox(height: 20), // Increased spacing
                  Text(title.isNotEmpty ? title : "Oops! Une erreur est survenue.", // Utiliser locale
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge // Bolder title
                          ?.copyWith(color: Colors.red.shade700, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12), // Increased spacing
                  Text(errorMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red.shade500, fontSize: 15)), // Slightly larger
                  SizedBox(height: 24), // Increased spacing
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    label: Text("Réessayer", // Utiliser locale
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    onPressed: onRefresh,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: kMainColor,
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Increased padding
                        textStyle: TextStyle(fontSize: 16.5)), // Larger text
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // --- Helpers de statut (Couleurs et Textes) ---
  Color _getOrderStatusColor(BuildContext context, String status) {
    status = status.toLowerCase();
    // Define light theme expressive colors
    Color pendingColor = Colors.orange.shade700; // Strong Orange
    Color confirmedColor = Colors.blue.shade600; // Vivid Blue
    Color preparingColor = Colors.purple.shade500; // Rich Purple
    Color outForDeliveryColor = Colors.teal.shade500;// Bright Teal
    Color deliveredColor = Colors.green.shade700; // Deep Green
    Color cancelledColor = Colors.red.shade600; // Strong Red
    Color defaultColor = Colors.grey.shade600;   // Medium Grey

    // Example: Adjust for dark theme if needed
    // if (Theme.of(context).brightness == Brightness.dark) {
    //   pendingColor = Colors.orange.shade400;
    //   // ... adjust other colors for dark theme ...
    // }

    switch (status) {
      case 'pending':
        return pendingColor;
      case 'confirmed':
        return confirmedColor;
      case 'preparing':
        return preparingColor;
      case 'out_for_delivery':
        return outForDeliveryColor;
        case 'accepted':
        return outForDeliveryColor;
      case 'delivered':
        return deliveredColor;
      case 'ready_for_pickup':
        return deliveredColor; // Assuming 'ready_for_pickup' is similar to 'preparing'
      case 'cancelled':
        return cancelledColor;
      default:
        return defaultColor;
    }
  }

  String _getOrderStatusText(BuildContext context, String status) {
    var locale = AppLocalizations.of(context)!;
    status = status.toLowerCase();
    switch (status) {
      case 'pending':
        return  'En attente'; // Assurez-vous que 'pending' existe dans vos locales
      case 'confirmed':
        return  'Confirmée'; // Assurez-vous que 'confirmed' existe
      case 'preparing':
        return  'En préparation'; // Assurez-vous que 'preparing' existe
      case 'out_for_delivery':
        return  'En livraison';
      case 'accepted':
        return  'En livraison';   // Assurez-vous que 'outForDelivery' existe
      case 'delivered':
        return locale.delivered ?? 'Livrée';
      case 'ready_for_pickup':
        return  'Prête pour le retrait'; // Assurez-vous que 'readyForPickup' existe  
      case 'cancelled':
        return  'Annulée'; // Assurez-vous que 'cancelled' existe
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }

  Color _getReservationStatusColor(
      BuildContext context, String status, bool isUpcoming) {
    status = status.toLowerCase();
    // Define expressive colors
    Color upcomingConfirmedColor = kMainColor.withOpacity(0.9); // Primary color for emphasis
    Color pastConfirmedColor = Colors.green.shade600;       // Consistent with delivered
    Color pendingColor = Colors.orange.shade600;            // Alerting orange
    Color completedColor = Colors.blueGrey.shade500;        // Subdued, finished
    Color cancelledColor = Colors.red.shade500;             // Clear cancellation
    Color noShowColor = Colors.brown.shade400;              // Distinct for no-show
    Color defaultColor = Colors.grey.shade500;              // Neutral

    // Example: Adjust for dark theme if needed
    // if (Theme.of(context).brightness == Brightness.dark) {
    //    upcomingConfirmedColor = kMainColor; // Or a brighter variant
    //    // ... adjust other colors ...
    // }

    if (isUpcoming && status == 'confirmed') {
      return upcomingConfirmedColor;
    }
    switch (status) {
      case 'confirmed': // This will now mostly apply to past confirmed
        return pastConfirmedColor;
      case 'pending':
        return pendingColor;
      case 'completed':
        return completedColor;
      case 'cancelled':
        return cancelledColor;
      case 'no-show':
        return noShowColor;
      default:
        return defaultColor;
    }
  }

  String _getReservationStatusText(BuildContext context, String status) {
     // Assuming you have these in locales
    status = status.toLowerCase();
    switch (status) {
      case 'pending':
        return  'En attente';
      case 'confirmed':
        return  'Confirmée';
      case 'completed':
        return  'Terminée'; // Assurez-vous que 'completed' existe
      case 'cancelled':
        return  'Annulée';
      case 'no-show':
        return  'Non présenté'; // Assurez-vous que 'noShow' existe
      default:
        return status[0].toUpperCase() + status.substring(1);
    }
  }
}