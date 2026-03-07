import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../entities/drawing_entity.dart';
import '../entities/recognition_result_entity.dart';
import '../repositories/recognition_repository.dart';

/// Runs the TFLite classifier on a captured drawing frame.
///
/// Single responsibility: delegates to [RecognitionRepository.classify].
/// Performs no pre-processing — that is the Data layer's concern.
@injectable
final class RecognizeDrawingUseCase {
  const RecognizeDrawingUseCase(this._repository);

  final RecognitionRepository _repository;

  /// Classifies [drawing] and returns the recognition result.
  Future<Either<Failure, RecognitionResultEntity>> call(
    DrawingEntity drawing,
  ) {
    return _repository.classify(drawing);
  }
}
