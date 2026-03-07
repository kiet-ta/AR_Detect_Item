import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// MaterialApp ThemeData for Magic Doodle.
/// Configured for children: oversized touch targets, rounded corners.
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surfaceLight,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.backgroundLight,
        textTheme: _buildTextTheme(Colors.black87),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(72, 72), // Spec: min 72x72dp touch target
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 4,
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(72, 72),
            iconSize: 36,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: AppColors.surfaceLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          secondary: AppColors.secondaryLight,
          surface: AppColors.surfaceDark,
          error: AppColors.error,
        ),
        scaffoldBackgroundColor: AppColors.backgroundDark,
        textTheme: _buildTextTheme(Colors.white),
      );

  static TextTheme _buildTextTheme(Color color) => TextTheme(
        displayLarge: AppTypography.display.copyWith(color: color),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: color),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: color),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: color),
        bodySmall: AppTypography.bodySmall.copyWith(color: color),
      );
}
