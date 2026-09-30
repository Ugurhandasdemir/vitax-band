import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class VSegmented extends StatelessWidget {
  const VSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: VColors.surfaceContainer,
      borderRadius: BorderRadius.circular(VRadius.pill),
    ),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: Container(
                key: ValueKey('seg-$i'),
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == selected
                      ? VColors.surfaceContainerLowest
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
                child: Text(
                  labels[i],
                  style: VText.labelMd.copyWith(
                    color: i == selected
                        ? VColors.primary
                        : VColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
