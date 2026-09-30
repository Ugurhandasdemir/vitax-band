import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  @override
  Widget build(BuildContext context) => Center(
    key: const ValueKey('screen-scan'),
    child: Text('Tara', style: VText.headlineLg),
  );
}
