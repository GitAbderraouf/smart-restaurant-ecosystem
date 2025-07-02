part of 'location_cubit.dart';

abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationPermissionDenied extends LocationState {}

class LocationServiceDisabled extends LocationState {}

class LocationError extends LocationState {
  final String message;
  const LocationError(this.message);
  @override
  List<Object?> get props => [message];
}

class LocationLoaded extends LocationState {
  final Position position;
  final Placemark? placemark; // Détails de l'adresse (peut être null)

  const LocationLoaded({required this.position, this.placemark});

  // Helper pour afficher une adresse simple
  String get simpleAddress {
    if (placemark == null) {
      // Si pas d'adresse, retourne les coordonnées formatées
      return "${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
    }
    // Construit une adresse simple (rue/quartier, ville)
    String addressLine =
        "${placemark!.street ?? placemark!.subLocality ?? placemark!.locality ?? ''}";
    if (addressLine.isEmpty && placemark!.locality != null) {
      addressLine =
          placemark!.locality!; // Fallback sur la ville si rue/quartier vides
    } else if (addressLine.isNotEmpty &&
        placemark!.locality != null &&
        !addressLine.contains(placemark!.locality!)) {
      // Ajoute la ville si elle n'est pas déjà dans la rue/quartier
      addressLine += ", ${placemark!.locality}";
    }

    return addressLine.isNotEmpty ? addressLine : "Adresse inconnue";
  }

  @override
  List<Object?> get props => [position, placemark];
}
