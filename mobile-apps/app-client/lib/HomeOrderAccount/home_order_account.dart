import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/Chat/UI/animated_bottom_bar.dart';
import 'package:hungerz/HomeOrderAccount/Account/UI/account_page.dart';
import 'package:hungerz/HomeOrderAccount/Home/UI/home.dart';
import 'package:hungerz/HomeOrderAccount/Order/UI/order_page.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/cubits/dishes_cubit/dishes_cubit.dart';
import 'package:hungerz/cubits/order_cubit/order_cubit.dart';
// --- AJOUT : Assurez-vous que ReservationCubit est importé si ce n'est pas déjà le cas ---
// (S'il est dans le même fichier que ReservationState, l'import de ReservationState suffit parfois,
// mais un import explicite du cubit est plus clair)
import 'package:hungerz/cubits/reservation_cubit/reservation_cubit.dart';
import 'package:hungerz/cubits/unpaid_bill_cubit/unpaid_bill_cubit.dart'; // Adaptez le chemin si nécessaire

class HomeOrderAccount extends StatefulWidget {
  final int index;
  const HomeOrderAccount({Key? key, this.index = 0}) : super(key: key);

  @override
  _HomeOrderAccountState createState() => _HomeOrderAccountState();
}

class _HomeOrderAccountState extends State<HomeOrderAccount> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;

    // Si l'onglet initial est OrderPage (index 1), son propre initState
    // (dans order_page.dart) aura déjà appelé fetchMyReservations.
    // Si vous voulez forcer un appel ici aussi au cas où, vous pouvez le faire,
    // mais cela pourrait être redondant si OrderPage.initState le fait déjà.
    // Exemple :
    // if (_currentIndex == 1) {
    //   print("HomeOrderAccount initState: L'onglet initial est OrderPage. Déclenchement préventif.");
    //   context.read<ReservationCubit>().fetchMyReservations();
    // }
  }

  static String bottomIconHome = 'images/footermenu/ic_home.png';
  static String bottomIconOrder = 'images/footermenu/ic_orders.png';
  static String bottomIconAccount = 'images/footermenu/ic_profile.png';

  @override
  Widget build(BuildContext context) {
    var appLocalization = AppLocalizations.of(context)!;

    return BlocListener<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state is OrderPlacementSuccessNavigateToOrders) {
          print(
              "HomeOrderAccount Listener: Commande réussie détectée. Passage à l'onglet Commandes (index 1).");
          if (_currentIndex != 1) {
            setState(() {
              _currentIndex = 1; // Change l'onglet vers OrderPage
            });
            // Après avoir changé l'onglet, on s'assure aussi que les données de OrderPage (réservations) sont fraîches.
            // Note : Si OrderPage gère aussi l'affichage des commandes et a besoin d'un refresh pour celles-ci,
            // il faudrait aussi appeler le cubit correspondant.
            print("HomeOrderAccount Listener: Déclenchement de la récupération des réservations après redirection.");
            context.read<OrderCubit>().fetchOrderHistory();
          }
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: const [ // Rendre les enfants const si possible et s'ils n'ont pas de paramètres variables
            HomePage(),
            OrderPage(), // Index 1
            AccountPage(),
          ],
        ),
        bottomNavigationBar: AnimatedBottomBar(
            barItems: [
              BarItem(text: appLocalization.homeText!, image: bottomIconHome),
              BarItem(text: appLocalization.orders!, image: bottomIconOrder), // Index 1
              BarItem(text: appLocalization.account!, image: bottomIconAccount),
            ],
            currentIndex: _currentIndex,
            onBarTap: (index) {
              // Si l'utilisateur clique sur l'onglet déjà actif,
              // vous pourriez vouloir ne rien faire ou forcer un rafraîchissement.
              // Pour l'instant, nous rafraîchissons si l'index change pour OrderPage,
              // ou si l'utilisateur clique sur OrderPage même s'il est déjà actif.

              bool
                  isSwitchingToOrderPage = (index == 1); // Index de OrderPage
              bool isSwitchingToHomePage=(index == 0); // Index de HomePage

              setState(() {
                _currentIndex = index;
              });

              if (isSwitchingToOrderPage) {
                print(
                    "HomeOrderAccount onBarTap: Onglet OrderPage (index 1) sélectionné. Déclenchement de la récupération des réservations.");
                // Assurez-vous que ReservationCubit est fourni au-dessus de HomeOrderAccount
                // (par exemple, dans votre main.dart via un MultiBlocProvider).
                context.read<ReservationCubit>().fetchMyReservations();
                context.read<UnpaidBillCubit>().fetchMyUnpaidBills();
                // Si vous avez un cubit séparé pour l'historique des commandes (dans l'autre onglet de OrderPage)
                // et que vous voulez aussi le rafraîchir, faites-le ici.
                // Exemple : context.read<YourOrderHistoryCubit>().fetchOrderHistory();
              }

              if (isSwitchingToHomePage) {
                print(
                    "HomeOrderAccount onBarTap: Onglet HomePage (index 0) sélectionné. Déclenchement de la récupération des réservations.");
                // Assurez-vous que ReservationCubit est fourni au-dessus de HomeOrderAccount
                // (par exemple, dans votre main.dart via un MultiBlocProvider).
                context.read<DishesCubit>().fetchDishes();
                // Si vous avez un cubit séparé pour l'historique des commandes (dans l'autre onglet de OrderPage)
                // et que vous voulez aussi le rafraîchir, faites-le ici.
                // Exemple : context.read<YourOrderHistoryCubit>().fetchOrderHistory();
              }
            }),
      ),
    );
  }
}

  // --- Supprimer si plus utilisé ---
  // void _checkForBuyNow() {
  //   WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
  //     if (widget.index == 1) {
  //       Navigator.pushNamed(context, PageRoutes.viewCart);
  //     }
  //   });
  // }
  // -----------------------------

  // void _checkForBuyNow() async {
  //   // SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  //   // if (!sharedPreferences.containsKey("key_buy_this_shown") &&
  //   //     AppConfig.isDemoMode) {
  //   //   Future.delayed(Duration(seconds: 10), () async {
  //   //     if (mounted) {
  //   //       BuyThisApp.showSubscribeDialog(context);
  //   //       sharedPreferences.setBool("key_buy_this_shown", true);
  //   //     }
  //   //   });
  //   // }
  // }

