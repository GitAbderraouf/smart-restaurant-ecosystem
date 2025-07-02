// lib/cubits/profile_cubit/profile_state.dart
part of 'profile_cubit.dart'; // Adaptez chemin

// lib/cubits/profile_cubit/profile_state.dart

// Adaptez le chemin vers votre modèle User

// Classe de base abstraite pour tous les états du profil
abstract class ProfileState extends Equatable {
  const ProfileState();

  // props vide par défaut, les classes filles surchargeront si elles ont des données
  @override
  List<Object?> get props => [];
}

// État Initial: Aucun profil n'est chargé (ex: au démarrage avant connexion, ou après déconnexion)
class ProfileInitial extends ProfileState {}

// État de Chargement: Le profil est en cours de récupération depuis le backend
class ProfileLoading extends ProfileState {
  // Optionnel: peut contenir l'utilisateur précédent pour un affichage pendant le chargement
  final UserModel? previousUser;
  const ProfileLoading({this.previousUser});

  @override
  List<Object?> get props => [previousUser];
}

// État de Succès: Le profil utilisateur a été chargé avec succès
class ProfileLoaded extends ProfileState {
  final UserModel
      user; // Contient l'objet User complet (avec nom, favoris, etc.)
  final AddressModel? activeDisplayAddress;
  const ProfileLoaded(this.user, {this.activeDisplayAddress});
  ProfileLoaded copyWith({
    UserModel? user,
    // Utiliser 'ValueGetter' pour permettre de passer explicitement null
    ValueGetter<AddressModel?>? activeDisplayAddress,
  }) {
    return ProfileLoaded(
      user ?? this.user,
      activeDisplayAddress: activeDisplayAddress != null
          ? activeDisplayAddress()
          : this.activeDisplayAddress,
    );
  }

  // Important: Inclure 'user' dans props pour que Equatable détecte les changements
  // sur l'objet User (si User lui-même étend Equatable et définit ses props)
  @override
  List<Object?> get props => [user, activeDisplayAddress];
}

// État d'Erreur: Une erreur s'est produite lors du chargement du profil
class ProfileError extends ProfileState {
  final String message;
  // Optionnel: peut contenir l'utilisateur précédent si on veut permettre de réessayer
  // tout en affichant les anciennes données avec l'erreur.
  // final User? previousUser;

  const ProfileError(this.message /*, {this.previousUser}*/);

  @override
  List<Object?> get props => [message /*, previousUser*/];
}

// --- NOTE sur ProfileActionError ---
// Dans la réponse précédente sur le toggleFavorite, j'avais suggéré un état comme
// ProfileActionError qui hérite de ProfileLoaded pour gérer les erreurs d'action
// SANS perdre l'état chargé. C'est une alternative à l'utilisation d'un Stream
// séparé pour les erreurs d'action. Vous pouvez choisir l'une ou l'autre approche.
// Si vous utilisez le Stream d'erreurs séparé (recommandé), vous n'avez pas
// forcément besoin de ProfileActionError ici. Si vous préférez gérer les erreurs
// d'action via l'état, vous pouvez ajouter :
/*
class ProfileActionError extends ProfileLoaded {
  final String errorMessage;
  const ProfileActionError(this.errorMessage, User user) : super(user);

  @override
  List<Object?> get props => [user, errorMessage];
}
*/
