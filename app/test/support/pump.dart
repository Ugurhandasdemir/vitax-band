import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/core/theme/app_theme.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/band_sample_repository.dart';
import 'package:vitax_app/data/repos/nutrition_repository.dart';
import 'package:vitax_app/data/repos/settings_repository.dart';
import 'package:vitax_app/data/repos/workout_repository.dart';
import 'package:vitax_app/data/exercise_catalog.dart';
import 'package:vitax_app/features/workout/workout_providers.dart';

import 'dart:io';

import 'seed.dart';

class TestEnv {
  TestEnv(
    this.container,
    this.nutrition,
    this.band,
    this.settings,
    this.workouts,
  );
  final InMemoryWorkoutRepository workouts;
  final ProviderContainer container;
  final InMemoryNutritionRepository nutrition;
  final InMemoryBandSampleRepository band;
  final InMemorySettingsRepository settings;
}

/// 24 Ekim 2026 14:30 sabit saatiyle bir ekranı iPhone SE 3 boyutunda açar.
Future<TestEnv> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  bool seeded = true,
  int steps = 0,
  Profile profile = const Profile(weightKg: 70, kcalGoal: 2100),
  List<Override> overrides = const [],
  DateTime Function()? clock,
  Future<void> Function(InMemoryNutritionRepository)? seedExtra,
  Future<void> Function(InMemoryWorkoutRepository)? seedWorkouts,
  Size size = const Size(375, 667),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final nutrition = InMemoryNutritionRepository();
  if (seeded) await seedDemoDay(nutrition);
  if (seedExtra != null) await seedExtra(nutrition);
  final band = InMemoryBandSampleRepository();
  if (steps > 0) {
    await band.insertSteps([
      StepSample(at: DateTime(2026, 10, 24, 9), total: steps),
    ]);
  }
  final settings = InMemorySettingsRepository();
  await settings.saveProfile(profile);
  final workouts = InMemoryWorkoutRepository();
  if (seedWorkouts != null) await seedWorkouts(workouts);
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(clock ?? () => DateTime(2026, 10, 24, 14, 30)),
      nutritionRepositoryProvider.overrideWithValue(nutrition),
      bandSampleRepositoryProvider.overrideWithValue(band),
      settingsRepositoryProvider.overrideWithValue(settings),
      workoutRepositoryProvider.overrideWithValue(workouts),
      exerciseCatalogProvider.overrideWith((ref) async => fixtureCatalog()),
      exerciseMediaBuilderProvider.overrideWithValue(fakeMedia),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: screen,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return TestEnv(container, nutrition, band, settings, workouts);
}

/// Öğeyi görünür alana kaydırıp dokunur (ListView tembel çizdiği için).
Future<void> tapVisible(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.pumpAndSettle();
  await tester.tap(f);
  await tester.pumpAndSettle();
}

ExerciseCatalog fixtureCatalog() => ExerciseCatalog.fromJson(
  File('test/fixtures/exercises_small.json').readAsStringSync(),
);

/// Ağ yerine yer tutucu: anahtar URL'yi taşır, testte hangi medya yüklendiği doğrulanır.
Widget fakeMedia(
  String url, {
  double size = 72,
  BoxFit fit = BoxFit.cover,
  bool controllable = false,
  double speed = 1,
  bool playing = true,
}) => Container(
  key: ValueKey('media:$url'),
  width: size,
  height: size,
  color: const Color(0xFFE3E1EB),
);
