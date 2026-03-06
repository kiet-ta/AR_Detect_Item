import 'package:equatable/equatable.dart';

/// Base sealed class for all domain-level failures.
/// Use with [dartz.Either] to propagate errors across layers.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Remote API / Firebase errors.
final class ServerFailure extends Failure {
  const ServerFailure([super.message = 'A server error occurred.']);
}

/// Local cache / Hive read-write errors.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'A local cache error occurred.']);
}

/// TFLite model loading or inference errors.
final class InferenceFailure extends Failure {
  const InferenceFailure([super.message = 'AI inference failed.']);
}

/// Device is offline and the operation requires connectivity.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No network connection.']);
}

/// Requested 3D asset is not in local cache and cannot be downloaded.
final class AssetNotFoundFailure extends Failure {
  const AssetNotFoundFailure(String label)
      : super('3D asset not found for label: $label');
}

/// Camera permission denied or hardware unavailable.
final class CameraFailure extends Failure {
  const CameraFailure([super.message = 'Camera is unavailable.']);
}
