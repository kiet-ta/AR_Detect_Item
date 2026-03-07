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
/// **Frame throttling strategy (latest-frame-only buffer):**
/// The camera plugin fires frames at 30-60 FPS. [CameraFrameCaptured] events
/// are stored in [_latestFrame], overwriting any unprocessed frame. A periodic
/// timer at [AppConstants.inferenceFps] (3 FPS) fires [_CameraTimerTick], which
/// drains the buffer and forwards the freshest frame to [RecognitionBloc] via
/// [CameraCapturing] state. Dropped frames are dereferenced immediately, so
/// the GC can reclaim the memory and the UI thread stays at 60 FPS.
@injectable
final class CameraBloc extends Bloc<CameraEvent, CameraState> {
  CameraBloc() : super(const CameraUninitialized()) {
    on<CameraInitialize>(_onInitialize);
    on<CameraStartStreaming>(_onStartStreaming);
    on<CameraPause>(_onPause);
    on<CameraResume>(_onResume);
    on<CameraFrameCaptured>(_onFrameCaptured);
    on<_CameraTimerTick>(_onTimerTick);
    on<CameraDispose>(_onDispose);
  }

  Timer? _captureTimer;
  Timer? _metricsTimer;

  /// Holds the most recent unprocessed frame. Overwritten on every incoming
  /// frame; nulled after the timer dispatches it to recognition.
  Uint8List? _latestFrame;

  /// Count of frames dropped since the last metrics log window.
  int _droppedFrameCount = 0;

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
    _metricsTimer?.cancel();
    _latestFrame = null; // Release buffered frame reference for GC
    emit(const CameraPaused());
  }

  Future<void> _onResume(
    CameraResume event,
    Emitter<CameraState> emit,
  ) async {
    emit(const CameraStreaming());
    _startCaptureTimer();
  }

  /// Stores the incoming frame in the single-slot buffer.
  ///
  /// If a previous frame was not yet dispatched by the timer, it is overwritten
  /// (dropped) and [_droppedFrameCount] is incremented. This keeps memory
  /// bounded to at most one unprocessed frame at any time.
  Future<void> _onFrameCaptured(
    CameraFrameCaptured event,
    Emitter<CameraState> emit,
  ) async {
    if (_latestFrame != null) _droppedFrameCount++;
    _latestFrame = event.imageBytes;
  }

  /// Drains the frame buffer at the throttled inference rate.
  ///
  /// If no new frame arrived since the last tick, the tick is skipped entirely
  /// to avoid re-processing a stale frame.
  void _onTimerTick(
    _CameraTimerTick event,
    Emitter<CameraState> emit,
  ) {
    final frame = _latestFrame;
    if (frame == null) return; // No new frame since last tick — idle skip
    _latestFrame = null; // Deref: GC may reclaim the previous frame bytes
    emit(CameraCapturing(frame));
    emit(const CameraStreaming());
  }

  Future<void> _onDispose(
    CameraDispose event,
    Emitter<CameraState> emit,
  ) async {
    _captureTimer?.cancel();
    _metricsTimer?.cancel();
    _latestFrame = null;
    AppLogger.i('CameraBloc: disposed');
  }

  void _startCaptureTimer() {
    _captureTimer?.cancel();
    _metricsTimer?.cancel();

    // At each tick, fire an internal event so the handler can safely emit state.
    _captureTimer = Timer.periodic(
      Duration(milliseconds: (1000 / AppConstants.inferenceFps).round()),
      (_) => add(const _CameraTimerTick()),
    );

    // Every 30 s, log how many frames were dropped. Resets the counter.
    _metricsTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (_droppedFrameCount > 0) {
          AppLogger.d(
            'CameraBloc: dropped $_droppedFrameCount frames in last 30 s '
            '(running at ${AppConstants.inferenceFps} FPS)',
          );
          _droppedFrameCount = 0;
        }
      },
    );
  }

  @override
  Future<void> close() {
    _captureTimer?.cancel();
    _metricsTimer?.cancel();
    return super.close();
  }
}
