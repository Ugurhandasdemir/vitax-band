import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../format.dart';
import '../theme/tokens.dart';

/// Günlük kalori halkası: ortada alınan kcal, altında hedef.
class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.value,
    required this.goal,
    this.size = 140,
  });

  final int value;
  final int goal;
  final double size;

  double get fraction => goal <= 0 ? 0 : (value / goal).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(size: Size.square(size), painter: _RingPainter(fraction)),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatTr(value),
              style: VText.headlineLg.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '/ ${formatTr(goal)} KCAL',
              style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.1;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = VColors.surfaceContainer;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);
    if (fraction <= 0) return;
    final prog = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = stroke
      ..color = VColors.primaryContainer;
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * fraction, false, prog);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction;
}
