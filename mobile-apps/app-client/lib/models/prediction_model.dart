// Vous n'avez probablement PAS besoin de créer ce fichier vous-même.
// Cette classe est DÉJÀ DÉFINIE par le package que vous importez.
// Ceci est juste pour ILLUSTRER sa structure probable.

import 'package:equatable/equatable.dart';

// Structure PROBABLE de l'objet Prediction retourné par le package
class Prediction extends Equatable {
  // L'identifiant unique du lieu (essentiel pour obtenir les détails)
  final String? placeId;

  // La chaîne de caractères principale affichée comme suggestion
  // (contient souvent le nom et une partie de l'adresse)
  final String? description;

  // --- Champs qui sont souvent remplis APRÈS l'appel aux détails ---
  // (dans le callback getPlaceDetailWithLatLng)
  // Ils peuvent être retournés comme String ou double par l'API/package
  final String? lat; // Latitude (peut être String)
  final String? lng; // Longitude (peut être String)
  // ---------------------------------------------------------------


  // --- Champs Optionnels souvent présents ---
  // Permet d'afficher le nom et l'adresse séparément si besoin
  final StructuredFormatting? structuredFormatting;
  // Liste des types de lieux (ex: 'establishment', 'geocode', 'restaurant')
  final List<String>? types;
  // Distance par rapport au point de recherche (si fournie)
  final num? distanceMeters;
  // ----------------------------------------


  // Constructeur (tel qu'il pourrait être défini dans le package)
  const Prediction({
    this.placeId,
    this.description,
    this.lat,
    this.lng,
    this.structuredFormatting,
    this.types,
    this.distanceMeters,
  });

  // Helper pour convertir lat/lng String en double (si nécessaire)
  double? get latitude => (lat != null) ? double.tryParse(lat!) : null;
  double? get longitude => (lng != null) ? double.tryParse(lng!) : null;


  // Nécessaire pour Equatable
  @override
  List<Object?> get props => [
        placeId, description, lat, lng, structuredFormatting, types, distanceMeters
      ];

  // Le package inclut probablement une factory fromJson interne
  // factory Prediction.fromJson(Map<String, dynamic> json) { ... }
}


// Classe auxiliaire souvent utilisée par les prédictions
class StructuredFormatting extends Equatable {
  final String? mainText; // Texte principal (ex: nom du lieu)
  final String? secondaryText; // Texte secondaire (ex: reste de l'adresse)
  // Il peut y avoir aussi des listes de "matched_substrings"

  const StructuredFormatting({this.mainText, this.secondaryText});

  // factory StructuredFormatting.fromJson(Map<String, dynamic> json) { ... }

  @override
  List<Object?> get props => [mainText, secondaryText];
}