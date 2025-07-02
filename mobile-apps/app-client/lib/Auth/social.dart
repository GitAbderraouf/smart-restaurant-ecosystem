import 'package:animation_wrappers/animation_wrappers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import Bloc
import 'package:hungerz/Auth/login_navigator.dart';
import 'package:hungerz/Components/bottom_bar.dart'; // Gardé
// import 'package:hungerz/Components/textfield.dart'; // Remplacé par TextFormField standard
import 'package:hungerz/Locale/locales.dart'; // Gardé
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart'; // Importer AuthCubit

class SocialLogIn extends StatefulWidget {
  const SocialLogIn({super.key});

  // Nom de route
  static const String routeName = LoginRoutes.socialLogin;

  @override
  _SocialLogInState createState() => _SocialLogInState();
}

class _SocialLogInState extends State<SocialLogIn> {
  final TextEditingController _phoneController = TextEditingController(); // Renommé pour clarté
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // Fonction pour soumettre le numéro
  void _submitPhoneNumber() {
    // ... validation, setState ...
    final String phoneNumber = _phoneController.text.trim();
    final authCubit = context.read<AuthCubit>();
    final currentState = authCubit.state;

    // Déclarer userId *avant* le if pour qu'il soit accessible après
    String? userId; // Déclaré ici, initialement null

    if (currentState is GoogleSignInSuccessfulNeedsPhone) {
      // Assigner la valeur si l'état est correct
      userId = currentState.userId; // userId (de portée externe) reçoit la valeur
      print("SocialLogin: userId récupéré depuis l'état: $userId");
    } else {
      // Cas où l'état n'est pas celui attendu au moment de cliquer sur le bouton
      // C'est un problème, on ne devrait pas pouvoir soumettre sans userId ici.
      print("ERREUR: État inattendu ($currentState) lors de la tentative de soumission du numéro.");
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Erreur interne : état utilisateur incorrect."), backgroundColor: Colors.orange), // TODO: Localize
      );
      // Arrêter le chargement et sortir de la fonction
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // --- Appel à submitPhoneNumber ---
    // Maintenant 'userId' est accessible et non-nul ici
    print("Appel de submitPhoneNumber avec userId: $userId");
    authCubit.submitPhoneNumber(phoneNumber, userId: userId).then((_) { // <--- Utilisation de userId externe
      // ... la logique .then() reste la même ...
       if (mounted && authCubit.state is! AuthError) {
         print("SocialLogin: Soumission numéro OK (pas d'erreur émise). Navigation vers Verification...");
         Navigator.pushNamed(
           context,
           LoginRoutes.verification,
           arguments: phoneNumber
         );
       } else if (mounted) {
          print("SocialLogin: Soumission terminée mais état final est une erreur.");
       }
    }).catchError((error) {
       // ... gestion catchError ...
    }).whenComplete(() {
       // ... gestion whenComplete ...
       if (mounted) setState(() => _isLoading = false );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Le listener est à l'intérieur du Scaffold pour le contexte du SnackBar
    return Scaffold(
      appBar: PreferredSize( // Gardé comme dans votre code
        preferredSize: const Size.fromHeight(100),
        child: AppBar(
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.chevron_left, size: 30),
            onPressed: _isLoading ? null : () => Navigator.pop(context),
          ),
          // backgroundColor: Colors.transparent, // Optionnel
          // elevation: 0, // Optionnel
        ),
      ),
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
           // Gérer le loading/error pendant l'appel submitPhoneNumber
           if (state is AuthLoading) {
              // setState(() => _isLoading = true); // Géré au début de _submitPhoneNumber
           } else if (state is AuthError) {
              if (mounted) {
                 FocusScope.of(context).unfocus(); // Cacher clavier en cas d'erreur
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(state.message), backgroundColor: Colors.red),
                 );
                 // S'assurer que isLoading est bien false si une erreur survient pendant le chargement
                 if (_isLoading) setState(() => _isLoading = false);
              }
           } else {
                // Si un autre état arrive pendant qu'on chargeait (et pas une erreur)
                 if (_isLoading && mounted) setState(() => _isLoading = false);
           }
           // La navigation se fait dans le .then() de _submitPhoneNumber
        },
        child: FadedSlideAnimation( // Gardé comme dans votre code
          beginOffset: const Offset(0.0, 0.3),
          endOffset: Offset.zero,
          slideCurve: Curves.linearToEaseOut,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                // Ajouter un Form pour la validation
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FadedScaleAnimation( // Gardé
                        fadeDuration: const Duration(milliseconds: 800),
                        child: Text(
                          AppLocalizations.of(context)!.hey!, // Gardé
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium!
                              .copyWith(fontSize: 25.0),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        AppLocalizations.of(context)!.youreAlmostin!, // Gardé
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium!
                            .copyWith(fontSize: 18.0),
                      ),
                       Padding(
                        padding: const EdgeInsets.only(top: 50.0),
                        child: Row(
                          children: [
                             Icon(
                              Icons.phone_android,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 10),
                            // Texte modifié pour être plus clair
                            Text( "ENTREZ VOTRE NUMÉRO DE TÉLÉPHONE", // Gardé et ajout de fallback
                                style: TextStyle(
                                    color: Colors.grey[600], fontSize: 12))
                          ],
                        ),
                      ),
                      // --- Remplacement de SmallTextFormField ---
                      Padding(
                        padding: const EdgeInsets.only(left: 0, top: 8.0), // Ajustement padding
                        child: TextFormField(
                           controller: _phoneController, // <<--- UTILISATION DU CONTROLLER
                           keyboardType: TextInputType.phone,
                           decoration: InputDecoration(
                             // Reproduire le style si possible, sinon style par défaut
                             hintText: "+213 123 45 67 89", // TODO: Localize placeholder
                             // prefixIcon: Icon(Icons.phone), // L'icône est déjà au-dessus
                             border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300)
                             ),
                             focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Theme.of(context).primaryColor)
                             ),
                             contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                           ),
                           validator: (value) {
                             if (value == null || value.trim().isEmpty) {
                               return  "Numéro requis"; // Gardé
                             }
                             // TODO: Ajouter validation format numéro
                             return null;
                           },
                        ),
                      ),
                      // --- Fin Remplacement ---
                      Padding(
                        padding: const EdgeInsets.only(left: 0, top: 15.0), // Ajustement padding
                        child: Text(
                          AppLocalizations.of(context)!.verificationText!, // Gardé
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall, // Style peut-être plus adapté ?
                              // .copyWith(fontSize: 12.8),
                        ),
                      ),
                       const Spacer(), // Pour pousser le bouton en bas si contenu court
                    ],
                  ),
                ),
              ),
              // --- Utilisation de votre BottomBar ---
              Align(
                alignment: Alignment.bottomCenter,
                child: BottomBar( // Gardé
                    text: _isLoading
                       ? ( "Chargement...") // Gardé
                       : ( "Continuer"), // Gardé
                    // Taper sur la barre appelle _submitPhoneNumber
                    onTap: _isLoading ? () {} : _submitPhoneNumber // Modifié
                 ),
              )
              // --- Fin BottomBar ---
            ],
          ),
        )
      ),
    );
  }
}