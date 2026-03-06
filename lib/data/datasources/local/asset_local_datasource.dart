import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/errors/exceptions.dart';

/// Manages local file cache for 3D models (.glb) and audio (.mp3).
///
/// Files are stored in the app's documents directory under `assets_cache/`.
abstract interface class AssetLocalDatasource {
  Future<void> saveFile(String label, String type, List<int> bytes);
  Future<String?> getFilePath(String label, String type);
  Future<bool> fileExists(String label, String type);
  Future<List<String>> getCachedLabels();
}

@Injectable(as: AssetLocalDatasource)
final class AssetLocalDatasourceImpl implements AssetLocalDatasource {
  static const _cacheDir = 'assets_cache';

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
}
