import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/image_preprocessor.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/entities/asset_3d_entity.dart';
import '../../../domain/entities/drawing_entity.dart';
import '../../../domain/entities/recognition_result_entity.dart';
import '../../../domain/usecases/fetch_3d_asset_usecase.dart';
import '../../../domain/usecases/recognize_drawing_usecase.dart';
import '../../../domain/usecases/save_failed_drawing_usecase.dart';

part 'recognition_event.dart';
part 'recognition_state.dart';

/// Orchestrates the full recognition pipeline:
/// Frame → TFLite → Confidence check → 3D asset → Display OR Data Flywheel.
@injectable
final class RecognitionBloc extends Bloc<RecognitionEvent, RecognitionState> {
  RecognitionBloc(
    this._recognizeUseCase,
    this._fetchAssetUseCase,
    this._saveFailedDrawingUseCase,
  ) : super(const RecognitionIdle()) {
    on<RecognitionFrameReceived>(_onFrameReceived);
    on<RecognitionResultDismissed>(_onResultDismissed);
    on<RecognitionReset>(_onReset);
  }

  final RecognizeDrawingUseCase _recognizeUseCase;
  final FetchAssetUseCase _fetchAssetUseCase;
  final SaveFailedDrawingUseCase _saveFailedDrawingUseCase;
  static const _uuid = Uuid();

  Future<void> _onFrameReceived(
    RecognitionFrameReceived event,
    Emitter<RecognitionState> emit,
  ) async {
    // Skip if already processing — prevents queue buildup
    if (state is RecognitionInferring || state is RecognitionPreProcessing) {
      return;
    }
    // Skip blank frames
    if (ImagePreprocessor.isBlankFrame(event.imageBytes)) return;

    emit(const RecognitionPreProcessing());

    final drawing = DrawingEntity(
      id: _uuid.v4(),
      imageBytes: event.imageBytes,
      capturedAt: DateTime.now().toUtc(),
    );

    emit(const RecognitionInferring());

    final recognitionResult = await _recognizeUseCase(drawing);

    await recognitionResult.fold(
      (failure) async {
        AppLogger.e('RecognitionBloc: inference failure', failure.message);
        emit(const RecognitionError('Recognition failed. Please try again.'));
        await Future<void>.delayed(const Duration(seconds: 2));
        emit(const RecognitionIdle());
      },
      (result) async {
        AppLogger.d(
          'RecognitionBloc: ${result.label} @ ${(result.confidence * 100).toStringAsFixed(1)}%',
        );

        if (result.isHighConfidence) {
          // confidence >= 70% — show 3D model
          final assetResult = await _fetchAssetUseCase(result.label);
          assetResult.fold(
            (failure) {
              AppLogger.w('RecognitionBloc: asset not found', failure.message);
              emit(const RecognitionError('3D model not available.'));
            },
            (asset) => emit(
              RecognitionRecognized(result: result, asset: asset),
            ),
          );
        } else if (result.requiresRetraining) {
          // confidence < 50% — Data Flywheel: binarize and save locally
          AppLogger.d('RecognitionBloc: queuing for retraining');
          await _saveFailedDrawingUseCase(drawing);
          emit(const RecognitionUnrecognized());
          await Future<void>.delayed(
            const Duration(milliseconds: 500),
          );
          emit(const RecognitionIdle());
        } else {
          // 50% <= confidence < 70% — uncertain, skip silently
          emit(const RecognitionUncertain());
          await Future<void>.delayed(
            const Duration(milliseconds: 200),
          );
          emit(const RecognitionIdle());
        }
      },
    );
  }

  Future<void> _onResultDismissed(
    RecognitionResultDismissed event,
    Emitter<RecognitionState> emit,
  ) async {
    emit(const RecognitionIdle());
  }

  Future<void> _onReset(
    RecognitionReset event,
    Emitter<RecognitionState> emit,
  ) async {
    emit(const RecognitionIdle());
  }
}
