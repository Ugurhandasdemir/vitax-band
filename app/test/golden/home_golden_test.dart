import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/core/theme/app_theme.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/band_sample_repository.dart';
import 'package:vitax_app/data/repos/nutrition_repository.dart';
import 'package:vitax_app/data/repos/settings_repository.dart';
import 'package:vitax_app/features/home/home_screen.dart';

import '../support/seed.dart';

void main() {
  testWidgets('Genel Bakış görünümü (golden)', (tester) async {
    tester.view.physicalSize = const Size(375, 1750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final nutrition = InMemoryNutritionRepository();
    await seedDemoDay(nutrition);
    final band = InMemoryBandSampleRepository();
    await band.insertHr([
      HrSample(at: DateTime(2026, 10, 24, 14, 29), bpm: 72),
    ]);
    await band.insertSteps([
      StepSample(at: DateTime(2026, 10, 24, 9), total: 8432),
    ]);
    final settings = InMemorySettingsRepository();
    await settings.saveProfile(const Profile(weightKg: 93.4, kcalGoal: 2100));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 24, 14, 30)),
          nutritionRepositoryProvider.overrideWithValue(nutrition),
          bandSampleRepositoryProvider.overrideWithValue(band),
          settingsRepositoryProvider.overrideWithValue(settings),
          coachBriefingProvider.overrideWith(
            (ref) async => const CoachBriefing(
              readiness: 88,
              plan: '45 dk Kuvvet Antrenmanı • 2.100 kcal hedefi • 2.5 L su',
              insight: 'Dün gece 7s 12dk derin uyku toparlanmanı artırdı. Bugün bacak antrenmanı için ideal gün!',
            ),
          ),
          lastNightSleepProvider.overrideWith(
            (ref) async => const Duration(hours: 7, minutes: 12),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home.png'),
    );
  });
}
