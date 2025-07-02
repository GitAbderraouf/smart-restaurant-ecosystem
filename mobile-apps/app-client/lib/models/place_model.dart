// lib/models/place_model.dart

// lib/models/place_model.dart (Version adaptée à la réponse de l'outil)
import 'package:equatable/equatable.dart';
// pour kDebugMode

class Place extends Equatable {
  final String id; // Identifiant unique du lieu (depuis l'outil)
  final String name; // Nom principal du lieu
  final String address; // Adresse formatée
  final String? distance; // Distance texte (ex: "1,3 km")
  final int? distanceInMeters;
  final List<String>? openingHours;
  final String? phoneNumber;
  final double? rating; // Converti depuis String
  final String? url; // Site web ou URL maps?

  // --- Coordonnées - Rendues optionnelles car absentes de Google Maps ---
  final double? latitude;
  final double? longitude;
  // --------------------------------------------------------------------

  const Place({
    required this.id,
    required this.name,
    required this.address,
    this.distance,
    this.distanceInMeters,
    this.openingHours,
    this.phoneNumber,
    this.rating,
    this.url,
    this.latitude, // Optionnel
    this.longitude, // Optionnel
  });

  // --- Factory pour créer depuis un Map (simulant l'objet retourné par l'outil) ---
  // !!! IMPORTANT !!! : Ceci suppose que la réponse de l'outil, bien qu'étant
  // un objet Python, peut être traitée comme un Map<String, dynamic> en Dart
  // après un json.decode si l'outil retournait du JSON, ou via une conversion
  // si l'outil retourne un objet structuré directement interprétable.
  // ADAPTEZ les clés si la structure réelle diffère légèrement.
  factory Place.fromJson(Map<String, dynamic> json) {
    double? parsedRating;
    if (json['rating'] != null && json['rating'] is String) {
      parsedRating = double.tryParse(json['rating'] as String);
    } else if (json['rating'] != null && json['rating'] is num) {
      parsedRating = (json['rating'] as num).toDouble();
    }

    List<String>? hours;
    if (json['opening_hours'] != null && json['opening_hours'] is List) {
      // Convertir chaque élément de la liste en String
      hours = List<String>.from(
          json['opening_hours'].map((item) => item.toString()));
    }

    return Place(
      id: json['id']?.toString() ??
          'id_inconnu_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Nom inconnu',
      address: json['address']?.toString() ?? 'Adresse inconnue',
      distance: json['distance']?.toString(),
      distanceInMeters: (json['distance_in_meters'] as num?)?.toInt(),
      openingHours: hours,
      phoneNumber: json['phone_number']?.toString(),
      rating: parsedRating,
      url: json['url']?.toString(),
      // Coordonnées non présentes dans Google Maps, laisser null pour l'instant
      latitude: null,
      longitude: null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        distance,
        distanceInMeters,
        openingHours,
        phoneNumber,
        rating,
        url,
        latitude,
        longitude
      ];
}
