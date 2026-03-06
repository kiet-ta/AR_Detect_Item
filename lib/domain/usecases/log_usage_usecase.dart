import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../entities/usage_log_entity.dart';
import '../repositories/usage_log_repository.dart';
import '../../core/errors/failures.dart';

/// Persists a completed session log for the parent dashboard.
///
/// Writes to local Hive first (offline-safe), then queues for Firestore sync.
@injectable
final class LogUsageUseCase {
  const LogUsageUseCase(this._repository);

  final UsageLogRepository _repository;

  /// Logs [session] and returns [Unit] on success.
  Future<Either<Failure, Unit>> call(UsageLogEntity session) {
    return _repository.logSession(session);
  }
}
