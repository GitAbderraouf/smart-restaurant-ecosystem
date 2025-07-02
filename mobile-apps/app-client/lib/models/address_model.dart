import 'package:equatable/equatable.dart';
// import 'package:hungerz/common/enums.dart'; // Importer AddressType si vous l'utilisez

class AddressModel extends Equatable {
  final String? placeId; // Optionnel: ID du lieu (ex: Google Place ID)
  final String
      label; // <-- CHAMP AJOUTÉ : Nom donné par l'user (ex: "Maison") - Requis
  final String?
      type; // 'home', 'office', 'other' (garder String si backend attend String)
  final String address; // Adresse formatée complète - Requis
  final String? apartment;
  final String? building;
  final String? landmark;
  final double? latitude;
  final double? longitude;
  final bool? isDefault;

  const AddressModel({
    this.placeId,
    required this.label, // <-- Requis
    this.type, // Rendre type nullable si ce n'est pas toujours défini
    required this.address,
    this.apartment,
    this.building,
    this.landmark,
    this.latitude,
    this.longitude,
    this.isDefault,
  });

  // --- FromJson (A adapter si vous lisez les adresses depuis l'API User) ---
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      placeId: json['placeId'] as String?,
      label: json['label'] as String? ?? 'Adresse', // Valeur par défaut
      type: json['type'] as String?,
      address: json['address'] as String? ?? 'Adresse inconnue',
      // ... reste du parsing ...
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  // --- ToJson (pour envoyer à l'API) ---
  Map<String, dynamic> toJson() {
    return {
      if (placeId != null) 'placeId': placeId,
      'label': label, // <-- Envoyer le label
      if (type != null) 'type': type, // Envoyer si non null
      'address': address,
      if (apartment != null && apartment!.isNotEmpty) 'apartment': apartment,
      if (building != null && building!.isNotEmpty) 'building': building,
      if (landmark != null && landmark!.isNotEmpty) 'landmark': landmark,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault ?? false,
    };
  }

  // --- CopyWith (mettre à jour avec les nouveaux champs) ---
  AddressModel copyWith({
    String? placeId,
    String? label,
    String? type,
    /* ... autres ...*/
  }) {
    return AddressModel(
      placeId: placeId ?? this.placeId,
      label: label ?? this.label, // <-- Mis à jour
      type: type ?? this.type,
      address: address ,
      // ...
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [
        placeId,
        label,
        type,
        address,
        apartment,
        building,
        landmark,
        latitude,
        longitude,
        isDefault
      ]; // <-- Mis à jour
}
