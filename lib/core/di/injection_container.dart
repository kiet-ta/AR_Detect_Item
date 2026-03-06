import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../data/datasources/local/hive_service.dart';
import 'injection_container.config.dart';

final GetIt getIt = GetIt.instance;

/// Initializes all dependencies registered via [Injectable].
///
/// Must be called in [main] after [Firebase.initializeApp]
/// and after [HiveService.init].
///
/// Generated code lives in [injection_container.config.dart]
/// (produced by `dart run build_runner build`).
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  // Hive must be initialized before any Hive-dependent singletons are created.
  await HiveService.init();
  await getIt.init();
}
