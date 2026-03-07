import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../models/asset_cache_metadata.dart';
import 'hive_service.dart';

/// Manages local file cache for 3D models (.glb) and audio (.mp3).
///
/// Files are stored in the app's documents directory under `assets_cache/`.
/// LRU eviction metadata is kept in the [HiveService.assetMetadataBox] box,
/// acting as a lightweight index without loading binary asset data into memory.
abstract interface class AssetLocalDatasource {
  Future<void> saveFile(String label, String type, List<int> bytes);
  Future<String?> getFilePath(String label, String type);
  Future<bool> fileExists(String label, String type);
  Future<List<String>> getCachedLabels();

  /// Records [totalSizeBytes] bytes cached for [label] in the LRU index.
  /// Call this once after all three files for a label have been saved.
  Future<void> recordCached(String label, int totalSizeBytes);

  /// Stamps [label]'s `lastAccessedAt` to now in the LRU index.
  /// Call this after every successful cache hit to keep access times current.
  Future<void> updateLastAccessed(String label);

  /// Deletes all three cached files for [label] (model + audio_en + audio_vi)
  /// and removes its metadata entry from the LRU index.
  Future<void> deleteAsset(String label);

  /// Evicts the least-recently-used assets until total cache size is at or
  /// below [AppConstants.maxCacheSizeBytes].
  Future<void> evictIfNeeded();
}

@Injectable(as: AssetLocalDatasource)
final class AssetLocalDatasourceImpl implements AssetLocalDatasource {
  const AssetLocalDatasourceImpl(this._hiveService);

  final HiveService _hiveService;

  static const _cacheDir = 'assets_cache';
  static const _allTypes = ['model', 'audio_en', 'audio_vi'];

  Future<Directory> _getCacheDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/$_cacheDir');
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }

  /// [type]: 'model', 'audio_en', 'audio_vi'
  String _fileName(String label, String type) {
    final ext = type == 'model' ? 'glb' : 'mp3';
    return '${label}_$type.$ext';
  }

  @override
  Future<void> saveFile(String label, String type, List<int> bytes) async {
    try {
      final dir = await _getCacheDirectory();
      final file = File('${dir.path}/${_fileName(label, type)}');
      await file.writeAsBytes(bytes, flush: true);
    } on Exception catch (e) {
      throw CacheException('Failed to cache asset $label/$type: $e');
    }
  }

  @override
  Future<String?> getFilePath(String label, String type) async {
    final dir = await _getCacheDirectory();
    final file = File('${dir.path}/${_fileName(label, type)}');
    return file.existsSync() ? file.path : null;
  }

  @override
  Future<bool> fileExists(String label, String type) async {
    final path = await getFilePath(label, type);
    return path != null;
  }

  @override
  Future<List<String>> getCachedLabels() async {
    try {
      final dir = await _getCacheDirectory();
      final files = dir.listSync().whereType<File>();
      // Extract unique labels from filenames like 'apple_model.glb'
      return files
          .map((f) => f.uri.pathSegments.last)
          .where((name) => name.endsWith('_model.glb'))
          .map((name) => name.replaceAll('_model.glb', ''))
          .toList();
    } on Exception catch (e) {
      throw CacheException('Failed to list cached labels: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // LRU cache management
  // ---------------------------------------------------------------------------

  @override
  Future<void> recordCached(String label, int totalSizeBytes) async {
    try {
      final box = _hiveService.assetMetadataBox;
      final existing = box.get(label);
      if (existing != null) {
        // Update in-place — asset was re-downloaded (version bump).
        existing
          ..totalSizeBytes = totalSizeBytes
          ..lastAccessedAtMs =
              DateTime.now().toUtc().millisecondsSinceEpoch;
        await existing.save();
      } else {
        await box.put(
          label,
          AssetCacheMetadata.fresh(
            label: label,
            totalSizeBytes: totalSizeBytes,
          ),
        );
      }
    } on Exception catch (e) {
      throw CacheException('Failed to record cache metadata for $label: $e');
    }
  }

  @override
  Future<void> updateLastAccessed(String label) async {
    final entry = _hiveService.assetMetadataBox.get(label);
    if (entry == null) {
      return; // Metadata may be absent for pre-LRU cached assets
    }
    entry.lastAccessedAtMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    await entry.save();
  }

  @override
  Future<void> deleteAsset(String label) async {
    try {
      final dir = await _getCacheDirectory();
      for (final type in _allTypes) {
        final file = File('${dir.path}/${_fileName(label, type)}');
        if (file.existsSync()) await file.delete();
      }
      await _hiveService.assetMetadataBox.delete(label);
      AppLogger.d('AssetLocalDatasource: evicted "$label" from cache');
    } on Exception catch (e) {
      throw CacheException('Failed to delete cached asset $label: $e');
    }
  }

  @override
  Future<void> evictIfNeeded() async {
    final box = _hiveService.assetMetadataBox;
    final allMeta = box.values.toList();

    int totalBytes = allMeta.fold(0, (sum, m) => sum + m.totalSizeBytes);
    if (totalBytes <= AppConstants.maxCacheSizeBytes) return;

    // Sort ascending by last access time: oldest (least-recently-used) first.
    allMeta.sort((a, b) => a.lastAccessedAtMs.compareTo(b.lastAccessedAtMs));

    for (final meta in allMeta) {
      if (totalBytes <= AppConstants.maxCacheSizeBytes) break;
      await deleteAsset(meta.label);
      totalBytes -= meta.totalSizeBytes;
    }
  }
}
