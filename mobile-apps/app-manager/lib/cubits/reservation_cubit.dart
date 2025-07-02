import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hungerz_store/models/reservation_model.dart';
import 'package:hungerz_store/services/reservation_service.dart';

abstract class ReservationState extends Equatable {
  const ReservationState();
  @override
  List<Object?> get props => [];
}

class ReservationInitial extends ReservationState {}

class ReservationLoading extends ReservationState {
  final bool isInitialLoad;
  
  const ReservationLoading({this.isInitialLoad = true});
  
  @override
  List<Object?> get props => [isInitialLoad];
}

class ReservationLoaded extends ReservationState {
  final List<Reservation> confirmedReservations;
  final List<Reservation> completedReservations;
  final double totalRevenue;
  final Map<String, dynamic> stats;

  const ReservationLoaded({
    required this.confirmedReservations,
    required this.completedReservations,
    this.totalRevenue = 0.0,
    this.stats = const {},
  });

  @override
  List<Object?> get props => [confirmedReservations, completedReservations, totalRevenue, stats];
}

class ReservationError extends ReservationState {
  final String message;
  const ReservationError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class ReservationCubit extends Cubit<ReservationState> {
  final ReservationService _reservationService;

  ReservationCubit(this._reservationService) : super(ReservationInitial());

  Future<void> fetchAllReservations() async {
    try {
      emit(ReservationLoading());
      
      // Fetch confirmed and completed reservations in parallel
      final confirmedFuture = _reservationService.getConfirmedReservations();
      final completedFuture = _reservationService.getCompletedReservations();
      
      // Wait for both API calls to complete
      final results = await Future.wait([confirmedFuture, completedFuture]);
      final confirmedResult = results[0];
      final completedResult = results[1];
      
      // Fetch stats
      final statsResult = await _reservationService.getReservationStats();
      
      // Debug: Log the raw response to see what's coming from the service
      if (kDebugMode) {
        print('Confirmed result: $confirmedResult');
        print('Completed result: $completedResult');
      }
      
      // Extract data
      final List<Reservation> confirmed = confirmedResult['reservations'];
      final List<Reservation> completed = completedResult['reservations'];
      final double totalRevenue = completedResult['totalRevenue'] ?? 0.0;
      
      // Debug: Check the menu items in the reservations
      if (kDebugMode) {
        print('Confirmed reservations count: ${confirmed.length}');
        if (confirmed.isNotEmpty) {
          print('First confirmed reservation: ${confirmed.first}');
          print('First confirmed menu items: ${confirmed.first.preSelectedMenu}');
        }
        
        print('Completed reservations count: ${completed.length}');
        if (completed.isNotEmpty) {
          print('First completed reservation: ${completed.first}');
          print('First completed menu items: ${completed.first.preSelectedMenu}');
        }
      }
      
      emit(ReservationLoaded(
        confirmedReservations: confirmed,
        completedReservations: completed,
        totalRevenue: totalRevenue,
        stats: statsResult,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchAllReservations: $e');
      }
      emit(ReservationError("Failed to fetch reservations: ${e.toString()}"));
    }
  }

  Future<void> fetchCompletedReservationsWithRange(DateTime startDate, DateTime endDate) async {
    try {
      // Use partial loading state to indicate refreshing just the completed tab
      if (state is ReservationLoaded) {
        emit(ReservationLoading(isInitialLoad: false));
      } else {
        emit(ReservationLoading());
      }
      
      final currentState = state;
      List<Reservation> currentConfirmed = [];
      
      if (currentState is ReservationLoaded) {
        currentConfirmed = currentState.confirmedReservations;
      }
      
      // Fetch completed reservations with date range using the new service method
      final completedResult = await _reservationService.getReservationsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      
      // Debug: Log the raw response
      if (kDebugMode) {
        print('Completed result with date range: $completedResult');
      }
      
      final List<Reservation> completed = completedResult['reservations'];
      // The total revenue and stats might need to be re-calculated or fetched separately if not provided by the new endpoint
      // For now, we'll keep the existing stats fetching but you might need to adjust based on the backend response
      final double totalRevenue = completed.fold(0, (sum, reservation) => sum + reservation.totalRevenue);
      
      // Refresh stats as well
      final statsResult = await _reservationService.getReservationStats();
      
      emit(ReservationLoaded(
        confirmedReservations: currentConfirmed,
        completedReservations: completed,
        totalRevenue: totalRevenue,
        stats: statsResult,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchCompletedReservationsWithRange: $e');
      }
      emit(ReservationError("Failed to fetch completed reservations: ${e.toString()}"));
    }
  }
  
  // Add a method to refresh just the upcoming/confirmed reservations
  Future<void> refreshConfirmedReservations() async {
    try {
      // Use partial loading state
      if (state is ReservationLoaded) {
        emit(ReservationLoading(isInitialLoad: false));
      } else {
        emit(ReservationLoading());
      }
      
      final currentState = state;
      List<Reservation> currentCompleted = [];
      double currentRevenue = 0.0;
      
      if (currentState is ReservationLoaded) {
        currentCompleted = currentState.completedReservations;
        currentRevenue = currentState.totalRevenue;
      }
      
      // Just fetch confirmed reservations
      final confirmedResult = await _reservationService.getConfirmedReservations();
      
      // Debug: Log the raw response
      if (kDebugMode) {
        print('Confirmed result from refresh: $confirmedResult');
      }
      
      final List<Reservation> confirmed = confirmedResult['reservations'];
      
      // Debug: Check menu items
      if (kDebugMode && confirmed.isNotEmpty) {
        print('First confirmed reservation from refresh: ${confirmed.first}');
        print('First confirmed menu items from refresh: ${confirmed.first.preSelectedMenu}');
      }
      
      // Refresh stats as well
      final statsResult = await _reservationService.getReservationStats();
      
      emit(ReservationLoaded(
        confirmedReservations: confirmed,
        completedReservations: currentCompleted,
        totalRevenue: currentRevenue,
        stats: statsResult,
      ));
    } catch (e) {
      if (kDebugMode) {
        print('Error in refreshConfirmedReservations: $e');
      }
      emit(ReservationError("Failed to refresh confirmed reservations: ${e.toString()}"));
    }
  }
  
  // New method to handle a reservation being marked as completed
  Future<void> markReservationCompleted(String reservationId) async {
    try {
      // Implementation would go here to call the API to mark as completed
      // For now, just refreshing both lists
      await fetchAllReservations();
    } catch (e) {
      if (kDebugMode) {
        print('Error in markReservationCompleted: $e');
      }
      emit(ReservationError("Failed to mark reservation as completed: ${e.toString()}"));
    }
  }

  // Cancel a reservation and refresh the lists
  Future<void> cancelReservation(String reservationId) async {
    try {
      await _reservationService.cancelReservation(reservationId);
      await fetchAllReservations();
    } catch (e) {
      if (kDebugMode) {
        print('Error in cancelReservation: $e');
      }
      emit(ReservationError("Failed to cancel reservation: [4m${e.toString()}[0m"));
    }
  }
}