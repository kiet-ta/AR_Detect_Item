part of 'camera_bloc.dart';

sealed class CameraEvent {
  const CameraEvent();
}

/// Initialize and open the camera controller.
final class CameraInitialize extends CameraEvent {
  const CameraInitialize();
}

/// Start streaming frames to the recognition pipeline.
final class CameraStartStreaming extends CameraEvent {
  const CameraStartStreaming();
}

/// Pause the frame stream (app backgrounded).
final class CameraPause extends CameraEvent {
  const CameraPause();
}

/// Resume from paused state.
final class CameraResume extends CameraEvent {
  const CameraResume();
}

/// A timer tick — capture the current frame and send to recognition.
final class CameraFrameCaptured extends CameraEvent {
  const CameraFrameCaptured(this.imageBytes);
  final Uint8List imageBytes;
}

/// Dispose the camera controller.
final class CameraDispose extends CameraEvent {
  const CameraDispose();
}
