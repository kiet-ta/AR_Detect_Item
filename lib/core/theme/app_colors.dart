import 'package:flutter/material.dart';

/// Design token colors for Magic Doodle.
/// Optimized for children 3-7: high contrast, vivid, joyful.
abstract final class AppColors {
  // --- Brand ---
  static const Color primary = Color(0xFF6C63FF); // Bright purple
  static const Color primaryLight = Color(0xFF9C94FF);
  static const Color primaryDark = Color(0xFF3D35CC);

  static const Color secondary = Color(0xFFFF6B9D); // Playful pink
  static const Color secondaryLight = Color(0xFFFF9BBD);

  // --- Accent ---
  static const Color success = Color(0xFF4CAF50); // Green (recognition OK)
  static const Color warning = Color(0xFFFF9800); // Orange (low confidence)
  static const Color error = Color(0xFFF44336); // Red (failure)

  // --- Background ---
  static const Color backgroundLight = Color(0xFFFFF9F0); // Warm white
  static const Color backgroundDark = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF252540);

  // --- AR Overlay ---
  static const Color scanFrameActive = Color(0xFF6C63FF);
  static const Color scanFrameIdle = Color(0x806C63FF); // 50% opacity
  static const Color overlayScrim = Color(0x80000000); // 50% black

  // --- Confidence indicator ---
  static const Color confidenceHigh = Color(0xFF4CAF50);
  static const Color confidenceMedium = Color(0xFFFF9800);
  static const Color confidenceLow = Color(0xFFF44336);

  // --- Semantic aliases ---
  static const Color surface = surfaceLight;
  static const Color background = backgroundLight;
  static const Color accent = secondary;

  // --- Text ---
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF757575);
}
