import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hungerz_store/Config/app_config.dart';
import 'package:hungerz_store/models/reservation_model.dart';

class ReservationService {
  final String _baseUrl = AppConfig.baseUrl;

  Future<Map<String, dynamic>> getConfirmedReservations() async {
    final String url = '$_baseUrl/reservations/confirmed';
    if (kDebugMode) {
      print('[ReservationService] Fetching confirmed reservations from: $url');
    }
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Debug: Log the raw response data
        if (kDebugMode) {
          print('[ReservationService/Confirmed] Raw confirmed response body: ${response.body.substring(0, (response.body.length > 1000) ? 1000 : response.body.length)}...'); // Log first 1000 chars
        }
        
        final List<dynamic> reservationsJson = responseData['reservations'];
        
        // --- New Debug Prints ---
        if (kDebugMode) {
          print('[ReservationService/Confirmed] reservationsJson is null? ${reservationsJson == null}');
          print('[ReservationService/Confirmed] reservationsJson runtimeType: ${reservationsJson.runtimeType}');
          print('[ReservationService/Confirmed] reservationsJson length: ${reservationsJson.length}');
          if (reservationsJson.isNotEmpty) {
            print('[ReservationService/Confirmed] First item in reservationsJson: ${reservationsJson.first}');
            print('[ReservationService/Confirmed] First item runtimeType: ${reservationsJson.first.runtimeType}');
        }
        }
        // --- End New Debug Prints ---
        
        final List<Reservation> reservations = reservationsJson
            .map((jsonMap) {
              // Ensure we are passing a Map<String, dynamic> to fromJson
              if (jsonMap is Map<String, dynamic>) {
                return Reservation.fromJson(jsonMap);
              } else {
                if (kDebugMode) {
                  print('[ReservationService/Confirmed] Error: Item in reservationsJson is not a Map<String, dynamic>. Actual type: ${jsonMap.runtimeType}, Value: $jsonMap');
                }
                // Decide how to handle this - skip, throw, or return a default/error Reservation object
                // For now, let's throw to make it obvious if this happens.
                throw Exception('Invalid item type in reservationsJson for ConfirmedReservations');
              }
            })
            .toList();
            
        // Debug: Check the parsed reservations
        if (kDebugMode && reservations.isNotEmpty) {
          print('[ReservationService] First parsed reservation: ${reservations.first}');
          print('[ReservationService] Menu items: ${reservations.first.preSelectedMenu}');
        }
            
        return {
          'reservations': reservations,
          'message': responseData['message'] ?? 'Confirmed reservations retrieved successfully',
        };
      } else {
        if (kDebugMode) {
          print('[ReservationService] Error: ${response.statusCode} Body: ${response.body}');
        }
        throw Exception('Failed to load confirmed reservations: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ReservationService] Exception when fetching confirmed reservations: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCompletedReservations({DateTime? startDate, DateTime? endDate}) async {
    String queryParams = '';
    if (startDate != null && endDate != null) {
      queryParams = '?startDate=${startDate.toIso8601String()}&endDate=${endDate.toIso8601String()}';
    }
    
    final String url = '$_baseUrl/reservations/completed$queryParams';
    if (kDebugMode) {
      print('[ReservationService] Fetching completed reservations from: $url');
    }
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Debug: Log the raw response data
        if (kDebugMode) {
          print('[ReservationService/Completed] Raw completed response body: ${response.body.substring(0, (response.body.length > 1000) ? 1000 : response.body.length)}...'); // Log first 1000 chars
        }
        
        final List<dynamic> reservationsJson = responseData['reservations'];
        
        // --- New Debug Prints ---
        if (kDebugMode) {
          print('[ReservationService/Completed] reservationsJson is null? ${reservationsJson == null}');
          print('[ReservationService/Completed] reservationsJson runtimeType: ${reservationsJson.runtimeType}');
          print('[ReservationService/Completed] reservationsJson length: ${reservationsJson.length}');
          if (reservationsJson.isNotEmpty) {
            print('[ReservationService/Completed] First item in reservationsJson: ${reservationsJson.first}');
            print('[ReservationService/Completed] First item runtimeType: ${reservationsJson.first.runtimeType}');
        }
        }
        // --- End New Debug Prints ---
        
        final List<Reservation> reservations = reservationsJson
            .map((jsonMap) {
               // Ensure we are passing a Map<String, dynamic> to fromJson
              if (jsonMap is Map<String, dynamic>) {
                return Reservation.fromJson(jsonMap);
              } else {
                if (kDebugMode) {
                  print('[ReservationService/Completed] Error: Item in reservationsJson is not a Map<String, dynamic>. Actual type: ${jsonMap.runtimeType}, Value: $jsonMap');
                }
                // For now, let's throw to make it obvious if this happens.
                throw Exception('Invalid item type in reservationsJson for CompletedReservations');
              }
            })
            .toList();
            
        // Debug: Check the parsed reservations
        if (kDebugMode && reservations.isNotEmpty) {
          print('[ReservationService] First parsed completed reservation: ${reservations.first}');
          print('[ReservationService] Menu items: ${reservations.first.preSelectedMenu}');
        }
        
        // Calculate total revenue from all reservations if not provided in the response
        double totalRevenue = responseData['totalRevenue'] != null 
            ? (responseData['totalRevenue'] as num).toDouble() 
            : reservations.fold(0, (sum, reservation) => sum + reservation.totalRevenue);
            
        return {
          'reservations': reservations,
          'totalCount': responseData['totalCount'] ?? reservations.length,
          'totalRevenue': totalRevenue,
          'message': responseData['message'] ?? 'Completed reservations retrieved successfully',
        };
      } else {
        if (kDebugMode) {
          print('[ReservationService] Error: ${response.statusCode} Body: ${response.body}');
        }
        throw Exception('Failed to load completed reservations: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ReservationService] Exception when fetching completed reservations: $e');
      }
      rethrow;
    }
  }
  
  // Method to get detailed statistics for dashboard
  Future<Map<String, dynamic>> getReservationStats() async {
    try {
      final confirmedData = await getConfirmedReservations();
      final completedData = await getCompletedReservations();
      
      final List<Reservation> confirmed = confirmedData['reservations'];
      final List<Reservation> completed = completedData['reservations'];
      final double totalRevenue = completedData['totalRevenue'] ?? 0.0;
      
      // Upcoming today
      final todayConfirmed = confirmed.where((res) => 
        res.reservationTime.year == DateTime.now().year &&
        res.reservationTime.month == DateTime.now().month &&
        res.reservationTime.day == DateTime.now().day
      ).toList();
      
      // Get total count of guests for today's reservations
      final int todayGuestCount = todayConfirmed.fold(0, (sum, res) => sum + res.guests);
      
      // Get average revenue per reservation if there are completed reservations
      final double averageRevenue = completed.isNotEmpty 
          ? totalRevenue / completed.length 
          : 0.0;
      
      return {
        'totalConfirmed': confirmed.length,
        'totalCompleted': completed.length,
        'todayReservations': todayConfirmed.length,
        'todayGuests': todayGuestCount,
        'totalRevenue': totalRevenue,
        'averageRevenue': averageRevenue,
      };
    } catch (e) {
      if (kDebugMode) {
        print('[ReservationService] Error getting reservation stats: $e');
      }
      rethrow;
    }
  }

  // Method to get reservations within a specific date range
  Future<Map<String, dynamic>> getReservationsByDateRange({required DateTime startDate, required DateTime endDate}) async {
    final String fromDateString = startDate.toIso8601String();
    final String toDateString = endDate.toIso8601String();
    final String url = '$_baseUrl/reservations/date-range?from=$fromDateString&to=$toDateString';

    if (kDebugMode) {
      print('[ReservationService/DateRange] Fetching reservations by date range from: $url');
    }
    
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Debug: Log the raw response data
        if (kDebugMode) {
          print('[ReservationService/DateRange] Raw date range response body: ${response.body.substring(0, (response.body.length > 1000) ? 1000 : response.body.length)}...');
        }
        
        final List<dynamic> reservationsJson = responseData['reservations'];

        // --- New Debug Prints for DateRange ---
        if (kDebugMode) {
          print('[ReservationService/DateRange] reservationsJson is null? ${reservationsJson == null}');
          print('[ReservationService/DateRange] reservationsJson runtimeType: ${reservationsJson.runtimeType}');
          print('[ReservationService/DateRange] reservationsJson length: ${reservationsJson.length}');
          if (reservationsJson.isNotEmpty) {
            print('[ReservationService/DateRange] First item in reservationsJson: ${reservationsJson.first}');
            print('[ReservationService/DateRange] First item runtimeType: ${reservationsJson.first.runtimeType}');
          }
        }
        // --- End New Debug Prints for DateRange ---
        
        final List<Reservation> reservations = reservationsJson
            .map((jsonMap) {
              if (jsonMap is Map<String, dynamic>) {
                return Reservation.fromJson(jsonMap);
              } else {
                if (kDebugMode) {
                  print('[ReservationService/DateRange] Error: Item in reservationsJson is not a Map<String, dynamic>. Actual type: ${jsonMap.runtimeType}, Value: $jsonMap');
                }
                throw Exception('Invalid item type in reservationsJson for DateRangeReservations');
              }
            })
            .toList();
            
        // Debug: Check the parsed reservations
        if (kDebugMode && reservations.isNotEmpty) {
          print('[ReservationService] First parsed date range reservation: ${reservations.first}');
          print('[ReservationService] Menu items: ${reservations.first.preSelectedMenu}');
        }
            
        return {
          'reservations': reservations,
          'message': responseData['message'] ?? 'Reservations retrieved successfully',
        };
      } else {
        if (kDebugMode) {
          print('[ReservationService] Error: ${response.statusCode} Body: ${response.body}');
        }
        throw Exception('Failed to load reservations by date range: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ReservationService] Exception when fetching reservations by date range: $e');
      }
      rethrow;
    }
  }

  // Cancel a reservation by ID
  Future<Map<String, dynamic>> cancelReservation(String reservationId) async {
    final String url = '$_baseUrl/reservations/$reservationId/cancel';
    if (kDebugMode) {
      print('[ReservationService] Cancelling reservation: $url');
    }
    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (kDebugMode) {
          print('[ReservationService] Cancel response: ${response.body}');
        }
        return responseData;
      } else {
        if (kDebugMode) {
          print('[ReservationService] Cancel error: ${response.statusCode} Body: ${response.body}');
        }
        throw Exception('Failed to cancel reservation: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ReservationService] Exception when cancelling reservation: $e');
      }
      rethrow;
    }
  }
}