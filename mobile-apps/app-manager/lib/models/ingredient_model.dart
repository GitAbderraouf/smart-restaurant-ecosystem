// models/ingredient_model.dart
import 'package:flutter/material.dart'; // Pour TextEditingController

class Ingredient {
  final String id; // Correspond à _id dans MongoDB
  String name;
  String unit;
  double stock;
  double lowStockThreshold;
  String category;
  DateTime? createdAt; // Optionnel, si l'API le fournit
  DateTime? updatedAt; // Optionnel, si l'API le fournit
  
  // TextEditingController pour la gestion de l'input dans l'UI
  // Il n'est pas final car il sera initialisé et potentiellement modifié
  late TextEditingController stockController;

  Ingredient({
    required this.id,
    required this.name,
    required this.unit,
    required this.stock,
    required this.lowStockThreshold,
    required this.category,
    this.createdAt,
    this.updatedAt,
  }) {
    // Initialiser le stockController avec la valeur actuelle du stock
    stockController = TextEditingController(text: stock.toStringAsFixed(1));
  }

  // Factory constructor pour créer une instance d'Ingredient à partir d'un JSON
  // C'est ce que vous utiliserez lors de la récupération des données de l'API
  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['id'] as String? ?? json['_id'] as String,
      name: json['name'] as String, //
      unit: json['unit'] as String, //
      stock: (json['stock'] as num).toDouble(), //
      lowStockThreshold: (json['lowStockThreshold'] as num? ?? 0.0).toDouble(), // (avec une valeur par défaut si null)
      category: json['category'] as String, //
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }

  // Méthode pour convertir une instance d'Ingredient en JSON
  // Utile si vous devez renvoyer des données modifiées à une API (moins pertinent pour le simulateur qui émet via socket)
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'unit': unit,
      'stock': stock,
      'lowStockThreshold': lowStockThreshold,
      'category': category,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Méthode pour mettre à jour le stock et synchroniser le controller
  // Utile pour maintenir la cohérence entre le modèle et l'UI
  void updateStockValue(double newStock) {
    stock = newStock;
    // Vérifier si la valeur du contrôleur est différente pour éviter les boucles de mise à jour inutiles
    // et formater correctement la nouvelle valeur.
    String formattedNewStock = newStock.toStringAsFixed(1);
    if (stockController.text != formattedNewStock) {
      stockController.text = formattedNewStock;
      // Si vous utilisez un curseur, le déplacer à la fin peut être une bonne UX.
      stockController.selection = TextSelection.fromPosition(
        TextPosition(offset: stockController.text.length),
      );
    }
  }

  // (Optionnel) Si vous avez besoin de libérer les ressources du TextEditingController
  // void dispose() {
  //   stockController.dispose();
  // }
}