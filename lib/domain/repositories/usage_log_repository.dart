import 'package:dartz/dartz.dart';

import '../entities/usage_log_entity.dart';
import '../../core/errors/failures.dart';

/// Contract for recording and syncing learning session data.
abstract interface class UsageLogRepository {
  /// Persists [log] locally first, then queues for Firestore sync.
  Future<Either<Failure, Unit>> logSession(UsageLogEntity log);

  /// Returns all unsynced logs stored in local cache.
  Future<Either<Failure, List<UsageLogEntity>>> getLocalLogs();

  /// Pushes all pending local logs to Firestore and marks them synced.
  Future<Either<Failure, Unit>> syncPendingLogs();
}
