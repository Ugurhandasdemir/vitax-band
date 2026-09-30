import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/data/exercise_catalog.dart';
import 'package:vitax_app/features/workout/active_workout.dart';
import 'package:vitax_app/features/workout/live_workout_screen.dart';
import 'package:vitax_app/features/workout/workout_summary_screen.dart';

import '../../support/pump.dart';
import '../../support/seed.dart';

class _Clock {
  DateTime now = DateTime(2026, 10, 24, 18, 0, 0);
  void advance(int s) => now = now.add(Duration(seconds: s));
}

class _Live {
  _Live(this.env, this.clock, this.hr);
  final TestEnv env;
  final _Clock clock;
  final StreamController<HrReading> hr;
  ActiveWorkoutController get ctl =>
      env.container.read(activeWorkoutProvider.notifier);
}

Future<_Live> pumpLive(WidgetTester tester, {bool start = true}) async {
  final clock = _Clock();
  final hr = StreamController<HrReading>.broadcast();
  addTearDown(hr.close);
  final env = await pumpScreen(
    tester,
    const LiveWorkoutScreen(),
    seeded: false,
    seedWorkouts: seedWorkouts,
    clock: () => clock.now,
    overrides: [liveHrProvider.overrideWith((ref) => hr.stream)],
  );
  if (start) {
    final r = await env.workouts.routine(1);
    await env.container.read(activeWorkoutProvider.notifier).start(routine: r);
    await tester.pumpAndSettle();
  }
  return _Live(env, clock, hr);
}

void main() {
  testWidgets('aktif antrenman yoksa bilgi gösterir', (tester) async {
    await pumpLive(tester, start: false);
    expect(find.text('Aktif antrenman yok'), findsOneWidget);
  });

  testWidgets('başlık, seans adı, toplam süre ve mod anahtarı', (tester) async {
    await pumpLive(tester);
    expect(find.text('Canlı Antrenman'), findsOneWidget);
    expect(find.text('Push Day (İtiş A)'), findsWidgets);
    expect(find.text('00:00'), findsWidgets);
    expect(find.text('Elle'), findsOneWidget);
    expect(find.text('Öneri'), findsOneWidget);
  });

  testWidgets('mevcut hareket kartı: set, ad, animasyon, hedefler', (
    tester,
  ) async {
    await pumpLive(tester);
    final ex = fixtureCatalog().byId('0001')!;
    expect(find.text('ŞU ANKİ HAREKET'), findsOneWidget);
    expect(find.text('SET 1 / 4'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.byKey(ValueKey('media:${ex.gifUrl}')), findsOneWidget);
    expect(find.text('Döngü'), findsOneWidget);
    expect(find.text('60 kg'), findsOneWidget);
    expect(find.text('12 tekrar'), findsOneWidget);
    expect(find.text('Seti Başlat (Set 1)'), findsOneWidget);
  });

  testWidgets('nabız akışı canlı kartı günceller; yokken hazırlanıyor yazar', (
    tester,
  ) async {
    final l = await pumpLive(tester);
    expect(find.text('CANLI NABIZ'), findsOneWidget);
    expect(find.textContaining('Nabız hazırlanıyor'), findsOneWidget);
    l.hr.add(HrReading(141));
    await tester.pumpAndSettle();
    expect(find.text('141'), findsOneWidget);
    expect(find.textContaining('Nabız hazırlanıyor'), findsNothing);
    expect(find.text('Zon 3'), findsWidgets);
  });

  testWidgets('hedef ağırlık ve tekrar adım düğmeleriyle değişir', (
    tester,
  ) async {
    final l = await pumpLive(tester);
    await tester.tap(find.byKey(const ValueKey('w-plus')));
    await tester.pumpAndSettle();
    expect(find.text('62,5 kg'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('r-minus')));
    await tester.pumpAndSettle();
    expect(find.text('11 tekrar'), findsOneWidget);
    expect(l.env.container.read(activeWorkoutProvider)!.draftWeightKg, 62.5);
  });

  testWidgets('Seti Başlat -> Seti Bitir -> dinlenme ve set geçmişi', (
    tester,
  ) async {
    final l = await pumpLive(tester);
    await tester.tap(find.text('Seti Başlat (Set 1)'));
    await tester.pumpAndSettle();
    expect(find.text('Seti Bitir (Set 1)'), findsOneWidget);
    l.clock.advance(40);
    await tester.tap(find.text('Seti Bitir (Set 1)'));
    await tester.pumpAndSettle();
    expect(find.text('DİNLENME SÜRESİ'), findsOneWidget);
    expect(find.textContaining('01:30'), findsOneWidget); // 90 sn mola
    expect(find.text('Seti Başlat (Set 2)'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('12 tekrar × 60 kg'), 300,
        scrollable: find.byType(Scrollable).first);
    expect(find.text('12 tekrar × 60 kg'), findsOneWidget);
  });

  testWidgets('dinlenme -15s / +15s ve atla', (tester) async {
    final l = await pumpLive(tester);
    await tester.tap(find.text('Seti Başlat (Set 1)'));
    await tester.pumpAndSettle();
    l.clock.advance(30);
    await tester.tap(find.text('Seti Bitir (Set 1)'));
    await tester.pumpAndSettle();
    l.clock.advance(20);
    await tapVisible(tester, find.byKey(const ValueKey('rest-plus')));
    expect(find.textContaining('01:45'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('rest-skip')));
    expect(find.text('DİNLENME SÜRESİ'), findsNothing);
  });

  testWidgets(
    'set geçmişi planlanan setleri gösterir: yapılan, şu an, sırada',
    (tester) async {
      await pumpLive(tester);
      await tester.scrollUntilVisible(
        find.text('Set Geçmişi'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('HEDEF: 4 SET'), findsOneWidget);
      expect(find.text('12 tekrar × 60 kg'), findsOneWidget);
      expect(find.text('ŞU AN'), findsOneWidget);
      expect(find.text('Sırada'), findsWidgets);
    },
  );

  testWidgets('Öneri modu: nabız yükselince banner, Onayla seti başlatır', (
    tester,
  ) async {
    final l = await pumpLive(tester);
    await tester.tap(find.text('Öneri'));
    await tester.pumpAndSettle();
    for (final bpm in [85, 92, 100, 108]) {
      l.clock.advance(10);
      l.hr.add(HrReading(bpm));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('VİTAX AKILLI ALGILAMA'), findsOneWidget);
    expect(find.textContaining('set başlamış olabilir'), findsOneWidget);
    await tester.tap(find.text('Onayla'));
    await tester.pumpAndSettle();
    expect(find.text('Seti Bitir (Set 1)'), findsOneWidget);
    expect(find.text('VİTAX AKILLI ALGILAMA'), findsNothing);
  });

  testWidgets('Öneri Yoksay banner\'ı kaldırır', (tester) async {
    final l = await pumpLive(tester);
    await tester.tap(find.text('Öneri'));
    await tester.pumpAndSettle();
    for (final bpm in [85, 92, 100, 108]) {
      l.clock.advance(10);
      l.hr.add(HrReading(bpm));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yoksay'));
    await tester.pumpAndSettle();
    expect(find.text('VİTAX AKILLI ALGILAMA'), findsNothing);
  });

  testWidgets('Elle modda öneri banner\'ı çıkmaz', (tester) async {
    final l = await pumpLive(tester);
    for (final bpm in [85, 92, 100, 108]) {
      l.clock.advance(10);
      l.hr.add(HrReading(bpm));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.text('VİTAX AKILLI ALGILAMA'), findsNothing);
  });

  testWidgets('sonraki hareket düğmesi sıradaki egzersize geçer', (
    tester,
  ) async {
    await pumpLive(tester);
    await tester.tap(find.byKey(const ValueKey('next-exercise')));
    await tester.pumpAndSettle();
    expect(find.text('Dumbbell Fly'), findsOneWidget);
    expect(find.text('SET 1 / 3'), findsOneWidget);
  });

  testWidgets('nabız eğrisi nabız verisi gelince çizilir', (tester) async {
    final l = await pumpLive(tester);
    await tester.scrollUntilVisible(
      find.text('Nabız & Efor Eğrisi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('hr-chart')), findsNothing);
    for (final bpm in [90, 100, 110]) {
      l.clock.advance(5);
      l.hr.add(HrReading(bpm));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('hr-chart')), findsOneWidget);
  });

  testWidgets('Bitir: onaylayınca seans kapanır ve özet açılır', (
    tester,
  ) async {
    final l = await pumpLive(tester);
    await tester.tap(find.text('Seti Başlat (Set 1)'));
    await tester.pumpAndSettle();
    l.clock.advance(30);
    await tester.tap(find.text('Seti Bitir (Set 1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Antrenmanı bitirmek'), findsOneWidget);
    await tester.tap(find.text('Bitir'));
    await tester.pumpAndSettle();
    expect(l.env.container.read(activeWorkoutProvider), isNull);
    expect(find.byType(WorkoutSummaryScreen), findsOneWidget);
  });

  testWidgets('Vazgeç: seans silinir', (tester) async {
    final l = await pumpLive(tester);
    final id = l.env.container.read(activeWorkoutProvider)!.sessionId;
    await tester.tap(find.byKey(const ValueKey('finish-workout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç ve Sil'));
    await tester.pumpAndSettle();
    expect(l.env.container.read(activeWorkoutProvider), isNull);
    expect(await l.env.workouts.session(id), isNull);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpLive(tester);
    expect(tester.takeException(), isNull);
  });
}
