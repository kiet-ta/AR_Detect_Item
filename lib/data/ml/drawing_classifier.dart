import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:injectable/injectable.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/recognition_result_model.dart';
import 'inference_isolate.dart';

/// Maps TFLite class indices to human-readable labels.
/// In production, loaded from [AssetPaths.labelMap].
const List<String> _labels = [
  'apple', 'banana', 'cat', 'dog', 'fish',
  'house', 'sun', 'tree', 'car', 'star',
  // ... 335 more from Quick, Draw! dataset
];

const Map<String, String> _categoryMap = {
  'apple': 'food', 'banana': 'food',
  'cat': 'animals', 'dog': 'animals', 'fish': 'animals',
  'house': 'objects', 'car': 'transport',
  'sun': 'nature', 'tree': 'nature',
  'star': 'shapes',
};

/// Pre-processes a raw camera frame and runs it through [InferenceIsolate].
///
/// Pipeline: RGB bytes → Resize 28×28 → Grayscale → Normalize → Isolate → Labels.
@injectable
final class DrawingClassifier {
  DrawingClassifier(this._inferenceIsolate);

  final InferenceIsolate _inferenceIsolate;

  /// Classifies the drawing in [rgbBytes] (raw camera JPEG bytes).
  ///
  /// Returns the top-1 prediction as [RecognitionResultModel].
  Future<RecognitionResultModel> classify(Uint8List rgbBytes) async {
    final tensor = _preprocess(rgbBytes);
    final scores = await _inferenceIsolate.run(tensor);
    return _parseOutput(scores);
  }

  /// Converts raw camera bytes to a normalized 28×28 float32 tensor.
  Float32List _preprocess(Uint8List rgbBytes) {
    try {
      // Decode JPEG/PNG from camera
      final image = img.decodeImage(rgbBytes);
      if (image == null) {
        throw const InferenceException('Failed to decode camera frame.');
      }

      // Resize to model input size
      final resized = img.copyResize(
        image,
        width: AppConstants.modelInputSize,
        height: AppConstants.modelInputSize,
      );

      // Convert to grayscale and normalize to [0.0, 1.0]
      final tensorSize =
          AppConstants.modelInputSize * AppConstants.modelInputSize;
      final tensor = Float32List(tensorSize);

      for (var y = 0; y < AppConstants.modelInputSize; y++) {
        for (var x = 0; x < AppConstants.modelInputSize; x++) {
          final pixel = resized.getPixel(x, y);
          // Luminance formula: 0.299R + 0.587G + 0.114B
          final luminance =
              (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
          // Invert: white paper (1.0) → 0.0, black ink (0.0) → 1.0
          tensor[y * AppConstants.modelInputSize + x] =
              1.0 - luminance.clamp(0.0, 1.0);
        }
      }

      return tensor;
    } on InferenceException {
      rethrow;
    } on Exception catch (e) {
      throw InferenceException('Image preprocessing failed: $e');
    }
  }

  /// Picks the top-1 prediction from raw softmax [scores].
  RecognitionResultModel _parseOutput(List<double> scores) {
    if (scores.isEmpty) {
      throw const InferenceException('Model returned empty output.');
    }

    var maxIdx = 0;
    var maxScore = scores[0];
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIdx = i;
      }
    }

    final label =
        maxIdx < _labels.length ? _labels[maxIdx] : 'unknown_$maxIdx';
    final category = _categoryMap[label] ?? 'general';

    return RecognitionResultModel.fromTfliteOutput({
      'label': label,
      'confidence': maxScore,
      'category': category,
    });
  }
}
