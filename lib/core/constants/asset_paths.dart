/// Constants for all bundled asset paths.
/// Centralizing paths prevents typos scattered across the codebase.
abstract final class AssetPaths {
  // --- ML Models ---
  static const String tfliteModel =
      'assets/ml_models/quickdraw_classifier_v1.tflite';
  static const String labelMap = 'assets/ml_models/labels.txt';

  // --- Images ---
  static const String appLogo = 'assets/images/magic_doodle_logo.png';
  static const String splashBackground =
      'assets/images/splash_background.png';
  static const String scanGuideFrame = 'assets/images/scan_guide_frame.png';
  static const String mascotIdle = 'assets/images/mascot_idle.png';
  static const String mascotHappy = 'assets/images/mascot_happy.png';
  static const String placeholderModel =
      'assets/models_3d/placeholder.glb';

  // --- Audio ---
  /// Pattern: assets/audio/{label}_{language}.mp3
  /// e.g. assets/audio/apple_en.mp3 / assets/audio/apple_vi.mp3
  static String audioForLabel(String label, String languageCode) =>
      'assets/audio/${label}_$languageCode.mp3';
}
