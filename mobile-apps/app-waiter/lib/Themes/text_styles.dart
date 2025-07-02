// File: lib/theme/text_styles.dart
import 'package:flutter/material.dart';
import './colors.dart'; // To use AppColors for text colors

class AppTextStyles {
  // Define your base font family in app_theme.dart
  // static const String _fontFamily = 'YourAppFont'; // e.g., 'ProductSans'

  static TextStyle get headlineLarge => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 32.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
        letterSpacing: 0.25,
      );

  static TextStyle get headlineMedium => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      );

  static TextStyle get headlineSmall => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 24.0,
        fontWeight: FontWeight.w600, // Semi-bold
        color: AppColors.textDark,
      );

  static TextStyle get titleLarge => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      );

  static TextStyle get titleMedium => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 16.0,
        fontWeight: FontWeight.w600, // Semi-bold
        color: AppColors.textDark,
        letterSpacing: 0.15,
      );

  static TextStyle get titleSmall => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 14.0,
        fontWeight: FontWeight.w500, // Medium
        color: AppColors.textDark,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyLarge => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        color: AppColors.textLight,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyMedium => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 14.0,
        fontWeight: FontWeight.normal,
        color: AppColors.textLight,
        letterSpacing: 0.25,
      );

  static TextStyle get bodySmall => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 12.0,
        fontWeight: FontWeight.normal,
        color: AppColors.textLight,
        letterSpacing: 0.4,
      );

  static TextStyle get labelLarge => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 14.0,
        fontWeight: FontWeight.w600, // Semi-bold for button text
        color: AppColors.textDark, // Often overridden by button's foregroundColor
        letterSpacing: 1.25,
      );

  static TextStyle get labelMedium => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 12.0,
        fontWeight: FontWeight.w500, // Medium
        color: AppColors.textLight,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => const TextStyle(
        // fontFamily: _fontFamily,
        fontSize: 10.0,
        fontWeight: FontWeight.normal,
        color: AppColors.textLight,
        letterSpacing: 1.5, // Overline style
      );
}