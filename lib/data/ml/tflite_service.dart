import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import 'model_loader.dart';

/// Executes raw inference using the loaded TFLite interpreter.
///
/// Input: normalised float32 tensor [1, 28, 28, 1] (grayscale, 0.0–1.0)
/// Output: float32 array [1, numClasses]
const int _numClasses = 345; // Quick, Draw! dataset classes

@injectable
final class TFLiteService {
  TFLiteService(this._loader);

  final ModelLoader _loader;

  /// Runs inference on a pre-processed [inputTensor].
  ///
  /// Returns a list of [_numClasses] confidence values (summing to ~1.0).
  /// Throws [InferenceException] on model error.
  Future<List<double>> runInference(Float32List inputTensor) async {
    if (!_loader.isLoaded) {
      await _loader.load();
    }

    final interpreter = _loader.interpreter;

    // Allocate input/output tensors
    final List<dynamic> input = inputTensor.reshape([
      1,
      AppConstants.modelInputSize,
      AppConstants.modelInputSize,
      1,
    ]);
    final List<dynamic> output =
        List.filled(_numClasses, 0.0).reshape([1, _numClasses]);

    try {
      interpreter.run(input, output);
    } on Exception catch (e) {
      throw InferenceException('TFLite inference failed: $e');
    }

    // Flatten the output to a simple list
    return (output[0] as List).cast<double>();
  }
}
