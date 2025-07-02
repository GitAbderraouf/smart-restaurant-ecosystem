import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Importer les écrans directement ou via les routes
import 'package:hungerz/Auth/MobileNumber/UI/phone_number.dart'; // Point d'entrée si non authentifié
import 'package:hungerz/HomeOrderAccount/Home/UI/home.dart'; // Écran si authentifié
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart';
import 'package:hungerz/HomeOrderAccount/home_order_account.dart';
import 'package:hungerz/Routes/routes.dart';
// import 'package:hungerz/routes/app_routes.dart'; // Pas nécessaire ici si on retourne les widgets

class AuthCheckScreen extends StatelessWidget {
  const AuthCheckScreen({super.key});

  // Nom de route si utilisé avec initialRoute
  //static const String routeName = PageRoutes.authCheck;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        print("AuthCheckScreen: Construire pour l'état -> ${state.runtimeType}");

        if (state is Authenticated) {
          // Si l'état final est Authenticated (après OTP), afficher Home.
          // La navigation effective a déjà été faite par le Listener Global.
          // Retourner Home ici assure que si l'état est déjà Authenticated au build, on affiche Home.
          return const HomeOrderAccount();
        }
        else if (state is AuthInitial || state is AuthLoading) {
          // Afficher l'écran de chargement pendant l'initialisation ou une opération globale.
          return Scaffold(
            body: Center(child: Column(
              children: [Image.asset("images/logo_light.png"), // Logo de l'application
                SizedBox(height: 20),
                CircularProgressIndicator(),
              ],
            )),
          );
        }
        else {
          // Pour TOUS les autres états (Unauthenticated, AuthError, GoogleSignInSuccessfulNeedsPhone, PhoneSubmittedAwaitingOtp...),
          // l'utilisateur doit se trouver dans le flux de connexion/vérification.
          // On affiche donc l'écran de départ de ce flux.
          return const PhoneNumber();
        }
      },
    );
  }
}