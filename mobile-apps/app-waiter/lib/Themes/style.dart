// File: maitre_app/lib/theme/style.dart
import 'package:flutter/material.dart';
import 'package:waiter_app/Themes/colors.dart'; // Uses the updated colors.dart

final ThemeData appTheme = ThemeData(
  fontFamily: 'ProductSans', // From kitchen_app theme
  scaffoldBackgroundColor: Colors.white, // From kitchen_app theme
  primaryColor: primaryColor, // From kitchen_app (0xffFBAF03 - Yellow/Orange)
  
  appBarTheme: AppBarTheme(
    color: Colors.transparent, // From kitchen_app theme
    elevation: 0.0,          // From kitchen_app theme
    iconTheme: IconThemeData(color: textColor), // Using kitchen_app's dark grey textColor
    titleTextStyle: TextStyle(
        color: textColor, // Using kitchen_app's dark grey textColor
        fontSize: 20,
        fontWeight: FontWeight.w500,
        fontFamily: 'ProductSans'),
  ),

  textTheme: TextTheme(
    // Replicating kitchen_app's textTheme approach
    bodyLarge: TextStyle(color: Colors.white, fontFamily: 'ProductSans'), // Kitchen app uses white for bodyLarge
    bodyMedium: TextStyle(color: textColor, fontFamily: 'ProductSans'), // For other general text, using kitchen_app's textColor
    titleMedium: TextStyle(fontWeight: FontWeight.w500, color: textColor, fontFamily: 'ProductSans', fontSize: 20), // For AppBar titles primarily
    // Other styles can be added/adjusted based on kitchen_app's TextTheme if more specific styles are found
    displayLarge: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'ProductSans'),
    titleLarge: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: textColor, fontFamily: 'ProductSans'),
    labelLarge: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'ProductSans'), // For ElevatedButton text, assuming white on primary/buttonColor
    bodySmall: TextStyle(fontSize: 12.0, color: AppColors.textLight, fontFamily: 'ProductSans'), // Using waiter_app's AppColors.textLight for now for smaller text
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: buttonColor, // Default to kitchen_app's red buttonColor
      foregroundColor: Colors.white,   // Text on red button
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'ProductSans'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      elevation: 2,
    ),
  ),

  outlinedButtonTheme: OutlinedButtonThemeData(
     style: OutlinedButton.styleFrom(
      foregroundColor: primaryColor, // Kitchen_app's yellow/orange for outlined button text/border
      side: BorderSide(color: primaryColor, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'ProductSans'),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
    ),
  ),

  cardTheme: CardTheme(
    elevation: 1.0,
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12.0),
    ),
    color: AppColors.cardBackground, // Using waiter_app's AppColors.cardBackground (white)
                                     // which matches kitchen_app's colorScheme.cardColor usage for its order cards
  ),

  dividerTheme: DividerThemeData(
    color: AppColors.divider, // Using waiter_app's AppColors.divider for now
    thickness: 0.5,
    space: 1,
  ),
  
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor, // Kitchen_app's yellow/orange
    primary: primaryColor,
    secondary: accentColor, // Using waiter_app's top-level accent (was AppColors.accent)
    surface: Colors.white, // Kitchen_app surface
    background: const Color(0xffF8F9FD), // Kitchen_app background
    error: errorColor, // Using waiter_app's top-level error (was AppColors.error)
    onPrimary: Colors.white, // Text on primary (yellow/orange)
    onSecondary: Colors.white, // Text on accent
    onSurface: textColor, // Kitchen_app textColor (dark grey) for text on white surfaces
    onBackground: textColor, // Kitchen_app textColor for text on light grey background
    onError: Colors.white, // Text on error color (red)
    brightness: Brightness.light,
  ),
);

// Define fallback colors if they are not directly in AppColors or for simpler access
final Color accentColor = AppColors.accent; 
final Color errorColor = AppColors.error;