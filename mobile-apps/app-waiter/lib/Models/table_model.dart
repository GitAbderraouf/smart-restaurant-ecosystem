// File: maitre_app/lib/models/table_model.dart
import 'package:flutter/material.dart'; // For Color
// Assuming your theme colors will be in 'package:maitre_app/theme/colors.dart'
import 'package:waiter_app/Themes/colors.dart' as theme_colors;


// Enum for different table statuses
enum TableStatus {
  available,
  occupied,
  needsCleaning,
  reserved,
  billRequested
}

// Extension to get display properties for TableStatus
extension TableStatusExtension on TableStatus {
  String get displayName {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.needsCleaning:
        return 'Needs Cleaning';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.billRequested:
        return 'Bill Requested';
      default:
        return 'Unknown';
    }
  }

  Color get displayColor {
    switch (this) {
      case TableStatus.available:
        return theme_colors.AppColors.success;
      case TableStatus.occupied:
        return theme_colors.AppColors.primary;
      case TableStatus.needsCleaning:
        return theme_colors.AppColors.warning;
      case TableStatus.reserved:
        return theme_colors.AppColors.preparation;
      case TableStatus.billRequested:
        return theme_colors.AppColors.accent;
      default:
        return theme_colors.AppColors.unknown;
    }
  }
}

class TableModel {
  final String id;
  final String name; // e.g., "Table 1", "Patio A2"
  final int capacity;
  TableStatus status;
  final String? currentOrderId; // ID of the active order, if any
  final String? assignedStaffId; // ID of staff member assigned

  TableModel({
    required this.id,
    required this.name,
    required this.capacity,
    this.status = TableStatus.available,
    this.currentOrderId,
    this.assignedStaffId,
  });

  // Optional: Add fromJson and toJson if you plan to fetch this from an API
}