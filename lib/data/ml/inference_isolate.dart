import 'dart:isolate';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../core/errors/exceptions.dart';

/// Message sent TO the inference Isolate.
final class InferenceRequest {
  const InferenceRequest({
    required this.inputTensor,
    required this.replyPort,
  });

  final Float32List inputTensor;
  final SendPort replyPort;
}

/// Message received FROM the inference Isolate.
final class InferenceResponse {
  const InferenceResponse({required this.scores, this.error});

  final List<double>? scores;
  final String? error;

  bool get hasError => error != null;
}

/// Manages a dedicated [Isolate] for TFLite inference.
///
/// The Isolate is spawned once and kept alive to avoid spawn overhead
/// on each inference call. The UI thread communicates via [SendPort].
///
/// **Why Isolate over compute()?**
/// `compute()` spawns a new isolate per call (expensive for 3-5 FPS).
/// This implementation reuses one isolate with a message channel.
@singleton
final class InferenceIsolate {
  Isolate? _isolate;
  SendPort? _sendPort;
  ReceivePort? _receivePort;

  bool get isRunning => _isolate != null;

  /// Spawns the inference isolate and waits for it to be ready.
  Future<void> start() async {
    _receivePort = ReceivePort();
    _isolate = await Isolate.spawn(
      _inferenceEntryPoint,
      _receivePort!.sendPort,
      debugName: 'InferenceIsolate',
    );

    // First message from the isolate is its own SendPort.
    _sendPort = await _receivePort!.first as SendPort;
  }

  /// Sends [inputTensor] to the Isolate and returns inference scores.
  Future<List<double>> run(Float32List inputTensor) async {
    if (_sendPort == null) {
      throw const InferenceException(
        'Inference Isolate is not started. Call start() first.',
      );
    }

    final replyPort = ReceivePort();
    _sendPort!.send(
      InferenceRequest(inputTensor: inputTensor, replyPort: replyPort.sendPort),
    );

    final response = await replyPort.first as InferenceResponse;
    replyPort.close();

    if (response.hasError) {
      throw InferenceException(response.error!);
    }
    return response.scores!;
  }

  /// Kills the inference isolate. Call on app dispose.
  void stop() {
    _isolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();
    _isolate = null;
    _sendPort = null;
  }
}

/// Isolate entry point — runs in the background thread.
///
/// This function is intentionally top-level (not a member) because
/// Isolate.spawn requires a top-level or static function.
void _inferenceEntryPoint(SendPort mainSendPort) {
  final receivePort = ReceivePort();
  mainSendPort.send(receivePort.sendPort);

  receivePort.listen((message) async {
    if (message is! InferenceRequest) return;

    try {
      // NOTE: In production, the TFLite interpreter is initialized here
      // inside the isolate. For testability, the actual inference logic
      // is injected via TFLiteService. This entry point is the boundary.
      //
      // Simplified response for scaffold — real interpreter runs here.
      message.replyPort.send(
        InferenceResponse(scores: List.filled(345, 0.0)),
      );
    } on Exception catch (e) {
      message.replyPort.send(InferenceResponse(scores: null, error: '$e'));
    }
  });
}
