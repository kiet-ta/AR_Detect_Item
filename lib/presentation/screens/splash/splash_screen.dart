import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/onboarding/onboarding_bloc.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/loading_overlay.dart';

/// Entry screen: shows animated logo, requests camera permission,
/// waits for asset caching, then navigates to CameraScreen.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          getIt<OnboardingBloc>()..add(const OnboardingCheck()),
      child: const _SplashView(),
    );
  }
}

class _SplashView extends StatefulWidget {
  const _SplashView();

  @override
  State<_SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<_SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isGranted) {
      context
          .read<OnboardingBloc>()
          .add(const OnboardingPermissionGranted());
    } else {
      context
          .read<OnboardingBloc>()
          .add(const OnboardingPermissionDenied());
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (ctx, state) {
        if (state is OnboardingReady || state is OnboardingOfflineReady) {
          ctx.go(AppRoutes.camera);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<OnboardingBloc, OnboardingState>(
          builder: (_, state) {
            String? label;
            if (state is OnboardingDownloading) {
              label =
                  'Downloading assets… ${(state.progressPercent * 100).round()}%';
            }
            return LoadingOverlay(
              isLoading: state is OnboardingDownloading,
              label: label,
              child: Center(
                child: FadeTransition(
                  opacity: _fadeIn,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App logo placeholder — replace with real asset.
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.draw_rounded,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Magic Doodle',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (state is OnboardingPermissionRequired) ...
                        [
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () => openAppSettings(),
                            icon: const Icon(Icons.camera_alt_rounded),
                            label: const Text('Allow Camera'),
                          ),
                        ],
                      if (state is OnboardingOfflineNoAssets) ...
                        [
                          const SizedBox(height: 32),
                          const Icon(
                            Icons.wifi_off_rounded,
                            size: 48,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Connect to Wi-Fi for first setup',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    color: AppColors.textSecondary),
                          ),
                        ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
