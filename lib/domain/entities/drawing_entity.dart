import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// A drawing captured from the camera, ready for AI classification.
/// Immutable. Carries raw image bytes and contextual metadata.
final class DrawingEntity extends Equatable {
  const DrawingEntity({
    required this.id,
    required this.imageBytes,
    required this.capturedAt,
    this.deviceId,
  });

  /// Unique identifier (UUID v4).
  final String id;

  /// Raw grayscale image bytes (28x28 pixels after preprocessing).
  final Uint8List imageBytes;

  /// UTC timestamp when the frame was captured.
  final DateTime capturedAt;

  /// Optional device identifier for analytics.
  final String? deviceId;

  DrawingEntity copyWith({
    String? id,
    Uint8List? imageBytes,
    DateTime? capturedAt,
    String? deviceId,
  }) {
    return DrawingEntity(
      id: id ?? this.id,
      imageBytes: imageBytes ?? this.imageBytes,
      capturedAt: capturedAt ?? this.capturedAt,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  @override
  List<Object?> get props => [id, imageBytes, capturedAt, deviceId];
}
