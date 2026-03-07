import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../routes/app_router.dart';
import '../../widgets/common/big_button.dart';
import 'model_3d_viewer.dart';

/// Displays the recognised entity's 3D model, bilingual vocabulary label,
/// and a big back button to return to the camera screen.
class ResultScreen extends StatelessWidget {
  const ResultScreen({required this.data, super.key});

  final RecognitionResultRouteData data;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Top bar — back button
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BigButton(
                  icon: Icons.arrow_back_rounded,
                  onPressed: () {
                    context.go(AppRoutes.camera);
                  },
                  backgroundColor: AppColors.surface,
                  iconColor: AppColors.primary,
                  tooltip: 'Back',
                ),
              ),
            ),
            const SizedBox(height: 16),
            // 3D model fills remaining space
            Expanded(
              child: Model3DViewer(
                label: data.label,
                vocabularyEn: data.vocabularyEn,
                vocabularyVi: data.vocabularyVi,
                modelPath: data.localModelPath,
                audioPathEn: data.localAudioPathEn,
                audioPathVi: data.localAudioPathVi,
              ),
            ),
            // Vocabulary badge
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      data.vocabularyEn,
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (data.vocabularyVi.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        data.vocabularyVi,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
