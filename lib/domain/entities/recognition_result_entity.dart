import 'package:equatable/equatable.dart';

/// The result produced by the TFLite classifier for a given drawing.
final class RecognitionResultEntity extends Equatable {
  const RecognitionResultEntity({
    required this.label,
    required this.confidence,
    required this.category,
    required this.recognizedAt,
  });

  /// Human-readable label (e.g. 'apple', 'cat', 'house').
  final String label;

  /// Confidence score in the range [0.0, 1.0].
  final double confidence;

  /// Vocabulary category (e.g. 'animals', 'food', 'transport').
  final String category;

  /// UTC timestamp of when inference completed.
  final DateTime recognizedAt;

  /// Whether the confidence meets the display threshold (≥70%).
  bool get isHighConfidence => confidence >= 0.70;

  /// Whether the drawing should be saved for retraining (<50%).
  bool get requiresRetraining => confidence < 0.50;

  @override
  List<Object?> get props =>
      [label, confidence, category, recognizedAt];
}
