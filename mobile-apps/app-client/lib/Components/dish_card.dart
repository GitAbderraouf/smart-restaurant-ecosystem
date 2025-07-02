// Dans votre fichier dish_card.dart ou équivalent

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hungerz/Themes/colors.dart';
// Assurez-vous d'importer votre modèle de plat (MenuItemModel ou Dish)
import 'package:hungerz/models/menu_item_model.dart';
// Importez la future page de détails
import 'package:hungerz/pages/dish_detail_page.dart'; // Adaptez le chemin

class DishCard extends StatelessWidget {
  // Utilisez le type de votre modèle de plat (MenuItemModel, Dish, etc.)
  final MenuItemModel dish;

  const DishCard({Key? key, required this.dish}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Le widget Card que vous aviez probablement déjà
    return Container(
      height: 150,
      margin: const EdgeInsets.only(right: 12.0),
      child: Card(
        color: Colors.white,
        clipBehavior: Clip.antiAlias, // Pour que l'image respecte les coins
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), // Ajout d'une marge
        child: InkWell( // --- Ajout de InkWell pour rendre cliquable ---
          onTap: () {
            // Action déclenchée au clic : Naviguer vers la page de détails
            print('Navigation vers les détails de: ${dish.name}');
            Navigator.push(
              context,
              MaterialPageRoute(
                // Construit la page de détails en lui passant l'objet 'dish' actuel
                builder: (context) => DishDetailPage(dish: dish),
              ),
            );
          },
          child: Row( // Votre contenu de carte existant
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image (gardez votre code Image.network existant)
              Image.network(
                 dish.image!, // Adaptez le nom du champ
                 width: 150, // Ajustez la hauteur si nécessaire
                 height: double.infinity,
                 fit: BoxFit.cover,
                 // N'oubliez pas errorBuilder et loadingBuilder pour une meilleure UX
                 errorBuilder: (context, error, stackTrace) => Container(height: 150, color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey)),
                 loadingBuilder: (context, child, loadingProgress) {
                   if (loadingProgress == null) return child;
                   return Container(width: 150, child: Center(child: CircularProgressIndicator()));
                 },
              ),
              // Informations sous l'image
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 12.0), // Ajoutez un espace vertical (ou utiliser Spacer(), height)
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
                            const SizedBox(height: 6.0),
                            Padding(
                              padding: const EdgeInsets.only(left:6.0),
                              child: Text('${dish.price} DA',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall!
                                      .copyWith(
                                          color: kLightTextColor, fontSize: 12.0)),
                            ),
                            const SizedBox(height:  6.0),
                            Padding(
                              padding: const EdgeInsets.only(left:4.0),
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
                            SizedBox(height: 6.0),
                            Padding(
                              padding: const EdgeInsets.only(left:6.0),
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
                ),
              // Vous pourriez même ajouter le bouton "Ajouter au panier" ici si désiré
              // Align(
              //    alignment: Alignment.centerRight,
              //    child: IconButton(...) // voir code précédent
              // )
            ],
          ),
        ),
      ),
    );
  }
}