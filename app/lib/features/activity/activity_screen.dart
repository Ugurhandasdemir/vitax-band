import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) => Center(
    key: const ValueKey('screen-activity'),
    child: Text('Sağlık ve Aktivite', style: VText.headlineLg),
  );
}
