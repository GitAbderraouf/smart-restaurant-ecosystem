// screens/stock_simulator_screen.dart
// screens/stock_simulator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Importer flutter_bloc
import 'package:iot_simulator_app/cubits/stock_cubit/stock_cubit.dart';
import '../models/ingredient_model.dart';
 // Importer votre Cubit

class StockSimulatorScreen extends StatefulWidget {
  const StockSimulatorScreen({super.key});

  @override
  _StockSimulatorScreenState createState() => _StockSimulatorScreenState();
}

class _StockSimulatorScreenState extends State<StockSimulatorScreen> {
  // Plus besoin de _groupedIngredients ici, il sera dans StockLoaded state

  @override
  void initState() {
    super.initState();
    // Demander au Cubit de charger les données initiales
    // Assurez-vous que StockCubit est fourni plus haut dans l'arbre (ex: dans main.dart via MultiBlocProvider)
    // ou si vous le fournissez ici, faites-le avant cet appel.
    // Si fourni dans main.dart:
    WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<StockCubit>().fetchInitialStock();
    });
  }

  // La méthode _updateStock est maintenant gérée par le Cubit: simulatorUpdateStock

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<StockCubit, StockState>(
        builder: (context, state) {
          if (state is StockInitial || state is StockLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is StockLoaded) {
            // Utiliser state.categorizedIngredients pour construire l'UI
            if (state.categorizedIngredients.isEmpty) {
              return Center(child: Text("Aucun ingrédient à afficher."));
            }
            return ListView.builder(
              itemCount: state.categorizedIngredients.keys.length,
              itemBuilder: (context, index) {
                String category = state.categorizedIngredients.keys.elementAt(index);
                List<Ingredient> ingredientsInCategory = state.categorizedIngredients[category]!;

                return ExpansionTile(
                  title: Text(category, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  initiallyExpanded: true,
                  children: ingredientsInCategory.map((ingredient) {
                    bool isLowStock = ingredient.stock < ingredient.lowStockThreshold && ingredient.lowStockThreshold > 0;
                    // Le contrôleur est maintenant dans l'objet ingredient
                    // ingredient.stockController.text = ingredient.stock.toStringAsFixed(1); // Déjà géré par updateStockValue

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: isLowStock ? Colors.red[100] : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${ingredient.name} (${ingredient.unit})",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            SizedBox(height: 4),
                            Text("Stock actuel: ${ingredient.stock.toStringAsFixed(1)} ${ingredient.unit}"),
                            if (isLowStock)
                              Text(
                                "Stock bas! (Seuil: ${ingredient.lowStockThreshold.toStringAsFixed(1)} ${ingredient.unit})",
                                style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                              ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    double currentStock = ingredient.stock;
                                    if (currentStock >= 1) { // Empêcher stock négatif par décrémentation
                                      // Appeler le Cubit pour la mise à jour
                                      context.read<StockCubit>().simulatorUpdateStock(ingredient.id, currentStock - 1);
                                    }
                                  },
                                ),
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: TextField(
                                      controller: ingredient.stockController, // Utiliser le contrôleur du modèle
                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      // onSubmitted est conservé pour la validation directe depuis le TextField
                                      onSubmitted: (value) {
                                        double? newStock = double.tryParse(value);
                                        if (newStock != null && newStock >= 0) {
                                          context.read<StockCubit>().simulatorUpdateStock(ingredient.id, newStock);
                                        } else {
                                          // Rétablir la valeur du contrôleur à la valeur actuelle du stock dans le modèle
                                          ingredient.stockController.text = ingredient.stock.toStringAsFixed(1);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.add_circle_outline),
                                  onPressed: () {
                                    double currentStock = ingredient.stock;
                                    context.read<StockCubit>().simulatorUpdateStock(ingredient.id, currentStock + 1);
                                  },
                                ),
                                SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    double? newStock = double.tryParse(ingredient.stockController.text);
                                    if (newStock != null && newStock >= 0) {
                                       context.read<StockCubit>().simulatorUpdateStock(ingredient.id, newStock);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("${ingredient.name} demande de MàJ envoyée.")),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Valeur de stock invalide pour ${ingredient.name}")),
                                      );
                                      ingredient.stockController.text = ingredient.stock.toStringAsFixed(1);
                                    }
                                  },
                                  child: Text('MàJ'),
                                   style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 10)
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            );
          } else if (state is StockError) {
            return Center(child: Text("Erreur: ${state.message}"));
          }
          return Center(child: Text("État inconnu du stock.")); // Cas par défaut
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.read<StockCubit>().fetchInitialStock(); // Appeler le Cubit pour rafraîchir
        },
        child: Icon(Icons.refresh),
        tooltip: 'Rafraîchir le stock',
      ),
    );
  }
}