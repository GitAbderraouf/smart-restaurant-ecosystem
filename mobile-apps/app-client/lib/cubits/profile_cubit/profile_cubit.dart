// Dans profile_cubit.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:hungerz/models/address_model.dart';
import 'package:hungerz/repositories/user_repository.dart';
import 'package:hungerz/models/user_model.dart';
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart'; 
import 'package:equatable/equatable.dart';// Importer AuthCubit et State
part 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final UserRepository userRepository;
  final AuthCubit authCubit; // Référence à AuthCubit
  StreamSubscription? _authSubscription; // Pour écouter AuthCubit
  String? _currentToken; // Pour stocker le token quand connecté

    final _actionErrorController = StreamController<String>.broadcast();
  Stream<String> get actionErrorStream => _actionErrorController.stream;

  ProfileCubit({required this.userRepository, required this.authCubit})
      : super(ProfileInitial()) { // Commence en état Initial

    // Écouter les changements d'état de AuthCubit dès la création
    _listenAuthChanges();

    // Vérifier aussi l'état initial de AuthCubit au cas où on serait déjà connecté
    _handleAuthState(authCubit.state);
  }

  void _listenAuthChanges() {
    _authSubscription = authCubit.stream.listen(_handleAuthState);
  }

  // Gère les différents états d'authentification
  void _handleAuthState(AuthState authState) {
    if (authState is Authenticated) {
      print("ProfileCubit: AuthState est Authenticated. Chargement profil si nécessaire.");
      _currentToken = authState.token; // Stocker le token
      // Charger le profil seulement si on n'a pas déjà un profil chargé
      // ou si l'ID utilisateur a changé (connexion d'un autre user)
      if (state is! ProfileLoaded || (state as ProfileLoaded).user.id != authState.user.id) {
         // Note: AuthState contient déjà User. On peut l'utiliser directement !
         // Pas besoin de refaire un appel API ici si AuthState contient déjà tout.
         // On peut directement passer à l'état chargé.
         print("ProfileCubit: Utilisation de l'User depuis AuthState.");
         emit(ProfileLoaded(authState.user)); // Utiliser l'user de AuthState
         // Ou si vous préférez recharger depuis l'API :
         // loadUserProfile(authState.token);
      }
    } else if (authState is Unauthenticated) {
      print("ProfileCubit: AuthState est Unauthenticated. Réinitialisation ProfileState.");
      _currentToken = null; // Oublier le token
      emit(ProfileInitial()); // Réinitialiser l'état du profil
    }
  }

    void setActiveDisplayAddress(AddressModel? address) {
    if (state is ProfileLoaded) {
      final currentState = state as ProfileLoaded;
      print("ProfileCubit: Changement adresse active -> ${address?.label ?? 'GPS Actuel'}");
      emit(currentState.copyWith(activeDisplayAddress: () => address)); // Utilise copyWith
    }
  }

  // Méthode pour charger explicitement (si nécessaire, ou si AuthState n'a pas l'User complet)
  // Future<void> loadUserProfile(String token) async {
  //   if (state is ProfileLoading) return;
  //   emit(ProfileLoading( (state is ProfileLoaded) ? (state as ProfileLoaded).user : null)); // Garder user précédent pendant chargement
  //   try {
  //     final user = await userRepository.getUserProfile(token);
  //     emit(ProfileLoaded(user));
  //   } catch (e) {
  //     emit(ProfileError(e.toString()));
  //   }
  // }

  // Méthode pour basculer un favori
  Future<void> toggleFavorite(String dishId) async {
    // Vérifier l'état du Profile ET récupérer le token via AuthCubit
    if (state is! ProfileLoaded) {
       print("ProfileCubit: Ne peut pas toggle favori, profil non chargé.");
       return;
    }
    if (authCubit.state is! Authenticated) {
       print("ProfileCubit: Ne peut pas toggle favori, non authentifié (AuthCubit).");
       // Peut-être réinitialiser l'état ici ?
       emit(ProfileInitial());
       return;
    }

    final currentProfileState = state as ProfileLoaded;
    final currentUser = currentProfileState.user;
    final token = (authCubit.state as Authenticated).token; // Obtenir le token actuel

    final currentFavorites = List<String>.from(currentUser.favorites ?? []);
    final bool isCurrentlyFavorite = currentFavorites.contains(dishId);

    // Update Optimiste
    final optimisticFavorites = List<String>.from(currentFavorites);
    if (isCurrentlyFavorite) optimisticFavorites.remove(dishId);
    else optimisticFavorites.add(dishId);
    final optimisticUser = currentUser.copyWith(favorites: optimisticFavorites);
    emit(ProfileLoaded(optimisticUser)); // Émet son propre état ProfileLoaded

    // Appel Backend
    try {
      if (isCurrentlyFavorite) {
        await userRepository.removeFavorite(token, dishId);
      } else {
        await userRepository.addFavorite(token, dishId);
      }
    } catch (e) {
      print("ProfileCubit: ERREUR API toggleFavorite - $e");
      // Annuler : Ré-émettre ProfileLoaded avec l'utilisateur *original*
      emit(ProfileLoaded(currentUser));
      // Signaler l'erreur (peut-être via un stream ou un état d'erreur temporaire)
      // _actionErrorController.add("Erreur favori");
    }
  }
  Future<void> saveAddress(AddressModel address) async {
    if (state is! ProfileLoaded) return;
    if (_currentToken == null) return;

    final currentState = state as ProfileLoaded;
    // Garder l'état actuel en cas de rollback
    final previousState = currentState;

    // Optionnel: émettre un état de chargement spécifique ?
    // emit(ProfileLoading(previousUser: currentState.user, activeDisplayAddress: currentState.activeDisplayAddress));

    try {
      // Appeler le repository. Supposons qu'il retourne l'User mis à jour
      final UserModel? updatedUserFromApi = await userRepository.saveUserAddress(_currentToken!, address);

      UserModel finalUser;
      if (updatedUserFromApi != null) {
        finalUser = updatedUserFromApi;
        print("ProfileCubit: Utilisateur mis à jour reçu de l'API après saveAddress.");
      } else {
        // Si l'API ne retourne pas l'user, on l'ajoute localement (moins fiable)
        print("ProfileCubit: Mise à jour locale de la liste d'adresses (API n'a pas retourné l'user).");
        final currentAddresses = List<AddressModel>.from(currentState.user.addresses ?? []);
        // Ici on devrait plutôt remplacer si l'adresse avait un ID, ou juste ajouter
        // Pour faire simple, on suppose un ajout pour l'instant :
        currentAddresses.add(address);
        finalUser = currentState.user.copyWith(addresses: currentAddresses); // Adaptez nom champ
      }

      // Émettre l'état succès en définissant la NOUVELLE adresse comme ACTIVE
      print("ProfileCubit: Émission ProfileLoaded après saveAddress, setActive=${address.label}");
      emit(ProfileLoaded(finalUser, activeDisplayAddress: address));

    } catch (e) {
      print("ProfileCubit: ERREUR API saveAddress - $e");
      // Annuler : revenir à l'état précédent (avant le loading éventuel)
      emit(previousState);
      _actionErrorController.add("Erreur lors de l'enregistrement de l'adresse.");
    }
  }


  // Ne pas oublier de nettoyer l'abonnement !
  @override
  Future<void> close() {
    _authSubscription?.cancel();
    // _actionErrorController.close(); // Si vous ajoutez un stream d'erreur
    return super.close();
  }
}


// --- État ProfileLoading et ProfileError (exemples) ---
/*
// Dans profile_state.dart
class ProfileLoading extends ProfileState {
   // Peut contenir l'utilisateur précédent pour l'afficher pendant le chargement
   final User? previousUser;
   const ProfileLoading(this.previousUser);
    @override List<Object?> get props => [previousUser];
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
   @override List<Object?> get props => [message];
}
*/