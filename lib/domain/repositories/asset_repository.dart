import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/asset_3d_entity.dart';

/// Contract for fetching and caching 3D model + audio assets.
abstract interface class AssetRepository {
  /// Returns the locally cached [Asset3DEntity] for [label].
  ///
  /// Checks local cache first. If missing, attempts a remote download.
  /// Returns [AssetNotFoundFailure] if neither source has the asset.
  Future<Either<Failure, Asset3DEntity>> getAsset(String label);

  /// Downloads all assets from Firebase Storage and caches them locally.
  ///
  /// Should be called on first launch when Wi-Fi is available.
  /// Returns [NetworkFailure] if offline.
  Future<Either<Failure, Unit>> cacheAllAssets();

  /// Returns true if at least one asset has been cached locally.
  Future<bool> hasLocalCache();

  /// Returns a list of all locally cached asset labels.
  Future<List<String>> getCachedLabels();
}
