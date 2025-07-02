// lib/pages/address_search_page.dart 

import 'package:flutter/material.dart'; 
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:google_places_flutter/google_places_flutter.dart'; 
import 'package:google_places_flutter/model/prediction.dart'; 
import 'package:hungerz/Config/app_config.dart'; 
import 'package:hungerz/models/place_model.dart'; 
import 'package:hungerz/pages/save_address_page.dart'; 
import 'package:hungerz/cubits/location_cubit/location_cubit.dart'; 
// --- AJOUTS ---
import 'package:hungerz/cubits/profile_cubit/profile_cubit.dart'; // Importer ProfileCubit et State
import 'package:hungerz/models/address_model.dart'; // Importer AddressModel
// Pour kMainColor ou autres couleurs de thème
// ---------------

class AddressSearchPage extends StatefulWidget { 
  const AddressSearchPage({Key? key}) : super(key: key); 

  @override 
  _AddressSearchPageState createState() => _AddressSearchPageState(); 
} 

class _AddressSearchPageState extends State<AddressSearchPage> { 
  final _controller = TextEditingController(); 

  @override 
  void initState() { 
    super.initState(); 
    // Optionnel: charger le profil si ce n'est pas déjà fait par une logique globale
    // context.read<ProfileCubit>().loadUserProfileIfNeeded(); // Vous auriez besoin d'une telle méthode
  } 

  @override 
  void dispose() { 
    _controller.dispose(); 
    super.dispose(); 
  } 

  void _navigateToSaveAddress(Place place) { 
    if (place.latitude == null || place.longitude == null) { 
      print("ERREUR: Coordonnées manquantes pour le lieu sélectionné : ${place.name}"); 
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar( 
          SnackBar( 
            content: Text("Impossible d'obtenir les coordonnées pour cette adresse."), 
            backgroundColor: Colors.red), 
        ); 
      }
      return; 
    } 
    print("Navigation vers SaveAddressPage avec: ${place.name} - ${place.address} (${place.latitude}, ${place.longitude})"); 
    if (mounted) {
      Navigator.pushReplacement( 
        context, 
        MaterialPageRoute( 
          builder: (_) => SaveAddressPage(selectedPlace: place))); 
    }
  } 

  // --- AJOUT: Méthode pour sélectionner une adresse sauvegardée ---
  void _selectSavedAddress(AddressModel savedAddress) {
    if (savedAddress.latitude == null || savedAddress.longitude == null) {
      print("ERREUR: Coordonnées manquantes pour l'adresse sauvegardée : ${savedAddress.label}");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Coordonnées manquantes pour cette adresse sauvegardée."),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    // Convertir AddressModel en Place
    final Place selectedPlace = Place(
      id: savedAddress.placeId ?? 'saved_${savedAddress.label}_${DateTime.now().millisecondsSinceEpoch}', // Utiliser placeId si disponible
      name: savedAddress.label, // Le label de l'adresse comme nom
      address: savedAddress.address, // L'adresse formatée
      latitude: savedAddress.latitude!,
      longitude: savedAddress.longitude!,
      // Les autres champs de Place (distance, rating, etc.) ne sont pas pertinents ici
    );

    print("AddressSearchPage: Retour avec adresse sauvegardée -> ${selectedPlace.address}");
    if (mounted) {
      Navigator.pop(context, selectedPlace); // Retourner le Place object
    }
  }
  // ---------------------------------------------------------

  @override 
  Widget build(BuildContext context) { 
    return Scaffold( 
      appBar: AppBar( 
        leading: IconButton( 
          icon: Icon(Icons.arrow_back), 
          onPressed: () => Navigator.pop(context)), 
        title: Text("Entrez votre adresse", 
          style: Theme.of(context).textTheme.bodyLarge), 
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1, 
      ), 
      body: Column( 
        children: [ 
          Padding( 
            padding: const EdgeInsets.all(16.0), 
            child: GooglePlaceAutoCompleteTextField( 
              textEditingController: _controller, 
              googleAPIKey: AppConfig.googleApiKey, 
              inputDecoration: InputDecoration( 
                hintText: "Rechercher un lieu ou une adresse...", 
                prefixIcon: Icon(Icons.search, color: Colors.grey), 
                border: OutlineInputBorder( 
                  borderRadius: BorderRadius.circular(8.0), 
                  borderSide: BorderSide(color: Colors.grey[300]!), 
                ), 
                focusedBorder: OutlineInputBorder( 
                  borderRadius: BorderRadius.circular(8.0), 
                  borderSide: BorderSide(color: Theme.of(context).primaryColor), 
                ), 
                contentPadding: EdgeInsets.symmetric(vertical: 10.0), 
              ), 
              debounceTime: 600, 
              countries: ["dz"], 
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (Prediction prediction) { 
                print("Détails Reçus: ${prediction.description}"); 
                print("Lat: ${prediction.lat}, Lng: ${prediction.lng}, ID: ${prediction.placeId}"); 
                double? lat = double.tryParse(prediction.lat?.toString() ?? ''); 
                double? lng = double.tryParse(prediction.lng?.toString() ?? ''); 

                if (lat != null && lng != null) { 
                  Place selectedPlace = Place( 
                    id: prediction.placeId ?? 'no-place-id-${DateTime.now().millisecondsSinceEpoch}', 
                    name: prediction.description ?? 'Lieu sélectionné', 
                    address: prediction.description ?? 'Adresse inconnue', 
                    latitude: lat, 
                    longitude: lng, 
                  ); 
                  _navigateToSaveAddress(selectedPlace); 
                } else { 
                  print("ERREUR: Lat/Lng non reçus ou invalides dans getPlaceDetailWithLatLng"); 
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar( 
                      SnackBar( 
                        content: Text("Impossible d'obtenir les coordonnées pour cette adresse."), 
                        backgroundColor: Colors.red), 
                    ); 
                  }
                } 
              }, 
              itemClick: (Prediction prediction) { 
                _controller.text = prediction.description ?? ''; 
                _controller.selection = TextSelection.fromPosition( 
                  TextPosition(offset: prediction.description?.length ?? 0)); 
                print("Item cliqué: ${prediction.description}"); 
              }, 
              itemBuilder: (context, index, Prediction prediction) { 
                return Container( 
                  color: Colors.white, 
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), 
                  child: Row( 
                    children: [ 
                      Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 20), 
                      SizedBox(width: 12), 
                      Expanded( 
                        child: Text( 
                          prediction.description ?? "", 
                          style: Theme.of(context).textTheme.bodyMedium, 
                          overflow: TextOverflow.ellipsis, 
                        )), 
                    ], 
                  ), 
                ); 
              }, 
              seperatedBuilder: const Divider(height: 1, thickness: 0.5), 
              isCrossBtnShown: true, 
              containerHorizontalPadding: 0, 
            ), 
          ), 
          BlocBuilder<LocationCubit, LocationState>( 
            builder: (context, locationState) { 
              if (locationState is LocationLoaded) { 
                return ListTile( 
                  leading: Icon(Icons.my_location, color: Theme.of(context).primaryColor), 
                  title: Text("Utiliser mon adresse actuelle", 
                    style: TextStyle( 
                      color: Theme.of(context).primaryColor, 
                      fontWeight: FontWeight.bold)), 
                  subtitle: Text(locationState.simpleAddress, 
                    maxLines: 1, overflow: TextOverflow.ellipsis), 
                  onTap: () { 
                    Place currentPlace = Place( 
                      id: 'current_${locationState.position.latitude}_${locationState.position.longitude}', 
                      name: locationState.placemark?.street ?? locationState.placemark?.locality ?? "Adresse Actuelle", 
                      address: locationState.simpleAddress, 
                      latitude: locationState.position.latitude, 
                      longitude: locationState.position.longitude, 
                    ); 
                    print("AddressSearchPage: Retour avec localisation actuelle -> ${currentPlace.address}"); 
                    if (mounted) {
                       Navigator.pop(context, currentPlace); 
                    }
                  }, 
                ); 
              } else { 
                return SizedBox.shrink(); 
              } 
            }, 
          ), 
          Divider(height: 1, thickness: 0.5), 

          // --- AJOUT : Section des adresses sauvegardées ---
          Expanded( // Pour que la ListView prenne l'espace restant
            child: BlocBuilder<ProfileCubit, ProfileState>(
              builder: (context, profileState) {
                if (profileState is ProfileLoaded && 
                    profileState.user.addresses != null && 
                    profileState.user.addresses!.isNotEmpty) {
                  final savedAddresses = profileState.user.addresses!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        child: Text(
                          "Adresses sauvegardées", // Texte direct
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          itemCount: savedAddresses.length,
                          itemBuilder: (context, index) {
                            final address = savedAddresses[index];
                            IconData addressIcon = Icons.location_on_outlined; // Icône par défaut
                            if (address.type?.toLowerCase() == 'home') {
                              addressIcon = Icons.home_outlined;
                            } else if (address.type?.toLowerCase() == 'office') {
                              addressIcon = Icons.work_outline;
                            }
                            return ListTile(
                              leading: Icon(addressIcon, color: Theme.of(context).primaryColor),
                              title: Text(address.label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                              subtitle: Text(address.address, maxLines: 1, overflow: TextOverflow.ellipsis),
                              onTap: () => _selectSavedAddress(address),
                            );
                          },
                          separatorBuilder: (context, index) => Divider(indent: 16, endIndent: 16, height: 1),
                        ),
                      ),
                    ],
                  );
                } else if (profileState is ProfileLoaded && (profileState.user.addresses == null || profileState.user.addresses!.isEmpty)) {
                   return Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Text("Aucune adresse sauvegardée.", style: TextStyle(color: Colors.grey[600])), // Texte direct
                   );
                } else if (profileState is ProfileLoading) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Chargement des adresses...", style: TextStyle(color: Colors.grey[600])), // Texte direct
                  ));
                }
                // Si ProfileInitial ou ProfileError, n'afficher rien ou un message discret
                return SizedBox.shrink(); 
              },
            ),
          ),
          // --------------------------------------------------
        ], 
      ), 
    ); 
  } 
}

