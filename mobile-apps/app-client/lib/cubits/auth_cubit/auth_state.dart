part of 'auth_cubit.dart'; // Lie ce fichier à auth_cubit.dart

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// État initial avant toute vérification
final class AuthInitial extends AuthState {}

// État pendant une opération asynchrone (connexion, vérification, déconnexion)
final class AuthLoading extends AuthState {}

// --- NOUVEL ÉTAT ---
// Émis après que submitPhoneNumber a réussi côté backend (OTP envoyé)
final class PhoneSubmittedAwaitingOtp extends AuthState {
  final String phoneNumber; // Garder le numéro pour le passer à l'écran OTP
  const PhoneSubmittedAwaitingOtp({required this.phoneNumber});
  @override List<Object?> get props => [phoneNumber];
}
// --- FIN NOUVEL ÉTAT ---
// --- États spécifiques à votre flux ---

// Émis après succès Google Sign-In + validation/liaison backend initiale.
// Indique que l'étape suivante est la saisie du numéro de téléphone.
final class GoogleSignInSuccessfulNeedsPhone extends AuthState {
  final String userId; // ID utilisateur Google
  const GoogleSignInSuccessfulNeedsPhone({required this.userId});
  @override List<Object?> get props => [userId];
}

// Émis APRÈS la vérification réussie de l'OTP (dernière étape).
// C'est l'état "pleinement authentifié" permettant l'accès à l'app principale.
final class Authenticated extends AuthState {
  final UserModel user;
  final String token; // Le token de session backend ACTIF (potentiellement renouvelé)
  const Authenticated({required this.user, required this.token});

  @override
  List<Object?> get props => [user, token];
}

// --- États génériques ---

// État lorsque l'utilisateur n'est pas authentifié (pas de session valide)
final class Unauthenticated extends AuthState {}
final class OtpVerifiedNeedsPreferences extends AuthState {
  final String userId; // Pour savoir quel utilisateur modifier
  const OtpVerifiedNeedsPreferences({required this.userId});
  @override List<Object?> get props => [userId];
}
// État en cas d'erreur lors d'une opération d'authentification
final class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}