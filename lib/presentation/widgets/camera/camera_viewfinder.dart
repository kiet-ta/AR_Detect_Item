import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Fills available space with the camera preview while maintaining
/// the native sensor aspect ratio. Does nothing when [controller] is null.
class CameraViewfinder extends StatelessWidget {
  const CameraViewfinder({required this.controller, super.key});

  final CameraController? controller;

  @override
  Widget build(BuildContext context) {
    if (controller == null || !controller!.value.isInitialized) {
      return const SizedBox.expand(
        child: ColoredBox(color: Colors.black),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: controller!.value.previewSize!.height,
              height: controller!.value.previewSize!.width,
              child: CameraPreview(controller!),
            ),
          ),
        );
      },
    );
  }
}
