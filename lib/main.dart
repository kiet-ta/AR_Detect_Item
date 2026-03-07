import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/di/injection_container.dart';
import 'core/utils/background_sync_dispatcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation (optimal for kids camera use)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Dependency Injection + Hive
  await configureDependencies();

  // Register background tasks (WorkManager periodic sync)
  await registerBackgroundTasks();

  runApp(const MagicDoodleApp());
}
