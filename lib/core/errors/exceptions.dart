/// Thrown when a Firebase / Firestore operation fails.
/// Caught in Data layer, converted to [ServerFailure].
final class ServerException implements Exception {
  const ServerException([this.message = 'Server error']);
  final String message;
  @override
  String toString() => 'ServerException: $message';
}

/// Thrown when a Hive read/write operation fails.
final class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
  @override
  String toString() => 'CacheException: $message';
}

/// Thrown when TFLite model fails to load or run inference.
final class InferenceException implements Exception {
  const InferenceException([this.message = 'Inference error']);
  final String message;
  @override
  String toString() => 'InferenceException: $message';
}

/// Thrown when the device is offline and connectivity is required.
final class NetworkException implements Exception {
  const NetworkException([this.message = 'No network connection']);
  final String message;
  @override
  String toString() => 'NetworkException: $message';
}

/// Thrown when a 3D asset file cannot be found locally or remotely.
final class AssetNotFoundException implements Exception {
  const AssetNotFoundException(this.label);
  final String label;
  @override
  String toString() => 'AssetNotFoundException: No asset for label "$label"';
}
