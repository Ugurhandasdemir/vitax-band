import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/providers.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/tokens.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/shell_screen.dart';

class VitaxApp extends StatelessWidget {
  const VitaxApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Vital Precision',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: const AppGate(),
  );
}

/// Profil yüklenene kadar bekler; ilk açılışta karşılama, sonra ana kabuk.
class AppGate extends ConsumerWidget {
  const AppGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return profile.when(
      data: (p) => p.onboarded ? const ShellScreen() : const OnboardingScreen(),
      loading: () => const Scaffold(
        backgroundColor: VColors.background,
        body: Center(child: CircularProgressIndicator(color: VColors.primary)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: VColors.background,
        body: Center(child: Text('Veri yüklenemedi: $e')),
      ),
    );
  }
}
