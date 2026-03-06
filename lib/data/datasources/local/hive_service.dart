import 'package:hive_flutter/hive_flutter.dart';
import 'package:injectable/injectable.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/drawing_model.dart';
import '../../models/usage_log_model.dart';

/// Manages Hive initialization and provides typed box access.
///
/// Must be called via [HiveService.init] before any box is accessed.
/// Registered as a singleton in the DI container.
@singleton
final class HiveService {
  /// Initializes Hive and registers all TypeAdapters.
  ///
  /// Call this once during app startup, before [configureDependencies].
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register generated TypeAdapters (from build_runner)
    if (!Hive.isAdapterRegistered(DrawingModelAdapter().typeId)) {
      Hive.registerAdapter(DrawingModelAdapter());
    }
    if (!Hive.isAdapterRegistered(UsageLogModelAdapter().typeId)) {
      Hive.registerAdapter(UsageLogModelAdapter());
    }

    // Open all boxes eagerly at startup to avoid first-access latency.
    await Future.wait([
      Hive.openBox<DrawingModel>(AppConstants.hiveBoxDrawings),
      Hive.openBox<UsageLogModel>(AppConstants.hiveBoxUsageLogs),
      Hive.openBox<dynamic>(AppConstants.hiveBoxSettings),
    ]);
  }

  /// Returns the box for storing failed drawings (Data Flywheel).
  Box<DrawingModel> get drawingsBox =>
      Hive.box<DrawingModel>(AppConstants.hiveBoxDrawings);

  /// Returns the box for usage session logs.
  Box<UsageLogModel> get usageLogsBox =>
      Hive.box<UsageLogModel>(AppConstants.hiveBoxUsageLogs);

  /// Returns the general settings box.
  Box<dynamic> get settingsBox =>
      Hive.box<dynamic>(AppConstants.hiveBoxSettings);

  /// Clears a corrupted box and re-opens it as empty.
  ///
  /// Called by the error recovery strategy (see Risk Register R4).
  Future<void> recoverBox(String boxName) async {
    await Hive.deleteBoxFromDisk(boxName);
    await Hive.openBox<dynamic>(boxName);
  }
}
