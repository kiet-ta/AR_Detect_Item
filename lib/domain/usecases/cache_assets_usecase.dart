import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/failures.dart';
import '../repositories/asset_repository.dart';

/// Downloads and caches all 3D model + audio assets from Firebase Storage.
///
/// Should be triggered on first launch when Wi-Fi is detected.
/// Subsequent launches skip this if [AssetRepository.hasLocalCache] is true.
@injectable
final class CacheAssetsUseCase {
  const CacheAssetsUseCase(this._repository);

  final AssetRepository _repository;

  /// Begins the full asset download and caching process.
  ///
  /// Returns [NetworkFailure] if the device is offline.
  Future<Either<Failure, Unit>> call() {
    return _repository.cacheAllAssets();
  }
}
