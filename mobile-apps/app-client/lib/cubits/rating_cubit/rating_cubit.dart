import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:hungerz/cubits/auth_cubit/auth_cubit.dart'; // Importez AuthCubit et AuthState
import 'package:hungerz/repositories/rating_repository.dart';
 // Importez RatingRepository

part 'rating_state.dart';

class RatingCubit extends Cubit<RatingState> {
  final RatingRepository ratingRepository;
  final AuthCubit authCubit; // Injectez AuthCubit

  RatingCubit({
    required this.ratingRepository,
    required this.authCubit, // AuthCubit est maintenant requis
  }) : super(RatingInitial());

  Future<void> submitRatings({
    required String orderId,
    required Map<String, double> ratings, // Clé: menuItemId, Valeur: notation
  }) async {
    if (ratings.isEmpty) {
      // emit(RatingSubmissionFailure("Aucune notation à soumettre.")); // Normalement géré par l'UI
      return;
    }

    // Obtenir l'état actuel de l'authentification
    final currentAuthState = authCubit.state;

    if (currentAuthState is Authenticated) {
      final token = currentAuthState.token; // Obtenir le token de l'utilisateur authentifié

      emit(RatingSubmissionInProgress());
      try {
        await ratingRepository.submitOrderRatings(
          token: token, // Passer le token au repository
          orderId: orderId,
          itemRatings: ratings,
        );
        emit(RatingSubmissionSuccess());
      } catch (e) {
        emit(RatingSubmissionFailure(e.toString().replaceFirst("Exception: ", "")));
      }
    } else {
      // L'utilisateur n'est pas authentifié, émettre un échec
      emit(RatingSubmissionFailure("Utilisateur non authentifié. Veuillez vous connecter pour noter."));
    }
  }
}
