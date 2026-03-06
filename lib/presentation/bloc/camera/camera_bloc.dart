import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/logger.dart';

part 'camera_event.dart';
part 'camera_state.dart';

/// Manages the camera lifecycle: initialize → stream → capture → dispose.
///
/// Frame capture is driven by a periodic Timer at [AppConstants.inferenceFps].
/// Captured frames are forwarded to [RecognitionBloc] via event.
@injectable
final class CameraBloc extends Bloc<CameraEvent, CameraState> {
  CameraBloc() : super(const CameraUninitialized()) {
    on<CameraInitialize>(_onInitialize);
    on<CameraStartStreaming>(_onStartStreaming);
    on<CameraPause>(_onPause);
    on<CameraResume>(_onResume);
    on<CameraFrameCaptured>(_onFrameCaptured);
    on<CameraDispose>(_onDispose);
  }

  Timer? _captureTimer;

  Future<void> _onInitialize(
    CameraInitialize event,
    Emitter<CameraState> emit,
  ) async {
    emit(const CameraInitializing());
    try {
      // Camera controller initialization is handled in the UI layer
      // (CameraScreen) via the `camera` plugin. The BLoC tracks state only.
      AppLogger.i('CameraBloc: initialized');
      emit(const CameraStreaming());
    } on Exception catch (e) {
      AppLogger.e('CameraBloc: initialization failed', e);
      emit(CameraError(e.toString()));
    }
  }

  Future<void> _onStartStreaming(
    CameraStartStreaming event,
    Emitter<CameraState> emit,
  ) async {
    emit(const CameraStreaming());
    _startCaptureTimer();
  }

  Future<void> _onPause(
    CameraPause event,
    Emitter<CameraState> emit,
  ) async {
    _captureTimer?.cancel();
    emit(const CameraPaused());
  }

  Future<void> _onResume(
    CameraResume event,
    Emitter<CameraState> emit,
  ) async {
    emit(const CameraStreaming());
    _startCaptureTimer();
  }

  Future<void> _onFrameCaptured(
    CameraFrameCaptured event,
    Emitter<CameraState> emit,
  ) async {
    // Briefly emit Capturing state — the UI can show a subtle shutter effect.
    emit(const CameraCapturing());
    emit(const CameraStreaming());
  }

  Future<void> _onDispose(
    CameraDispose event,
    Emitter<CameraState> emit,
  ) async {
    _captureTimer?.cancel();
    AppLogger.i('CameraBloc: disposed');
  }

  void _startCaptureTimer() {
    _captureTimer?.cancel();
    // Timer drives inference at [inferenceFps] — actual frame bytes
    // are captured by CameraScreen and dispatched as CameraFrameCaptured.
    _captureTimer = Timer.periodic(
      Duration(
        milliseconds: (1000 / AppConstants.inferenceFps).round(),
      ),
      (_) => AppLogger.d('CameraBloc: capture tick'),
    );
  }

  @override
  Future<void> close() {
    _captureTimer?.cancel();
    return super.close();
  }
}
