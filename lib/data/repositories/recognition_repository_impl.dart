import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/drawing_entity.dart';
import '../../domain/entities/recognition_result_entity.dart';
import '../../domain/repositories/recognition_repository.dart';
import '../ml/drawing_classifier.dart';

@Injectable(as: RecognitionRepository)
final class RecognitionRepositoryImpl implements RecognitionRepository {
  const RecognitionRepositoryImpl(this._classifier);

  final DrawingClassifier _classifier;

  @override
  Future<Either<Failure, RecognitionResultEntity>> classify(
    DrawingEntity drawing,
  ) async {
    try {
      final model = await _classifier.classify(drawing.imageBytes);
      return Right(model.toEntity());
    } on InferenceException catch (e) {
      return Left(InferenceFailure(e.message));
    } on Exception catch (e) {
      return Left(InferenceFailure('Unexpected inference error: $e'));
    }
  }
}
