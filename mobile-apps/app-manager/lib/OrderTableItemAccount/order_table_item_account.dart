// Dans votre fichier order_item_account.dart

import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/ListItems/stock.dart';
import 'package:hungerz_store/cubits/manager_stock_cubit/manager_stock_cubit.dart'; 
import 'package:hungerz_store/models/ingredient_model.dart'; 
// Importez votre nouvelle page de stock // VÉRIFIEZ CE CHEMIN

// ... (le reste de vos imports pour OrderPageProvider, etc.)
import 'package:hungerz_store/OrderTableItemAccount/Account/UI/account_page.dart';
import 'package:hungerz_store/OrderTableItemAccount/Order/UI/order_page.dart'; 
import 'package:hungerz_store/OrderTableItemAccount/Table/UI/table_booking_page.dart'; 
import 'package:hungerz_store/Pages/items.dart'; // Si ce n'est PAS la page de stock poussée, son rôle change
import 'package:hungerz_store/Themes/colors.dart';


class OrderItemAccount extends StatefulWidget {
  final int? initialIndex;
  OrderItemAccount({this.initialIndex = 0, Key? key}) : super(key: key);

  @override
  _OrderItemAccountState createState() => _OrderItemAccountState();
}

class _OrderItemAccountState extends State<OrderItemAccount> {
  late int _currentIndex;
  StreamSubscription? _lowStockAlertSubscription;

  // Mettez à jour cette liste si ItemsPageProvider n'est plus la page de stock principale
  // Ou si vous voulez la garder comme un aperçu rapide et avoir une page de gestion détaillée.
  late List<Widget> _children; 

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;

    _children = [
      OrderPageProvider(), 
      TableBookingPageWithProvider(),
      ItemsPageProvider(), // Si c'est toujours un onglet pertinent
      AccountPage(),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final managerStockCubit = context.read<ManagerStockCubit>();
        _lowStockAlertSubscription = managerStockCubit.lowStockAlertStream.listen((ingredientEnStockBas) {
          if (mounted) {
            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'STOCK BAS: ${ingredientEnStockBas.name}! (${ingredientEnStockBas.stock.toStringAsFixed(1)} ${ingredientEnStockBas.unit})'),
                backgroundColor: Colors.orangeAccent,
                duration: Duration(seconds: 3), // Durée plus courte si on navigue
              ),
            );

            // MODIFIÉ : Utiliser Navigator.push pour la nouvelle page de stock
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => StockPage(
                  highlightIngredientId: ingredientEnStockBas.id, // Passer l'ID pour mise en évidence
                ),
              ),
            );
            // Si vous avez des routes nommées :
            // Navigator.of(context).pushNamed('/stock_management_page', arguments: ingredientEnStockBas.id);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _lowStockAlertSubscription?.cancel();
    super.dispose();
  }

  // Cette méthode n'est plus utilisée pour la navigation vers la page de stock principale
  // si elle est poussée. Vous pouvez la supprimer ou l'adapter si l'onglet "Items"
  // a un autre but.
  // void _navigateToStockPage() { ... } 

  void onTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // ... (vos constantes d'icônes) ...
  static const String bottomIconOrder = 'images/footermenu/ic_orders.png';
  static const String bottomIconTable = 'images/footermenu/ic_table.png';
  static const String bottomIconItems = 'images/footermenu/ic_item.png';
  static const String bottomIconAccount = 'images/footermenu/ic_profile.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),
      bottomNavigationBar: BottomNavigationBar(
        // ... (votre BottomNavigationBar reste la même) ...
         currentIndex: _currentIndex,
        onTap: onTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: kMainColor, 
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 12),
        items: [
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage(bottomIconOrder)),
            label: "Commandes",
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage(bottomIconTable)),
            label: "Tables", 
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage(bottomIconItems)),
            // Ce label pourrait changer si ItemsPageProvider n'est plus la page de stock principale
            label: "Produits", 
          ),
          BottomNavigationBarItem(
            icon: ImageIcon(AssetImage(bottomIconAccount)),
            label: "Compte",
          ),
        ],
      ),
    );
  }
}