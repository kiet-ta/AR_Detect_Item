import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/drawing_entity.dart';
import '../entities/recognition_result_entity.dart';

/// Contract for the AI drawing classification pipeline.
/// Data layer provides the concrete implementation via TFLite.
abstract interface class RecognitionRepository {
  /// Runs the TFLite classifier on [drawing] and returns the top result.
  ///
  /// Returns [InferenceFailure] if the model is unavailable or crashes.
  /// Returns [RecognitionResultEntity] with confidence in [0.0, 1.0].
  Future<Either<Failure, RecognitionResultEntity>> classify(
    DrawingEntity drawing,
  );
}
