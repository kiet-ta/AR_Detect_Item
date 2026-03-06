import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

/// Renders a local .glb 3D model using model_viewer_plus.
/// Falls back to a placeholder icon when [modelPath] is null.
class ARModelRenderer extends StatelessWidget {
  const ARModelRenderer({
    required this.label,
    super.key,
    this.modelPath,
  });

  final String label;

  /// Absolute path on device to the cached .glb file,
  /// or null if not yet downloaded.
  final String? modelPath;

  @override
  Widget build(BuildContext context) {
    if (modelPath == null) {
      return Center(
        child: Icon(
          Icons.view_in_ar_rounded,
          size: 120,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.35),
        ),
      );
    }

    // model_viewer_plus requires a URI, not a file path.
    // On Android/iOS, use a "file://" URI for cached assets.
    return ModelViewer(
      src: 'file://$modelPath',
      alt: label,
      autoRotate: true,
      cameraControls: false,
      backgroundColor: const Color(0x00000000),
    );
  }
}
