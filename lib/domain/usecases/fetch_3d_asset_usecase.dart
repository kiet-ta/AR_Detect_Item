import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../entities/asset_3d_entity.dart';
import '../repositories/asset_repository.dart';
import '../../core/errors/failures.dart';

/// Fetches the 3D model asset for a recognized label.
///
/// The repository handles the local-first + remote-fallback strategy;
/// this use case expresses the intent, not the mechanism.
@injectable
final class FetchAssetUseCase {
  const FetchAssetUseCase(this._repository);

  final AssetRepository _repository;

  /// Returns the [Asset3DEntity] for [label] (e.g. 'apple').
  Future<Either<Failure, Asset3DEntity>> call(String label) {
    return _repository.getAsset(label);
  }
}
