class Ingredient {
  final String id;
  final String name;
  final double? quantity; // Made nullable
  final String? unit; // Made nullable, was already string
  final String? category; // Added nullable category

  Ingredient({
    required this.id,
    required this.name,
    this.quantity, // Optional
    this.unit,
    this.category,
  });

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    return Ingredient(
      id: json['_id'] as String? ?? json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: json['name'] as String,
      quantity: (json['quantity'] as num?)?.toDouble(), // Keep if present, else null
      unit: json['unit'] as String?,
      category: json['category'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (quantity != null) 'quantity': quantity,
    if (unit != null) 'unit': unit,
    if (category != null) 'category': category,
  };
}

class MenuItem {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String? image;
  final String category;
  final List<String> dietaryInfo; // e.g., ["veg", "gluten-free"]
  final List<String> healthInfo;
  final int? preparationTime; // in minutes
  final bool isPopular;
  final bool isAvailable; // For the toggle
  final List<Ingredient> ingredients; // Changed from Addon to Ingredient

  MenuItem({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.image,
    required this.category,
    this.dietaryInfo = const [],
    this.healthInfo = const [],
    this.preparationTime,
    required this.isPopular,
    required this.isAvailable,
    this.ingredients = const [], // Changed from addons to ingredients
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    List<String> _convertMapToList(Map<String, dynamic>? map) {
      if (map == null) return [];
      final List<String> list = [];
      map.forEach((key, value) {
        if (value == true) {
          list.add(key);
        }
      });
      return list;
    }

    var ingredientsListJson = json['ingredients'] as List<dynamic>? ?? [];
    List<Ingredient> parsedIngredients = ingredientsListJson
        .map((i) => Ingredient.fromJson(i as Map<String, dynamic>))
        .toList();

    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String?,
      category: json['category'] as String,
      dietaryInfo: _convertMapToList(json['dietaryInfo'] as Map<String, dynamic>?),
      healthInfo: _convertMapToList(json['healthInfo'] as Map<String, dynamic>?),
      preparationTime: json['preparationTime'] as int?,
      isPopular: json['isPopular'] as bool? ?? false,
      isAvailable: json['isAvailable'] as bool? ?? true,
      ingredients: parsedIngredients, // Changed from addons to ingredients
    );
  }

  bool get isVeg {
    return dietaryInfo.any((info) => info.toLowerCase() == 'veg' || info.toLowerCase() == 'vegetarian');
  }

  String get stockStatus {
    return isAvailable ? 'in stock' : 'out of stock';
  }

  MenuItem copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? image,
    String? category,
    List<String>? dietaryInfo,
    List<String>? healthInfo,
    int? preparationTime,
    bool? isPopular,
    bool? isAvailable,
    List<Ingredient>? ingredients, // Changed from Addon to Ingredient
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      image: image ?? this.image,
      category: category ?? this.category,
      dietaryInfo: dietaryInfo ?? this.dietaryInfo,
      healthInfo: healthInfo ?? this.healthInfo,
      preparationTime: preparationTime ?? this.preparationTime,
      isPopular: isPopular ?? this.isPopular,
      isAvailable: isAvailable ?? this.isAvailable,
      ingredients: ingredients ?? this.ingredients, // Changed from addons to ingredients
    );
  }
}