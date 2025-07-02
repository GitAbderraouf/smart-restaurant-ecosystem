import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hungerz/Themes/colors.dart';
import 'package:hungerz/models/menu_item_model.dart';
import 'package:hungerz/pages/dish_detail_page.dart';

class RecommendedDishCard extends StatelessWidget {
  final MenuItemModel dish; // Adaptez le type
  final bool showFlameIcon; // <-- Nouveau paramètre booléen

  const RecommendedDishCard({
    super.key,
    required this.dish,
    this.showFlameIcon = false, // <-- Valeur par défaut = false
  });

  @override
  Widget build(BuildContext context) {
    // Le Container externe définit la largeur fixe
    return Container(
      width: 200, // <-- Largeur Fixe ! Ajustez cette valeur selon votre design
      margin: const EdgeInsets.only(right: 12.0),
      child: Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          // Rendez-la cliquable aussi si vous voulez
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => DishDetailPage(dish: dish)),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Image.network(
                    dish.image ?? '', // Gestion null
                    height: 120, // Hauteur pour l'image
                    width: double.infinity, // Prend la largeur du Container (160)
                    fit: BoxFit.cover, // Important pour remplir
                    // ... errorBuilder, loadingBuilder ...
                  ),
                                    if (showFlameIcon) // S'affiche seulement si true
                    Positioned(
                      top: 1,
                      left: 1,
                      child: Container( // Petit fond pour mieux voir l'icône ? Optionnel
                         padding: EdgeInsets.all(2),
                         decoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                         ),
                        child: Icon(
                          Icons.local_fire_department, // Icône de feu/flamme
                          color: const Color.fromARGB(255, 255, 0, 0), // Couleur de la flamme
                          size: 25, // Taille de l'icône
                        ),),)
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize:
                                      14, // Base: titleMedium (assez grand) ou titleSmall
                                  fontWeight: FontWeight.bold,
                                ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Text('${dish.price} DA',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall!
                                .copyWith(
                                    color: kLightTextColor, fontSize: 12.0)),
                      ),
                      const SizedBox(height: 4.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 16),
                            SizedBox(width: 4),
                            Text(
                              "4.${Random().nextInt(10)}", // Exemple
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(width: 2),
                            Text(
                              ' (${Random().nextInt(300) + 100})', // Exemple
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey),
                            )
                          ],
                        ),
                      ),
                      SizedBox(height: 4.0),
                      Padding(
                        padding: const EdgeInsets.only(left: 6.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time, // Ou une autre icône
                              size:
                                  16.0, // Ajustez la taille (en pixels logiques)
                              color: Colors
                                  .grey[600], // Choisissez la couleur désirée
                            ),
                            SizedBox(width: 6),
                            Text('${dish.preparationTime} min',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
