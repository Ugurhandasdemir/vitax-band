import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/features/exercises/exercise_detail_screen.dart';
import 'package:vitax_app/features/exercises/exercises_screen.dart';
import 'package:vitax_app/features/workout/active_workout.dart';
import 'package:vitax_app/features/workout/live_workout_screen.dart';
import 'package:vitax_app/features/workout/routine_builder_screen.dart';

import '../../support/pump.dart';
import '../../support/seed.dart';

Future<TestEnv> pumpLib(WidgetTester tester, {bool workouts = true}) =>
    pumpScreen(
      tester,
      const Scaffold(body: ExercisesScreen()),
      seeded: false,
      seedWorkouts: workouts ? seedWorkouts : null,
    );

void main() {
  testWidgets('başlık, arama, sekmeler ve sayaç', (tester) async {
    await pumpLib(tester);
    expect(find.text('Egzersizler'), findsWidgets);
    expect(
      find.text('Hedef kas grubunu seç ve tekniği incele'),
      findsOneWidget,
    );
    expect(find.text('Egzersiz veya kas ara...'), findsOneWidget);
    expect(find.text('Rutinler'), findsOneWidget);
    expect(find.text('KÜTÜPHANE (8 HAREKET)'), findsOneWidget);
  });

  testWidgets('grup çipleri filtreler ve sayaç güncellenir', (tester) async {
    await pumpLib(tester);
    await tester.tap(find.byKey(const ValueKey('group-chest')));
    await tester.pumpAndSettle();
    expect(find.text('KÜTÜPHANE (2 HAREKET)'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Pull Up'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('group-all')));
    await tester.pumpAndSettle();
    expect(find.text('KÜTÜPHANE (8 HAREKET)'), findsOneWidget);
  });

  testWidgets('arama: ad ve Türkçe kas adıyla', (tester) async {
    await pumpLib(tester);
    await tester.enterText(
      find.byKey(const ValueKey('exercise-search')),
      'biseps',
    );
    await tester.pumpAndSettle();
    expect(find.text('Dumbbell Curl'), findsOneWidget);
    expect(find.text('KÜTÜPHANE (1 HAREKET)'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('exercise-search')),
      'xqzw',
    );
    await tester.pumpAndSettle();
    expect(find.text('Sonuç bulunamadı'), findsOneWidget);
  });

  testWidgets(
    'satır: ad, ekipman ve hedef kas, animasyonlu küçük resim (GIF)',
    (tester) async {
      await pumpLib(tester);
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Halter • Göğüs'), findsOneWidget);
      final ex = fixtureCatalog().byId('0001')!;
      expect(find.byKey(ValueKey('media:${ex.gifUrl}')), findsOneWidget);
    },
  );

  testWidgets('ekipman filtresi sayfası', (tester) async {
    await pumpLib(tester);
    await tester.tap(find.byKey(const ValueKey('equipment-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dumbbell').last);
    await tester.pumpAndSettle();
    expect(find.text('KÜTÜPHANE (3 HAREKET)'), findsOneWidget);
  });

  testWidgets('satıra dokununca egzersiz detayı açılır', (tester) async {
    await pumpLib(tester);
    await tester.tap(find.text('Barbell Bench Press'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
  });

  testWidgets(
    'Rutinler sekmesi: kayıtlı rutin, egzersiz sayısı, süre ve son yapılış',
    (tester) async {
      await pumpLib(tester);
      await tester.tap(find.text('Rutinler'));
      await tester.pumpAndSettle();
      expect(find.text('KAYITLI RUTİN'), findsOneWidget);
      expect(find.text('Push Day (İtiş A)'), findsOneWidget);
      // 2 egzersiz, 7 set: 4*(45+90)+3*(45+60)=855 sn -> 14 dk; son yapılış 21 Ekim = 3 gün önce
      expect(find.textContaining('2 Egzersiz'), findsOneWidget);
      expect(find.textContaining('14 dk'), findsOneWidget);
      expect(find.textContaining('3 gün önce'), findsOneWidget);
    },
  );

  testWidgets('Rutin Başlat: aktif antrenman başlar ve canlı ekran açılır', (
    tester,
  ) async {
    final env = await pumpLib(tester);
    await tester.tap(find.text('Rutinler'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Başlat'));
    await tester.pumpAndSettle();
    expect(env.container.read(activeWorkoutProvider), isNotNull);
    expect(find.byType(LiveWorkoutScreen), findsOneWidget);
  });

  testWidgets('rutin düzenle ve yeni rutin oluşturucuyu açar', (tester) async {
    await pumpLib(tester);
    await tester.tap(find.text('Rutinler'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-routine-1')));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineBuilderScreen), findsOneWidget);
  });

  testWidgets('rutin yokken boş durum ve Yeni Rutin', (tester) async {
    await pumpLib(tester, workouts: false);
    await tester.tap(find.text('Rutinler'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Henüz rutin yok'), findsOneWidget);
    await tester.tap(find.text('Yeni Rutin'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineBuilderScreen), findsOneWidget);
  });

  testWidgets('devam eden antrenman kartı Devam Et ile canlı ekranı açar', (
    tester,
  ) async {
    final env = await pumpLib(tester);
    await env.container
        .read(activeWorkoutProvider.notifier)
        .start(name: 'Serbest');
    await tester.pumpAndSettle();
    expect(find.text('Devam eden antrenman'), findsOneWidget);
    await tester.tap(find.text('Devam Et'));
    await tester.pumpAndSettle();
    expect(find.byType(LiveWorkoutScreen), findsOneWidget);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpLib(tester);
    expect(tester.takeException(), isNull);
  });
}
