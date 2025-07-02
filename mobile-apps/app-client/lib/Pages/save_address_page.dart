// --- Fichier: lib/pages/save_address_page.dart ---

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// --- Vos Imports ---
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/Themes/colors.dart'; // Pour kMainColor ou couleurs du thème
import 'package:hungerz/models/place_model.dart'; // Modèle reçu de la recherche
import 'package:hungerz/models/address_model.dart'; // Modèle à sauvegarder (avec label, sans id interne)
import 'package:hungerz/common/enums.dart'; // Enum AddressType (home, office, other)
import 'package:hungerz/cubits/profile_cubit/profile_cubit.dart'; // Cubit pour sauvegarder
// import 'package:hungerz/cubits/profile_cubit/profile_state.dart'; // Moins utile ici

class SaveAddressPage extends StatefulWidget {
  final Place selectedPlace; // Reçoit les infos du lieu choisi

  const SaveAddressPage({Key? key, required this.selectedPlace})
      : super(key: key);

  @override
  _SaveAddressPageState createState() => _SaveAddressPageState();
}

class _SaveAddressPageState extends State<SaveAddressPage> {
  // Controllers pour les champs texte
  late TextEditingController _labelController;
  late TextEditingController _apartmentController;
  late TextEditingController _landmarkController;
  // Ajoutez d'autres controllers si nécessaire (ex: _buildingController)

  // Type d'adresse sélectionné
  AddressType _selectedAddressType = AddressType.other; // Défaut

  // État pour le bouton Enregistrer
  bool _isSaving = false;

  // États pour la carte Google Map
  GoogleMapController? _mapController;
  LatLng? _selectedLatLng; // Coordonnées finales choisies sur la carte
  String? _currentFormattedAddress; // Adresse texte dérivée de _selectedLatLng
  bool _isFetchingAddress = false; // Indicateur pour le géocodage inversé
  Marker? _currentMarker; // Le marqueur affiché sur la carte

  // Position initiale pour la caméra (évite le re-calcul dans build)
  late CameraPosition _initialCameraPosition;

  @override
  void initState() {
    super.initState();

    // Initialiser les controllers texte
    _labelController = TextEditingController(text: widget.selectedPlace.name);
    _apartmentController = TextEditingController();
    _landmarkController = TextEditingController();

    // Initialiser la position et l'adresse depuis le lieu reçu
    if (widget.selectedPlace.latitude != null &&
        widget.selectedPlace.longitude != null) {
      _selectedLatLng = LatLng(
          widget.selectedPlace.latitude!, widget.selectedPlace.longitude!);
      _currentFormattedAddress = widget.selectedPlace.address;
    } else {
      // Fallback : Coordonnées par défaut si celles du lieu manquent
      print(
          "Attention: Coordonnées manquantes pour le lieu initial. Utilisation de coordonnées par défaut.");
      _selectedLatLng = LatLng(36.726, 3.178); // Bab Ezzouar approx.
      _currentFormattedAddress = "Veuillez ajuster la position";
      // Lancer immédiatement la recherche d'adresse pour les coordonnées par défaut
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _getAddressFromCoordinates(_selectedLatLng!);
        }
      });
    }

    // Définir la position initiale de la caméra
    _initialCameraPosition = CameraPosition(
      target: _selectedLatLng!,
      zoom: 16.5, // Zoom un peu plus proche
    );

    // Créer le marqueur initial
    _updateMarker(_selectedLatLng!);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _apartmentController.dispose();
    _landmarkController.dispose();
    _mapController?.dispose(); // Très important
    super.dispose();
  }

  // --- Met à jour l'adresse texte depuis les coordonnées ---
  Future<void> _getAddressFromCoordinates(LatLng position) async {
    if (!mounted) return;
    setState(() {
      _isFetchingAddress = true;
    });
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
        // Optionnel: Spécifier la langue pour l'adresse retournée
        // localeIdentifier: AppLocalizations.of(context)?.locale.languageCode ?? 'fr',
      );

      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        // Construire une adresse formatée simple mais efficace
        String addr = [
          place.street, // Numéro + Nom rue
          // place.subLocality, // Quartier (peut être redondant)
          place.locality, // Ville
          place.postalCode, // Code Postal
          place.country // Pays
        ]
            .where((s) => s != null && s.isNotEmpty)
            .join(', '); // Joindre avec des virgules

        setState(() {
          _currentFormattedAddress =
              addr.isNotEmpty ? addr : "Adresse introuvable";
          // Mettre à jour le LatLng sélectionné au cas où l'appel venait de onCameraIdle
          _selectedLatLng = position;
        });
      } else if (mounted) {
        setState(() {
          _currentFormattedAddress = "Adresse non trouvée";
        });
      }
    } catch (e) {
      print("Erreur Reverse Geocoding: $e");
      if (mounted) {
        setState(() {
          _currentFormattedAddress = "Erreur recherche adresse";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingAddress = false;
        });
      }
    }
  }

  // --- Met à jour la position du marqueur sur la carte ---
  void _updateMarker(LatLng position) {
    // Mettre à jour l'état LatLng ici est important car c'est la référence
    _selectedLatLng = position;
    setState(() {
      _currentMarker = Marker(
        markerId: const MarkerId('selectedLocation'), // ID constant
        position: position,
        draggable: true, // Permettre de faire glisser
        icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed), // Couleur standard
        onDragEnd: (newPosition) {
          // Quand l'utilisateur lâche le marqueur après l'avoir déplacé
          print("Marqueur déplacé (fin drag) vers: $newPosition");
          _selectedLatLng = newPosition; // Mettre à jour la position stockée
          _getAddressFromCoordinates(
              newPosition); // Chercher la nouvelle adresse
          // Optionnel : Recentrer la caméra si le marqueur est déplacé loin
          _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
        },
        infoWindow: const InfoWindow(title: "Position choisie"),
      );
    });
  }

  // --- Méthode pour sauvegarder l'adresse ---
  Future<void> _saveAddress() async {
    
    // Validation
    if (_labelController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Veuillez donner un nom à l'adresse."),
            backgroundColor: Colors.orange),
      );
      return;
    }
    if (_selectedLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Veuillez sélectionner une position sur la carte."),
          backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isSaving = true;
    });

    // Créer l'objet AddressModel avec les données finales
    final newAddress = AddressModel(
      placeId: widget.selectedPlace.id, // Conserver l'ID original si pertinent
      label: _labelController.text.trim(),
      type: _selectedAddressType.name,
      // Utiliser l'adresse formatée trouvée via géocodage inversé
      // ou l'adresse initiale si le géocodage a échoué
      address: _currentFormattedAddress ?? widget.selectedPlace.address,
      apartment: _apartmentController.text.trim().isNotEmpty
          ? _apartmentController.text.trim()
          : null,
      landmark: _landmarkController.text.trim().isNotEmpty
          ? _landmarkController.text.trim()
          : null,
      latitude:
          _selectedLatLng!.latitude, // <-- Coordonnées finales de la carte
      longitude:
          _selectedLatLng!.longitude, // <-- Coordonnées finales de la carte
      isDefault: false, // Gérer la logique 'isDefault' si nécessaire
    );

    // Appel au Cubit
    try {
      await context.read<ProfileCubit>().saveAddress(newAddress);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("'${newAddress.label}' enregistrée !"),
              backgroundColor: Colors.green),
        );
        // Revenir en arrière de 2 pages (SavePage -> SearchPage -> Page précédente)
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      print("Erreur lors de l'appel à saveAddress: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Erreur lors de l'enregistrement : $e"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context)),
        title: Text("Ajouter une adresse"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        // Permet le défilement si le contenu dépasse
        padding: const EdgeInsets.only(
            bottom: 80), // Espace pour le bouton flottant en bas
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Carte Google Map ---
            SizedBox(
              height: 280, // Augmenter un peu la hauteur
              child: GoogleMap(
                initialCameraPosition: _initialCameraPosition,
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  // S'assurer que le marqueur est bien à sa place initiale
                  if (_selectedLatLng != null) {
                    _updateMarker(_selectedLatLng!);
                  }
                },
                markers: _currentMarker != null ? {_currentMarker!} : {},
                // Déplacer la carte met à jour la position cible
                // On peut utiliser onCameraIdle OU le drag du marqueur pour mettre à jour l'adresse
                onCameraMove: (CameraPosition position) {
                  // Optionnel: Mettre à jour la position du marqueur PENDANT le mouvement
                  // Peut être moins performant que juste onDragEnd/onCameraIdle
                  _updateMarker(position.target);
                },
                onCameraIdle: () async {
                  // Appel quand la carte arrête de bouger
                  // On peut récupérer le centre et mettre à jour l'adresse
                  if (_mapController != null && _selectedLatLng != null) {
                    print(
                        "Camera Idle. Position actuelle du marqueur: $_selectedLatLng");
                    // Lancer le géocodage inversé pour la position du marqueur
                    _getAddressFromCoordinates(_selectedLatLng!);
                  }
                },
                myLocationEnabled:
                    true, // Affiche le point bleu de la position GPS
                myLocationButtonEnabled:
                    true, // Affiche le bouton pour centrer sur le GPS
                mapToolbarEnabled:
                    false, // Cacher la barre d'outils Google Maps
                zoomControlsEnabled: true, // Afficher les contrôles de zoom +/-
                mapType: MapType.normal,
                padding: const EdgeInsets.only(
                    bottom: 30), // Pour décaler le logo Google
              ),
            ),

            // --- Section Infos Adresse ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Affichage Adresse Sélectionnée/Dérivée
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_pin,
                          color: Theme.of(context).primaryColor, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                _labelController.text.isNotEmpty
                                    ? _labelController.text
                                    : widget.selectedPlace.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold)),
                            SizedBox(height: 5),
                            if (_isFetchingAddress)
                              Row(children: [
                                const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5)),
                                const SizedBox(width: 8),
                                Text("Recherche de l'adresse...",
                                    style: TextStyle(
                                        fontSize: 13, color: Colors.grey[600]))
                              ])
                            else
                              Text(
                                  _currentFormattedAddress ??
                                      "Ajustez le marqueur sur la carte",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      // Optionnel: Bouton "Change" pour revenir à la recherche
                      // TextButton(onPressed: () => Navigator.pop(context), child: Text(locale.change ?? "Change")),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Champs de Texte (Label, Appart, Repère)
                  _buildTextField(
                    controller: _labelController,
                    label: "Label / Nom adresse (ex: Maison)",
                    icon: Icons.label_outline,
                    required: true,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _apartmentController,
                    label: "Appartement, étage, etc.",
                    icon: Icons.business_outlined,
                    required: false,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _landmarkController,
                    label: "Point de repère (optionnel)",
                    icon: Icons.flag_outlined,
                    required: false,
                  ),
                  SizedBox(height: 24),

                  // Type d'Adresse
                  Text("Type d'adresse",
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: AddressType.values.map((type) {
                      bool isSelected = _selectedAddressType == type;
                      return ChoiceChip(
                        label: Text(addressTypeToString(
                            type)), // Assurez-vous que cette fonction existe
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedAddressType = type;
                            });
                          }
                        },
                        selectedColor:
                            Theme.of(context).primaryColor.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: StadiumBorder(
                            side: BorderSide(
                                color: isSelected
                                    ? Theme.of(context).primaryColor
                                    : Colors.grey[300]!)),
                        backgroundColor: Theme.of(context).cardColor,
                        showCheckmark: false,
                        avatar: isSelected
                            ? Icon(Icons.check_circle_outline,
                                size: 18, color: Theme.of(context).primaryColor)
                            : null,
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      );
                    }).toList(),
                  ),
                  // Espace ajouté pour éviter que le bouton ne colle trop
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),

      // --- Bouton Sauvegarder ---
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            16.0, 8.0, 16.0, MediaQuery.of(context).padding.bottom + 16.0),
        child: ElevatedButton.icon(
          icon: _isSaving
              ? Container(
                  width: 20,
                  height: 20,
                  margin: EdgeInsets.only(right: 8),
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Icon(Icons.save_outlined, size: 20),
          label: Text(_isSaving
              ? ('Enregistrement...')
              : (locale.saveAddress ?? 'Enregistrer l\'adresse')),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 14),
            backgroundColor: kMainColor, // Utilisez votre couleur principale
            foregroundColor: Colors.white,
            textStyle: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed:
              _isSaving ? null : _saveAddress, // Désactiver pendant chargement
        ),
      ),
    );
  }

  // Helper pour créer les TextField
  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool required = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[500]),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(
                  color: Theme.of(context).primaryColor, width: 1.5)),
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 12)),
      textCapitalization: TextCapitalization.sentences,
    );
  }
}

// --- Assurez-vous que cette fonction existe quelque part accessible ---
// (peut être dans le même fichier ou dans un fichier d'helpers)
