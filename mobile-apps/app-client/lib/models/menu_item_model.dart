import 'package:equatable/equatable.dart';
import 'addon_model.dart'; // Importer AddonModel

// --- Sous-modèles pour MenuItem ---

class DietaryInfoModel extends Equatable {
  final bool? vegetarian;
  final bool? vegan;
  final bool? glutenFree;
  final bool? lactoseFree; // Note: Le schéma dit lactoseFree ici

  const DietaryInfoModel({
    this.vegetarian,
    this.vegan,
    this.glutenFree,
    this.lactoseFree,
  });

  factory DietaryInfoModel.fromJson(Map<String, dynamic> json) {
    return DietaryInfoModel(
      vegetarian: json['vegetarian'] as bool?,
      vegan: json['vegan'] as bool?,
      glutenFree: json['glutenFree'] as bool?,
      lactoseFree: json['lactoseFree'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vegetarian': vegetarian,
      'vegan': vegan,
      'glutenFree': glutenFree,
      'lactoseFree': lactoseFree,
    };
  }

  DietaryInfoModel copyWith({
    bool? vegetarian,
    bool? vegan,
    bool? glutenFree,
    bool? lactoseFree,
  }) {
    return DietaryInfoModel(
      vegetarian: vegetarian ?? this.vegetarian,
      vegan: vegan ?? this.vegan,
      glutenFree: glutenFree ?? this.glutenFree,
      lactoseFree: lactoseFree ?? this.lactoseFree,
    );
  }

  @override
  List<Object?> get props => [vegetarian, vegan, glutenFree, lactoseFree];
}

// Nom de classe corrigé pour correspondre au champ Dart
class HealthInfoModel extends Equatable {
    final bool? lowCarb;
    final bool? lowFat;
    final bool? lowSugar;
    final bool? lowSodium;

  const HealthInfoModel({
    this.lowCarb,
    this.lowFat,
    this.lowSugar,
    this.lowSodium,
  });

  factory HealthInfoModel.fromJson(Map<String, dynamic> json) {
    return HealthInfoModel(
      lowCarb: json['low_carb'] as bool?, // Clé JSON originale
      lowFat: json['low_fat'] as bool?,
      lowSugar: json['low_sugar'] as bool?,
      lowSodium: json['low_sodium'] as bool?,
    );
  }

   Map<String, dynamic> toJson() {
    return {
      'low_carb': lowCarb,
      'low_fat': lowFat,
      'low_sugar': lowSugar,
      'low_sodium': lowSodium,
    };
  }

  HealthInfoModel copyWith({
    bool? lowCarb,
    bool? lowFat,
    bool? lowSugar,
    bool? lowSodium,
  }) {
    return HealthInfoModel(
      lowCarb: lowCarb ?? this.lowCarb,
      lowFat: lowFat ?? this.lowFat,
      lowSugar: lowSugar ?? this.lowSugar,
      lowSodium: lowSodium ?? this.lowSodium,
    );
  }

  @override
  List<Object?> get props => [lowCarb, lowFat, lowSugar, lowSodium];
}


// --- Classe Principale MenuItemModel ---

class MenuItemModel extends Equatable {
  final String? id; // Provenant de _id MongoDB
  final String name; // Requis
  final String? description;
  final double price; // Requis
  final String? image;
  final String category; // Requis - Gardé comme String (ID) pour l'instant
  
  final DietaryInfoModel? dietaryInfo;
  final bool? isAvailable;
  final HealthInfoModel? healthInfo; // Nom de champ corrigé
  final bool? isPopular;
  final List<AddonModel>? addons;
  final int? preparationTime; // en minutes
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MenuItemModel({
    this.id,
    required this.name,
    this.description,
    required this.price,
    this.image,
    required this.category,
    this.dietaryInfo,
    this.isAvailable,
    this.healthInfo,
    this.isPopular,
    this.addons,
    this.preparationTime,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String?,
      category: json['category'].toString(), // Requis - Peut être un objet populé ou juste l'ID
   // Optionnel - Peut être objet populé ou ID

      dietaryInfo: json['dietaryInfo'] == null
          ? null
          : DietaryInfoModel.fromJson(json['dietaryInfo'] as Map<String, dynamic>),
      isAvailable: json['isAvailable'] as bool? ?? true, // Default true
      healthInfo: json['HealthInfo'] == null // Clé JSON originale
          ? null
          : HealthInfoModel.fromJson(json['HealthInfo'] as Map<String, dynamic>),
      isPopular: json['isPopular'] as bool? ?? false, // Default false
      addons: (json['addons'] as List<dynamic>?)
          ?.map((e) => AddonModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      preparationTime: (json['preparationTime'] as num?)?.toInt(),
      createdAt: json['createdAt'] == null ? null : DateTime.tryParse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null ? null : DateTime.tryParse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // ou _id
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category': category, // ID as String
      // ID as String
      'dietaryInfo': dietaryInfo?.toJson(),
      'isAvailable': isAvailable,
      'HealthInfo': healthInfo?.toJson(), // Clé JSON originale
      'isPopular': isPopular,
      'addons': addons?.map((e) => e.toJson()).toList(),
      'preparationTime': preparationTime,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

   MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? image,
    String? category,
    

    DietaryInfoModel? dietaryInfo,
    bool? isAvailable,
    HealthInfoModel? healthInfo,
    bool? isPopular,
    List<AddonModel>? addons,
    int? preparationTime,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
     

      dietaryInfo: dietaryInfo ?? this.dietaryInfo,
      isAvailable: isAvailable ?? this.isAvailable,
      healthInfo: healthInfo ?? this.healthInfo,
      isPopular: isPopular ?? this.isPopular,
      addons: addons ?? this.addons,
      preparationTime: preparationTime ?? this.preparationTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }


  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        image,
        category,
        

        dietaryInfo,
        isAvailable,
        healthInfo,
        isPopular,
        addons,
        preparationTime,
        createdAt,
        updatedAt,
      ];
}