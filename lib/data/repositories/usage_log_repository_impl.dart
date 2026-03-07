import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/usage_log_entity.dart';
import '../../domain/repositories/usage_log_repository.dart';
import '../datasources/local/hive_service.dart';
import '../datasources/remote/firestore_service.dart';
import '../models/usage_log_model.dart';

@Injectable(as: UsageLogRepository)
final class UsageLogRepositoryImpl implements UsageLogRepository {
  const UsageLogRepositoryImpl(this._hive, this._firestoreService);

  final HiveService _hive;
  final FirestoreService _firestoreService;

  @override
  Future<Either<Failure, Unit>> logSession(UsageLogEntity log) async {
    try {
      // Write to local Hive first — guaranteed to succeed offline.
      final model = UsageLogModel.fromEntity(log);
      await _hive.usageLogsBox.put(model.sessionId, model);
      return const Right(unit);
    } on Exception catch (e) {
      return Left(CacheFailure('Failed to save usage log: $e'));
    }
  }

  @override
  Future<Either<Failure, List<UsageLogEntity>>> getLocalLogs() async {
    try {
      final logs = _hive.usageLogsBox.values
          .where((m) => !m.isSynced)
          .map((m) => m.toEntity())
          .toList();
      return Right(logs);
    } on Exception catch (e) {
      return Left(CacheFailure('Failed to read local logs: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> syncPendingLogs() async {
    try {
      final pending =
          _hive.usageLogsBox.values.where((m) => !m.isSynced).toList();

      for (final log in pending) {
        await _firestoreService.writeUsageLog(log);
        // Mark as synced in Hive
        log.isSynced = true;
        await log.save();
      }
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure('Log sync failed: $e'));
    }
  }
}
