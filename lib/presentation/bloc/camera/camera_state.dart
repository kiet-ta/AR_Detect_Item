part of 'camera_bloc.dart';

sealed class CameraState extends Equatable {
  const CameraState();

  @override
  List<Object?> get props => [];
}

/// Initial state before camera is opened.
final class CameraUninitialized extends CameraState {
  const CameraUninitialized();
}

/// Camera controller is being opened.
final class CameraInitializing extends CameraState {
  const CameraInitializing();
}

/// Camera is open and streaming live preview frames.
final class CameraStreaming extends CameraState {
  const CameraStreaming();
}

/// Camera is open but frame stream is paused.
final class CameraPaused extends CameraState {
  const CameraPaused();
}

/// A frame has been captured and is ready to be forwarded to recognition.
/// Carries the raw image bytes so the UI can dispatch them to [RecognitionBloc]
/// without re-accessing the camera controller.
final class CameraCapturing extends CameraState {
  CameraCapturing(this.imageBytes);

  final Uint8List imageBytes;

  @override
  List<Object?> get props => [imageBytes];
}

/// Camera initialization or stream failed.
final class CameraError extends CameraState {
  const CameraError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
