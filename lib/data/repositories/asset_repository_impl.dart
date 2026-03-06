import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/network_info.dart';
import '../../domain/entities/asset_3d_entity.dart';
import '../../domain/repositories/asset_repository.dart';
import '../datasources/local/asset_local_datasource.dart';
import '../datasources/remote/firebase_storage_service.dart';
import '../datasources/remote/firestore_service.dart';

@Injectable(as: AssetRepository)
final class AssetRepositoryImpl implements AssetRepository {
  const AssetRepositoryImpl(
    this._localDatasource,
    this._storageService,
    this._firestoreService,
    this._networkInfo,
  );

  final AssetLocalDatasource _localDatasource;
  final FirebaseStorageService _storageService;
  final FirestoreService _firestoreService;
  final NetworkInfo _networkInfo;

  @override
  Future<Either<Failure, Asset3DEntity>> getAsset(String label) async {
    // 1. Try local cache first (Offline-First)
    final modelPath = await _localDatasource.getFilePath(label, 'model');
    final audioEnPath = await _localDatasource.getFilePath(label, 'audio_en');
    final audioViPath = await _localDatasource.getFilePath(label, 'audio_vi');

    if (modelPath != null && audioEnPath != null && audioViPath != null) {
      // Fully cached — return immediately without network
      return Right(
        Asset3DEntity(
          label: label,
          localModelPath: modelPath,
          localAudioPathEn: audioEnPath,
          localAudioPathVi: audioViPath,
          vocabularyEn: _toTitleCase(label),
          vocabularyVi: label, // Resolved from Firestore on full cache
          category: 'general',
        ),
      );
    }

    // 2. Not cached — try remote download
    final isOnline = await _networkInfo.isConnected;
    if (!isOnline) {
      return Left(AssetNotFoundFailure(label));
    }

    return _downloadAndCacheAsset(label);
  }

  @override
  Future<Either<Failure, Unit>> cacheAllAssets() async {
    try {
      final manifest = await _firestoreService.fetchAssetManifest();
      for (final asset in manifest) {
        final modelBytes =
            await _storageService.downloadFile(asset.remoteModelPath);
        await _localDatasource.saveFile(asset.label, 'model', modelBytes);

        final audioEnBytes =
            await _storageService.downloadFile(asset.remoteAudioPathEn);
        await _localDatasource.saveFile(
          asset.label, 'audio_en', audioEnBytes,
        );

        final audioViBytes =
            await _storageService.downloadFile(asset.remoteAudioPathVi);
        await _localDatasource.saveFile(
          asset.label, 'audio_vi', audioViBytes,
        );
      }
      return const Right(unit);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  @override
  Future<bool> hasLocalCache() async {
    final labels = await _localDatasource.getCachedLabels();
    return labels.isNotEmpty;
  }

  @override
  Future<List<String>> getCachedLabels() =>
      _localDatasource.getCachedLabels();

  Future<Either<Failure, Asset3DEntity>> _downloadAndCacheAsset(
    String label,
  ) async {
    try {
      final manifest = await _firestoreService.fetchAssetManifest();
      final assetDoc = manifest.firstWhere(
        (a) => a.label == label,
        orElse: () => throw AssetNotFoundException(label),
      );

      final modelBytes =
          await _storageService.downloadFile(assetDoc.remoteModelPath);
      await _localDatasource.saveFile(label, 'model', modelBytes);

      final audioEnBytes =
          await _storageService.downloadFile(assetDoc.remoteAudioPathEn);
      await _localDatasource.saveFile(label, 'audio_en', audioEnBytes);

      final audioViBytes =
          await _storageService.downloadFile(assetDoc.remoteAudioPathVi);
      await _localDatasource.saveFile(label, 'audio_vi', audioViBytes);

      return Right(assetDoc.withLocalPaths(
        modelPath:
            (await _localDatasource.getFilePath(label, 'model'))!,
        audioEnPath:
            (await _localDatasource.getFilePath(label, 'audio_en'))!,
        audioViPath:
            (await _localDatasource.getFilePath(label, 'audio_vi'))!,
      ).toEntity());
    } on AssetNotFoundException catch (e) {
      return Left(AssetNotFoundFailure(e.label));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } on CacheException catch (e) {
      return Left(CacheFailure(e.message));
    }
  }

  String _toTitleCase(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
