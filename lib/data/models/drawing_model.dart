import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/entities/drawing_entity.dart';

part 'drawing_model.g.dart';

/// Hive-persisted DTO for [DrawingEntity].
/// Used by the Data Flywheel to store low-confidence captures locally.
@HiveType(typeId: 0)
final class DrawingModel extends HiveObject {
  DrawingModel({
    required this.id,
    required this.imageBytes,
    required this.capturedAtMs,
    this.deviceId,
    this.needsRetraining = true,
  });

  @HiveField(0)
  final String id;

  @HiveField(1)
  final Uint8List imageBytes;

  /// Stored as milliseconds since epoch for Hive compatibility.
  @HiveField(2)
  final int capturedAtMs;

  @HiveField(3)
  final String? deviceId;

  /// True when this drawing failed recognition and is queued for upload.
  @HiveField(4)
  final bool needsRetraining;

  /// Converts to domain entity.
  DrawingEntity toEntity() => DrawingEntity(
        id: id,
        imageBytes: imageBytes,
        capturedAt: DateTime.fromMillisecondsSinceEpoch(capturedAtMs),
        deviceId: deviceId,
      );

  /// Creates a model from a domain entity.
  factory DrawingModel.fromEntity(
    DrawingEntity entity, {
    bool needsRetraining = false,
  }) {
    return DrawingModel(
      id: entity.id,
      imageBytes: entity.imageBytes,
      capturedAtMs: entity.capturedAt.millisecondsSinceEpoch,
      deviceId: entity.deviceId,
      needsRetraining: needsRetraining,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'image_bytes': imageBytes,
        'captured_at_ms': capturedAtMs,
        'device_id': deviceId,
        'needs_retraining': needsRetraining,
      };
}
