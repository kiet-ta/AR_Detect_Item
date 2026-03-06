/// Firestore collection names and field name constants.
/// Never scatter raw string collection names in the codebase.
abstract final class FirestoreCollections {
  // --- Collections ---
  static const String usageLogs = 'usage_logs';
  static const String failedDrawings = 'failed_drawings';
  static const String assetManifest = 'asset_manifest';

  // --- usage_logs fields ---
  static const String fieldSessionId = 'session_id';
  static const String fieldUserId = 'user_id';
  static const String fieldWordsLearned = 'words_learned';
  static const String fieldDurationSeconds = 'duration_seconds';
  static const String fieldIsOffline = 'is_offline';
  static const String fieldTimestamp = 'timestamp';

  // --- failed_drawings fields ---
  static const String fieldImageBytes = 'image_bytes';
  static const String fieldLabel = 'label';
  static const String fieldConfidence = 'confidence';
  static const String fieldDeviceId = 'device_id';
  static const String fieldNeedsRetraining = 'needs_retraining';

  // --- asset_manifest fields ---
  static const String fieldAssetLabel = 'label';
  static const String fieldVersion = 'version';
  static const String fieldStoragePath = 'storage_path';
  static const String fieldAudioPath = 'audio_path';
  static const String fieldCategory = 'category';
}
