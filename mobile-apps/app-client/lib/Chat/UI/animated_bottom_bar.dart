import 'package:flutter/material.dart';
import 'package:hungerz/Themes/colors.dart'; // Assurez-vous que kMainColor est importé

// Définition de BarItem (inchangée)
class BarItem {
  String? text;
  String? image;
  BarItem({this.text, this.image});
}


// Le Widget Principal
class AnimatedBottomBar extends StatefulWidget {
  final List<BarItem>? barItems;
  final Function(int)? onBarTap; // Callback vers le parent
  final int currentIndex; // <-- Paramètre REQUIS reçu du parent

  const AnimatedBottomBar({
    Key? key, // Utiliser Key? key
    this.barItems,
    this.onBarTap,
    required this.currentIndex, // Reçoit l'index actif depuis HomeOrderAccount
  }) : super(key: key);

  @override
  _AnimatedBottomBarState createState() => _AnimatedBottomBarState();
}

// Le State (gardé car utilise TickerProviderStateMixin pour AnimatedSize)
class _AnimatedBottomBarState extends State<AnimatedBottomBar>
    with TickerProviderStateMixin { // Garder pour AnimatedSize

  // --- SUPPRESSION de l'état local pour l'index ---
  // int selectedBarIndex = widget.currentIndex; // <-- SUPPRIMÉ : On utilise widget.currentIndex directement
  // ----------------------------------------------

  Duration duration = Duration(milliseconds: 250); // Durée animation

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 10.0, // Ombre
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceAround, // Espacer les items
          children: _buildBarItems(), // Construit les items
        ),
      ),
    );
  }

  // Méthode pour construire les items de la barre
  List<Widget> _buildBarItems() {
    List<Widget> _barItemsWidget = []; // Liste pour contenir les widgets des items
    for (int i = 0; i < widget.barItems!.length; i++) { // Boucle sur les données des items
      BarItem item = widget.barItems![i]; // Item actuel

      // --- MODIFICATION : Utilise widget.currentIndex ---
      // Détermine si cet item (index i) est celui qui doit être sélectionné
      // en comparant avec l'index reçu du parent (widget.currentIndex)
      bool isSelected = (widget.currentIndex == i);
      // --------------------------------------------------

      _barItemsWidget.add(
        InkWell(
          splashColor: Colors.transparent, // Pas d'effet au clic
          onTap: () {
            // --- MODIFICATION : Pas de setState local ---
            // Informe juste le parent qu'un item a été cliqué, en passant son index 'i'
            if (widget.onBarTap != null) {
              widget.onBarTap!(i);
            }
            // -----------------------------------------
          },
          child: AnimatedContainer( // Container qui s'anime (couleur de fond)
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Padding interne
            duration: duration, // Durée de l'animation
            decoration: BoxDecoration(
                // Change la couleur de fond si sélectionné
                color: isSelected
                    ? kMainColor.withOpacity(0.1) // Couleur sélectionnée (adaptez)
                    : Colors.transparent, // Couleur non sélectionnée
                borderRadius: BorderRadius.all(Radius.circular(30))), // Coins arrondis
            child: Row( // Icône et Texte
              children: <Widget>[
                // Icône
                ImageIcon(
                  AssetImage(item.image!),
                  // Change la couleur de l'icône si sélectionné
                  color: isSelected
                      ? kMainColor // Couleur sélectionnée
                      : Theme.of(context).secondaryHeaderColor.withOpacity(0.7), // Couleur non sélectionnée (plus discrète)
                   // size: isSelected ? 26 : 24, // Optionnel: Agrandir l'icône si sélectionné
                ),
                SizedBox(width: isSelected ? 8.0 : 0), // Espace seulement si sélectionné

                // Texte (taille animée pour apparaître/disparaître)
                AnimatedSize(
                  duration: duration,
                  curve: Curves.easeOut, // Animation sympa
                  child: Text(
                    isSelected ? item.text! : "", // Affiche le texte seulement si sélectionné
                    style: Theme.of(context).textTheme.labelSmall!.copyWith( // Style plus petit pour la barre
                          fontWeight: FontWeight.bold, // Texte en gras
                          color: kMainColor, // Toujours la couleur principale ? Ou utiliser 'isSelected' ?
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return _barItemsWidget;
  }
}