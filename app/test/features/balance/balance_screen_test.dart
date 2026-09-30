import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/features/add_food/add_food_screen.dart';
import 'package:vitax_app/features/balance/balance_screen.dart';

import '../../support/pump.dart';

const _profile = Profile(
  sex: Sex.male,
  weightKg: 80,
  heightCm: 180,
  age: 30,
  kcalGoal: 2100,
);

Future<TestEnv> pumpBalance(
  WidgetTester tester, {
  bool seeded = true,
  int steps = 10000,
}) => pumpScreen(
  tester,
  const BalanceScreen(),
  seeded: seeded,
  steps: seeded ? steps : 0,
  profile: _profile,
);

Future<void> scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('dönem seçici ve başlık', (tester) async {
    await pumpBalance(tester);
    for (final l in ['Bu Hafta', 'Geçen Hafta', 'Aylık']) {
      expect(find.text(l), findsOneWidget);
    }
    expect(find.text('HAFTALIK ENERJİ DENGESİ'), findsOneWidget);
  });

  testWidgets('özet: başlık, net rozeti ve üç hücre', (tester) async {
    await pumpBalance(tester);
    // 1420 alınan, 1780 bazal + 457 adım = 2237 harcanan, net -817
    expect(find.text('Ortalama 817 kcal Açık'), findsOneWidget);
    expect(find.text('-817 kcal'), findsOneWidget);
    expect(find.text('1.420'), findsWidgets);
    expect(find.text('2.237'), findsWidgets);
    expect(find.text('Kcal Defisit'), findsOneWidget);
    expect(find.text('Ort. 1.420/gün'), findsOneWidget);
    expect(find.text('Ort. 2.237/gün'), findsOneWidget);
  });

  testWidgets('grafik çizilir', (tester) async {
    await pumpBalance(tester);
    expect(find.byKey(const ValueKey('balance-chart')), findsOneWidget);
  });

  testWidgets('kayıt yokken yönlendirici başlık, grafik yok', (tester) async {
    await pumpBalance(tester, seeded: false);
    expect(find.text('Henüz yeterli kayıt yok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Geçen Hafta seçilince o haftanın verisi (boş)', (tester) async {
    await pumpBalance(tester);
    await tester.tap(find.text('Geçen Hafta'));
    await tester.pumpAndSettle();
    expect(find.text('Henüz yeterli kayıt yok'), findsOneWidget);
    await tester.tap(find.text('Aylık'));
    await tester.pumpAndSettle();
    expect(find.text('Ortalama 817 kcal Açık'), findsOneWidget);
  });

  testWidgets('günlük enerji dağılımı: bazal, aktif, toplam, alınan', (
    tester,
  ) async {
    await pumpBalance(tester);
    await scrollTo(tester, find.text('Günlük Enerji Dağılımı'));
    expect(find.text('1.780 kcal'), findsOneWidget);
    expect(find.text('457 kcal'), findsOneWidget);
    expect(find.text('2.237 kcal'), findsWidgets);
    expect(find.text('%80 pay'), findsOneWidget);
    expect(find.text('%20 pay'), findsOneWidget);
    expect(find.text('1.420 kcal'), findsWidgets);
  });

  testWidgets('Öğün veya Efor Ekle Yemek Ekle ekranını açar', (tester) async {
    await pumpBalance(tester);
    await scrollTo(tester, find.text('Öğün veya Efor Ekle'));
    await tapVisible(tester, find.text('Öğün veya Efor Ekle'));
    expect(find.byType(AddFoodScreen), findsOneWidget);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpBalance(tester);
    expect(tester.takeException(), isNull);
  });
}
