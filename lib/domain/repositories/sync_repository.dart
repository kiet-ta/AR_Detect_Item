import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';

/// Connectivity status values emitted by the sync stream.
enum ConnectivityStatus { online, offline }

/// Contract for background sync: uploading failed drawings and
/// monitoring device connectivity.
abstract interface class SyncRepository {
  /// A stream that emits [ConnectivityStatus] changes in real time.
  Stream<ConnectivityStatus> get connectivityStream;

  /// Uploads all queued failed drawings to Firebase Storage.
  ///
  /// Should be called when [connectivityStream] emits [online].
  /// Returns [NetworkFailure] if connectivity is lost mid-upload.
  Future<Either<Failure, int>> uploadFailedDrawings();

  /// Returns the number of drawings currently queued for upload.
  Future<int> getQueuedDrawingCount();
}
