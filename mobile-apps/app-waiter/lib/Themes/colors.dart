// File: lib/theme/colors.dart
import 'package:flutter/material.dart';

// Colors replicated from kitchen_app/lib/Theme/colors.dart

// --- Original Theme Colors from Kitchen App ---
Color buttonColor = const Color(0xffED3F40);        // Red used for buttons
Color blackColor = Colors.black;                    // Pure black
Color? strikeThroughColor = Colors.grey[400];       // Grey for strikethrough text
Color newOrderColor = const Color(0xff009946);      // Original green color
Color primaryColor = const Color(0xffFBAF03);      // Original yellow/orange accent (Kitchen App's primary)
Color textColor = const Color(0xff4D4D4D);            // Default dark grey text color

// --- Order Status Colors for Kitchen Screen Timer (replicated for potential use or consistency) ---
const Color orderGreen = Color(0xff009946);   // Initial state (using the value of newOrderColor)
const Color orderYellow = Color(0xffFBAF03);  // Warning state (using the value of primaryColor)
const Color orderRed = Color(0xffED3F40);     // Urgent state (using the value of buttonColor)

// --- Additional colors that were in waiter_app/lib/Themes/colors.dart previously ---
// --- We will decide if these are still needed or should be mapped to kitchen_app colors ---

// Default AppColors class from the original waiter_app theme structure.
// We will consolidate these with the kitchen_app colors above.
class AppColors {
  static const Color primary = Color(0xffFBAF03); // Matches kitchen_app primaryColor (Yellow/Orange)
  static const Color secondary = Color(0xff007AFF); // Example: Blue (Original waiter app secondary)
  static const Color accent = Color(0xff00C49F);   // Example: Teal/Green (Original waiter app accent)

  static const Color background = Color(0xffF8F9FD); // Very light grey/blue (Matches kitchen_app colorScheme.background)
  static const Color surface = Colors.white;           // White (Matches kitchen_app scaffoldBackgroundColor & colorScheme.surface)
  static const Color cardBackground = Colors.white;    // Card background

  static const Color textDark = Color(0xff1A1A1A);    // Dark text
  static const Color textLight = Color(0xff757575);   // Lighter grey text
  static const Color textOnPrimary = Colors.white;     // Text on primary color (e.g., on yellow/orange button)
  static const Color textOnSecondary = Colors.white;   // Text on secondary color
  static const Color textOnAccent = Colors.white;      // Text on accent color

  static const Color success = Color(0xff28A745);      // Green for success messages/indicators
  static const Color warning = Color(0xffFFC107);      // Yellow for warnings
  static const Color error = Color(0xffDC3545);        // Red for errors

  static const Color disabled = Color(0xffBDBDBD);     // Color for disabled elements
  static const Color divider = Color(0xffE0E0E0);      // Color for dividers
  static const Color icon = Color(0xff757575);         // Default icon color

  static const Color lightYellowBackground = Color(0xFFFFF9C4); // Changed back to very light yellow (was 0xFFFFE082)

  // Order Status specific from original waiter app (may need re-evaluation)
  static const Color pending = Color(0xffFF9800);      // Orange
  static const Color confirmed = Color(0xff2196F3);    // Blue
  static const Color preparation = Color(0xff795548);  // Brown
  static const Color readyForPickup = orderGreen;      // Using kitchen_app's orderGreen
  static const Color outForDelivery = Color(0xff607D8B); // Blue Grey
  static const Color delivered = Color(0xff4CAF50);    // Green
  static const Color cancelled = Color(0xffF44336);    // Red
  static const Color unknown = Color(0xff9E9E9E);      // Grey for unknown status

  // Table Status Colors (from user suggestion for kitchen-like UI)
  static const Color tableReserved = Color(0xff2196F3);
  static const Color tableBillRequested = Color(0xff9C27B0);
  static const Color tableAvailable = Color(0xff4CAF50);
  static const Color tableNeedsCleaning = Color(0xffF44336);
}