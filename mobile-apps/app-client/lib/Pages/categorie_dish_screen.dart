// lib/pages/category_dishes_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/cubits/dishes_cubit/dishes_cubit.dart'; // Adaptez chemin // Adaptez chemin
import 'package:hungerz/models/menu_item_model.dart'; // Adaptez chemin/nom
import 'package:hungerz/Components/dish_card.dart'; // Adaptez chemin vers votre DishCard verticale/normale

class CategoryDishesPage extends StatelessWidget {
  // Ou int, selon votre modèle
  final String categoryName; // Pour afficher dans l'AppBar

  const CategoryDishesPage({
    super.key,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          categoryName,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(fontSize: 18),
        ), // Affiche le nom de la catégorie
        leading: IconButton(
          // Bouton retour standard
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<DishesCubit, DishesState>(
        builder: (context, state) {
          // --- Gérer les états de chargement et d'erreur ---
          if (state is DishesLoading || state is DishesInitial) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is DishesLoadFailure) {
            return Center(
                child: Text('Erreur de chargement des plats: ${state.error}'));
          }
          // --- État de succès : Filtrer et afficher les plats ---
          else if (state is DishesLoadSuccess) {
            // Filtrer la liste complète des plats pour ne garder que ceux de cette catégorie
            // Adaptez 'categoryId' au nom réel du champ dans votre MenuItemModel
            final List<MenuItemModel> categoryDishes = state.dishes
                .where((dish) =>
                    dish.category == categoryName.toLowerCase()) // Le filtrage clé !
                .toList();

            // --- Gérer le cas où aucun plat n'est trouvé pour cette catégorie ---
            if (categoryDishes.isEmpty) {
              return Center(
                child: Text(
                  'Aucun plat trouvé dans la catégorie "$categoryName".',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: Colors.grey),
                ),
              );
            }

            // --- Afficher la liste des plats de la catégorie ---
            // Utilise ListView.builder pour la performance si la liste peut être longue
            return ListView.builder(
              padding: const EdgeInsets.all(12.0), // Ajouter un peu de padding
              itemCount: categoryDishes.length,
              itemBuilder: (context, index) {
                final dish = categoryDishes[index];
                // Utilise la même DishCard que pour la liste "Tous nos plats"
                return DishCard(dish: dish);
              },
            );
          }
          // --- Fallback ---
          else {
            return const Center(child: Text('État inconnu.'));
          }
        },
      ),
    );
  }
}

// --- Assurez-vous que votre modèle MenuItemModel a un champ pour la catégorie ---
/*
class MenuItemModel {
  // ... autres champs: id, name, price, image, description, isPopular ...
  final String categoryId; // Ou int? Ou String categoryName;
  // final String? categoryName; // Optionnel, si vous ne le passez pas en argument

  MenuItemModel({
     // ... autres paramètres ...
     required this.categoryId,
     // this.categoryName,
  });
}
*/
