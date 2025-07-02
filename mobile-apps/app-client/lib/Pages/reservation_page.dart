// lib/pages/reservation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/common/enums.dart';
import 'package:intl/intl.dart';

// Importer Cubits et States
import 'package:hungerz/cubits/reservation_cubit/reservation_cubit.dart';
// Importez votre état
import 'package:hungerz/cubits/cart_cubit/cart_cubit.dart';
// Pour TimeSlotAvailabilityModel

// Importer Widgets et Thèmes
import 'package:hungerz/Themes/colors.dart'; // Pour kMainColor
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Components/bottom_bar.dart';
// Pour la navigation après succès

// Helper pour les détails du moyen de paiement (vous l'avez déjà)
Map<String, dynamic> getPaymentMethodDetails(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.wallet:
      return {'name': 'WALLET', 'icon': Icons.account_balance_wallet_outlined};
    case PaymentMethod.cash:
      return {'name': 'CASH', 'icon': Icons.money_outlined};
    case PaymentMethod.card:
      return {
        'name': 'CARTE',
        'icon': Icons.credit_card
      }; // J'ai changé CIB par CARTE pour correspondre à l'enum
  }
}

class ReservationPage extends StatefulWidget {
  const ReservationPage({super.key});

  @override
  _ReservationPageState createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  DateTime _selectedDate = DateTime.now();
  int _selectedGuests = 2;
  String? _selectedTimeSlot;
  PaymentMethod _selectedPaymentMethod =
      PaymentMethod.cash; // Valeur par défaut
  bool _isPaymentExpanded = false;
  final List<PaymentMethod> _availablePaymentMethods = [
    PaymentMethod.wallet,
    PaymentMethod.cash,
    PaymentMethod.card,
  ];
  final TextEditingController _specialRequestsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _triggerAvailabilityCheck();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate:
          DateTime.now().subtract(Duration(days: 1)), // Permet aujourd'hui
      lastDate: DateTime.now().add(Duration(days: 60)),
      // TODO: Localiser les boutons
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedTimeSlot = null; // Réinitialiser le créneau
      });
      _triggerAvailabilityCheck();
    }
  }

  void _incrementGuests() {
    if (_selectedGuests < 10) {
      // Limite Max
      setState(() {
        _selectedGuests++;
        _selectedTimeSlot = null;
      });
      _triggerAvailabilityCheck();
    }
  }

  void _decrementGuests() {
    if (_selectedGuests > 1) {
      // Limite Min
      setState(() {
        _selectedGuests--;
        _selectedTimeSlot = null;
      });
      _triggerAvailabilityCheck();
    }
  }

  void _triggerAvailabilityCheck() {
    print(
        "Déclenchement checkAvailability pour Date: $_selectedDate, Personnes: $_selectedGuests");
    context.read<ReservationCubit>().checkAvailability(
          date: _selectedDate,
          guests: _selectedGuests,
        );
  }

  void _submitReservation() {
    final cartState = context.read<CartCubit>().state;

    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Veuillez sélectionner un créneau horaire."),
          backgroundColor: Colors.orange));
      return;
    }

    if (cartState is! CartUpdated || cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Votre panier est vide pour la réservation."),
          backgroundColor: Colors.orange));
      return;
    }

    // Tous les champs nécessaires sont là
    context.read<ReservationCubit>().submitReservation(
          date: _selectedDate,
          timeSlot: _selectedTimeSlot!,
          guests: _selectedGuests,
          items: cartState.items,
          paymentMethod: _selectedPaymentMethod,
          specialRequests: _specialRequestsController.text.trim(),
        );
  }

  @override
  void dispose() {
    _specialRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          title: Text('Réserver une Table',
              style: Theme.of(context).textTheme.bodyLarge),
          leading: IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: () => Navigator.of(context).pop()),
        ),
        body: BlocListener<ReservationCubit, ReservationState>(
          listener: (context, state) {
            if (state is ReservationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "Réservation confirmée !",
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color.fromRGBO(0, 153, 70,
                      1), // Use the theme's green color (make sure _orderGreen is defined in your state)
                  behavior: SnackBarBehavior.floating, // Make it float
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12.0), // Rounded corners
                  ),
                  margin: EdgeInsets.only(
                    // Position near top-center
                    bottom: 50.0,
                    // top: MediaQuery.of(context).size.height -
                    //     500, // Adjust vertical position from bottom
                    left: MediaQuery.of(context).size.width *
                        0.2, // Indent from left
                    right: MediaQuery.of(context).size.width *
                        0.2, // Indent from right
                  ),
                  duration:
                      const Duration(seconds: 3), // Slightly longer duration
                  elevation: 6.0,
                ),
              );
              context.read<CartCubit>().clearCart();
              context
                  .read<ReservationCubit>()
                  .resetState(); // Pour une future réservation propre

              // Naviguer et forcer l'affichage de l'onglet des commandes
              // Cette action (changer l'onglet d'un parent) est celle
              // que nous avions mise en place dans HomeOrderAccount via un autre BlocListener.
              // L'état ReservationSuccess va être détecté par le listener dans HomeOrderAccount
              // qui changera l'onglet. Donc, on a juste besoin de pop ici.
              Navigator.of(context).popUntil(
                  (route) => route.isFirst); // Retour à la page principale
            } else if (state is ReservationFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.error), backgroundColor: Colors.red),
              );
            }
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                16.0, 16.0, 16.0, 80.0), // Padding pour la BottomBar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Sélectionnez les Détails",
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 20),

                // --- Sélecteur de Date ---
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.calendar_today, color: kMainColor),
                  title: Text(locale.date ?? "Date"),
                  trailing: Text(
                      DateFormat('EEE d MMM yyyy', locale.locale.languageCode)
                          .format(_selectedDate),
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  onTap: () => _selectDate(context),
                ),
                Divider(height: 1),

                // --- Sélecteur Nombre de Personnes ---
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.people_outline, color: kMainColor),
                  title: Text("Nombre de personnes"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                          icon: Icon(Icons.remove_circle_outline,
                              color: _selectedGuests > 1
                                  ? kMainColor
                                  : Colors.grey),
                          onPressed: _decrementGuests),
                      Text(_selectedGuests.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: Icon(Icons.add_circle_outline,
                              color: _selectedGuests < 10
                                  ? kMainColor
                                  : Colors.grey),
                          onPressed: _incrementGuests),
                    ],
                  ),
                ),
                Divider(height: 1),
                SizedBox(height: 20),

                // --- Affichage des Créneaux Horaires ---
                Text("Créneaux Horaires Disponibles",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                BlocBuilder<ReservationCubit, ReservationState>(
                  buildWhen: (previous, current) {
                    // Reconstruire seulement pour les états liés à la disponibilité
                    return current is AvailabilityLoading ||
                        current is AvailabilityLoaded ||
                        current is AvailabilityError ||
                        current is ReservationInitial;
                  },
                  builder: (context, state) {
                    if (state is AvailabilityLoading) {
                      return Center(
                          child: CircularProgressIndicator(color: kMainColor));
                    } else if (state is AvailabilityError) {
                      return Center(
                          child: Text(state.message,
                              style: TextStyle(color: Colors.red)));
                    } else if (state is AvailabilityLoaded) {
                      if (state.date != _selectedDate ||
                          state.guests != _selectedGuests) {
                        return Center(
                            child: Text("Mise à jour des créneaux..."));
                      }
                      if (state.availableSlots.isEmpty) {
                        return Center(child: Text("Aucun créneau disponible."));
                      }
                      return Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: state.availableSlots.map((slot) {
                          bool isCurrentlySelected =
                              _selectedTimeSlot == slot.time;
                          return ChoiceChip(
                            label: Text(slot.time,
                                style: TextStyle(
                                    color: slot.available
                                        ? (isCurrentlySelected
                                            ? Colors.white
                                            : kMainColor)
                                        : Colors.grey[400])),
                            selected: isCurrentlySelected,
                            selectedColor: kMainColor,
                            backgroundColor: Theme.of(context)
                                .cardColor, // Couleur de fond du chip
                            disabledColor: Colors.grey[200], // Chip désactivé
                            onSelected: slot.available
                                ? (selected) {
                                    setState(() {
                                      _selectedTimeSlot =
                                          selected ? slot.time : null;
                                    });
                                  }
                                : null,
                            shape: StadiumBorder(
                                side: BorderSide(
                                    color: slot.available
                                        ? (isCurrentlySelected
                                            ? kMainColor
                                            : kMainColor.withOpacity(0.5))
                                        : Colors.grey[300]!)),
                            labelPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4), // Padding interne
                          );
                        }).toList(),
                      );
                    }
                    return Center(
                        child: Text("Sélectionnez date et personnes."));
                  },
                ),
                SizedBox(height: 20),

                // --- Affichage du Panier pour Pré-commande ---
                Text("Plats à Pré-commander",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                BlocBuilder<CartCubit, CartState>(
                  builder: (context, cartState) {
                    /* ... (inchangé, mais vérifiez le style) ... */
                    if (cartState is CartUpdated &&
                        cartState.items.isNotEmpty) {
                      return Card(
                        color: Colors.white,
                        // Envelopper dans une Card pour un meilleur style
                        elevation: 0.5,
                        margin: EdgeInsets.zero,
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: cartState.items.length,
                          itemBuilder: (context, index) {
                            final item = cartState.items[index];
                            return ListTile(
                              dense: true,
                              title:
                                  Text("${item.quantity}x ${item.dish.name}"),
                              trailing: Text(
                                  "${(item.dish.price * item.quantity).toStringAsFixed(2)} ${'DA'}"),
                            );
                          },
                          separatorBuilder: (context, index) =>
                              Divider(height: 1, indent: 16, endIndent: 16),
                        ),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                          "Votre panier est vide. Ajoutez des plats depuis le menu."),
                    );
                  },
                ),
                SizedBox(height: 20),

                // --- Section Méthode de Paiement ---
                Text("Méthode de paiement",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                InkWell(
                  onTap: () =>
                      setState(() => _isPaymentExpanded = !_isPaymentExpanded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12.0, horizontal: 8.0),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Icon(
                            getPaymentMethodDetails(_selectedPaymentMethod)[
                                    'icon'] as IconData? ??
                                Icons.help_outline,
                            color: kMainColor,
                            size: 22),
                        SizedBox(width: 10),
                        Expanded(
                            child: Text(
                                getPaymentMethodDetails(_selectedPaymentMethod)[
                                        'name'] as String? ??
                                    'Inconnu',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.bold))),
                        Icon(
                            _isPaymentExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                if (_isPaymentExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Card(
                      // Envelopper les options dans une Card
                      color: Colors.white,
                      elevation: 1,
                      margin: EdgeInsets.zero,
                      child: Column(
                        children: _availablePaymentMethods.map((method) {
                          final details = getPaymentMethodDetails(method);
                          final bool isSelected =
                              _selectedPaymentMethod == method;
                          return ListTile(
                            dense: true,
                            leading: Icon(
                                details['icon'] as IconData? ??
                                    Icons.help_outline,
                                color:
                                    isSelected ? kMainColor : Colors.grey[600]),
                            title: Text(details['name'] as String? ?? 'Inconnu',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal)),
                            trailing: isSelected
                                ? Icon(Icons.check_circle,
                                    color: kMainColor, size: 20)
                                : null,
                            onTap: () => setState(() {
                              _selectedPaymentMethod = method;
                              _isPaymentExpanded = false;
                            }),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                SizedBox(height: 20),

                // --- Champ pour les Demandes Spéciales ---
                Text("Demandes Spéciales (optionnel)",
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                TextField(
                  controller: _specialRequestsController,
                  decoration: InputDecoration(
                      hintText: "Ex: près de la fenêtre, chaise bébé...",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BlocBuilder<ReservationCubit, ReservationState>(
          builder: (context, reservationState) {
            bool isSubmitting = reservationState is ReservationSubmitting;
            // Activer le bouton seulement si un créneau est choisi et le panier n'est pas vide (et pas en soumission)
            bool canSubmit = _selectedTimeSlot != null &&
                (context.read<CartCubit>().state is CartUpdated &&
                    (context.read<CartCubit>().state as CartUpdated)
                        .items
                        .isNotEmpty) &&
                !isSubmitting;

            return BottomBar(
              text: isSubmitting ? ("Soumission...") : ("Réserver cette Table"),
              onTap: canSubmit
                  ? _submitReservation
                  : () {}, // Désactiver si conditions non remplies
              // Style pour bouton désactivé ? BottomBar doit le gérer ou on passe une couleur.
              // backgroundColor: canSubmit ? kMainColor : Colors.grey, // Exemple
            );
          },
        ));
  }
}
