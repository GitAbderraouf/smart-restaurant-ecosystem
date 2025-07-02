// user_app/lib/cubits/table_session_cubit/table_session_state.dart
part of 'table_session_cubit.dart';

abstract class TableSessionState extends Equatable {
  const TableSessionState();

  @override
  List<Object?> get props => [];
}

class TableSessionInitial extends TableSessionState {}

class TableSessionLoading extends TableSessionState {}

// State when the User App has successfully joined a table session
class TableSessionJoined extends TableSessionState {
  final String sessionId;
  final String kioskDeviceId; // The deviceId of the Kiosk/Table
  final List<Map<String, dynamic>> initialCartItems; // Parsed from socket event

  const TableSessionJoined({
    required this.sessionId,
    required this.kioskDeviceId,
    required this.initialCartItems,
  });

  @override
  List<Object?> get props => [sessionId, kioskDeviceId, initialCartItems];
}

// State if joining a session fails from the User App's perspective
// This can be used if a specific join error needs to be handled differently.
// For general errors, TableSessionError is used.
class TableSessionJoinError extends TableSessionState {
  final String message;
  const TableSessionJoinError(this.message);

  @override
  List<Object?> get props => [message];
}

// Generic error state for the table session cubit
class TableSessionError extends TableSessionState {
  final String message;
  const TableSessionError(this.message);

  @override
  List<Object?> get props => [message];
}

// State when the User App is actively part of a session and cart updates might occur
class TableSessionActive extends TableSessionState {
  final String sessionId;
  final String kioskDeviceId;
  // The cart items themselves will be managed by CartCubit,
  // but this state signifies we are in an active, shared session.
  // We might add more session-specific details here later if needed.

  const TableSessionActive({
    required this.sessionId,
    required this.kioskDeviceId,
  });

  @override
  List<Object?> get props => [sessionId, kioskDeviceId];
}

// State when the table session has ended or the user has left
class TableSessionEnded extends TableSessionState {
   final Map<String, dynamic>? closingData; // e.g., bill info from backend
   const TableSessionEnded({this.closingData});

   @override
   List<Object?> get props => [closingData];
}
