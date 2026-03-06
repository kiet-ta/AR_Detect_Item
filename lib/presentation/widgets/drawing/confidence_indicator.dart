import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Horizontal bar showing model confidence (0.0–1.0).
/// Only shown in parent/debug mode.
class ConfidenceIndicator extends StatelessWidget {
  const ConfidenceIndicator({required this.confidence, super.key});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final color = switch (confidence) {
      >= 0.70 => AppColors.secondary,
      >= 0.50 => Colors.orange,
      _ => AppColors.error,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: confidence,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${(confidence * 100).round()}%',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
