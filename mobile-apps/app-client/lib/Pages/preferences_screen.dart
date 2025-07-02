import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart'; // Importer AuthCubit
import 'package:hungerz/Components/bottom_bar.dart'; // <-- Importer votre BottomBar
// <-- Importer AppLocalizations

class PreferencesScreen extends StatefulWidget {
  final String userId;

  const PreferencesScreen({required this.userId, super.key});

  // Nom de route
  static const String routeName = '/preferences'; // Ou AppRoutes.preferences

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  // États locaux pour les sélections
  final Map<String, bool> _dietarySelections = {
    'vegetarian': false, 'vegan': false, 'glutenFree': false, 'dairyFree': false,
  };
  final Map<String, bool> _healthSelections = {
    'low_carb': false, 'low_fat': false, 'low_sugar': false, 'low_sodium': false,
  };
  bool _isLoading = false; // État de chargement

  // --- Fonction de soumission (inchangée) ---
  void _submitPreferences() {
    if (_isLoading) return;
    setState(() { _isLoading = true; });
    final preferencesData = {
      'dietaryProfile': _dietarySelections,
      'healthProfile': _healthSelections,
    };
    context.read<AuthCubit>().submitPreferences(widget.userId, preferencesData)
      .catchError((e){ if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur inattendue.")));}) // TODO: Localize
      .whenComplete(() { if (mounted) setState(() => _isLoading = false); });
    // Navigation gérée par Listener GLOBAL dans main.dart
  }

  // Helper Checkbox (inchangé)
  Widget _buildCheckbox({ required String title, required String profileKey, required String optionKey,}) {
    final selectionsMap = (profileKey == 'dietary') ? _dietarySelections : _healthSelections;
    return CheckboxListTile(
      title: Text(title),
      value: selectionsMap[optionKey],
      onChanged: (bool? newValue) {
        if (newValue != null && mounted) {
          setState(() { selectionsMap[optionKey] = newValue; });
        }
      },
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Theme.of(context).primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser AppLocalizations pour les textes
   

    return Scaffold(
      appBar: AppBar(
        title: Text( "Vos Préférences", style: Theme.of(context).textTheme.bodyLarge), // Texte localisé
      ),
      // Listener pour les erreurs pendant la soumission
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
           if (state is AuthError) {
               if (mounted && _isLoading) { // Erreur pendant notre soumission
                  FocusScope.of(context).unfocus();
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                  );
                  setState(() => _isLoading = false);
               }
           } else if (state is! AuthLoading && _isLoading) {
                 if (mounted) setState(() => _isLoading = false);
           }
           // Navigation vers Home gérée par listener global
        },
        // Utilisation d'un Stack pour positionner BottomBar en bas
        child: Stack(
          children: [
            // Contenu scrollable (avec padding pour ne pas être sous la BottomBar)
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 80.0), // Ajout padding bas pour BottomBar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                     "Profil Diététique", // Localisé
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildCheckbox(title:  "Végétarien", profileKey: 'dietary', optionKey: 'vegetarian'),
                  _buildCheckbox(title:  "Vegan", profileKey: 'dietary', optionKey: 'vegan'),
                  _buildCheckbox(title:  "Sans Gluten", profileKey: 'dietary', optionKey: 'glutenFree'),
                  _buildCheckbox(title:  "Sans Lactose", profileKey: 'dietary', optionKey: 'dairyFree'),

                  const SizedBox(height: 24),

                  Text(
                      "Profil Santé", // Localisé
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _buildCheckbox(title:  "Faible en Glucides", profileKey: 'health', optionKey: 'low_carb'),
                  _buildCheckbox(title:  "Faible en Gras", profileKey: 'health', optionKey: 'low_fat'),
                  _buildCheckbox(title:  "Faible en Sucre", profileKey: 'health', optionKey: 'low_sugar'),
                  _buildCheckbox(title:  "Faible en Sodium", profileKey: 'health', optionKey: 'low_sodium'),

                  // Le bouton n'est plus dans cette Column
                ],
              ),
            ),

            // --- Utilisation de votre BottomBar en bas de l'écran ---
            Align(
              alignment: Alignment.bottomCenter,
              child: BottomBar( // Utilisation de votre widget
                text: _isLoading
                    ? ( "Chargement...") // Texte chargement
                    // Texte normal (utilisez la clé de localisation appropriée)
                    : ( "ENREGISTRER"), // Ou "TERMINER" ? Adaptez.
                // Désactiver onTap si en chargement, sinon appeler _submitPreferences
                onTap: _isLoading ? (){} : _submitPreferences,
              ),
            ),
            // --- Fin BottomBar ---
          ],
        ),
      ),
    );
  }
}