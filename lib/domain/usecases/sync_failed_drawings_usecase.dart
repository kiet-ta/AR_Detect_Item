import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../repositories/sync_repository.dart';

/// Uploads all locally queued failed drawings to Firebase Storage.
///
/// Part of the Data Flywheel: low-confidence captures are tagged
/// and uploaded for ML team analysis and model retraining.
@injectable
final class SyncFailedDrawingsUseCase {
  const SyncFailedDrawingsUseCase(this._repository);

  final SyncRepository _repository;

  /// Uploads the full queue. Returns the count of successfully uploaded items.
  Future<Either<Failure, int>> call() {
    return _repository.uploadFailedDrawings();
  }
}
