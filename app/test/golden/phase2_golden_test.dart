import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/features/exercises/exercise_detail_screen.dart';
import 'package:vitax_app/features/exercises/exercises_screen.dart';
import 'package:vitax_app/features/workout/routine_builder_screen.dart';
import 'package:vitax_app/features/workout/workout_history_screen.dart';
import 'package:vitax_app/features/workout/workout_summary_screen.dart';

import '../support/pump.dart';
import '../support/seed.dart';

void main() {
  testWidgets('Egzersiz kütüphanesi (golden)', (tester) async {
    await pumpScreen(tester, const Scaffold(body: ExercisesScreen()),
        seeded: false, seedWorkouts: seedWorkouts, size: const Size(375, 1000));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/exercise_library.png'));
  });

  testWidgets('Egzersiz detayı (golden)', (tester) async {
    await pumpScreen(tester, const ExerciseDetailScreen(exerciseId: '0001'),
        seeded: false, seedWorkouts: seedWorkouts, size: const Size(375, 1900));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/exercise_detail.png'));
  });

  testWidgets('Antrenman oluşturucu (golden)', (tester) async {
    await pumpScreen(tester, RoutineBuilderScreen(routine: demoRoutine()),
        seeded: false, seedWorkouts: seedWorkouts, size: const Size(375, 1500));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/routine_builder.png'));
  });

  testWidgets('Antrenman özeti (golden)', (tester) async {
    await pumpScreen(tester, const WorkoutSummaryScreen(sessionId: 1),
        seeded: false, seedWorkouts: seedWorkouts, size: const Size(375, 1700));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/workout_summary.png'));
  });

  testWidgets('Antrenman geçmişi (golden)', (tester) async {
    await pumpScreen(tester, const WorkoutHistoryScreen(),
        seeded: false, seedWorkouts: seedWorkouts, size: const Size(375, 1800));
    await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/workout_history.png'));
  });
}
