import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Shows a confetti-like particle burst and a ✓ icon on recognition success.
/// Trigger by calling [AnimatedFeedbackController.fire()].
class AnimatedFeedback extends StatefulWidget {
  const AnimatedFeedback({
    required this.controller,
    required this.child,
    super.key,
  });

  final AnimatedFeedbackController controller;
  final Widget child;

  @override
  State<AnimatedFeedback> createState() => _AnimatedFeedbackState();
}

class AnimatedFeedbackController extends ChangeNotifier {
  void fire() => notifyListeners();
}

class _Confetti {
  _Confetti(math.Random rng)
      : dx = (rng.nextDouble() - 0.5) * 2,
        dy = -(rng.nextDouble() * 0.8 + 0.4),
        color = _kColors[rng.nextInt(_kColors.length)],
        size = rng.nextDouble() * 8 + 4;

  final double dx;
  final double dy;
  final Color color;
  final double size;

  static const _kColors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    Colors.yellow,
    Colors.greenAccent,
  ];
}

class _AnimatedFeedbackState extends State<AnimatedFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _rng = math.Random();
  late final List<_Confetti> _particles;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    _particles = List.generate(24, (_) => _Confetti(_rng));
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    widget.controller.addListener(_fire);
  }

  void _fire() {
    setState(() => _visible = true);
    _ctrl.forward(from: 0).whenComplete(
          () => setState(() => _visible = false),
        );
  }

  @override
  void dispose() {
    widget.controller.removeListener(_fire);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        if (_visible)
          AnimatedBuilder(
            animation: _ctrl,
            builder: (_, __) {
              return CustomPaint(
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _ctrl.value,
                ),
                child: const SizedBox.expand(),
              );
            },
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({
    required this.particles,
    required this.progress,
  });

  final List<_Confetti> particles;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final paint = Paint();
    for (final p in particles) {
      final opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = p.color.withOpacity(opacity);
      final x = cx + p.dx * size.width * 0.4 * progress;
      final y = cy + p.dy * size.height * 0.5 * progress +
          (progress * progress * size.height * 0.15); // gravity
      canvas.drawCircle(Offset(x, y), p.size * (1 - progress * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress;
}
