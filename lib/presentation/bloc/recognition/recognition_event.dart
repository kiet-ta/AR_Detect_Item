part of 'recognition_bloc.dart';

sealed class RecognitionEvent {
  const RecognitionEvent();
}

/// Triggers classification of a captured camera frame.
final class RecognitionFrameReceived extends RecognitionEvent {
  const RecognitionFrameReceived(this.imageBytes);
  final Uint8List imageBytes;
}

/// Dismisses the current result and returns to idle.
final class RecognitionResultDismissed extends RecognitionEvent {
  const RecognitionResultDismissed();
}

/// Resets to idle (e.g. after error recovery).
final class RecognitionReset extends RecognitionEvent {
  const RecognitionReset();
}
