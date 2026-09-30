import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class VProgressBar extends StatelessWidget {
  const VProgressBar({
    super.key,
    required this.value,
    this.color = VColors.secondary,
    this.height = 8,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Container(
      key: const ValueKey('vprogress-track'),
      height: height,
      decoration: BoxDecoration(
        color: VColors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(VRadius.pill),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: v,
        child: Container(
          key: const ValueKey('vprogress-fill'),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(VRadius.pill),
          ),
        ),
      ),
    );
  }
}
