import 'package:flutter/material.dart';

import '../../widgets/ar/ar_audio_player.dart';
import '../../widgets/ar/ar_model_renderer.dart';

/// Composites the 3D model viewer with the bilingual audio playback button.
class Model3DViewer extends StatelessWidget {
  const Model3DViewer({
    required this.label,
    required this.vocabularyEn,
    required this.vocabularyVi,
    super.key,
    this.modelPath,
    this.audioPathEn,
    this.audioPathVi,
  });

  final String label;
  final String vocabularyEn;
  final String vocabularyVi;
  final String? modelPath;
  final String? audioPathEn;
  final String? audioPathVi;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ARModelRenderer(
            label: label,
            modelPath: modelPath,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ARAudioPlayer(
            audioPathEn: audioPathEn,
            audioPathVi: audioPathVi,
          ),
        ),
      ],
    );
  }
}
