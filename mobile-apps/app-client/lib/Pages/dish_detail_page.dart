// lib/pages/dish_detail_page.dart

import 'package:flutter/material.dart';
import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/cubits/profile_cubit/profile_cubit.dart';
// Importez votre modèle de plat
import 'package:hungerz/models/menu_item_model.dart';
// Importez CartCubit si vous voulez un bouton "Ajouter au panier" ici
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/cubits/cart_cubit/cart_cubit.dart'; // Adaptez le chemin

// lib/pages/dish_detail_page.dart (VERSION SIMPLIFIÉE)

// Adaptez chemin

class DishDetailPage extends StatefulWidget {
  final MenuItemModel dish;

  const DishDetailPage({Key? key, required this.dish}) : super(key: key);

  @override
  _DishDetailPageState createState() => _DishDetailPageState();
}

class _DishDetailPageState extends State<DishDetailPage> {
  int _quantity = 1; // État local pour la quantité

  // --- Méthodes pour gérer la quantité ---
  void _incrementQuantity() {
    setState(() {
      _quantity++;
    });
  }

  void _decrementQuantity() {
    // Empêche la quantité de descendre en dessous de 1
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  // --- Calcul du prix total (basé uniquement sur le prix du plat et la quantité) ---
  double get _totalPrice {
    return widget.dish.price * _quantity;
  }

  // --- Méthode pour ajouter au panier (simplifiée) ---
  void _addToCart() {
    // TODO: Adaptez cet appel à la méthode exacte de votre CartCubit pour ajouter
    // un article simple avec une quantité.
    // Votre CartCubit a-t-il une méthode comme `addItem(Dish dish, int quantity)` ?
    // Ou gérez-vous la quantité différemment ? Adaptez l'appel ci-dessous.

    print('Ajout au panier: ${widget.dish.name}, Qté: $_quantity');

    // Supposons une méthode `addItem` simple dans CartCubit pour cet exemple
    // Vous pourriez devoir appeler addItem plusieurs fois ou adapter CartItem
    // pour stocker la quantité directement si ce n'est pas déjà fait.
    for (int i = 0; i < _quantity; i++) {
      context
          .read<CartCubit>()
          .addItem(widget.dish); // Exemple d'appel simple répété
    }
    // OU si votre cubit a une méthode dédiée :
    // context.read<CartCubit>().addItemWithQuantity(dish: widget.dish, quantity: _quantity);

    ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
  content: Row(
    mainAxisAlignment: MainAxisAlignment.center, // Ajouté pour centrer les enfants de la Row
    crossAxisAlignment: CrossAxisAlignment.center, // Optionnel: pour centrer verticalement les enfants
    children: [
      const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
      const SizedBox(width: 4), // Maintenir un petit espacement
      // L'Expanded prendra l'espace restant, mais la Row sera centrée
      // Si vous voulez que le texte lui-même soit moins large,
      // vous pourriez envisager de ne pas utiliser Expanded ici,
      // ou de l'envelopper dans un Flexible avec un fit lâche.
      // Pour un centrage simple de l'icône et du texte comme un groupe,
      // il est souvent préférable de ne pas utiliser Expanded si la largeur totale
      // du contenu est inférieure à la largeur de la SnackBar.
      // Essayons sans Expanded pour voir si cela donne l'effet désiré
      // si le texte n'est pas trop long.
      Flexible( // Remplacer Expanded par Flexible pour un meilleur contrôle du centrage
        child: Text(
          '${widget.dish.name} (x$_quantity) ajouté au panier!',
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center, // Peut aider à centrer le texte s'il est sur plusieurs lignes
        ),
      ),
    ],
  ),
  backgroundColor: kMainColor, // Assurez-vous que kMainColor est défini
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12.0),
  ),
  margin: EdgeInsets.only(
    bottom: 50.0,
    left: MediaQuery.of(context).size.width * 0.1,
    right: MediaQuery.of(context).size.width * 0.1,
  ),
  duration: const Duration(seconds: 3),
  elevation: 6.0,
)
    );
    Navigator.pop(context); // Retourne à la page précédente après ajout
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Section Image avec Bouton Fermer ---
            Stack(
              children: [
                Image.network(
                  widget.dish.image ?? 'URL_PLACEHOLDER',
                  width: double.infinity,
                  height: 280,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                      height: 280,
                      color: Colors.grey[200],
                      child: Icon(Icons.broken_image,
                          size: 50, color: Colors.grey)),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                        height: 280,
                        child: Center(child: CircularProgressIndicator()));
                  },
                ),
                Positioned(
                  top: 40, // Status bar height safe area might be needed
                  right: 15,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.5),
                    child: IconButton(
                      icon: Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Fermer',
                    ),
                  ),
                ),
              ],
            ),

            // --- Section Infos Texte (Nom, Desc, Prix) ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start, // Aligner en haut
                    children: [
                      // Nom du plat (prend l'espace disponible)
                      Expanded(
                        child: Text(
                          widget.dish.name,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          // maxLines: 3, // Si besoin de limiter la hauteur du nom
                          // overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 16), // Espace avant le coeur

                      // Bouton Favori (écoute ProfileCubit)
                      BlocSelector<ProfileCubit, ProfileState, bool>(
                        selector: (state) {
                          // Vérifie si l'état est chargé ET si l'ID du plat est dans les favoris
                          if (state is ProfileLoaded) {
                            // Assurez-vous que votre modèle 'dish' a un champ 'id' (String)
                            return state.user.favorites
                                    ?.contains(widget.dish.id) ??
                                false;
                          }
                          return false; // Non favori par défaut ou si état non chargé
                        },
                        builder: (context, isFavorite) {
                          print(
                              "DishDetailPage: Rebuild bouton favori pour ${widget.dish.name}. Est favori: $isFavorite");
                          return IconButton(
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color:
                                  isFavorite ? Colors.redAccent : Colors.grey,
                              size: 28, // Taille de l'icône
                            ),
                            tooltip: isFavorite
                                ? 'Retirer des favoris'
                                : 'Ajouter aux favoris',
                            onPressed: () {
                              // Appelle la méthode toggleFavorite du ProfileCubit
                              // Assurez-vous que votre modèle 'dish' a un champ 'id' (String)
                              context
                                  .read<ProfileCubit>()
                                  .toggleFavorite(widget.dish.id!);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    widget.dish.description ??
                        "Description non disponible.", // Texte par défaut
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.grey[700]),
                  ),
                  SizedBox(height: 16),
                  Text(
                    '${widget.dish.price.toStringAsFixed(0)} DA', // Formatage prix
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
            ),

            // !!! SECTION OPTIONS SUPPRIMÉE !!!

            // Espace pour éviter que le contenu soit caché par la barre du bas
            SizedBox(height: 100),
          ],
        ),
      ),

      // --- Barre d'Action en Bas (Quantité + Ajout Panier) ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12.0)
            .copyWith(bottom: MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 5, spreadRadius: 1)
          ],
        ),
        child: Row(
          children: [
            // Sélecteur de Quantité
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.remove, size: 18),
                    onPressed: _decrementQuantity, // Appelle la méthode locale
                    visualDensity: VisualDensity.compact,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('$_quantity',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium), // Affiche l'état local
                  ),
                  IconButton(
                    icon: Icon(Icons.add, size: 18),
                    onPressed: _incrementQuantity, // Appelle la méthode locale
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            SizedBox(width: 12),

            // Bouton Ajouter au Panier
            Expanded(
              child: ElevatedButton(
                onPressed: _addToCart, // Appelle la méthode locale simplifiée
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: kMainColor,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Add to cart',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)), // Texte du bouton
                      SizedBox(width: 8),
                      Text('${_totalPrice.toStringAsFixed(0)} DA',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight
                                  .bold)), // Affiche le prix total calculé (prix * quantité)
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
