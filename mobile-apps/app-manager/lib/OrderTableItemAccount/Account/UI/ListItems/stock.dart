// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hungerz_store/Themes/colors.dart'; // Vos couleurs
// import 'package:hungerz_store/cubits/manager_stock_cubit/manager_stock_cubit.dart'; // Ajustez le chemin
// import 'package:hungerz_store/models/ingredient_model.dart'; // Ajustez le chemin
// import 'package:flutter_animate/flutter_animate.dart';

// class StockPage extends StatefulWidget {
//   final String? highlightIngredientId;

//   const StockPage({Key? key, this.highlightIngredientId}) : super(key: key);

//   @override
//   _StockManagementPageState createState() => _StockManagementPageState();
// }

// class _StockManagementPageState extends State<StockPage> {
//   bool _isSearching = false;
//   final TextEditingController _searchQueryController = TextEditingController();
  
//   // _filteredCategorizedIngredients sera maintenant dérivé de l'état du Cubit lors de la recherche
//   Map<String, List<Ingredient>> _filteredCategorizedIngredients = {};

//   @override
//   void initState() {
//     super.initState();
//     _searchQueryController.addListener(_onSearchChanged);
    
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final stockCubit = context.read<ManagerStockCubit>();
//       if (stockCubit.state is ManagerStockInitial || 
//           (stockCubit.state is ManagerStockLoaded && (stockCubit.state as ManagerStockLoaded).allIngredients.isEmpty)) {
//         // Charger seulement si l'état est initial ou si chargé mais vide (ex: après une erreur puis retour)
//         stockCubit.fetchInitialStock().then((_) {
//           // Après le fetch initial, si on a un highlightId, on peut tenter de scroller
//           if (widget.highlightIngredientId != null && stockCubit.state is ManagerStockLoaded) {
//             _scrollToHighlightedItem((stockCubit.state as ManagerStockLoaded).allIngredients);
//           }
//         });
//       } else if (stockCubit.state is ManagerStockLoaded) {
//         // Si déjà chargé, initialiser le filtre avec les données actuelles du Cubit
//         _initializeAndFilter((stockCubit.state as ManagerStockLoaded).categorizedIngredients, "");
//          if (widget.highlightIngredientId != null) {
//            _scrollToHighlightedItem((stockCubit.state as ManagerStockLoaded).allIngredients);
//          }
//       }
//     });
//   }

//   // Méthode pour initialiser et appliquer le filtre
//   void _initializeAndFilter(Map<String, List<Ingredient>>? originalData, String query) {
//     if (originalData == null) {
//       if (mounted) setState(() => _filteredCategorizedIngredients = {});
//       return;
//     }

//     if (query.isEmpty) {
//       if (mounted) setState(() => _filteredCategorizedIngredients = Map.from(originalData));
//       return;
//     }

//     final lowerCaseQuery = query.toLowerCase();
//     Map<String, List<Ingredient>> filteredMap = {};

//     originalData.forEach((category, ingredients) {
//       List<Ingredient> matchingIngredients = ingredients
//           .where((item) => item.name.toLowerCase().contains(lowerCaseQuery))
//           .toList();
//       if (matchingIngredients.isNotEmpty) {
//         filteredMap[category] = matchingIngredients;
//       }
//     });

//     if (mounted) setState(() => _filteredCategorizedIngredients = filteredMap);
//   }

//   void _scrollToHighlightedItem(List<Ingredient> allIngredients) {
//     // TODO: Implémenter la logique de défilement si un ScrollController est utilisé avec CustomScrollView
//     // Pour cela, il faudrait un GlobalKey pour chaque item ou une logique plus complexe
//     // pour calculer la position de défilement.
//     // Pour l'instant, on peut juste logguer ou styler l'item différemment (déjà fait via ListTile.tileColor).
//     debugPrint("Tentative de mise en évidence (défilement non implémenté) pour : ${widget.highlightIngredientId}");
//   }

//   @override
//   void dispose() {
//     _searchQueryController.removeListener(_onSearchChanged);
//     _searchQueryController.dispose();
//     super.dispose();
//   }

//   void _onSearchChanged() {
//     final currentState = context.read<ManagerStockCubit>().state;
//     if (currentState is ManagerStockLoaded) {
//       _initializeAndFilter(currentState.categorizedIngredients, _searchQueryController.text);
//     }
//   }

//   Future<void> _refreshStockData() async {
//     // Clear search on refresh
//     // if (_isSearching || _searchQueryController.text.isNotEmpty) {
//     //   _searchQueryController.clear(); // Cela appellera _onSearchChanged qui réinitialisera le filtre
//     //   if (_isSearching) setState(() => _isSearching = false);
//     // }
//     await context.read<ManagerStockCubit>().fetchInitialStock();
//     // Le listener du BlocConsumer s'occupera de réinitialiser _filteredCategorizedIngredients
//   }

//   AppBar _buildAppBar(BuildContext context) {
//     final theme = Theme.of(context);
//     if (_isSearching) {
//       return AppBar(
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: kMainColor),
//           onPressed: () {
//             setState(() {
//               _isSearching = false;
//               _searchQueryController.clear(); // _onSearchChanged sera appelé par le listener
//             });
//           },
//         ),
//         title: TextField(
//           controller: _searchQueryController,
//           autofocus: true,
//           decoration: InputDecoration(
//             hintText: 'Rechercher ingrédients...',
//             border: InputBorder.none,
//             hintStyle: TextStyle(color: kLightTextColor),
//           ),
//           style: TextStyle(color: kMainTextColor, fontSize: 16),
//         ),
//         backgroundColor: theme.scaffoldBackgroundColor,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.close, color: kMainColor),
//             onPressed: () {
//               if (_searchQueryController.text.isEmpty) {
//                 setState(() { _isSearching = false; });
//               } else {
//                 _searchQueryController.clear(); // _onSearchChanged sera appelé
//               }
//             },
//           ),
//         ],
//       );
//     } else {
//       return AppBar(
//         title: Text('Inventaire', style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
//         backgroundColor: theme.scaffoldBackgroundColor,
//         elevation: 0,
//         actions: [
//           IconButton(
//             icon: Icon(Icons.search, color: kMainColor),
//             onPressed: () => setState(() => _isSearching = true),
//           ),
//         ],
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: _buildAppBar(context),
//       body: RefreshIndicator(
//         color: kMainColor,
//         onRefresh: _refreshStockData,
//         child: BlocConsumer<ManagerStockCubit, ManagerStockState>(
//           listener: (context, state) {
//             if (state is ManagerStockLoaded) {
//               // Mettre à jour les données filtrées chaque fois que les données chargées changent
//               _initializeAndFilter(state.categorizedIngredients, _searchQueryController.text);
//               if (widget.highlightIngredientId != null && state.allIngredients.isNotEmpty) {
//                  _scrollToHighlightedItem(state.allIngredients);
//               }
//             } else if (state is ManagerStockError) {
//                 // Optionnel: Afficher un SnackBar pour les erreurs si elles ne sont pas bloquantes
//                 // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
//             }
//           },
//           builder: (context, state) {
//             if (state is ManagerStockInitial || state is ManagerStockLoading && _filteredCategorizedIngredients.isEmpty) {
//               return Center(
//                 child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kMainColor))
//                     .animate().fadeIn(duration: 400.ms).scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)),
//               );
//             } else if (state is ManagerStockError && _filteredCategorizedIngredients.isEmpty) {
//               return _buildErrorState(state.message);
//             } else if (state is ManagerStockLoaded || (_filteredCategorizedIngredients.isNotEmpty && state is! ManagerStockError) ) {
//               // Afficher les données, qu'elles viennent de StockLoaded ou d'un filtre sur un état précédent
//               final ManagerStockLoaded? loadedState = state is ManagerStockLoaded ? state : null;
              
//               // Utiliser _filteredCategorizedIngredients pour l'affichage
//               final Map<String, List<Ingredient>> displayCategories = _filteredCategorizedIngredients;

//               final int totalIngredients = loadedState?.totalIngredientsCount ?? 
//                                           displayCategories.values.fold(0, (prev, list) => prev + list.length);
//               final int lowStockCount = loadedState?.lowStockIngredientsCount ?? 
//                                         displayCategories.values.fold(0, (prev, list) => 
//                                             prev + list.where((item) => item.lowStockThreshold > 0 && item.stock <= item.lowStockThreshold).length);


//               if (displayCategories.isEmpty && _searchQueryController.text.isNotEmpty) {
//                 return CustomScrollView(slivers: [SliverToBoxAdapter(child: _buildSearchEmptyState())]);
//               }
//               if (displayCategories.isEmpty && _searchQueryController.text.isEmpty && loadedState != null && loadedState.allIngredients.isEmpty) {
//                 return _buildEmptyState();
//               }
//                if (displayCategories.isEmpty && _searchQueryController.text.isEmpty && loadedState == null && !(state is ManagerStockLoading)) {
//                  // Cas où l'état n'est pas encore chargé et pas d'erreur, mais on n'a rien à filtrer
//                 return Center(child: Text("Aucune donnée de stock à afficher. Tirez pour rafraîchir."));
//               }


//               return CustomScrollView(
//                 physics: BouncingScrollPhysics(),
//                 slivers: [
//                   SliverPadding(
//                     padding: EdgeInsets.all(16),
//                     sliver: SliverToBoxAdapter(
//                       child: _buildHeaderStats(totalIngredients, lowStockCount)
//                           .animate().fadeIn(duration: 400.ms, delay: 100.ms)
//                           .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
//                     ),
//                   ),
//                   SliverPadding(
//                     padding: EdgeInsets.symmetric(horizontal: 16),
//                     sliver: SliverList(
//                       delegate: SliverChildBuilderDelegate(
//                         (context, index) {
//                           if (index >= displayCategories.length) return null;
//                           final entry = displayCategories.entries.elementAt(index);
//                           final String category = entry.key;
//                           final List<Ingredient> ingredients = entry.value; 
//                           return _buildCategorySection(category, ingredients, index);
//                         },
//                         childCount: displayCategories.length,
//                       ),
//                     ),
//                   ),
//                   SliverPadding(padding: EdgeInsets.only(bottom: 80)),
//                 ],
//               );
//             }
//             return Center(child: Text("Attente de l'état du stock...")); // État par défaut
//           },
//         ),
//       ),
//       floatingActionButton: FloatingActionButton( // Exemple de FAB pour ajouter
//         onPressed: _showAddStockDialog,
//         backgroundColor: kMainColor,
//         child: Icon(Icons.add, color: Colors.white),
//         tooltip: 'Ajouter Ingrédient',
//       ).animate().scale(delay: 1.seconds),
//     );
//   }

//   Widget _buildSearchEmptyState() {
//      return Padding(
//         padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(Icons.search_off, size: 60, color: kLightTextColor),
//               SizedBox(height: 16),
//               Text(
//                 'Aucun ingrédient trouvé pour "${_searchQueryController.text}"',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 16, color: kMainTextColor),
//               ),
//             ],
//           )
//         ).animate().fadeIn(),
//       );
//   }

//   Widget _buildHeaderStats(int totalIngredients, int lowStockCount) {
//     return Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [kMainColor.withOpacity(0.9), kMainColor],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(16),
//         boxShadow: [
//           BoxShadow(color: kMainColor.withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4)),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text('Aperçu de l\'Inventaire', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
//             SizedBox(height: 16),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 _buildStatCard('Total', totalIngredients.toString(), Icons.category_outlined, Colors.white.withOpacity(0.9)),
//                 _buildStatCard('Stock Bas', lowStockCount.toString(), Icons.warning_amber_rounded, Colors.red[100]!, textColor: Colors.red[800]),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, {Color? textColor}) {
//     return Container(
//       width: MediaQuery.of(context).size.width * 0.4 - 20, // Ajuster pour le padding
//       padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: [
//             Icon(icon, color: textColor ?? kMainTextColor /*kMainColor était ici, change pour cohérence*/, size: 18),
//             SizedBox(width: 8),
//             Text(title, style: TextStyle(color: textColor ?? kMainTextColor, fontWeight: FontWeight.w500, fontSize: 13)),
//           ]),
//           SizedBox(height: 6),
//           Text(value, style: TextStyle(color: textColor ?? kMainTextColor, fontWeight: FontWeight.bold, fontSize: 22)),
//         ],
//       ),
//     );
//   }

//   Widget _buildCategorySection(String category, List<Ingredient> ingredients, int categoryIndex) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Padding(
//           padding: const EdgeInsets.only(top: 24.0, bottom: 12.0),
//           child: Row(children: [
//             Container(width: 4, height: 20, decoration: BoxDecoration(color: kMainColor, borderRadius: BorderRadius.circular(2))),
//             SizedBox(width: 8),
//             Text(category, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kMainTextColor)),
//             SizedBox(width: 8),
//             Text('(${ingredients.length})', style: TextStyle(fontSize: 16, color: kLightTextColor)),
//           ]),
//         ).animate().fadeIn(duration: 400.ms, delay: (150 + categoryIndex * 50).ms) // Réduit le délai pour les catégories
//                .slideX(begin: -0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
//         ListView.builder(
//           shrinkWrap: true,
//           physics: NeverScrollableScrollPhysics(),
//           itemCount: ingredients.length,
//           itemBuilder: (context, idx) {
//             final ingredient = ingredients[idx];
//             final bool isLowStock = ingredient.lowStockThreshold > 0 && ingredient.stock <= ingredient.lowStockThreshold;
//             final bool isHighlighted = ingredient.id == widget.highlightIngredientId;

//             return _buildStockItem(ingredient, isLowStock, isHighlighted, idx, categoryIndex)
//                 .animate()
//                 .fadeIn(duration: 300.ms, delay: Duration(milliseconds: 200 + (idx * 30) + (categoryIndex * 50))) // Réduit les délais
//                 .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutQuad);
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildStockItem(Ingredient ingredient, bool isLowStock, bool isHighlighted, int itemIndex, int categoryIndex) {
//     return Hero(
//       tag: 'stock_item_${ingredient.id}',
//       child: Card(
//         margin: EdgeInsets.only(bottom: 10),
//         elevation: isHighlighted ? 4 : 1, // Plus d'élévation si en surbrillance
//         color: isHighlighted ? kMainColor.withOpacity(0.15) : null, // Couleur de fond si en surbrillance
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//           side: isLowStock && !isHighlighted
//             ? BorderSide(color: Colors.red.withOpacity(0.3), width: 1)
//             : (isHighlighted ? BorderSide(color: kMainColor, width: 1.5) : BorderSide.none),
//         ),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(12),
//           onTap: () {
//              _showEditStockDialog(ingredient);
//           },
//           child: Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Row(children: [
//               AnimatedContainer(
//                 duration: Duration(milliseconds: 300),
//                 width: isLowStock ? 8 : 6,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   color: isLowStock ? Colors.red : Colors.green,
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(ingredient.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
//                     SizedBox(height: 4),
//                     Text('Stock: ${ingredient.stock.toStringAsFixed(1)} ${ingredient.unit}', style: TextStyle(color: kTextColor, fontSize: 14)),
//                      if (ingredient.lowStockThreshold > 0) // Afficher le seuil s'il est défini
//                       Text('Seuil bas: ${ingredient.lowStockThreshold.toStringAsFixed(1)} ${ingredient.unit}', style: TextStyle(color: kLightTextColor, fontSize: 12)),
//                   ],
//                 ),
//               ),
//               if (isLowStock)
//                 Container(
//                   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                   decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
//                   child: Row(children: [
//                     Icon(Icons.warning, color: Colors.red, size: 16),
//                     SizedBox(width: 4),
//                     Text('Bas', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
//                   ]),
//                 ),
//             ]),
//           ),
//         ),
//       ),
//     );
//   }

//   void _showAddStockDialog() {
//     // TODO: Implémenter la logique pour ajouter un ingrédient via le Cubit -> Service API -> Backend
//     // Pour l'instant, affiche un message
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Fonctionnalité d'ajout d'ingrédient à implémenter.")));
//     debugPrint("Afficher la boîte de dialogue pour ajouter un stock");
//   }

//   void _showEditStockDialog(Ingredient ingredient) {
//     // TODO: Implémenter la logique pour modifier un ingrédient via le Cubit -> Service API -> Backend
//     // Ou, si le gérant ne peut pas modifier le stock, cette fonction pourrait afficher plus de détails.
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Affichage/Édition de ${ingredient.name} à implémenter.")));
//     debugPrint("Afficher la boîte de dialogue pour modifier: ${ingredient.name}");
//   }

//   Widget _buildEmptyState() {
//      return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.inventory_2_outlined, size: 80, color: kLightTextColor)
//               .animate().scale(duration: 600.ms, curve: Curves.elasticOut).fadeIn(duration: 400.ms),
//           SizedBox(height: 16),
//           Text('Aucun ingrédient dans l\'inventaire', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kMainTextColor))
//               .animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
//           SizedBox(height: 8),
//           Text('Ajoutez votre premier ingrédient pour commencer.', style: TextStyle(color: kLightTextColor))
//               .animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
//           SizedBox(height: 24),
//           ElevatedButton.icon(
//             icon: Icon(Icons.add),
//             label: Text('Ajouter Ingrédient'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: kMainColor, foregroundColor: Colors.white,
//               padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//             ),
//             onPressed: _showAddStockDialog,
//           ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState(String error) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(Icons.error_outline, size: 80, color: Colors.red[300])
//               .animate().scale(duration: 600.ms, curve: Curves.elasticOut).fadeIn(duration: 400.ms),
//           SizedBox(height: 16),
//           Text('Oops! Un problème est survenu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kMainTextColor))
//               .animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
//           SizedBox(height: 8),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 32.0),
//             child: Text(error, textAlign: TextAlign.center, style: TextStyle(color: kLightTextColor)),
//           ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
//           SizedBox(height: 24),
//           ElevatedButton.icon(
//             icon: Icon(Icons.refresh),
//             label: Text('Réessayer'),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: kMainColor, foregroundColor: Colors.white,
//               padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
//             ),
//             onPressed: _refreshStockData,
//           ).animate().fadeIn(duration: 400.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),
//         ],
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/Themes/colors.dart'; // Vos couleurs
import 'package:hungerz_store/cubits/manager_stock_cubit/manager_stock_cubit.dart'; // Ajustez le chemin
import 'package:hungerz_store/models/ingredient_model.dart'; // Ajustez le chemin
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart'; // Pour le formatage de la date
import 'package:collection/collection.dart'; // For firstWhereOrNull

class StockPage extends StatefulWidget {
  final String? highlightIngredientId;

  const StockPage({Key? key, this.highlightIngredientId}) : super(key: key);

  @override
  _StockManagementPageState createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockPage> {
  bool _isSearching = false;
  final TextEditingController _searchQueryController = TextEditingController();
  Map<String, List<Ingredient>> _filteredCategorizedIngredients = {};
  final ScrollController _scrollController = ScrollController();

  // Pour stocker l'ingrédient qui a déclenché l'alerte et la navigation
  Ingredient? _alertedIngredientOnPageLoad;

  @override
  void initState() {
    super.initState();
    _searchQueryController.addListener(_onSearchChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stockCubit = context.read<ManagerStockCubit>();
      if (stockCubit.state is ManagerStockInitial ||
          (stockCubit.state is ManagerStockLoaded &&
              (stockCubit.state as ManagerStockLoaded)
                  .allIngredients
                  .isEmpty)) {
        stockCubit.fetchInitialStock().then((_) {
          _checkAndSetAlertedIngredientOnLoad(stockCubit.state);
          if (_alertedIngredientOnPageLoad != null && mounted) { // Check mounted
             _scrollToHighlightedItem(
                (stockCubit.state as ManagerStockLoaded).categorizedIngredients,
                isAlertedItemAtTop: true);
          }
        });
      } else if (stockCubit.state is ManagerStockLoaded) {
        _initializeAndFilter(
            (stockCubit.state as ManagerStockLoaded).categorizedIngredients,
            "");
        _checkAndSetAlertedIngredientOnLoad(stockCubit.state);
        if (_alertedIngredientOnPageLoad != null && mounted) { // Check mounted
          _scrollToHighlightedItem(
              (stockCubit.state as ManagerStockLoaded).categorizedIngredients,
              isAlertedItemAtTop: true);
        }
      }
    });
  }

  void _checkAndSetAlertedIngredientOnLoad(ManagerStockState state) {
    if (widget.highlightIngredientId != null && state is ManagerStockLoaded) {
      final potentialHighlight = state.allIngredients
          .firstWhereOrNull((ing) => ing.id == widget.highlightIngredientId);
      if (potentialHighlight != null &&
          state.lowStockIngredients
              .any((lowIng) => lowIng.id == potentialHighlight.id)) {
        if (mounted) {
          setState(() {
            _alertedIngredientOnPageLoad = potentialHighlight;
          });
        }
      } else { // If not low stock anymore, or not found, clear it
        if (mounted && _alertedIngredientOnPageLoad?.id == widget.highlightIngredientId) {
           setState(() {
            _alertedIngredientOnPageLoad = null;
          });
        }
      }
    } else if (widget.highlightIngredientId == null && _alertedIngredientOnPageLoad != null) {
        // If highlightIngredientId becomes null (e.g. navigating back without highlight), clear alerted item
        if (mounted) {
           setState(() {
            _alertedIngredientOnPageLoad = null;
          });
        }
    }
  }


  void _initializeAndFilter(
      Map<String, List<Ingredient>>? originalData, String query) {
    if (!mounted) return;

    if (originalData == null) {
      setState(() => _filteredCategorizedIngredients = {});
      return;
    }

    if (query.isEmpty) {
      setState(() => _filteredCategorizedIngredients = Map.from(originalData));
      return;
    }

    final lowerCaseQuery = query.toLowerCase();
    Map<String, List<Ingredient>> filteredMap = {};

    originalData.forEach((category, ingredients) {
      List<Ingredient> matchingIngredients = ingredients
          .where((item) => item.name.toLowerCase().contains(lowerCaseQuery))
          .toList();
      if (matchingIngredients.isNotEmpty) {
        filteredMap[category] = matchingIngredients;
      }
    });

    setState(() => _filteredCategorizedIngredients = filteredMap);
  }

  void _scrollToHighlightedItem(Map<String, List<Ingredient>> categories, {bool isAlertedItemAtTop = false}) {
    if (!_scrollController.hasClients || !mounted) return;

    if (isAlertedItemAtTop && _alertedIngredientOnPageLoad != null) {
      _scrollController.animateTo(
        0.0,
        duration: Duration(milliseconds: 700),
        curve: Curves.easeInOutQuad,
      );
      debugPrint("Défilement vers l'alerte en haut de page pour: ${_alertedIngredientOnPageLoad!.name}");
      return;
    }
    
    if (widget.highlightIngredientId == null || categories.isEmpty) return;
    // Only scroll if the highlighted item is NOT the one at the top
    if (_alertedIngredientOnPageLoad != null && widget.highlightIngredientId == _alertedIngredientOnPageLoad!.id) return;


    double offset = 0.0;
    bool found = false;
    // Approximations, peuvent nécessiter un ajustement fin ou une approche avec GlobalKey
    const double categoryHeaderHeight = 70.0; 
    const double itemHeight = 180.0; // Augmenté un peu pour la marge
    const double alertSectionHeight = 250.0; // Hauteur approximative de la section d'alerte

    if (_alertedIngredientOnPageLoad != null) {
        offset += alertSectionHeight; // Compter la hauteur de la section d'alerte si elle est présente
    }
    offset += 150; // Hauteur approximative du _buildHeaderStats

    for (var entry in categories.entries) {
      // Si l'alerte est en haut, et que la catégorie de l'alerte est vide après filtrage, ne pas compter son header
      if (_alertedIngredientOnPageLoad != null && entry.key == _alertedIngredientOnPageLoad!.category && entry.value.isEmpty) {
        // Ne rien faire
      } else if (entry.value.isNotEmpty) { // Ne compter que si la catégorie a des items (après filtrage de l'alerte)
        offset += categoryHeaderHeight;
      }
      
      for (var ingredient in entry.value) {
        if (ingredient.id == widget.highlightIngredientId) {
          found = true;
          break;
        }
        offset += itemHeight;
      }
      if (found) break;
    }

    if (found) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      // Viser un peu avant l'item pour qu'il ne soit pas collé en haut
      final targetOffset = (offset - itemHeight).clamp(0.0, maxScroll); 

      _scrollController.animateTo(
        targetOffset,
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOutQuad,
      );
      debugPrint("Défilement vers ${widget.highlightIngredientId} (dans la liste) à l'offset approx $targetOffset");
    }
  }


  @override
  void dispose() {
    _searchQueryController.removeListener(_onSearchChanged);
    _searchQueryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final currentState = context.read<ManagerStockCubit>().state;
    if (currentState is ManagerStockLoaded) {
      _initializeAndFilter(
          currentState.categorizedIngredients, _searchQueryController.text);
    }
  }

  Future<void> _refreshStockData() async {
    if (!mounted) return;
    // Optionnel: réinitialiser l'alerte avant de rafraîchir si on veut qu'elle disparaisse
    // setState(() { _alertedIngredientOnPageLoad = null; });
    await context.read<ManagerStockCubit>().fetchInitialStock().then((_){
        if (mounted) {
          _checkAndSetAlertedIngredientOnLoad(context.read<ManagerStockCubit>().state);
        }
    });
  }

  AppBar _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    if (_isSearching) {
      return AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: kMainColor),
          onPressed: () {
            if (!mounted) return;
            setState(() {
              _isSearching = false;
              _searchQueryController.clear(); // _onSearchChanged est appelé par le listener
            });
          },
        ),
        title: TextField(
          controller: _searchQueryController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Rechercher ingrédients...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: kLightTextColor),
          ),
          style: TextStyle(color: kMainTextColor, fontSize: 16),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
           IconButton(
            icon: Icon(Icons.close, color: kMainColor),
            onPressed: () {
              if (_searchQueryController.text.isEmpty) {
                if (!mounted) return;
                setState(() { _isSearching = false; });
              } else {
                _searchQueryController.clear(); // _onSearchChanged sera appelé
              }
            },
          ),
        ],
      );
    } else {
      return AppBar(
        title: Text('Inventaire des Ingrédients',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)), // Utiliser titleLarge pour plus d'emphase
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0, // Ou une légère élévation si vous préférez: theme.appBarTheme.elevation ?? 1.0
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: kMainColor, size: 26),
            onPressed: () {
              if (!mounted) return;
              setState(() => _isSearching = true);
            },
          ),
           IconButton( // Bouton de rafraîchissement direct
            icon: Icon(Icons.refresh_rounded, color: kMainColor, size: 26),
            onPressed: _refreshStockData,
            tooltip: "Rafraîchir l'inventaire",
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: kMainColor,
        onRefresh: _refreshStockData,
        child: BlocConsumer<ManagerStockCubit, ManagerStockState>(
          listener: (context, state) {
            if (state is ManagerStockLoaded) {
              _initializeAndFilter(state.categorizedIngredients, _searchQueryController.text);
               if(mounted) { // S'assurer que le widget est toujours monté
                // Mettre à jour l'état de l'alerte en haut si l'ID de highlight change ou si le stock de l'item change
                _checkAndSetAlertedIngredientOnLoad(state);
                // Si l'alerte est active, s'assurer qu'on est en haut
                if (_alertedIngredientOnPageLoad != null) {
                   _scrollToHighlightedItem(state.categorizedIngredients, isAlertedItemAtTop: true);
                }
              }
            } else if (state is ManagerStockError) {
                if(mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Erreur: ${state.message}"), backgroundColor: Colors.redAccent)
                    );
                }
            }
          },
          builder: (context, state) {
            if (state is ManagerStockInitial ||
                (state is ManagerStockLoading && _filteredCategorizedIngredients.isEmpty && _alertedIngredientOnPageLoad == null)) {
              return Center( child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(kMainColor))
                    .animate().fadeIn(duration: 400.ms).scale(begin: Offset(0.8, 0.8), end: Offset(1.0, 1.0)), );
            } else if (state is ManagerStockError && _filteredCategorizedIngredients.isEmpty && _alertedIngredientOnPageLoad == null) {
              return _buildErrorState(state.message);
            } else if (state is ManagerStockLoaded || _alertedIngredientOnPageLoad != null || (_filteredCategorizedIngredients.isNotEmpty && state is! ManagerStockError)) {
              
              final ManagerStockLoaded? loadedState = state is ManagerStockLoaded ? state : null;
              
              Ingredient? actualItemToHighlightAtTop = _alertedIngredientOnPageLoad;
              if (loadedState != null && actualItemToHighlightAtTop != null) {
                bool stillLowStock = loadedState.lowStockIngredients.any((ing) => ing.id == actualItemToHighlightAtTop!.id);
                if (!stillLowStock) {
                  actualItemToHighlightAtTop = null; 
                  // Si l'item n'est plus en stock bas, on pourrait vouloir réinitialiser _alertedIngredientOnPageLoad
                  // Cependant, _checkAndSetAlertedIngredientOnLoad dans le listener devrait s'en charger.
                }
              }


              List<Widget> slivers = [];

              if (actualItemToHighlightAtTop != null) {
                debugPrint("Build: Ajout de _buildHighlightedLowStockItemSection pour ${actualItemToHighlightAtTop.name}"); // <--- AJOUTEZ CECI
              
                slivers.add(SliverToBoxAdapter(
                  child: _buildHighlightedLowStockItemSection(actualItemToHighlightAtTop),
                ));
              }

              final int totalIngredients = loadedState?.totalIngredientsCount ?? _filteredCategorizedIngredients.values.fold(0, (prev, list) => prev + list.length);
              final int lowStockCount = loadedState?.lowStockIngredientsCount ?? _filteredCategorizedIngredients.values.fold(0, (prev, list) => prev + list.where((item) => item.lowStockThreshold > 0 && item.stock <= item.lowStockThreshold).length);
              
              slivers.add(SliverPadding(
                padding: EdgeInsets.fromLTRB(16, actualItemToHighlightAtTop != null ? 10 : 16 ,16,20),
                sliver: SliverToBoxAdapter(
                  child: _buildHeaderStats(totalIngredients, lowStockCount)
                      .animate().fadeIn(duration: 400.ms, delay: actualItemToHighlightAtTop != null ? 50.ms : 100.ms) // Délai plus court si alerte
                      .slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOutQuad),
                ),
              ));

              Map<String, List<Ingredient>> categoriesForDisplayList = Map.from(_filteredCategorizedIngredients);
              if (actualItemToHighlightAtTop != null) {
                String categoryOfHighlighted = actualItemToHighlightAtTop.category;
                if (categoriesForDisplayList.containsKey(categoryOfHighlighted)) {
                  categoriesForDisplayList[categoryOfHighlighted] = 
                      categoriesForDisplayList[categoryOfHighlighted]!
                          .where((ing) => ing.id != actualItemToHighlightAtTop!.id)
                          .toList();
                  if (categoriesForDisplayList[categoryOfHighlighted]!.isEmpty) {
                    categoriesForDisplayList.remove(categoryOfHighlighted);
                  }
                }
              }
              
              if (categoriesForDisplayList.isEmpty && _searchQueryController.text.isNotEmpty && actualItemToHighlightAtTop == null) {
                 return CustomScrollView(controller: _scrollController, slivers: [SliverToBoxAdapter(child: _buildSearchEmptyState())]);
              }
              if (categoriesForDisplayList.isEmpty && _searchQueryController.text.isEmpty && loadedState != null && loadedState.allIngredients.isEmpty && actualItemToHighlightAtTop == null) {
                return _buildEmptyState();
              }
              // Si seulement l'alerte est affichée et rien d'autre
              if (categoriesForDisplayList.isEmpty && actualItemToHighlightAtTop != null && _searchQueryController.text.isEmpty) {
                // Ne rien ajouter de plus, la section d'alerte et les stats sont déjà dans slivers.
                // On pourrait ajouter un message "Aucun autre ingrédient" si besoin.
              } else {
                 slivers.add(SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index >= categoriesForDisplayList.length) return null;
                      final entry = categoriesForDisplayList.entries.elementAt(index);
                      return _buildCategorySection(entry.key, entry.value, index);
                    },
                    childCount: categoriesForDisplayList.length,
                  ),
                ));
              }
              
              slivers.add(SliverPadding(padding: EdgeInsets.only(bottom: 80)));

              return CustomScrollView(
                controller: _scrollController,
                physics: BouncingScrollPhysics(),
                slivers: slivers,
              );
            }
            return Center(child: Text("Attente de l'état du stock..."));
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddStockDialog,
        backgroundColor: kMainColor,
        icon: Icon(Icons.add_circle_outline_rounded, color: Colors.white),
        label: Text("Ajouter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        tooltip: 'Ajouter Ingrédient',
      ).animate().scale(delay: 1.seconds, duration: 500.ms, curve: Curves.elasticOut),
    );
  }

Widget _buildSimpleAlertItemDisplay(Ingredient ingredient, BuildContext context) {
  final theme = Theme.of(context);

  // Logique de statut et couleur (similaire à _buildStockItem)
  // Pour l'alerte, on considère toujours que c'est un état critique/stock bas
  final Color stockLevelColor = Colors.red.shade700;
  final String stockStatusText = "STOCK BAS";
  final IconData stockStatusIcon = Icons.warning_amber_rounded;
  final bool isActuallyLowStock = true; // Car c'est pour la section d'alerte

  final double stockPercentage = ingredient.lowStockThreshold > 0 && ingredient.stock > 0
      ? (ingredient.stock / (ingredient.lowStockThreshold * 1.5)).clamp(0.0, 1.0)
      : (ingredient.stock > 0 ? 1.0 : 0.0);

  String lastUpdateText = "Date de MàJ inconnue";
  if (ingredient.updatedAt != null) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCompare = DateTime(ingredient.updatedAt!.year,
        ingredient.updatedAt!.month, ingredient.updatedAt!.day);

    if (dateToCompare == today) {
      lastUpdateText =
          "MàJ Aujourd'hui à ${DateFormat.Hm().format(ingredient.updatedAt!)}";
    } else if (dateToCompare == yesterday) {
      lastUpdateText =
          "MàJ Hier à ${DateFormat.Hm().format(ingredient.updatedAt!)}";
    } else {
      lastUpdateText =
          "MàJ le ${DateFormat('dd/MM/yy HH:mm').format(ingredient.updatedAt!)}";
    }
  }

  return Container(
    // Le Container parent dans _buildHighlightedLowStockItemSection gère le fond principal de l'alerte.
    // Ce Container interne est plus pour la structure du contenu.
    padding: EdgeInsets.symmetric(vertical: 8.0), // Léger padding interne
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nom et Catégorie, avec la puce de statut
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ingredient.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 19, // Un peu plus grand pour l'alerte
                      color: kMainTextColor, // Ou une couleur spécifique pour l'alerte
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Catégorie: ${ingredient.category}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: kLightTextColor,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Container( // Puce de statut
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: stockLevelColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: stockLevelColor.withOpacity(0.5), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(stockStatusIcon, color: stockLevelColor, size: 15),
                  SizedBox(width: 5),
                  Text(
                    stockStatusText,
                    style: TextStyle(
                        color: stockLevelColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),

        // Stock Actuel vs Seuil Bas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actuel:',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: kLightTextColor, fontSize: 13),
                ),
                SizedBox(height: 2),
                Text(
                  '${ingredient.stock.toStringAsFixed(1)} ${ingredient.unit}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: stockLevelColor), // Couleur d'alerte pour le stock
                ),
              ],
            ),
            if (ingredient.lowStockThreshold > 0)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Seuil Bas:',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: kLightTextColor, fontSize: 13),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '${ingredient.lowStockThreshold.toStringAsFixed(1)} ${ingredient.unit}',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        // Couleur d'alerte si stock bas, sinon couleur normale
                        color: isActuallyLowStock
                            ? Colors.red.shade700
                            : kTextColor),
                  ),
                ],
              ),
          ],
        ),
        SizedBox(height: 12),

        // Barre de progression
        if (ingredient.lowStockThreshold > 0 || ingredient.stock > 0)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: stockPercentage,
              backgroundColor: kLightTextColor.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(stockLevelColor), // Couleur d'alerte
              minHeight: 10,
            ),
          ),
        SizedBox(height: 14),

        // Date de mise à jour
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            lastUpdateText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: kLightTextColor.withOpacity(0.8),
              fontStyle: FontStyle.italic,
            ),
          ),
        )
      ],
    ),
  );
}

  Widget _buildHighlightedLowStockItemSection(Ingredient ingredient) {
    return Container(
      margin: const EdgeInsets.only(left:16, right:16, top:16, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:Colors.red.shade50,
        borderRadius: BorderRadius.circular(20), // Bords plus arrondis
        border: Border.all(color: Colors.red.shade300, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.15), blurRadius: 10, offset: Offset(0,5)) // Ombre plus douce
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.crisis_alert_rounded, color: Colors.red.shade700, size: 30), // Icône plus grande
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "ALERTE - STOCK CRITIQUE !",
                  style: TextStyle(
                    fontSize: 19, // Taille augmentée
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade800,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16), // Plus d'espace
          _buildSimpleAlertItemDisplay(ingredient, context),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: -0.25, end: 0, curve: Curves.easeOutBack); // Animation plus prononcée
  }

  Widget _buildStockItem(Ingredient ingredient, bool isHighlightedActuallyOnCard, int itemIndex, int categoryIndex, {bool isSpecialAlert = false}) {
    final theme = Theme.of(context);
    if (isSpecialAlert ) {
      // Si c'est une alerte spéciale mais qu'il n'y a pas de seuil bas, on ne l'affiche pas
      debugPrint("Dans _buildStockItem - Nom: '${ingredient.name}', Cat: '${ingredient.category}'");
    }
    final double stockPercentage = ingredient.lowStockThreshold > 0 && ingredient.stock > 0
        ? (ingredient.stock / (ingredient.lowStockThreshold * 1.5)).clamp(0.0, 1.0) 
        : (ingredient.stock > 0 ? 1.0 : 0.0);

    Color stockLevelColor = Colors.green.shade600;
    String stockStatusText = "OK";
    IconData stockStatusIcon = Icons.check_circle_outline_rounded;

    bool isActuallyLowStock = ingredient.lowStockThreshold > 0 && ingredient.stock <= ingredient.lowStockThreshold;

    if (isActuallyLowStock) {
      stockLevelColor = Colors.red.shade700;
      stockStatusText = "STOCK BAS";
      stockStatusIcon = Icons.warning_amber_rounded;
    } else if (ingredient.lowStockThreshold > 0 && ingredient.stock <= ingredient.lowStockThreshold * 1.25) { // Seuil "moyen" un peu plus large
      stockLevelColor = Colors.orange.shade700;
      stockStatusText = "STOCK MOYEN";
      stockStatusIcon = Icons.info_outline_rounded;
    }
    
    String lastUpdateText = "Date de MàJ inconnue";
    if (ingredient.updatedAt != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = DateTime(now.year, now.month, now.day - 1);
        final dateToCompare = DateTime(ingredient.updatedAt!.year, ingredient.updatedAt!.month, ingredient.updatedAt!.day);

        if (dateToCompare == today) {
            lastUpdateText = "MàJ Aujourd'hui à ${DateFormat.Hm().format(ingredient.updatedAt!)}";
        } else if (dateToCompare == yesterday) {
            lastUpdateText = "MàJ Hier à ${DateFormat.Hm().format(ingredient.updatedAt!)}";
        } else {
            lastUpdateText = "MàJ le ${DateFormat('dd/MM/yy HH:mm').format(ingredient.updatedAt!)}";
        }
    }

    return Hero(
      tag: 'stock_item_${ingredient.id}${isSpecialAlert ? "_alert" : ""}',
      child: Card(
        margin: EdgeInsets.only(bottom: isSpecialAlert ? 0 : 14, left: isSpecialAlert ? 0 : 2, right: isSpecialAlert ? 0 : 2),
        elevation: isHighlightedActuallyOnCard || isSpecialAlert ? 7 : 3, // Elevation ajustée
        shadowColor: isHighlightedActuallyOnCard || isSpecialAlert ? (isSpecialAlert ? Colors.red.withOpacity(0.4) : kMainColor.withOpacity(0.4)) : Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: isHighlightedActuallyOnCard || isSpecialAlert
              ? BorderSide(color: isSpecialAlert ? Colors.red.shade400 : kMainColor, width: isSpecialAlert ? 2.0 : 2.5) // Largeur de bordure ajustée
              : BorderSide(color: stockLevelColor.withOpacity(0.4), width: 1.2), // Bordure subtile pour tous
        ),
        child: InkWell( 
        onTap: () { _showEditStockDialog(ingredient); },
        borderRadius: BorderRadius.circular(18), // S'assurer que l'effet d'encre respecte les coins arrondis
        child: Padding( 
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ingredient.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18, // Cohérence de taille
                              color: kMainTextColor
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Catégorie: ${ingredient.category}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: kLightTextColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: stockLevelColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: stockLevelColor.withOpacity(0.5), width: 0.8)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(stockStatusIcon, color: stockLevelColor, size: 15),
                          SizedBox(width: 5),
                          Text(
                            stockStatusText,
                            style: TextStyle(
                                color: stockLevelColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end, // Aligner en bas pour un look plus propre
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                          'Actuel:',
                          style: theme.textTheme.bodyMedium?.copyWith(color: kLightTextColor, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '${ingredient.stock.toStringAsFixed(1)} ${ingredient.unit}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: kMainTextColor),
                        ),
                      ],
                    ),
                    if (ingredient.lowStockThreshold > 0)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                           Text(
                            'Seuil Bas:',
                            style: theme.textTheme.bodyMedium?.copyWith(color: kLightTextColor, fontSize: 13),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '${ingredient.lowStockThreshold.toStringAsFixed(1)} ${ingredient.unit}',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isActuallyLowStock ? Colors.red.shade700 : kTextColor),
                          ),
                        ],
                      ),
                  ],
                ),
                SizedBox(height: 12),
                if (ingredient.lowStockThreshold > 0 || ingredient.stock > 0)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: stockPercentage,
                      backgroundColor: kLightTextColor.withOpacity(0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(stockLevelColor),
                      minHeight: 10, // Barre de progression plus épaisse
                    ),
                  ),
                SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    lastUpdateText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: kLightTextColor.withOpacity(0.8),
                      fontStyle: FontStyle.italic
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ).animate(target: isSpecialAlert ? 0 : 1) 
          .fadeIn(
              duration: 350.ms, 
              delay: isSpecialAlert 
                  ? 0.ms // Corrected: Explicit 0 delay for special alert
                  : (100 + (itemIndex * 25) + (categoryIndex * 40)).ms 
            )
          .slideY(begin: 0.15, end: 0, duration: 400.ms, curve: Curves.easeOutCubic),
    );
  }
  
  Widget _buildSearchEmptyState() { 
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
      child: Center(
              child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 70, color: kLightTextColor.withOpacity(0.7)),
          SizedBox(height: 20),
          Text(
            'Aucun ingrédient trouvé pour "${_searchQueryController.text}"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, color: kMainTextColor, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          Text(
            'Vérifiez l\'orthographe ou essayez un autre terme.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: kLightTextColor),
          ),
        ],
      ))
          .animate()
          .fadeIn(),
    );
   }
  Widget _buildHeaderStats(int totalIngredients, int lowStockCount) { 
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kMainColor, kMainColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: kMainColor.withOpacity(0.3),
              blurRadius: 12,
              offset: Offset(0, 5)),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aperçu de l\'Inventaire',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Ingrédients Totaux', totalIngredients.toString(),
                    Icons.inventory_2_outlined, Colors.white, textColor: kMainColor),
                _buildStatCard('En Stock Bas', lowStockCount.toString(),
                    Icons.warning_amber_rounded, Colors.white, textColor: Colors.red.shade700, highlightValue: lowStockCount > 0),
              ],
            ),
          ],
        ),
    );
   }

  Widget _buildStatCard(String title, String value, IconData icon, Color bgColor, {Color? textColor, bool highlightValue = false}) {
    return Expanded( 
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
            color: bgColor.withOpacity(0.9), 
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: Offset(0,2))]
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(icon, color: textColor ?? kMainTextColor, size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(color: textColor ?? kMainTextColor, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis,)),
            ]),
            SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    color: highlightValue && textColor != null ? textColor : (textColor ?? kMainTextColor),
                    fontWeight: FontWeight.bold,
                    fontSize: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<Ingredient> ingredients, int categoryIndex) {
     return Padding( 
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 28.0, bottom: 14.0, left: 4),
            child: Row(children: [
              Container(
                  width: 5,
                  height: 22,
                  decoration: BoxDecoration(
                      color: kMainColor,
                      borderRadius: BorderRadius.circular(2.5))),
              SizedBox(width: 10),
              Text(category,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: kMainTextColor)),
              SizedBox(width: 8),
              Text('(${ingredients.length})',
                  style: TextStyle(fontSize: 15, color: kLightTextColor)),
            ]),
          )
              .animate()
              .fadeIn(
                  duration: 400.ms,
                  delay: (150 + categoryIndex * 50).ms) 
              .slideX(
                  begin: -0.1,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutQuad),
          ListView.builder( 
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: ingredients.length,
            itemBuilder: (context, idx) {
              final ingredient = ingredients[idx];
              final bool isHighlightedOnCard = ingredient.id == widget.highlightIngredientId && ingredient.id != _alertedIngredientOnPageLoad?.id;
              return _buildStockItem(ingredient, isHighlightedOnCard, idx, categoryIndex, isSpecialAlert: false);
            },
          ),
        ],
      ),
    );
  }
  void _showAddStockDialog() { 
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Fonctionnalité d'ajout d'ingrédient à implémenter."),
        backgroundColor: kMainColor, // Using kMainColor for consistency
        behavior: SnackBarBehavior.floating, // Floating SnackBar
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(10),
        ));
    debugPrint("Afficher la boîte de dialogue pour ajouter un stock");
  }
  void _showEditStockDialog(Ingredient ingredient) { 
     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Affichage/Édition de ${ingredient.name} à implémenter."),
         backgroundColor: kMainColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(10),
        ));
    debugPrint("Afficher la boîte de dialogue pour modifier: ${ingredient.name}");
  }
  Widget _buildEmptyState() { 
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                    size: 80, color: kLightTextColor.withOpacity(0.6))
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            SizedBox(height: 20),
            Text('Votre inventaire est vide',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kMainTextColor))
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            SizedBox(height: 10),
            Text('Commencez par ajouter vos ingrédients pour suivre leur stock.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kLightTextColor, fontSize: 15))
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.2, end: 0),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.add_circle_outline_rounded, color: Colors.white),
              label: Text('Ajouter un Ingrédient', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 3,
              ),
              onPressed: _showAddStockDialog,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
   }
  Widget _buildErrorState(String error) { 
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 80, color: Colors.red.shade300)
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .fadeIn(duration: 400.ms),
            SizedBox(height: 20),
            Text('Oops! Un problème est survenu',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kMainTextColor))
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: 0.2, end: 0),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(error,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kLightTextColor, fontSize: 15)),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms)
                .slideY(begin: 0.2, end: 0),
            SizedBox(height: 30),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text('Réessayer', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 3,
              ),
              onPressed: _refreshStockData,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms)
                .slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

}

