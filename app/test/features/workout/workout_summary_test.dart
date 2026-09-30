import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/core/workout_calc.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/features/workout/workout_summary_screen.dart';

import '../../support/pump.dart';
import '../../support/seed.dart';

Future<TestEnv> pumpSummary(
  WidgetTester tester, {
  int id = 1,
  bool hrSamples = false,
}) async {
  final env = await pumpScreen(
    tester,
    WorkoutSummaryScreen(sessionId: id),
    seeded: false,
    seedWorkouts: seedWorkouts,
  );
  return env;
}

Future<void> scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('başlık, seans adı ve tarih', (tester) async {
    await pumpSummary(tester);
    expect(find.text('TEBRİKLER! ANTRENMAN TAMAMLANDI'), findsOneWidget);
    expect(find.text('Göğüs & Triceps'), findsOneWidget);
    expect(find.textContaining('21 Ekim'), findsOneWidget);
    expect(find.textContaining('18:00'), findsOneWidget);
  });

  testWidgets('istatistik kutuları: süre, kalori, ortalama nabız, hacim', (
    tester,
  ) async {
    await pumpSummary(tester);
    expect(find.text('TOPLAM SÜRE'), findsOneWidget);
    expect(find.text('46'), findsOneWidget); // dk
    expect(find.text('YAKILAN KALORİ'), findsOneWidget);
    final kcal = estimateWorkoutKcal(
      const Duration(minutes: 46),
      70,
      avgHr: 131,
    );
    expect(find.text('$kcal'), findsOneWidget);
    expect(find.text('ORTALAMA NABIZ'), findsOneWidget);
    expect(find.text('131'), findsOneWidget);
    expect(find.text('Zirve: 152 bpm'), findsOneWidget);
    expect(find.text('TOPLAM HACİM'), findsOneWidget);
    expect(find.text('3.340'), findsOneWidget);
    expect(find.text('7 toplam set'), findsOneWidget);
  });

  testWidgets(
    'hareket detayları: egzersiz başına set, ortalama ağırlık, nabız, toparlanma',
    (tester) async {
      await pumpSummary(tester);
      await scrollTo(tester, find.text('Hareket Detayları'));
      expect(find.text('2 Egzersiz'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('4 Set'), findsOneWidget);
      // bench: 12x60, 10x75, 8x80, 6x85 -> ağırlık ort. 75
      expect(find.text('75 kg ort.'), findsOneWidget);
      expect(find.text('Zirve: 152'), findsOneWidget);
      expect(
        find.text('-23 bpm'),
        findsOneWidget,
      ); // toparlanma ort. (20,22,26,24)
    },
  );

  testWidgets('kişisel rekor yoksa banner çıkmaz', (tester) async {
    await pumpSummary(tester);
    expect(find.textContaining('YENİ KİŞİSEL REKOR'), findsNothing);
  });

  testWidgets('önceki en iyiyi aşan set varsa kişisel rekor banner\'ı', (
    tester,
  ) async {
    final env = await pumpScreen(
      tester,
      const WorkoutSummaryScreen(sessionId: 4),
      seeded: false,
      seedWorkouts: (repo) async {
        await seedWorkouts(repo);
        final t = DateTime(2026, 10, 24, 10);
        final s = await repo.startSession(name: 'PR Günü', startedAt: t);
        await repo.addSet(
          s,
          SetLog(
            exerciseId: '0001',
            setNo: 1,
            reps: 5,
            weightKg: 90,
            startedAt: t,
            endedAt: t.add(const Duration(seconds: 40)),
          ),
        );
        await repo.finishSession(s, t.add(const Duration(minutes: 20)));
      },
    );
    expect(env.workouts, isNotNull);
    expect(find.text('YENİ KİŞİSEL REKOR (PR)'), findsOneWidget);
    expect(find.textContaining('90 kg × 5 tekrar'), findsOneWidget);
  });

  testWidgets('kişisel not kaydedilir', (tester) async {
    final env = await pumpSummary(tester);
    await scrollTo(tester, find.byKey(const ValueKey('summary-note')));
    await tester.enterText(
      find.byKey(const ValueKey('summary-note')),
      'Omuz iyi, bel biraz yorgun',
    );
    await scrollTo(tester, find.text('Özeti Kaydet ve Kapat'));
    await tapVisible(tester, find.text('Özeti Kaydet ve Kapat'));
    expect((await env.workouts.session(1))!.note, 'Omuz iyi, bel biraz yorgun');
  });

  testWidgets('mevcut not alana yüklenir', (tester) async {
    await pumpSummary(tester);
    await scrollTo(tester, find.byKey(const ValueKey('summary-note')));
    final f = tester.widget<TextField>(
      find.byKey(const ValueKey('summary-note')),
    );
    expect(f.controller!.text, 'İyi geçti');
  });

  testWidgets('seans yoksa bilgi gösterir', (tester) async {
    await pumpSummary(tester, id: 999);
    expect(find.text('Antrenman bulunamadı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('nabız verisi olmayan seans çökmez', (tester) async {
    await pumpSummary(tester, id: 2); // bacak: bazı setlerde nabız yok
    expect(tester.takeException(), isNull);
    expect(find.text('Bacak & Karın'), findsOneWidget);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpSummary(tester);
    expect(tester.takeException(), isNull);
  });
}
