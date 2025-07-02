import 'package:flutter/material.dart';
import 'package:hungerz/Auth/MobileNumber/UI/phone_number.dart';
import 'package:hungerz/Auth/Registration/UI/register_page.dart';
import 'package:hungerz/Auth/Verification/UI/verification_page.dart'; // Assurez-vous d'importer la page modifiée
import 'package:hungerz/Auth/social.dart'; // Assurez-vous que SocialLogIn est bien défini ici ou importez-le séparément
// import 'package:hungerz/Auth/social_login_screen.dart'; // Ou le chemin vers SocialLogIn si différent
import 'package:hungerz/Routes/routes.dart'; // Pour PageRoutes.homeOrderAccountPage si encore utilisé ailleurs

// Clé Globale pour le Navigator imbriqué (si nécessaire ailleurs)
GlobalKey<NavigatorState> loginNavigatorKey = GlobalKey<NavigatorState>();

class LoginRoutes {
  static const String signInRoot = 'signInRoot'; // Simplifié sans /
  static const String signUp = 'signUp';
  static const String verification = 'verification';
  static const String socialLogin = 'socialLogin'; // Écran de saisie du numéro
}

class LoginNavigator extends StatelessWidget {
  const LoginNavigator({super.key});

  // Gère le bouton retour : pop interne d'abord, puis pop principal
  void _checkCanPop(BuildContext context) {
    // Utiliser la clé globale définie ci-dessus
    final nestedNavigator = loginNavigatorKey.currentState;
    if (nestedNavigator != null && nestedNavigator.canPop()) {
      nestedNavigator.pop();
    } else {
      // Si le navigateur interne ne peut pas pop, on pop le navigateur principal
      // (ce qui retire LoginNavigator de AuthCheckScreen)
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // NavigatorPopHandler peut être utile si vous avez besoin de gérer les résultats
    // mais pour un simple pop, on peut le gérer via WillPopScope ou AppBar
    // Utilisons WillPopScope pour intercepter le bouton retour Android
    return WillPopScope(
      onWillPop: () async {
        // Logique pour intercepter le bouton retour Android
        final nestedNavigator = loginNavigatorKey.currentState;
        if (nestedNavigator != null && nestedNavigator.canPop()) {
          nestedNavigator.pop();
          return false; // Empêche le pop du navigateur principal
        }
        return true; // Autorise le pop du navigateur principal
      },
      child: Navigator(
        key: loginNavigatorKey, // Utiliser la clé globale
        initialRoute:LoginRoutes.signInRoot, // Commence par PhoneNumber
        onGenerateRoute: (RouteSettings settings) {
          late WidgetBuilder builder;
          switch (settings.name) {
            case LoginRoutes.signInRoot:
              builder = (BuildContext _) => const PhoneNumber();
              break;
            case LoginRoutes.signUp:
              builder = (BuildContext _) => const RegisterPage();
              break;

            // --- CASE CORRIGÉ ---
            case LoginRoutes.verification:
              // 1. Récupérer l'argument phoneNumber passé par pushNamed
              if (settings.arguments is String) {
                 final String phoneNumber = settings.arguments as String;
                 // 2. Utiliser le nouveau constructeur de VerificationPage
                 builder = (BuildContext _) => VerificationPage(phoneNumber: phoneNumber);
              } else {
                 // Gérer le cas où l'argument est manquant ou incorrect
                 print("ERREUR: Argument 'phoneNumber' manquant pour la route ${settings.name}");
                 // Afficher une page d'erreur ou revenir en arrière ?
                 builder = (BuildContext _) => Scaffold(body: Center(child: Text("Erreur: Numéro manquant"))); // Exemple
              }
              break;
            // --- FIN CORRECTION ---

            case LoginRoutes.socialLogin: // C'est l'écran où on saisit le numéro maintenant
              builder = (BuildContext _) => const SocialLogIn();
              break;

            default:
              // Gérer les routes inconnues
               print("ERREUR: Route inconnue dans LoginNavigator: ${settings.name}");
               builder = (BuildContext _) => Scaffold(body: Center(child: Text("Route inconnue: ${settings.name}")));
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      ),
    );
  }
}