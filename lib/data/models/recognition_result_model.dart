import '../../domain/entities/recognition_result_entity.dart';

/// DTO mapping TFLite output to [RecognitionResultEntity].
final class RecognitionResultModel {
  const RecognitionResultModel({
    required this.label,
    required this.confidence,
    required this.category,
    required this.recognizedAtMs,
  });

  final String label;
  final double confidence;
  final String category;
  final int recognizedAtMs;

  RecognitionResultEntity toEntity() => RecognitionResultEntity(
        label: label,
        confidence: confidence,
        category: category,
        recognizedAt:
            DateTime.fromMillisecondsSinceEpoch(recognizedAtMs, isUtc: true),
      );

  /// Creates a model from a raw TFLite output map.
  ///
  /// Expected keys: 'label', 'confidence', 'category'.
  factory RecognitionResultModel.fromTfliteOutput(
    Map<String, dynamic> output,
  ) {
    return RecognitionResultModel(
      label: output['label'] as String,
      confidence: (output['confidence'] as num).toDouble(),
      category: output['category'] as String? ?? 'general',
      recognizedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'category': category,
        'recognized_at_ms': recognizedAtMs,
      };
}
