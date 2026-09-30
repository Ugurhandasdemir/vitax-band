import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/features/workout/workout_history_screen.dart';
import 'package:vitax_app/features/workout/workout_summary_screen.dart';

import '../../support/pump.dart';
import '../../support/seed.dart';

Future<TestEnv> pumpHistory(WidgetTester tester, {bool seeded = true}) =>
    pumpScreen(
      tester,
      const WorkoutHistoryScreen(),
      seeded: false,
      seedWorkouts: seeded ? seedWorkouts : null,
    );

Future<void> scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('başlık ve seri rozeti', (tester) async {
    await pumpHistory(tester);
    expect(find.text('Antrenman Geçmişi'), findsOneWidget);
    expect(find.text('3 Günlük Seri • Bu ay 3 Antrenman'), findsOneWidget);
  });

  testWidgets('bu hafta kartı: tarih aralığı, tamamlanan gün, gün daireleri', (
    tester,
  ) async {
    await pumpHistory(tester);
    expect(find.text('BU HAFTA (19 - 25 EKİM)'), findsOneWidget);
    expect(find.text('3 / 7 TAMAMLANDI'), findsOneWidget);
    for (final d in ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz']) {
      expect(find.text(d), findsWidgets);
    }
    Color? fill(int day) =>
        ((tester
                    .widget<Container>(find.byKey(ValueKey('week-day-$day')))
                    .decoration)
                as BoxDecoration)
            .color;
    expect(fill(21), isNot(const Color(0xFFEEEDF7))); // antrenman yapılmış gün
    expect(fill(20), const Color(0xFFEEEDF7)); // yapılmamış gün
  });

  testWidgets('haftalık hacim toplamı ton cinsinden', (tester) async {
    await pumpHistory(tester);
    expect(find.text('HAFTALIK ANTRENMAN HACMİ'), findsOneWidget);
    expect(find.text('6,9'), findsOneWidget); // 3340+3000+540 = 6880 kg
  });

  testWidgets('son seanslar: en yeni önce, dün etiketi, tarih ve gün adı', (
    tester,
  ) async {
    await pumpHistory(tester);
    await scrollTo(tester, find.text('Son Seanslar'));
    expect(find.text('3 Oturum Listelendi'), findsOneWidget);
    expect(find.text('Sırt & Biseps'), findsOneWidget);
    expect(find.text('DÜN, 18:00'), findsOneWidget);
    await scrollTo(tester, find.text('Bacak & Karın'));
    expect(find.text('22 EKİM, PERŞEMBE'), findsOneWidget);
    await scrollTo(tester, find.text('Göğüs & Triceps'));
    expect(find.text('21 EKİM, ÇARŞAMBA'), findsOneWidget);
  });

  testWidgets('seans kartı: süre, hacim, ortalama nabız ve hareket çipleri', (
    tester,
  ) async {
    await pumpHistory(tester);
    await scrollTo(tester, find.text('Göğüs & Triceps'));
    expect(find.text('46 dk'), findsOneWidget);
    expect(find.text('3.340 kg'), findsOneWidget);
    expect(find.text('131 bpm'), findsOneWidget);
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.text('Dumbbell Fly'), findsOneWidget);
  });

  testWidgets('Detayları İncele özet ekranını açar', (tester) async {
    await pumpHistory(tester);
    await scrollTo(tester, find.text('Göğüs & Triceps'));
    final detail = find.byKey(const ValueKey('session-detail-1'));
    await tapVisible(tester, detail);
    expect(find.byType(WorkoutSummaryScreen), findsOneWidget);
  });

  testWidgets('antrenman yokken boş durum', (tester) async {
    await pumpHistory(tester, seeded: false);
    expect(find.textContaining('Henüz antrenman yok'), findsOneWidget);
    expect(find.text('0 / 7 TAMAMLANDI'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpHistory(tester);
    expect(tester.takeException(), isNull);
  });
}
