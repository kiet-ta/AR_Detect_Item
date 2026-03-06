import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/connectivity_service.dart';
import '../../domain/repositories/sync_repository.dart';
import '../datasources/local/drawing_local_datasource.dart';
import '../datasources/remote/firebase_storage_service.dart';
import '../datasources/remote/firestore_service.dart';

@Injectable(as: SyncRepository)
final class SyncRepositoryImpl implements SyncRepository {
  const SyncRepositoryImpl(
    this._localDatasource,
    this._storageService,
    this._firestoreService,
    this._connectivityService,
  );

  final DrawingLocalDatasource _localDatasource;
  final FirebaseStorageService _storageService;
  final FirestoreService _firestoreService;
  final ConnectivityService _connectivityService;

  @override
  Stream<ConnectivityStatus> get connectivityStream =>
      _connectivityService.statusStream;

  @override
  Future<Either<Failure, int>> uploadFailedDrawings() async {
    try {
      final drawings = await _localDatasource.getAllFailedDrawings();
      if (drawings.isEmpty) return const Right(0);

      var uploadedCount = 0;
      for (final drawing in drawings) {
        // Upload binary to Firebase Storage
        final storagePath = await _storageService.uploadFailedDrawing(
          drawingId: drawing.id,
          imageBytes: drawing.imageBytes,
        );

        // Write metadata to Firestore for ML team
        await _firestoreService.writeFailedDrawingMetadata(
          drawingId: drawing.id,
          storagePath: storagePath,
          confidence: 0.0, // Confidence stored separately in Hive
        );

        // Mark as synced and remove from local queue
        await _localDatasource.deleteDrawing(drawing.id);
        uploadedCount++;
      }

      return Right(uploadedCount);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on Exception catch (e) {
      return Left(ServerFailure('Sync failed: $e'));
    }
  }

  @override
  Future<int> getQueuedDrawingCount() =>
      _localDatasource.getQueueCount();
}
