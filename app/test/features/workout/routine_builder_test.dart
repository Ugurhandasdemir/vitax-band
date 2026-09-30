import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/features/workout/active_workout.dart';
import 'package:vitax_app/features/workout/live_workout_screen.dart';
import 'package:vitax_app/features/workout/routine_builder_screen.dart';

import '../../support/pump.dart';
import '../../support/seed.dart';

Future<TestEnv> pumpBuilder(
  WidgetTester tester, {
  bool existing = true,
  List<String> initial = const [],
}) => pumpScreen(
  tester,
  RoutineBuilderScreen(
    routine: existing ? demoRoutine() : null,
    initialExerciseIds: initial,
  ),
  seeded: false,
  seedWorkouts: existing ? seedWorkouts : null,
);

Future<void> scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('başlık, rutin adı ve Kaydet', (tester) async {
    await pumpBuilder(tester);
    expect(find.text('ANTRENMAN PLANI'), findsOneWidget);
    expect(find.text('Kaydet'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('routine-name')),
    );
    expect(field.controller!.text, 'Push Day (İtiş A)');
  });

  testWidgets('özet şeridi: süre, hacim (set), hedef', (tester) async {
    await pumpBuilder(tester);
    expect(find.text('14 dk'), findsOneWidget);
    expect(find.text('7 Set'), findsOneWidget);
    expect(find.text('Hipertrofi'), findsOneWidget);
  });

  testWidgets('egzersiz sıralaması, küçük resim ve mola çipleri', (
    tester,
  ) async {
    await pumpBuilder(tester);
    expect(find.text('EGZERSİZ SIRALAMASI (2)'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Dumbbell Fly'), findsOneWidget);
    expect(find.text('90 sn mola'), findsOneWidget);
    expect(find.text('60 sn mola'), findsOneWidget);
    final ex = fixtureCatalog().byId('0001')!;
    expect(find.byKey(ValueKey('media:${ex.gifUrl}')), findsOneWidget);
  });

  testWidgets('ilk egzersizin set satırları ve ağırlık artırma', (
    tester,
  ) async {
    await pumpBuilder(tester);
    expect(find.text('12 tekrar • 60 kg'), findsOneWidget);
    expect(find.text('10 tekrar • 75 kg'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('w-plus-0-1')));
    await tester.pumpAndSettle();
    expect(find.text('10 tekrar • 77,5 kg'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('r-minus-0-1')));
    await tester.pumpAndSettle();
    expect(find.text('9 tekrar • 77,5 kg'), findsOneWidget);
  });

  testWidgets('Set ekle son setin kopyasını ekler', (tester) async {
    await pumpBuilder(tester);
    await tapVisible(tester, find.byKey(const ValueKey('add-set-0')));
    await tester.scrollUntilVisible(find.text('8 Set'), -300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('7 Set'), findsNothing);
    expect(find.text('8 Set'), findsOneWidget);
  });

  testWidgets('egzersiz silinince özet güncellenir', (tester) async {
    await pumpBuilder(tester);
    await tapVisible(tester, find.byKey(const ValueKey('remove-exercise-0')));
    expect(find.text('EGZERSİZ SIRALAMASI (1)'), findsOneWidget);
    expect(find.text('3 Set'), findsOneWidget);
  });

  testWidgets('Egzersiz Ekle: seçiciden hareket eklenir', (tester) async {
    await pumpBuilder(tester);
    await scrollTo(tester, find.text('Egzersiz Ekle'));
    await tapVisible(tester, find.text('Egzersiz Ekle'));
    await tester.tap(find.text('Crunch'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('EGZERSİZ SIRALAMASI (3)'), -300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('EGZERSİZ SIRALAMASI (3)'), findsOneWidget);
  });

  testWidgets('Kaydet: rutin güncellenir', (tester) async {
    final env = await pumpBuilder(tester);
    await tester.enterText(
      find.byKey(const ValueKey('routine-name')),
      'Push Day v2',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect((await env.workouts.routine(1))!.name, 'Push Day v2');
    expect(await env.workouts.routines(), hasLength(1));
  });

  testWidgets('Kaydet: adsız ya da egzersizsiz rutin reddedilir', (
    tester,
  ) async {
    final env = await pumpBuilder(tester, existing: false);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(
      find.text('Rutine ad ver ve en az bir egzersiz ekle'),
      findsOneWidget,
    );
    expect(await env.workouts.routines(), isEmpty);
  });

  testWidgets('yeni rutin: hareket önceden eklenmiş gelir, kaydedilir', (
    tester,
  ) async {
    final env = await pumpBuilder(tester, existing: false, initial: ['0003']);
    expect(find.text('Pull Up'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('routine-name')),
      'Sırt Günü',
    );
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    final r = (await env.workouts.routines()).single;
    expect(r.name, 'Sırt Günü');
    expect(r.items.single.exerciseId, '0003');
  });

  testWidgets(
    'Antrenmanı Başlat: kaydeder, aktif antrenman başlatır, canlı ekranı açar',
    (tester) async {
      final env = await pumpBuilder(tester);
      await scrollTo(tester, find.textContaining('Antrenmanı Başlat'));
      await tapVisible(tester, find.textContaining('Antrenmanı Başlat'));
      expect(env.container.read(activeWorkoutProvider), isNotNull);
      expect(find.byType(LiveWorkoutScreen), findsOneWidget);
    },
  );

  testWidgets('Rutini Sil: onayla silinir', (tester) async {
    final env = await pumpBuilder(tester);
    await scrollTo(tester, find.text('Rutini Sil'));
    await tapVisible(tester, find.text('Rutini Sil'));
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(await env.workouts.routines(), isEmpty);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpBuilder(tester);
    expect(tester.takeException(), isNull);
  });
}
