import 'package:injectable/injectable.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/drawing_model.dart';
import 'hive_service.dart';

/// Local persistence for failed drawings pending upload (Data Flywheel).
abstract interface class DrawingLocalDatasource {
  Future<void> saveFailedDrawing(DrawingModel drawing);
  Future<List<DrawingModel>> getAllFailedDrawings();
  Future<void> deleteDrawing(String id);
  Future<void> deleteAllSynced();
  Future<int> getQueueCount();
}

@Injectable(as: DrawingLocalDatasource)
final class DrawingLocalDatasourceImpl implements DrawingLocalDatasource {
  const DrawingLocalDatasourceImpl(this._hive);

  final HiveService _hive;

  @override
  Future<void> saveFailedDrawing(DrawingModel drawing) async {
    try {
      // Enforce queue size limit to prevent unbounded disk usage.
      final box = _hive.drawingsBox;
      if (box.length >= AppConstants.maxFailedDrawingsQueue) {
        // Evict the oldest entry (FIFO).
        await box.deleteAt(0);
      }
      await box.put(drawing.id, drawing);
    } on Exception catch (e) {
      throw CacheException('Failed to save drawing: $e');
    }
  }

  @override
  Future<List<DrawingModel>> getAllFailedDrawings() async {
    try {
      return _hive.drawingsBox.values.toList();
    } on Exception catch (e) {
      throw CacheException('Failed to read drawings: $e');
    }
  }

  @override
  Future<void> deleteDrawing(String id) async {
    try {
      await _hive.drawingsBox.delete(id);
    } on Exception catch (e) {
      throw CacheException('Failed to delete drawing $id: $e');
    }
  }

  @override
  Future<void> deleteAllSynced() async {
    try {
      final toDelete = _hive.drawingsBox.values
          .where((d) => !d.needsRetraining)
          .map((d) => d.id)
          .toList();
      await _hive.drawingsBox.deleteAll(toDelete);
    } on Exception catch (e) {
      throw CacheException('Failed to purge synced drawings: $e');
    }
  }

  @override
  Future<int> getQueueCount() async => _hive.drawingsBox.length;
}
