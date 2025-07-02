import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:hungerz/Config/app_config.dart';
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart';
import 'package:hungerz/Locale/locales.dart';
import 'package:hungerz/cubits/cart_cubit/cart_cubit.dart';
import 'package:hungerz/cubits/dishes_cubit/dishes_cubit.dart';
import 'package:hungerz/cubits/location_cubit/location_cubit.dart';
import 'package:hungerz/cubits/order_cubit/order_cubit.dart';
import 'package:hungerz/cubits/profile_cubit/profile_cubit.dart';
import 'package:hungerz/cubits/rating_cubit/rating_cubit.dart';
import 'package:hungerz/cubits/reservation_cubit/reservation_cubit.dart';
import 'package:hungerz/cubits/table_session_cubit/table_session_cubit.dart';
import 'package:hungerz/cubits/unpaid_bill_cubit/unpaid_bill_cubit.dart';
import 'package:hungerz/repositories/unpaid_bill_repository.dart';
import 'package:hungerz/services/socket_service.dart'; // Import the socket service

import 'package:hungerz/language_cubit.dart';
import 'package:hungerz/Pages/preferences_screen.dart';
import 'package:hungerz/repositories/order_repository.dart';
import 'package:hungerz/repositories/rating_repository.dart';
import 'package:hungerz/repositories/user_repository.dart';
import 'package:hungerz/repositories/reservation_repository.dart';
import 'package:hungerz/services/stripe_service.dart';
import 'package:hungerz/theme_cubit.dart';

import 'package:hungerz/Auth/MobileNumber/UI/phone_number.dart';
import 'package:hungerz/Auth/social.dart';
import 'package:hungerz/Auth/Verification/UI/verification_page.dart';
import 'package:hungerz/HomeOrderAccount/home_order_account.dart';
import 'package:hungerz/Auth/Registration/UI/register_page.dart';
import 'package:hungerz/Routes/routes.dart';

class AppRoutes {
  static const String loginPhone = '/loginPhone';
  static const String enterPhone = '/enterPhone';
  static const String verifyOtp = '/verifyOtp';
  static const String preferences = '/preferences';
  static const String home = '/home';
  static const String register = '/register';
}

// --- Clé Globale pour le Navigateur Principal ---
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
    try {
    await dotenv.load(fileName: ".env"); // Charge le fichier .env
    print(".env chargé avec succès.");
  } catch (e) {
    print("Erreur lors du chargement du fichier .env: $e");
    // Gérer l'erreur si nécessaire (ex: valeurs par défaut, arrêt de l'app?)
  }
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey =
      AppConfig.stripePublishableKey; // Clé publique Stripe
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));


  // Create AuthCubit first
  final httpClient = http.Client();
  final authCubit = AuthCubit(httpClient: httpClient);

  // Initialize SocketService with AuthCubit

  runApp(Phoenix(child: HungerzApp(authCubit: authCubit)));
}



class HungerzApp extends StatelessWidget {
  final AuthCubit authCubit;

  const HungerzApp({super.key, required this.authCubit});

  @override
  Widget build(BuildContext context) {
    final httpClient = http.Client(); // Client HTTP pour les requêtes API
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<UnpaidBillRepository>(create: (context) {
          return UnpaidBillRepository(httpClient: httpClient);
        }),
        RepositoryProvider<UserRepository>(
          create: (context) => UserRepository(httpClient: httpClient),
        ),
        RepositoryProvider<OrderRepository>(
          create: (context) => OrderRepository(httpClient: httpClient),
        ),
        RepositoryProvider<ReservationRepository>(
          create: (context) => ReservationRepository(httpClient: httpClient),
        ),
        RepositoryProvider<RatingRepository>(
          create: (context) => RatingRepository(httpClient: httpClient),
        ),
        // Add UserAppSocketService to repository providers
        // Change 'Provider' to 'RepositoryProvider' here
        RepositoryProvider<UserAppSocketService>(
          create: (_) => UserAppSocketService(),
          dispose: (service) => service.dispose(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(
              value: authCubit), // Provide the existing instance
          BlocProvider<DishesCubit>(
              create: (context) => DishesCubit(
                  httpClient: httpClient,
                  authCubit: context.read<AuthCubit>())),
          BlocProvider<CartCubit>(
              create: (context) => CartCubit()), // Cubit pour le thème
          BlocProvider<TableSessionCubit>(
            create: (context) => TableSessionCubit(
              socketService: context.read<UserAppSocketService>(),
              cartCubit: context.read<CartCubit>(),
            ),
            lazy: false,
          ),
          BlocProvider<UnpaidBillCubit>(create: (context) {
            return UnpaidBillCubit(
              unpaidBillRepository: context.read<UnpaidBillRepository>(),
              authCubit: context.read<AuthCubit>(),
              stripeService: StripeService.instance, // Injecter StripeService
            );
          }),
          BlocProvider<LanguageCubit>(create: (context) => LanguageCubit()),
          BlocProvider<ThemeCubit>(create: (context) => ThemeCubit()),
          BlocProvider<LocationCubit>(
            create: (context) => LocationCubit(),
            lazy:
                false, // Important pour lancer getCurrentLocation au démarrage
          ),
          BlocProvider<ProfileCubit>(
            create: (context) {
              print("Création globale de ProfileCubit");
              // Il est créé au démarrage, mais il devra écouter AuthCubit
              // pour savoir quand charger le profil et obtenir le token.
              return ProfileCubit(
                // Il a besoin du UserRepository
                userRepository: context.read<UserRepository>(),
                // Il a besoin de AuthCubit pour écouter les changements d'état
                // et obtenir le token quand nécessaire.
                authCubit: context.read<AuthCubit>(),
              );
            },
            lazy:
                false, // Mettre false si vous voulez qu'il écoute AuthCubit dès le début
            // Sinon, il ne sera créé/écoutera que lors du premier accès.
            // 'false' est probablement mieux ici.
          ),
          BlocProvider<OrderCubit>(
            create: (context) => OrderCubit(
              orderRepository: context.read<OrderRepository>(),
              authCubit: context.read<
                  AuthCubit>(), // OrderCubit a besoin de AuthCubit pour le token
            ),
          ),
          BlocProvider<RatingCubit>(
            create: (context) => RatingCubit(
              ratingRepository: context.read<RatingRepository>(),
              authCubit: context.read<AuthCubit>(), // AuthCubit pour le token
            ),
          ),
          BlocProvider<ReservationCubit>(
            create: (context) => ReservationCubit(
              // Lit les dépendances fournies plus haut
              reservationRepository: context.read<ReservationRepository>(),
              authCubit: context.read<AuthCubit>(),
            ),
            // lazy: false, // Pas forcément nécessaire ici, dépend quand vous voulez l'activer
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeData>(
          builder: (_, theme) => BlocBuilder<LanguageCubit, Locale>(
            builder: (_, locale) => MaterialApp(
              navigatorKey: navigatorKey, // Assignation clé globale

              // --- Listener Global pour Navigation & Effets ---
              builder: (context, child) {
                return BlocListener<AuthCubit, AuthState>(
                  listenWhen: (previous, current) {
                    // Écoute tous les changements SAUF Authenticated -> Authenticated
                    final isUpdateWithinAuthenticated =
                        previous is Authenticated && current is Authenticated;
                    print(
                        "BlocListener listenWhen: previous=${previous.runtimeType}, current=${current.runtimeType}, shouldListen=${!isUpdateWithinAuthenticated}");
                    return !isUpdateWithinAuthenticated;
                  },
                  listener: (context, state) {
                    print(
                        ">>> Global Listener: Nouvel état -> ${state.runtimeType}");
                    final navigator = navigatorKey.currentState;
                    if (navigator == null) return;

                    // --- Logique de Navigation Centralisée ---
                    if (state is GoogleSignInSuccessfulNeedsPhone) {
                      print(
                          ">>> Global Listener: Navigation vers ${AppRoutes.enterPhone}");
                      navigator.pushNamed(AppRoutes.enterPhone,
                          arguments: state.userId);
                    } else if (state is PhoneSubmittedAwaitingOtp) {
                      print(
                          ">>> Global Listener: Navigation vers ${AppRoutes.verifyOtp} avec ${state.phoneNumber}");
                      navigator.pushNamed(AppRoutes.verifyOtp,
                          arguments: state.phoneNumber);
                    } else if (state is OtpVerifiedNeedsPreferences) {
                      print(
                          ">>> Global Listener: Navigation vers ${AppRoutes.preferences} avec userId: ${state.userId}");
                      navigator.pushReplacementNamed(AppRoutes.preferences,
                          arguments: state.userId);
                    } else if (state is Authenticated) {
                      print(
                          ">>> Global Listener: Navigation vers ${AppRoutes.home} (remplacement total)");
                      // Navigation vers votre écran d'accueil confirmé
                      navigator.pushNamedAndRemoveUntil(
                          AppRoutes.home, (route) => false);
                    } else if (state is Unauthenticated) {
                      print(
                          ">>> Global Listener: Navigation vers ${AppRoutes.loginPhone} (remplacement total)");
                      final currentRouteName =
                          ModalRoute.of(navigator.context)?.settings.name;
                      // Vérifier qu'on n'est pas déjà sur l'écran de login pour éviter boucle
                      if (currentRouteName != AppRoutes.loginPhone &&
                          currentRouteName != '/') {
                        navigator.pushNamedAndRemoveUntil(
                            AppRoutes.loginPhone, (route) => false);
                      }
                    } else if (state is AuthError) {
                      print(
                          ">>> Global Listener: Erreur Auth -> ${state.message}");
                      ScaffoldMessenger.of(navigator.context).showSnackBar(
                        SnackBar(
                            content: Text("Erreur: ${state.message}"),
                            backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: child!,
                );
              },

              localizationsDelegates: const [
                AppLocalizationsDelegate(),
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: AppLocalizations.getSupportedLocales(),
              locale: locale,
              theme: theme,
              debugShowCheckedModeBanner: false,

              home: const AuthCheckBuilder(),

              onGenerateRoute: (settings) {
                print("onGenerateRoute: Génération pour '${settings.name}'");

                Widget? page;
                switch (settings.name) {
                  case '/':
                  case AppRoutes.loginPhone:
                    page = const PhoneNumber();
                    break;
                  case AppRoutes.enterPhone:
                    final userId = settings.arguments as String?;
                    if (userId != null) page = SocialLogIn();
                    break;
                  case AppRoutes.verifyOtp:
                    final phoneNumber = settings.arguments as String?;
                    if (phoneNumber != null)
                      page = VerificationPage(phoneNumber: phoneNumber);
                    break;
                  case AppRoutes.preferences:
                    final userId = settings.arguments as String?;
                    if (userId != null)
                      page = PreferencesScreen(userId: userId);
                    break;
                  case AppRoutes.home:
                    page = const HomeOrderAccount();
                    break;
                  case AppRoutes.register:
                    page = const RegisterPage();
                    break;
                }

                if (page != null) {
                  if ((settings.name == AppRoutes.enterPhone ||
                          settings.name == AppRoutes.preferences ||
                          settings.name == AppRoutes.verifyOtp) &&
                      page == null) {
                    print(
                        "ERREUR ROUTE: Argument manquant pour ${settings.name}, fallback vers loginPhone");
                    return MaterialPageRoute(
                        builder: (_) => const PhoneNumber());
                  }
                  return MaterialPageRoute(
                      builder: (_) => page!, settings: settings);
                }

                print(
                    "onGenerateRoute: Route '${settings.name}' non trouvée dans le switch principal, recherche dans PageRoutes...");
                final pageRoutesMap = PageRoutes().routes();
                if (pageRoutesMap.containsKey(settings.name)) {
                  print(
                      "onGenerateRoute: Utilisation de PageRoutes pour '${settings.name}'");

                  return MaterialPageRoute(
                      builder: pageRoutesMap[settings.name]!,
                      settings: settings);
                }

                print(
                    "ERREUR: Route inconnue dans onGenerateRoute: ${settings.name}");
                return MaterialPageRoute(
                    builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text("Erreur")),
                        body: Center(
                            child: Text("Page inconnue: ${settings.name}"))));
              },
            ),
          ),
        ),
      ),
    );
  }
}

class AuthCheckBuilder extends StatelessWidget {
  const AuthCheckBuilder({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        print(
            "AuthCheckBuilder: Construire pour l'état -> ${state.runtimeType}");

        if (state is Authenticated) {
          return const HomeOrderAccount();
        } else if (state is AuthInitial || state is AuthLoading) {
          return Scaffold(
              body: Center(
                  child: Column(
            children: [
              const SizedBox(height: 100),
              Image.asset(
                'images/logo_light.png',
                width: 400,
                height: 400,
              ),
              CircularProgressIndicator(),
            ],
          )));
        } else {
          return const PhoneNumber();
        }
      },
    );
  }
}
