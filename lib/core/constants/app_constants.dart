/// App-wide configuration constants.
/// All environment-sensitive values should come from flavors/env files,
/// not hardcoded here.
abstract final class AppConstants {
  // --- AI Thresholds ---
  /// Minimum confidence to trigger 3D model display.
  static const double recognitionThreshold = 0.70;

  /// Below this threshold, the drawing is saved for retraining (Data Flywheel).
  static const double dataFlywheelThreshold = 0.50;

  // --- Camera ---
  /// Frames per second sent to the TFLite classifier.
  static const int inferenceFps = 4;

  // --- Image Processing ---
  /// Input size for the QuickDraw TFLite model.
  static const int modelInputSize = 28;

  // --- Sync ---
  /// Max items batched in a single Firestore sync operation.
  static const int syncBatchSize = 20;

  /// Max failed drawings stored locally before oldest is evicted.
  static const int maxFailedDrawingsQueue = 50;

  // --- Parental Controls ---
  /// Default screen-time limit in minutes before app auto-pauses.
  static const int defaultScreenTimeLimitMinutes = 20;

  // --- Result Screen ---
  /// Duration (in seconds) before result screen auto-dismisses.
  static const int resultAutoDismissSeconds = 8;

  // --- Hive Box Names ---
  static const String hiveBoxDrawings = 'failed_drawings';
  static const String hiveBoxAssets = 'asset_manifest';
  static const String hiveBoxUsageLogs = 'usage_logs';
  static const String hiveBoxSettings = 'app_settings';
}
