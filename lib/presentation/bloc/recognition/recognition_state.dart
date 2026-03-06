part of 'recognition_bloc.dart';

sealed class RecognitionState extends Equatable {
  const RecognitionState();

  @override
  List<Object?> get props => [];
}

/// Waiting for the next frame.
final class RecognitionIdle extends RecognitionState {
  const RecognitionIdle();
}

/// Pre-processing image tensor before sending to isolate.
final class RecognitionPreProcessing extends RecognitionState {
  const RecognitionPreProcessing();
}

/// Inference is running on the background isolate.
final class RecognitionInferring extends RecognitionState {
  const RecognitionInferring();
}

/// Confidence ≥ 70% — display 3D model.
final class RecognitionRecognized extends RecognitionState {
  const RecognitionRecognized({
    required this.result,
    required this.asset,
  });

  final RecognitionResultEntity result;
  final Asset3DEntity asset;

  @override
  List<Object?> get props => [result, asset];
}

/// Confidence < 50% — saved for retraining, continue scanning.
final class RecognitionUnrecognized extends RecognitionState {
  const RecognitionUnrecognized();
}

/// 50% ≤ confidence < 70% — silently ignored.
final class RecognitionUncertain extends RecognitionState {
  const RecognitionUncertain();
}

/// Inference or asset fetch failed.
final class RecognitionError extends RecognitionState {
  const RecognitionError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
