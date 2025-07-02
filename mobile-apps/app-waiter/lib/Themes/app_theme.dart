// File: lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import './colors.dart';
import './text_styles.dart'; // If you created AppTextStyles

class AppTheme {
  // Define your default font family here, and ensure it's in pubspec.yaml
  static const String _fontFamily = 'YourAppFont'; // e.g., 'Roboto', 'ProductSans'

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        background: AppColors.background,
        error: AppColors.error,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnAccent,
        onSurface: AppColors.textDark,
        onBackground: AppColors.textDark,
        onError: AppColors.textOnPrimary, // Text on error color (e.g., on a red snackbar)
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: _fontFamily, // Set default font

      // AppBar Theme (can adapt from Hungerz style.dart)
      appBarTheme: const AppBarTheme(
        color: AppColors.surface, // Or Colors.transparent
        elevation: 0.5,          // Slight elevation for definition
        iconTheme: IconThemeData(color: AppColors.textDark), // Icons on appbar
        titleTextStyle: TextStyle( // Using a specific style for AppBar titles
          fontFamily: _fontFamily,
          color: AppColors.textDark,
          fontSize: 18.0, // Adjust as per titleMedium or titleLarge from AppTextStyles
          fontWeight: FontWeight.w600,
        ),
      ),

      // Text Theme (integrating AppTextStyles)
      textTheme: TextTheme(
        displayLarge: AppTextStyles.headlineLarge,
        displayMedium: AppTextStyles.headlineMedium,
        displaySmall: AppTextStyles.headlineSmall,
        headlineMedium: AppTextStyles.titleLarge, // Material 3 maps headlineMedium to M2 titleLarge
        headlineSmall: AppTextStyles.titleMedium,
        titleLarge: AppTextStyles.titleSmall,    // Material 3 maps titleLarge to M2 titleSmall
        titleMedium: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w500), // M3 titleMedium is like M2 Subtitle1
        titleSmall: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w500),  // M3 titleSmall is like M2 Subtitle2
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge, // For buttons
        labelSmall: AppTextStyles.labelSmall, // For captions / overline
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.textOnPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0), // Default button border radius
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
           shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        elevation: 1.0,
        color: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0), // Consistent card radius
        ),
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      ),

      // Input Decoration Theme (for TextFormFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface, // Or a slightly off-white like Colors.grey[100]
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.divider.withOpacity(0.7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.error.withOpacity(0.7), width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        labelStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight.withOpacity(0.7)),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.icon,
        size: 24.0,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1, // No extra space, handled by padding around it
      ),
    );
  }

  // You can also define a darkTheme in a similar way if needed
  // static ThemeData get darkTheme { ... }
}