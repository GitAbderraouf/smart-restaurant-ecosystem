// Dans AuthCubit.dart

import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:hungerz/Config/app_config.dart';
import 'package:hungerz/models/user_model.dart';
import 'package:hungerz/services/socket_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
 // Adaptez chemin

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
// In AuthCubit.dart
final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: AppConfig.serverClientId, // <-- CORRECTED VALUE
);
  final _secureStorage = const FlutterSecureStorage();
  final String _backendTokenKey = 'backend_session_token';
  final String _apiBaseUrl = AppConfig.baseUrl; // Adaptez IP/Port/Base
  final http.Client _httpClient;
  AuthCubit({http.Client? httpClient,})
      : _httpClient = httpClient ?? http.Client(),
        super(AuthInitial()) {
    checkAuthStatus();
    UserAppSocketService.initialize(this);
  }

  // --- checkAuthStatus (utilise GET /api/auth/me) ---
  Future<void> checkAuthStatus() async {
    if (state is! Authenticated) emit(AuthLoading());
    String? currentToken;
    try {
      currentToken = await _secureStorage.read(key: _backendTokenKey);
      print("AuthCubit: Current token: $currentToken");
      if (currentToken == null || currentToken.isEmpty) {
        emit(Unauthenticated());
        return;
      }

      final response = await _httpClient.get(
        Uri.parse(
            '$_apiBaseUrl/users/profile'), // Endpoint pour vérifier + rafraîchir
        headers: {'Authorization': 'Bearer $currentToken'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        // --- PARSING UserModel ---
        final user = UserModel.fromJson(
            responseData['user']); // Le backend renvoie l'user directement

        // --- GESTION TOKEN RAFRAÎCHI ---
        // Utilise la clé 'refreshedToken' comme défini dans le backend getMyProfile
        String? newToken = responseData['refreshedToken'] as String?;
        String tokenToUse = currentToken; // Utiliser l'ancien par défaut

        if (newToken != null && newToken.isNotEmpty) {
          await _secureStorage.write(key: _backendTokenKey, value: newToken);
          tokenToUse = newToken;
          print("AuthCubit: Token rafraîchi et stocké.");
        }
        // --- FIN GESTION ---

        // Save userId in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (user.id != null) {
          await prefs.setString('userId', user.id!);
        }

        emit(Authenticated(
            user: user, token: tokenToUse)); // Utiliser user et le bon token
      } else {
        // Inclut 401 Unauthorized
        await _secureStorage.delete(key: _backendTokenKey);
        emit(Unauthenticated());
      }
    } catch (e) {
      await _secureStorage.delete(key: _backendTokenKey);
      emit(AuthError('Erreur vérification session: ${e.toString()}'));
    }
  }

  // --- signInWithGoogle (utilise POST /api/auth/google) ---
// Dans la classe AuthCubit (fichier auth_cubit.dart)

  // Gère la connexion Google initiale et la validation/liaison backend
  Future<void> signInWithGoogle() async {
    // Émettre l'état de chargement au début
    emit(AuthLoading());
    print("signInWithGoogle: Started"); // <-- Print 1: Début de la méthode

    try {
      // --- Étape 1: Connexion Google côté client ---
      print(
          "signInWithGoogle: Calling _googleSignIn.signIn()"); // <-- Print 2: Appel à Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Afficher si l'utilisateur a annulé ou non
      print(
          "signInWithGoogle: _googleSignIn.signIn() completed. googleUser is null? ${googleUser == null}"); // <-- Print 3: Résultat Google

      // Gérer l'annulation par l'utilisateur
      if (googleUser == null) {
        emit(Unauthenticated()); // Remettre à l'état non authentifié
        print(
            "signInWithGoogle: User cancelled Google Sign-In, emitted Unauthenticated"); // <-- Print 4: Annulation
        return; // Arrêter la fonction ici
      }

      // --- Étape 2: Obtenir l'idToken ---
      print(
          "signInWithGoogle: Getting Google authentication details..."); // <-- Print 5: Obtention des tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      // Afficher si l'idToken a été obtenu
      print(
          "signInWithGoogle: Got idToken. Is null? ${idToken == null}"); // <-- Print 6: Résultat idToken
      // Pour débogage SEULEMENT, ne pas laisser en production !
      // if(idToken != null) print("signInWithGoogle: idToken starts with: ${idToken.substring(0, 15)}...");

      // Gérer le cas où l'idToken est manquant
      if (idToken == null) {
        emit(AuthError('Token Google (idToken) non obtenu.'));
        print(
            "signInWithGoogle: idToken was null, emitted AuthError"); // <-- Print 7: Erreur idToken null
        return; // Arrêter la fonction ici
      }

      // --- Étape 3: Appel au Backend ---
      print(
          "signInWithGoogle: Calling backend POST /api/auth/google with idToken..."); // <-- Print 8: Appel Backend
      final response = await _httpClient.post(
        // Utiliser l'URL de base et le chemin corrects
        Uri.parse(
            '$_apiBaseUrl/auth/social-login'), // Assurez-vous que _apiBaseUrl est correct
        headers: {'Content-Type': 'application/json'},
        // Envoyer l'idToken et le provider
        body: jsonEncode({'idToken': idToken, 'provider': 'google'}),
      );
      final responseBody = jsonDecode(response.body);
      // Afficher le statut de la réponse backend
      print(
          "signInWithGoogle: Backend response received. Status: ${response.statusCode}"); // <-- Print 9: Statut Backend
      // Optionnel: Afficher le corps pour déboguer la réponse backend
      // print("signInWithGoogle: Backend response body: ${response.body}");

      // --- Étape 4: Traiter la réponse Backend ---
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Succès ! Le backend a validé Google, l'utilisateur est trouvé/créé.
        // Prochaine étape = demander le téléphone.
        // Vous pouvez parser la réponse si le backend renvoie des infos utiles ici (comme userId)
        // final responseData = jsonDecode(response.body);
        // final userId = responseData['userId'];
        // print("signInWithGoogle: Backend OK (userId: $userId). Emitting GoogleSignInSuccessfulNeedsPhone"); // <-- Print 10: Succès Backend
        print(
            "signInWithGoogle: Backend OK. Emitting GoogleSignInSuccessfulNeedsPhone {userId: ${responseBody['userId']}}"); // <-- Print 10 (simplifié)
        print(responseBody[
                'userId']);
        // Save userId in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (responseBody['userId'] != null) {
          await prefs.setString('userId', responseBody['userId']);
        }
        emit(GoogleSignInSuccessfulNeedsPhone(
            userId: responseBody[
                'userId'])); // Émettre l'état pour passer au téléphone
      } else {
        // Erreur renvoyée par le backend
        String errorMessage = 'Erreur serveur connexion Google';
        try {
          final responseBody = jsonDecode(response.body);
          errorMessage = responseBody['error'] ??
              errorMessage; // Essayer de prendre l'erreur du JSON
        } catch (_) {} // Ignorer les erreurs de parsing JSON

        print(
            "signInWithGoogle: Backend error (${response.statusCode}). Emitting AuthError: $errorMessage"); // <-- Print 11: Erreur Backend
        emit(AuthError(errorMessage));
        // Déconnecter de Google si le backend échoue pour éviter incohérence? Optionnel.
        await _googleSignIn.signOut();
        print("signInWithGoogle: Signed out from Google due to backend error.");
      }
    } catch (e, stackTrace) {
      // Intercepter TOUTES les autres erreurs (réseau, etc.)
      print(
          "!!!! signInWithGoogle: CAUGHT UNEXPECTED ERROR !!!!"); // <-- Print 12: Erreur Catch All
      print("Error: $e");
      print("StackTrace: $stackTrace"); // Très utile pour le débogage
      emit(AuthError('Erreur technique connexion Google: ${e.toString()}'));
      // Déconnecter de Google en cas d'erreur imprévue
      await _googleSignIn.signOut();
      print("signInWithGoogle: Signed out from Google due to caught error.");
    }
  }

// N'oubliez pas d'avoir les autres méthodes (checkAuthStatus, submitPhoneNumber, etc.) dans la classe.

  // --- submitPhoneNumber (utilise POST /api/auth/submit-phone -> appelle sendOTP) ---
  Future<void> submitPhoneNumber(String phoneNumber, {String? userId}) async {
    if (phoneNumber.trim().isEmpty) {
      /* ... validation ... */ return;
    }
    emit(AuthLoading());
    try {
      final body = {'mobileNumber': phoneNumber};
      if (userId != null) {
        body['userId'] = userId;
      }
      body["countryCode"] = "+213"; // Ajouter le code pays si nécessaire
      final response = await _httpClient.post(
        Uri.parse('$_apiBaseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("AuthCubit: Soumission numéro OK. Backend a envoyé l'OTP.");
        // --- Émettre le nouvel état pour déclencher la navigation vers OTP ---
        emit(PhoneSubmittedAwaitingOtp(
            phoneNumber: phoneNumber)); // <-- MODIFIÉ ICI
      } else {
        // ... gestion erreur backend ...
        emit(AuthError("Erreur backend soumission numéro"));
      }
    } catch (e) {
      emit(AuthError("Erreur soumission numéro: ${e.toString()}"));
    }
  }

  // --- completeOtpVerification (utilise POST /api/auth/verify-otp -> appelle verifyOTP) ---
  Future<void> completeOtpVerification(String otp, String phoneNumber) async {
    emit(AuthLoading());
    try {
      final response = await _httpClient.post(
        Uri.parse('$_apiBaseUrl/auth/verify-otp'), // Nouvelle route backend
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobileNumber': phoneNumber, 'otp': otp}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final userId = responseData['userId']
            as String?; // Récupérer userId depuis backend
        if (userId == null) {
          emit(AuthError(
              "Réponse invalide après vérification OTP (userId manquant)."));
          return;
        }
        print("AuthCubit: OTP Vérifié! -> Needs Preferences. UserId: $userId");
        // Save userId in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (userId != null) {
          await prefs.setString('userId', userId);
        }
        emit(OtpVerifiedNeedsPreferences(userId: userId)); // <-- Nouvel état
      } else {
        final responseBody = jsonDecode(response.body);
        emit(AuthError(responseBody['error'] ?? 'Code OTP invalide/expiré'));
      }
    } catch (e) {
      emit(AuthError("Erreur vérification OTP: ${e.toString()}"));
    }
  }

  Future<void> submitPreferences(
      String userId, Map<String, dynamic> preferencesData) async {
    emit(AuthLoading());
    try {
      final response = await _httpClient.post(
          Uri.parse('$_apiBaseUrl/auth/preferences'), // Nouvelle route backend
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': userId, 'preferences': preferencesData}));

      if (response.statusCode == 200) {
        // Le backend renvoie le token FINAL et l'user COMPLET
        final responseData = jsonDecode(response.body);
        final backendToken = responseData['token'] as String?;
        final Map<String, dynamic>? userData =
            responseData['user'] as Map<String, dynamic>?;

        if (backendToken == null || backendToken.isEmpty || userData == null) {
          emit(AuthError("Réponse invalide après soumission des préférences."));
          return;
        }
        final user = UserModel.fromJson(userData); // Utiliser votre modèle
        // Save userId in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        if (user.id != null) {
          await prefs.setString('userId', user.id!);
        }
        await _secureStorage.write(key: _backendTokenKey, value: backendToken);
        print("AuthCubit: Préférences enregistrées! Session finale établie.");
        emit(
            Authenticated(user: user, token: backendToken)); // <-- État Final !
      } else {
        final responseBody = jsonDecode(response.body);
        emit(AuthError(
            responseBody['error'] ?? 'Erreur soumission des préférences'));
      }
    } catch (e) {
      emit(AuthError("Erreur soumission des préférences: ${e.toString()}"));
    }
  }

  // --- signOut (utilise POST /api/auth/logout) ---
  Future<void> signOut() async {
    final currentState = state;
    if (currentState is Authenticated) {
      try {
        await _httpClient.post(
          // Appel backend pour invalider côté serveur
          Uri.parse('$_apiBaseUrl/auth/logout'),
          headers: {'Authorization': 'Bearer ${currentState.token}'},
        );
      } catch (e) {/* Ignorer erreur logout backend ? */}
    }
    // Déconnexion locale (Google + stockage)
    try {
      await _googleSignIn.signOut();
      await _secureStorage.delete(key: _backendTokenKey);
      emit(Unauthenticated());
    } catch (e) {
      await _secureStorage.delete(key: _backendTokenKey); // Assurer suppression
      emit(AuthError('Erreur déconnexion locale: ${e.toString()}'));
    }
  }

  





  @override
  Future<void> close() {
    _httpClient.close();
    return super.close();
  }
}
