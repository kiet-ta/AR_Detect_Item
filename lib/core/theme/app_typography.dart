import 'package:flutter/material.dart';

/// Text styles for Magic Doodle.
/// All sizes are large because target users are children 3-7.
/// Interactive elements use NO text per spec — these styles are
/// used only in parent dashboard and onboarding.
abstract final class AppTypography {
  // Base font — rounded, friendly
  static const String _fontFamily = 'Nunito';

  static const TextStyle display = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  /// Used for vocabulary word display ("Apple / Quả Táo")
  static const TextStyle vocabularyBilingual = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  /// Parental dashboard / settings — smaller, more formal
  static const TextStyle parentUI = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );
}
