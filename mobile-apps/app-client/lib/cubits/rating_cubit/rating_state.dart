// lib/cubits/rating_cubit/rating_state.dart
part of 'rating_cubit.dart'; // Assurez-vous que rating_cubit.dart existe dans le même dossier

abstract class RatingState extends Equatable {
  const RatingState();
  @override
  List<Object> get props => [];
}

class RatingInitial extends RatingState {}

class RatingSubmissionInProgress extends RatingState {}

class RatingSubmissionSuccess extends RatingState {
    // Optionnel: vous pouvez ajouter un message de succès ou les données retournées
    // final String successMessage;
    // const RatingSubmissionSuccess({this.successMessage = "Notations soumises avec succès!"});
    // @override
    // List<Object> get props => [successMessage];
}

class RatingSubmissionFailure extends RatingState {
  final String error;
  const RatingSubmissionFailure(this.error);
  @override
  List<Object> get props => [error];
}