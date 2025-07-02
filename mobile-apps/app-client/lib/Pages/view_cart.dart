// --- Fichier: lib/pages/view_cart.dart (ou adaptez le chemin) ---

import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/Components/bottom_bar.dart'; // Assurez-vous que ce widget existe et est importé
import 'package:hungerz/Locale/locales.dart'; // Pour AppLocalizations
import 'package:hungerz/Pages/address_search_page.dart'; // Pour PageRoutes (si utilisé pour paiement)
import 'package:hungerz/Themes/colors.dart'; // Pour kMainColor, kDisabledColor
import 'package:hungerz/common/enums.dart';
import 'package:hungerz/cubits/cart_cubit/cart_cubit.dart'; // Adaptez chemin
import 'package:hungerz/cubits/location_cubit/location_cubit.dart';
import 'package:hungerz/cubits/order_cubit/order_cubit.dart';
import 'package:hungerz/cubits/profile_cubit/profile_cubit.dart';
import 'package:hungerz/models/address_model.dart';
import 'package:hungerz/models/cart_item_model.dart';
import 'package:hungerz/models/place_model.dart';
import 'package:hungerz/services/stripe_service.dart'; // Adaptez chemin/nom
//import 'package:hungerz/models/menu_item_model.dart'; // Adaptez chemin/nom
//import 'package:hungerz/common/enums.dart'; // --- Assurez-vous d'avoir ce fichier ou définissez l'enum ici ---

// Fonction helper pour obtenir l'icône et le nom (optionnel mais pratique)
Map<String, dynamic> getPaymentMethodDetails(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.wallet:
      return {
        'name': 'WALLET',
        'icon': Icons.account_balance_wallet_outlined
      }; // Adaptez l'icône exacte
    case PaymentMethod.cash:
      return {
        'name': 'CASH',
        'icon': Icons.money_outlined
      }; // Adaptez l'icône exacte
    case PaymentMethod.card:
      return {
        'name': 'CIB',
        'icon': Icons.credit_card
      }; // Adaptez l'icône exacte // Icône placeholder, adaptez
  }
}

// --- ViewCart est maintenant StatefulWidget ---
class ViewCart extends StatefulWidget {
  const ViewCart({super.key});

  @override
  _ViewCartState createState() => _ViewCartState();
}

class _ViewCartState extends State<ViewCart> {
  // --- État local pour le mode de livraison ---
  DeliveryMethod _selectedDeliveryMethod =
      DeliveryMethod.delivery; // Défaut: Livraison

  // --- Constante pour les frais (exemple, adaptez ou rendez dynamique) ---
  final double _deliveryFeeConstant = 500; // Exemple Frais de livraison en DA
  final double _takeAwayFeeConstant = 0.0; // Exemple Frais pour emporter
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash; // Défaut: Cash
  bool _isPaymentExpanded = false; // Pour contrôler l'affichage des options
  // Liste des méthodes disponibles (peut venir de l'API plus tard)
  final List<PaymentMethod> _availablePaymentMethods = [
    PaymentMethod.wallet,
    PaymentMethod.cash,
    PaymentMethod.card,
  ];
  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(Icons.chevron_left, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            Text(locale.confirm!, style: Theme.of(context).textTheme.bodyLarge),
        actions: [
          BlocBuilder<CartCubit, CartState>(
            builder: (context, state) {
              if (state is CartUpdated && state.items.isNotEmpty) {
                return IconButton(
                  icon: Icon(Icons.delete_sweep_outlined),
                  tooltip: 'Vider le panier',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: Text('Vider le panier ?'),
                        content: Text(
                            'Voulez-vous vraiment supprimer tous les articles ?'),
                        actions: [
                          TextButton(
                              child: Text('Annuler'),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop()),
                          TextButton(
                            child: Text('Vider',
                                style: TextStyle(color: Colors.red)),
                            onPressed: () {
                              context.read<CartCubit>().clearCart();
                              Navigator.of(dialogContext).pop();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              }
              return SizedBox.shrink();
            },
          )
        ],
      ),
      // --- Utiliser BlocBuilder pour réagir aux changements du panier (items, subTotal) ---
      body: BlocListener<OrderCubit, OrderState>(
        listener: (context, orderState) {
          if (orderState is OrderPlacementSuccessNavigateToOrders) {
            print("ViewCart Listener: Commande réussie !");
            // 1. Vider le panier
            context.read<CartCubit>().clearCart();
            // 2. (Optionnel) Afficher un message de succès
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
                        "Commande passée avec succès !",
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
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
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
            // 3. Fermer la page ViewCart pour revenir à HomeOrderAccount
            // Donner un petit délai pour que l'utilisateur voie le SnackBar
            if (mounted) {
                // Vérifier si toujours monté

                Navigator.of(context).pop(); // Ferme juste la page actuelle
              }
            
            // Future.delayed(Duration(milliseconds: 500), () {
            //   if (mounted) {
            //     // Vérifier si toujours monté

            //     Navigator.of(context).pop(); // Ferme juste la page actuelle
            //   }
            // }
            // );
          } else if (orderState is OrderPlacementFailure) {
            print("ViewCart Listener: ÉCHEC COMMANDE: ${orderState.error}");
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text("Erreur commande: ${orderState.error}"),
                  backgroundColor: Colors.red),
            );
          }
        },
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, state) {
            // --- Panier Vide ---
            if (state is CartInitial ||
                (state is CartUpdated && state.items.isEmpty)) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined,
                        size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "Votre panier est vide.",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            // --- Panier avec Articles (CartUpdated) ---
            if (state is CartUpdated) {
              // Calculer les frais et total ICI basé sur l'état LOCAL _selectedDeliveryMethod
              double currentDeliveryFee =
                  (_selectedDeliveryMethod == DeliveryMethod.delivery)
                      ? _deliveryFeeConstant
                      : _takeAwayFeeConstant;

              // --- IMPORTANT: Assurez-vous que votre CartUpdated State contient 'subTotal' ---
              // Si CartUpdated n'a que 'totalPrice' (qui n'inclut pas les frais), utilisez-le ici.
              double subTotalFromState =
                  state.totalPrice; // Adaptez si le champ s'appelle autrement
              // --------------------------------------------------------------------------

              double finalAmount = subTotalFromState +
                  currentDeliveryFee; // + Autres frais éventuels

              return FadedSlideAnimation(
                beginOffset: Offset(0.0, 0.3),
                endOffset: Offset(0, 0),
                slideCurve: Curves.linearToEaseOut,
                child: Stack(
                  children: <Widget>[
                    ListView(
                      padding: const EdgeInsets.only(
                          bottom: 250), // Padding pour le contenu fixe en bas
                      children: <Widget>[
                        // Optionnel: Titre magasin
                        // Container(child: Text(locale.store!.toUpperCase(), ...)),

                        // --- Liste dynamique des articles ---
                        ...state.items
                            .expand((item) => [
                                  _CartListItem(
                                      item:
                                          item), // Widget défini ci-dessous ou importé
                                  Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withOpacity(0.1)),
                                ])
                            .toList(),
                        // -------------------------------------------

                        // --- Section Choix Mode Livraison ---
                        //Divider(color: Theme.of(context).dividerColor.withOpacity(0.1), thickness: 8.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Mode de récupération",
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold)),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    // Livraison
                                    child: _buildDeliveryOptionCard(
                                        context: context,
                                        icon: Icons.delivery_dining,
                                        title: "Livraison",
                                        fee: _deliveryFeeConstant,
                                        isSelected: _selectedDeliveryMethod ==
                                            DeliveryMethod.delivery,
                                        onTap: () => setState(() =>
                                            _selectedDeliveryMethod =
                                                DeliveryMethod.delivery)),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    // À Emporter
                                    child: _buildDeliveryOptionCard(
                                        context: context,
                                        icon: Icons.shopping_bag_outlined,
                                        title: "À emporter",
                                        fee: _takeAwayFeeConstant,
                                        isSelected: _selectedDeliveryMethod ==
                                            DeliveryMethod.takeAway,
                                        onTap: () => setState(() =>
                                            _selectedDeliveryMethod =
                                                DeliveryMethod.takeAway)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        // --------------------------------------------

                        // Section Informations de Paiement (utilise valeurs calculées localement)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 20.0),
                          child: Text("Informations de paiement".toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge!
                                  .copyWith(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.67)),
                        ),
                        Container(
                          // Sous-Total
                          padding: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(locale.sub!,
                                  style: Theme.of(context).textTheme.bodySmall),
                              Text('${subTotalFromState.toStringAsFixed(2)} DA',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall), // Depuis CartState
                            ],
                          ),
                        ),
                        Divider(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.1),
                            thickness: 1.0),
                        Container(
                          // Frais Livraison
                          padding: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 20.0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Frais de livraison",
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                                Text(
                                    '${currentDeliveryFee.toStringAsFixed(2)} DA',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall), // Calculé localement
                              ]),
                        ),
                        Divider(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.1),
                            thickness: 1.0),
                        Container(
                          // Montant Total
                          padding: EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 20.0),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Montant total",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(fontWeight: FontWeight.bold)),
                                Text('${finalAmount.toStringAsFixed(2)} DA',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall!
                                        .copyWith(
                                            fontWeight: FontWeight
                                                .bold)), // Calculé localement
                              ]),
                        ),

                        // --- Section Méthode de Paiement ---
                        Divider(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.1),
                            thickness: 8.0),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isPaymentExpanded =
                                  !_isPaymentExpanded; // Bascule la visibilité
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20.0, vertical: 15.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Méthode de paiement",
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                // Affiche l'icône et le nom de la méthode sélectionnée
                                Icon(
                                  getPaymentMethodDetails(
                                              _selectedPaymentMethod)['icon']
                                          as IconData? ??
                                      Icons.help_outline,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  getPaymentMethodDetails(
                                              _selectedPaymentMethod)['name']
                                          as String? ??
                                      'Inconnu',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8),
                                // Icône pour ouvrir/fermer
                                Icon(
                                  _isPaymentExpanded
                                      ? Icons.expand_less
                                      : Icons.expand_more, // Flèche haut/bas
                                  color: Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // --- Liste des options de paiement (conditionnelle) ---
                        // Utilise Visibility ou un simple 'if'
                        if (_isPaymentExpanded)
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20.0,
                                right: 20.0,
                                bottom: 10.0), // Padding pour la liste
                            child: Column(
                              // Génère une ListTile pour chaque méthode disponible
                              children: _availablePaymentMethods.map((method) {
                                final details = getPaymentMethodDetails(method);
                                final bool isSelected =
                                    _selectedPaymentMethod == method;

                                return ListTile(
                                  dense: true, // Rend la tuile plus compacte
                                  contentPadding: EdgeInsets.symmetric(
                                      vertical: 0,
                                      horizontal: 0), // Ajuster padding interne
                                  leading: Icon(
                                    details['icon'] as IconData? ??
                                        Icons.help_outline,
                                    color: isSelected
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey[600],
                                  ),
                                  title: Text(
                                    details['name'] as String? ?? 'Inconnu',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                  ),
                                  // Optionnel: Afficher une coche si sélectionné
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle,
                                          color: Theme.of(context).primaryColor,
                                          size: 20)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedPaymentMethod =
                                          method; // Met à jour la sélection
                                      _isPaymentExpanded =
                                          false; // Referme la liste
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        Divider(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.1),
                            thickness: 8.0),
                        // ---------------------------------------------
                      ],
                    ),

                    // --- Partie Basse Fixe ---
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: double.infinity, // Prend toute la largeur
                            color: Theme.of(context)
                                .scaffoldBackgroundColor, // Fond pour cacher la liste
                            padding: EdgeInsets.only(
                                left: 20.0,
                                right: 12.0,
                                top: 13.0,
                                bottom: 13.0),
                            child: BlocBuilder<ProfileCubit, ProfileState>(
                              // <-- Écoute ProfileCubit
                              builder: (context, profileState) {
                                AddressModel? activeAddress;
                                if (profileState is ProfileLoaded) {
                                  activeAddress =
                                      profileState.activeDisplayAddress;
                                }

                                // Si une adresse active est définie dans ProfileCubit, on l'affiche
                                if (activeAddress != null) {
                                  return _buildAddressDisplay(
                                    context: context,
                                    label: activeAddress.label,
                                    address: activeAddress.address,
                                    icon: Icons
                                        .location_on_outlined, // Ou une icône basée sur le type?
                                    locale: locale,
                                  );
                                } else {
                                  // Sinon, Fallback sur LocationCubit
                                  return BlocBuilder<LocationCubit,
                                      LocationState>(
                                    builder: (context, locationState) {
                                      String addressText = locale.setLocation ??
                                          "Définir l'adresse de livraison";
                                      IconData addressIcon =
                                          Icons.gps_not_fixed;
                                      if (locationState is LocationLoading) {
                                        addressText =
                                            "Localisation en cours...";
                                      } else if (locationState
                                          is LocationLoaded) {
                                        addressText =
                                            locationState.simpleAddress;
                                        addressIcon = Icons
                                            .my_location; // Icône différente pour GPS
                                      } else if (locationState
                                          is LocationPermissionDenied) {
                                        addressText =
                                            "Permission localisation refusée";
                                      } else if (locationState
                                          is LocationServiceDisabled) {
                                        addressText =
                                            "Service localisation désactivé";
                                      } else if (locationState
                                          is LocationError) {
                                        addressText = "Erreur localisation";
                                      }

                                      return _buildAddressDisplay(
                                        context: context,
                                        label: "Livraison à",
                                        address: addressText,
                                        icon: addressIcon,
                                        locale: locale,
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                          ),
                          BottomBar(
                            text: _selectedPaymentMethod == PaymentMethod.card
                                ? "Payer ${finalAmount.toStringAsFixed(2)} DA"
                                : "Confirmer Commande", // Total final local
                            onTap: () async {
                              if (state.items.isNotEmpty) {
                                // --- Récupérer les informations nécessaires ---
                                // 1. Items depuis CartCubit state
                                final List<CartItem> currentItems = state.items;

                                // 2. Adresse active depuis ProfileCubit state
                                final profileState =
                                    context.read<ProfileCubit>().state;
                                AddressModel?
                                    activeAddress; // Peut être null pour Take Away
                                if (profileState is ProfileLoaded) {
                                  activeAddress =
                                      profileState.activeDisplayAddress;
                                }

                                // 3. Vérification : Pour la livraison, une adresse est requise
                                if (_selectedDeliveryMethod ==
                                        DeliveryMethod.delivery &&
                                    activeAddress == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            "Veuillez sélectionner une adresse de livraison."),
                                        backgroundColor: Colors.orange),
                                  );
                                  return; // Arrêter si l'adresse manque pour la livraison
                                }

                                // 4. Méthode de livraison et paiement depuis l'état local
                                final DeliveryMethod deliveryMethod =
                                    _selectedDeliveryMethod;
                                final PaymentMethod paymentMethod =
                                    _selectedPaymentMethod;
                                bool success = true;
                                if (paymentMethod == PaymentMethod.card) {
                                  success = await StripeService.instance.makePayment(
                                          finalAmount.toInt() )
                                     ; // Convertir en centimes
                                }
                                // TODO: Récupérer les instructions de livraison si vous ajoutez un champ pour cela

                                print("Déclenchement de placeOrder:");
                                print(" - Methode: $deliveryMethod");
                                print(" - Paiement: $paymentMethod");
                                print(
                                    " - Adresse: ${activeAddress?.address ?? 'N/A'}");
                                print(" - Nb Items: ${currentItems.length}");

                                // --- Appel à OrderCubit ---
                                if (success) {
                                  context.read<OrderCubit>().placeOrder(
                                        items: currentItems,
                                        deliveryAddress:
                                            activeAddress, // Null si Take Away
                                        deliveryMethod: deliveryMethod,
                                        paymentMethod: paymentMethod,
                                        // deliveryInstructions: _instructionsController.text, // Si vous avez un controller
                                      );
                                }

                                // --- Gérer le résultat de la commande ---
                                // Il faut maintenant écouter OrderCubit ailleurs (ex: avec BlocListener
                                // autour du Scaffold de ViewCart ou même plus haut) pour réagir au succès/échec.
                                // Par exemple, pour naviguer vers une page de confirmation ou afficher une erreur.
                                // Pour l'instant, on ne navigue plus directement ici.
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Votre panier est vide.")),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            // --- Fallback ---
            return Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  // --- Helper Widget pour les cartes d'option de livraison ---
  Widget _buildDeliveryOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double fee,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color cardColor = isSelected
        ? Theme.of(context).primaryColor.withOpacity(0.10)
        : Theme.of(context).cardColor;
    Color borderColor = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).dividerColor.withOpacity(0.1);
    Color contentColor = isSelected
        ? Theme.of(context).primaryColor
        : Theme.of(context).textTheme.bodyLarge!.color!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: contentColor, size: 28),
            SizedBox(height: 8),
            Text(title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold, color: contentColor)),
            SizedBox(height: 2),
            Text(
              (title == ("À emporter") || fee == 0)
                  ? 'Gratuit'
                  : '+ ${fee.toStringAsFixed(0)} DA', // Adaptez format
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: contentColor.withOpacity(0.8)),
            )
          ],
        ),
      ),
    );
  }

  // --- Helper pour afficher l'adresse de livraison ---
  Widget _buildAddressDisplay({
    required BuildContext context,
    required String label,
    required String address,
    required IconData icon,
    required AppLocalizations locale,
  }) {
    
    return InkWell(
      // Rendre l'adresse cliquable pour la changer
      onTap: () async {
        print("ViewCart: Clic pour changer/choisir l'adresse");
        final result = await Navigator.push<Place?>(
          context,
          MaterialPageRoute(builder: (_) => AddressSearchPage()),
        );
        if (result != null && context.mounted) {
          print("ViewCart: Adresse sélectionnée reçue: ${result.name}");
          if (result.latitude != null && result.longitude != null) {
            AddressModel selectedAddrModel = AddressModel(
              label: result.name, address: result.address,
              latitude: result.latitude!, longitude: result.longitude!,
              type: AddressType.other.name, // Type par défaut?
              placeId: result.id,
            );
            // Mettre à jour l'adresse active dans ProfileCubit
            context
                .read<ProfileCubit>()
                .setActiveDisplayAddress(selectedAddrModel);
          } else {/* ... Gérer coordonnées manquantes ... */}
        } else if (context.mounted) {
          print("ViewCart: Retour AddressSearchPage sans sélection.");
          // Optionnel: revenir explicitement à la localisation GPS ?
          // context.read<ProfileCubit>().setActiveDisplayAddress(null);
        }
      },
      child: Row(
        children: <Widget>[
          Icon(icon,
              color: Color(0xffc4c8c1), size: 16), // Icône un peu plus grande
          SizedBox(width: 11.0),
          Expanded(
            // Pour que le texte utilise ellipsis si besoin
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, // Le label (ex: "Maison", "Livraison à")
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: kDisabledColor, fontWeight: FontWeight.bold)),
                SizedBox(height: 2),
                Text(
                  address, // L'adresse formatée
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontSize: 11.7, color: Color(0xffb7b7b7)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              ],
            ),
          ),
          //Spacer(), // Retiré car Expanded gère l'espace
          Icon(Icons.arrow_drop_down,
              color: Colors.grey), // Indicateur pour changer
        ],
      ),
    );
  }
  // --- Fin Helper Widget ---
}

// --- Widget _CartListItem (Doit être défini ici ou importé) ---
// (Collez ici la définition de _CartListItem fournie précédemment)
class _CartListItem extends StatelessWidget {
  final CartItem item;
  const _CartListItem({Key? key, required this.item}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ClipRRect(
                borderRadius: BorderRadius.circular(4.0),
                child: Image.network(item.dish.image ?? 'URL_PLACEHOLDER',
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                        width: 45,
                        height: 45,
                        color: Colors.grey[200],
                        child: Icon(Icons.image_not_supported,
                            size: 20, color: Colors.grey)))),
            SizedBox(width: 16.0),
            Expanded(
                child: Text(item.dish.name,
                    style: Theme.of(context).textTheme.titleSmall!.copyWith(
                        color: Theme.of(context).secondaryHeaderColor,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2)),
            SizedBox(width: 12.0),
            Container(
              height: 33.0,
              padding: EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                  border: Border.all(color: kMainColor.withOpacity(0.7)),
                  borderRadius: BorderRadius.circular(30.0)),
              child: Row(
                children: <Widget>[
                  InkWell(
                      onTap: item.quantity > 1
                          ? () => context
                              .read<CartCubit>()
                              .decrementItem(item.dish.id!)
                          : () => context
                              .read<CartCubit>()
                              .removeItem(item.dish.id!),
                      child: Icon(
                          item.quantity > 1
                              ? Icons.remove
                              : Icons.delete_outline,
                          color: item.quantity > 1
                              ? kMainColor
                              : Colors.red.withOpacity(0.8),
                          size: 18.0)),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(item.quantity.toString(),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontWeight: FontWeight.bold))),
                  InkWell(
                      onTap: () => context
                          .read<CartCubit>()
                          .incrementItem(item.dish.id!),
                      child: Icon(Icons.add, color: kMainColor, size: 18.0)),
                ],
              ),
            ),
            SizedBox(width: 12.0),
            SizedBox(
                width: 65,
                child: Text(
                    '${(item.dish.price * item.quantity).toStringAsFixed(2)} DA',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
// --- Fin _CartListItem ---

