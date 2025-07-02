import 'package:equatable/equatable.dart';

class AddonModel extends Equatable {
  final String name; // Requis
  final double price; // Requis
  final bool? isAvailable;

  const AddonModel({
    required this.name,
    required this.price,
    this.isAvailable,
  });

  factory AddonModel.fromJson(Map<String, dynamic> json) {
    return AddonModel(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      isAvailable: json['isAvailable'] as bool? ?? true, // Default true
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'isAvailable': isAvailable,
    };
  }

  AddonModel copyWith({
    String? name,
    double? price,
    bool? isAvailable,
  }) {
    return AddonModel(
      name: name ?? this.name,
      price: price ?? this.price,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  List<Object?> get props => [name, price, isAvailable];
}