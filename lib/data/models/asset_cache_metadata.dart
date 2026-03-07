import 'package:hive_flutter/hive_flutter.dart';

part 'asset_cache_metadata.g.dart';

/// Hive-persisted metadata for a locally cached 3D model asset.
///
/// This is the "librarian's notebook": only lightweight bookkeeping data
/// lives here (label, size, timestamps). The actual files (.glb / .mp3) are
/// stored separately on the file system under `assets_cache/`.
///
/// Used by [AssetLocalDatasource] to implement an LRU eviction policy:
/// when the total cache size exceeds [AppConstants.maxCacheSizeBytes] (200 MB),
/// the asset with the oldest [lastAccessedAt] is deleted first.
@HiveType(typeId: 2)
final class AssetCacheMetadata extends HiveObject {
  AssetCacheMetadata({
    required this.label,
    required this.totalSizeBytes,
    required this.lastAccessedAtMs,
    required this.cachedAtMs,
  });

  /// Classifier label (e.g. `'apple'`). Used as the Hive box key.
  @HiveField(0)
  final String label;

  /// Combined on-disk size of all three cached files:
  /// `{label}_model.glb` + `{label}_audio_en.mp3` + `{label}_audio_vi.mp3`.
  @HiveField(1)
  int totalSizeBytes;

  /// Epoch milliseconds of the last time this asset was successfully read
  /// from the local cache. Updated on every cache hit inside [getFilePath].
  @HiveField(2)
  int lastAccessedAtMs;

  /// Epoch milliseconds of when this asset was first downloaded and saved.
  @HiveField(3)
  final int cachedAtMs;

  /// Convenience accessor — resolves [lastAccessedAtMs] to a UTC [DateTime].
  DateTime get lastAccessedAt =>
      DateTime.fromMillisecondsSinceEpoch(lastAccessedAtMs, isUtc: true);

  /// Convenience accessor — resolves [cachedAtMs] to a UTC [DateTime].
  DateTime get cachedAt =>
      DateTime.fromMillisecondsSinceEpoch(cachedAtMs, isUtc: true);

  /// Creates a fresh metadata entry immediately after all three files for
  /// [label] have been written to disk with a combined size of [totalSizeBytes].
  factory AssetCacheMetadata.fresh({
    required String label,
    required int totalSizeBytes,
  }) {
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    return AssetCacheMetadata(
      label: label,
      totalSizeBytes: totalSizeBytes,
      lastAccessedAtMs: nowMs,
      cachedAtMs: nowMs,
    );
  }
}
