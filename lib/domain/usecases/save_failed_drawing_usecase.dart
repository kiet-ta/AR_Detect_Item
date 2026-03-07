import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../entities/drawing_entity.dart';
import '../repositories/sync_repository.dart';

/// Saves a low-confidence [DrawingEntity] to the local Data Flywheel queue.
///
/// Delegates binarization (Otsu's method) to [SyncRepository.saveForRetraining],
/// ensuring all photographic content is stripped before persistence (COPPA).
@injectable
final class SaveFailedDrawingUseCase {
  const SaveFailedDrawingUseCase(this._repository);

  final SyncRepository _repository;

  Future<Either<Failure, Unit>> call(DrawingEntity drawing) =>
      _repository.saveForRetraining(drawing);
}
