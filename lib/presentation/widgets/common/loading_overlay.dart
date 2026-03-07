import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Full-screen semi-transparent overlay shown during async operations.
/// Child is still rendered underneath so there is no layout jump.
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    required this.isLoading,
    required this.child,
    super.key,
    this.label,
  });

  final bool isLoading;
  final Widget child;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          ModalBarrier(
            color: Colors.black.withOpacity(0.45),
            dismissible: false,
          ),
        if (isLoading)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 5,
                    color: AppColors.primary,
                  ),
                ),
                if (label != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label!,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
