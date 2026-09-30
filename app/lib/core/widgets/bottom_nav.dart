import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class _NavItem {
  const _NavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _items = [
  _NavItem('Genel', Icons.space_dashboard_outlined),
  _NavItem('Aktivite', Icons.monitor_heart_outlined),
  _NavItem('Tara', Icons.qr_code_scanner),
  _NavItem('AI Koç', Icons.smart_toy_outlined),
  _NavItem('Egzersiz', Icons.fitness_center),
];

/// Alt sekme çubuğu: seçili sekme turuncu hap.
class VBottomNav extends StatelessWidget {
  const VBottomNav({super.key, required this.selected, required this.onTap});

  final int selected;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 64,
    decoration: const BoxDecoration(
      color: VColors.surface,
      border: Border(top: BorderSide(color: VColors.surfaceContainerHighest)),
    ),
    padding: const EdgeInsets.fromLTRB(VSpace.xs, 6, VSpace.xs, 6),
    child: Row(
      children: [
        for (var i = 0; i < _items.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Center(
                child: Container(
                  key: ValueKey('nav-pill-$i'),
                  constraints: const BoxConstraints(minHeight: VSpace.touchMin),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: i == selected
                        ? VColors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _items[i].icon,
                        size: 22,
                        color: i == selected
                            ? VColors.onPrimaryContainer
                            : VColors.onSurfaceVariant,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _items[i].label,
                        maxLines: 1,
                        style: VText.microTag.copyWith(
                          color: i == selected
                              ? VColors.onPrimaryContainer
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
