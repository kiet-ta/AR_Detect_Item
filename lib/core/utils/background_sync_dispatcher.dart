import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/datasources/local/drawing_local_datasource.dart';
import '../../data/datasources/local/hive_service.dart';
import '../../data/datasources/remote/firebase_storage_service.dart';
import '../../data/datasources/remote/firestore_service.dart';
import 'logger.dart';

const _taskNamePeriodicSync = 'background_sync_drawings';

/// Registers WorkManager periodic tasks for overnight Data Flywheel uploads.
///
/// Constraints ensure uploads only run when the device is connected and
/// charging — minimal impact on battery and metered data.
///
/// Call once after [configureDependencies] in [main].
Future<void> registerBackgroundTasks() async {
  await Workmanager().initialize(_callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    _taskNamePeriodicSync,
    _taskNamePeriodicSync,
    frequency: const Duration(hours: 6),
    constraints: Constraints(
      networkType: NetworkType.connected,
      requiresCharging: true,
    ),
    existingWorkPolicy: ExistingWorkPolicy.keep,
  );
  AppLogger.i(
    'BackgroundSync: periodic task registered (6h, connected + charging)',
  );
}

/// WorkManager top-level callback — must be a free function annotated with
/// [pragma('vm:entry-point')] so the AOT compiler does not tree-shake it.
///
/// The GetIt DI container is unavailable in this isolate, so all dependencies
/// are manually instantiated after re-initialising Firebase and Hive.
@pragma('vm:entry-point')
void _callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _taskNamePeriodicSync) return true;
    try {
      await Firebase.initializeApp();
      await HiveService.init();
      final hiveService = HiveService();
      final localDatasource = DrawingLocalDatasourceImpl(hiveService);
      final storageService = FirebaseStorageService(FirebaseStorage.instance);
      final firestoreService = FirestoreService(FirebaseFirestore.instance);
      await _runSync(localDatasource, storageService, firestoreService);
      return true;
    } on Exception catch (e) {
      AppLogger.e('BackgroundSync: task failed', e.toString());
      return false; // WorkManager will retry with exponential back-off
    }
  });
}

Future<void> _runSync(
  DrawingLocalDatasource localDatasource,
  FirebaseStorageService storageService,
  FirestoreService firestoreService,
) async {
  final drawings = await localDatasource.getAllFailedDrawings();
  if (drawings.isEmpty) {
    AppLogger.d('BackgroundSync: nothing to upload');
    return;
  }
  AppLogger.i('BackgroundSync: uploading ${drawings.length} drawings');
  for (final drawing in drawings) {
    final storagePath = await storageService.uploadFailedDrawing(
      drawingId: drawing.id,
      imageBytes: drawing.imageBytes,
    );
    await firestoreService.writeFailedDrawingMetadata(
      drawingId: drawing.id,
      storagePath: storagePath,
      confidence: 0.0,
    );
    await localDatasource.deleteDrawing(drawing.id);
  }
  AppLogger.i('BackgroundSync: uploaded ${drawings.length} drawings');
}
