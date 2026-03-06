import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/constants/asset_paths.dart';
import '../../../core/errors/exceptions.dart';

/// Loads and provides the TFLite [Interpreter] from bundled assets.
///
/// The interpreter is loaded once and reused to avoid repeated I/O.
/// Dispose via [dispose] when the app is terminated.
@singleton
final class ModelLoader {
  Interpreter? _interpreter;
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Loads the bundled TFLite model into memory.
  ///
  /// Uses [InterpreterOptions] to request 2 CPU threads —
  /// enough for 3-5 FPS inference without draining the battery.
  Future<Interpreter> load() async {
    if (_isLoaded && _interpreter != null) {
      return _interpreter!;
    }

    try {
      // Load model bytes from Flutter asset bundle
      final modelData = await rootBundle.load(AssetPaths.tfliteModel);
      final modelBytes = modelData.buffer.asUint8List();

      final options = InterpreterOptions()..threads = 2;
      _interpreter = Interpreter.fromBuffer(modelBytes, options: options);
      _isLoaded = true;

      return _interpreter!;
    } on Exception catch (e) {
      throw InferenceException('Failed to load TFLite model: $e');
    }
  }

  /// Returns the cached interpreter, throwing if not yet loaded.
  Interpreter get interpreter {
    if (_interpreter == null || !_isLoaded) {
      throw const InferenceException('Model not loaded. Call load() first.');
    }
    return _interpreter!;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}
