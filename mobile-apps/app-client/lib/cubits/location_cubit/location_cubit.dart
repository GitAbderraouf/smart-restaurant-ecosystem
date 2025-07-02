// lib/cubits/location_cubit/location_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:equatable/equatable.dart';
part 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit() : super(LocationInitial());
  // Tenter de récupérer la localisation dès la création du Cubit

  Future<void> getCurrentLocation() async {
    // Éviter de relancer si déjà en chargement
    if (state is LocationLoading) return;

    emit(LocationLoading());
    print("LocationCubit: Vérification service et permissions...");

    // 1. Service activé ?
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("LocationCubit: Service désactivé.");
      emit(LocationServiceDisabled());
      return;
    }

    // 2. Permissions ?
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("LocationCubit: Permission refusée.");
        emit(LocationPermissionDenied());
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("LocationCubit: Permission refusée définitivement.");
      emit(LocationPermissionDenied()); // Ou état spécifique
      return;
    }

    // 3. Récupérer la position
    print("LocationCubit: Permissions OK. Récupération position...");
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium);
      print(
          "LocationCubit: Position = ${position.latitude}, ${position.longitude}");

      // 4. Reverse Geocoding (Coordonnées -> Adresse)
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude)
              .catchError((error) {
        // Gérer l'erreur spécifique du geocoding (ex: réseau)
        print("LocationCubit: Erreur Geocoding - ${error.toString()}");
        emit(LocationError("Impossible de trouver l'adresse."));
        return <Placemark>[]; // Retourner liste vide pour éviter crash
      });

      // Si le geocoding a échoué et a émis une erreur, on arrête
      if (state is LocationError) return;

      Placemark? place = placemarks.isNotEmpty ? placemarks[0] : null;
      String addr = (place != null)
          ? "${place.street ?? ''}, ${place.locality ?? ''}"
          : "Adresse non trouvée";
      print("LocationCubit: Adresse = $addr");

      // 5. Émettre l'état succès
      emit(LocationLoaded(position: position, placemark: place));
    } on LocationServiceDisabledException catch (e) {
      print(
          "LocationCubit: Erreur Service désactivé pendant l'opération - ${e.toString()}");
      emit(LocationServiceDisabled());
    } catch (e) {
      // Gérer toutes les autres erreurs (Timeout, etc.)
      print("LocationCubit: Erreur inconnue - ${e.toString()}");
      emit(LocationError(e.toString()));
    }
  }
}
