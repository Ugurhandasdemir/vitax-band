import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Beyaz yüzey, 1px ince kenarlık, 16px yarıçap. Gölge yok (tasarım düz).
class VCard extends StatelessWidget {
  const VCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(VSpace.md),
    this.radius = VRadius.card,
    this.color = VColors.surfaceContainerLowest,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: VColors.surfaceContainerHighest),
    ),
    child: Padding(padding: padding, child: child),
  );
}
