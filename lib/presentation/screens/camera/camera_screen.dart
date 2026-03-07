import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/theme/app_colors.dart';
import '../../bloc/camera/camera_bloc.dart';
import '../../bloc/recognition/recognition_bloc.dart';
import '../../routes/app_router.dart';
import '../../widgets/camera/camera_viewfinder.dart';
import '../../widgets/camera/scan_guide_overlay.dart';
import '../../widgets/common/big_button.dart';
import '../../widgets/common/loading_overlay.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<CameraBloc>()),
        BlocProvider(
          create: (_) => getIt<RecognitionBloc>(),
        ),
      ],
      child: const _CameraView(),
    );
  }
}

class _CameraView extends StatefulWidget {
  const _CameraView();

  @override
  State<_CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<_CameraView> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    context.read<CameraBloc>().add(const CameraInitialize());
    unawaited(_initController());
  }

  Future<void> _initController() async {
    try {
      final cameras = await availableCameras();
      if (!mounted || cameras.isEmpty) return;
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() => _controller = controller);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera initialization failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<CameraBloc, CameraState>(
        listener: (ctx, camState) {
          if (camState is CameraCapturing) {
            // Forward the captured image bytes to RecognitionBloc.
            ctx
                .read<RecognitionBloc>()
                .add(RecognitionFrameReceived(camState.imageBytes));
          }
          if (camState is CameraError) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(camState.message)),
            );
          }
        },
        builder: (ctx, camState) {
          return BlocConsumer<RecognitionBloc, RecognitionState>(
            listener: (rCtx, recState) {
              if (recState is RecognitionRecognized) {
                // Pause camera while showing result.
                rCtx.read<CameraBloc>().add(const CameraPause());
                final data = RecognitionResultRouteData(
                  label: recState.result.label,
                  confidence: recState.result.confidence,
                  vocabularyEn: recState.asset.vocabularyEn,
                  vocabularyVi: recState.asset.vocabularyVi,
                  localModelPath: recState.asset.localModelPath,
                  localAudioPathEn: recState.asset.localAudioPathEn,
                  localAudioPathVi: recState.asset.localAudioPathVi,
                );
                rCtx.go(AppRoutes.result, extra: data);
              }
            },
            builder: (rCtx, recState) {
              final isProcessing = recState is RecognitionPreProcessing ||
                  recState is RecognitionInferring;

              return LoadingOverlay(
                isLoading: camState is CameraInitializing,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CameraViewfinder(controller: _controller),
                    ScanGuideOverlay(isActive: isProcessing),
                    _Toolbar(
                      onHistory: () => rCtx.push(AppRoutes.history),
                      onSettings: () => rCtx.push(AppRoutes.settings),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.onHistory,
    required this.onSettings,
  });

  final VoidCallback onHistory;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BigButton(
                icon: Icons.photo_library_rounded,
                onPressed: onHistory,
                backgroundColor: AppColors.surface,
                iconColor: AppColors.primary,
                tooltip: 'History',
              ),
              BigButton(
                icon: Icons.settings_rounded,
                onPressed: onSettings,
                backgroundColor: AppColors.surface,
                iconColor: AppColors.textSecondary,
                tooltip: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
