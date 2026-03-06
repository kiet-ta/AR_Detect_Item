import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Large icon-only button sized for small children (min 72×72dp).
/// Conforms to the zero-text UI requirement in the spec.
class BigButton extends StatelessWidget {
  const BigButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.size = 72.0,
    this.backgroundColor,
    this.iconColor,
    this.tooltip,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? tooltip;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final fg = iconColor ?? Colors.white;

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: onPressed == null ? bg.withOpacity(0.4) : bg,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bg.withOpacity(0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isLoading
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: fg,
              ),
            )
          : Icon(icon, color: fg, size: size * 0.45),
    );

    final button = GestureDetector(
      onTap: onPressed,
      child: child,
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
