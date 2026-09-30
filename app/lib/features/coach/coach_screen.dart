import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) => Center(
    key: const ValueKey('screen-coach'),
    child: Text('AI Koç', style: VText.headlineLg),
  );
}
