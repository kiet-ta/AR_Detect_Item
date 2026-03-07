import 'package:go_router/go_router.dart';

import '../screens/camera/camera_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/result/result_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/splash/splash_screen.dart';

/// Named route paths — use constants to avoid typos.
abstract final class AppRoutes {
  static const splash = '/';
  static const camera = '/camera';
  static const result = '/result';
  static const history = '/history';
  static const settings = '/settings';
}

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.camera,
        name: 'camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: AppRoutes.result,
        name: 'result',
        builder: (context, state) {
          final extra = state.extra as RecognitionResultRouteData?;
          return ResultScreen(data: extra!);
        },
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    // Redirect unknown routes to splash.
    errorBuilder: (context, state) => const SplashScreen(),
  );
}

/// Data passed via router to ResultScreen.
class RecognitionResultRouteData {
  const RecognitionResultRouteData({
    required this.label,
    required this.confidence,
    required this.vocabularyEn,
    required this.vocabularyVi,
    this.localModelPath,
    this.localAudioPathEn,
    this.localAudioPathVi,
  });

  final String label;
  final double confidence;
  final String vocabularyEn;
  final String vocabularyVi;
  final String? localModelPath;
  final String? localAudioPathEn;
  final String? localAudioPathVi;
}
