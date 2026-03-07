import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Animated rounded-rectangle overlay guiding the child to position
/// their drawing inside the bracket.
class ScanGuideOverlay extends StatefulWidget {
  const ScanGuideOverlay({super.key, this.isActive = false});

  final bool isActive;

  @override
  State<ScanGuideOverlay> createState() => _ScanGuideOverlayState();
}

class _ScanGuideOverlayState extends State<ScanGuideOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final t = _pulse.value;
        final color = widget.isActive
            ? Color.lerp(AppColors.primary, AppColors.accent, t)!
            : Colors.white.withValues(alpha: 0.6);
        return CustomPaint(
          painter: _BracketPainter(color: color, pulse: t),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({required this.color, required this.pulse});

  final Color color;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5 + pulse * 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final padding = size.width * 0.08;
    final rect = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );
    const cornerLen = 28.0;
    const r = 16.0;

    final corners = <({Offset start, Offset corner, Offset end})>[
      (
        start: Offset(rect.left + cornerLen, rect.top),
        corner: Offset(rect.left + r, rect.top),
        end: Offset(rect.left, rect.top + cornerLen),
      ),
      (
        start: Offset(rect.right - cornerLen, rect.top),
        corner: Offset(rect.right - r, rect.top),
        end: Offset(rect.right, rect.top + cornerLen),
      ),
      (
        start: Offset(rect.right - cornerLen, rect.bottom),
        corner: Offset(rect.right - r, rect.bottom),
        end: Offset(rect.right, rect.bottom - cornerLen),
      ),
      (
        start: Offset(rect.left + cornerLen, rect.bottom),
        corner: Offset(rect.left + r, rect.bottom),
        end: Offset(rect.left, rect.bottom - cornerLen),
      ),
    ];

    final path = Path();
    for (final c in corners) {
      path
        ..moveTo(c.start.dx, c.start.dy)
        ..quadraticBezierTo(c.corner.dx, c.corner.dy, c.end.dx, c.end.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) =>
      old.color != color || old.pulse != pulse;
}
