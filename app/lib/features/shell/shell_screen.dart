import 'package:flutter/material.dart';

import '../../core/widgets/bottom_nav.dart';
import '../activity/activity_screen.dart';
import '../coach/coach_screen.dart';
import '../exercises/exercises_screen.dart';
import '../home/home_screen.dart';
import '../profile/profile_hub_screen.dart';
import '../scan/scan_screen.dart';
import 'top_bar.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const _subtitles = [
    'Genel Bakış',
    'Sağlık ve Aktivite',
    'Tara',
    'AI Koç',
    'Egzersiz',
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: VTopBar(
      subtitle: _subtitles[_index],
      onAvatarTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const ProfileHubScreen())),
    ),
    body: IndexedStack(
      index: _index,
      children: const [
        HomeScreen(),
        ActivityScreen(),
        ScanScreen(),
        CoachScreen(),
        ExercisesScreen(),
      ],
    ),
    bottomNavigationBar: VBottomNav(
      selected: _index,
      onTap: (i) => setState(() => _index = i),
    ),
  );
}
