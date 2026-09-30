import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/features/weight/weight_screen.dart';

import '../../support/pump.dart';
import '../../support/seed.dart';

const _profile = Profile(
  weightKg: 76.4,
  heightCm: 172,
  startWeightKg: 81,
  goalWeightKg: 72,
  kcalGoal: 2100,
);

Future<TestEnv> pumpWeight(
  WidgetTester tester, {
  bool weights = true,
  Profile profile = _profile,
}) => pumpScreen(
  tester,
  const WeightScreen(),
  seeded: false,
  profile: profile,
  seedExtra: weights ? seedWeights : null,
);

Future<void> scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('başlık ve 7 günlük değişim rozeti', (tester) async {
    await pumpWeight(tester);
    expect(find.text('HASSAS ANALİZ'), findsOneWidget);
    expect(find.text('Kilo & Vücut Kompozisyonu'), findsOneWidget);
    expect(find.byKey(const ValueKey('weight-change-chip')), findsOneWidget);
    expect(find.text('-0,2 kg'), findsWidgets);
  });

  testWidgets('mevcut kilo, başlangıç, hedef ve kalan', (tester) async {
    await pumpWeight(tester);
    expect(find.text('MEVCUT KİLO'), findsOneWidget);
    expect(find.text('76,4'), findsOneWidget);
    expect(find.text('Başlangıç: 81,0 kg'), findsOneWidget);
    expect(find.text('Hedef: 72,0 kg'), findsOneWidget);
    expect(find.text('Kalan: 4,4 kg (%51 tamamlandı)'), findsOneWidget);
  });

  testWidgets('30 günlük özet cümlesi', (tester) async {
    await pumpWeight(tester);
    expect(find.textContaining('1,8 kg verdin'), findsOneWidget);
  });

  testWidgets('aralık seçici: varsayılan 30G, dokununca değişir', (
    tester,
  ) async {
    await pumpWeight(tester);
    for (final l in ['7G', '30G', '90G', '1 Yıl']) {
      expect(find.text(l), findsOneWidget);
    }
    Color? colorOf(String k) =>
        ((tester.widget<Container>(find.byKey(ValueKey('range-$k'))).decoration)
                as BoxDecoration)
            .color;
    expect(colorOf('30G'), isNot(Colors.transparent));
    expect(colorOf('7G'), Colors.transparent);
    await tester.tap(find.text('7G'));
    await tester.pumpAndSettle();
    expect(colorOf('7G'), isNot(Colors.transparent));
    expect(colorOf('30G'), Colors.transparent);
  });

  testWidgets('grafik çizilir', (tester) async {
    await pumpWeight(tester);
    expect(find.byKey(const ValueKey('weight-chart')), findsOneWidget);
  });

  testWidgets('Kilo Kaydet: yeni kilo kaydedilir ve profil güncellenir', (
    tester,
  ) async {
    final env = await pumpWeight(tester);
    await scrollTo(tester, find.text('Kilo Kaydet'));
    await tapVisible(tester, find.text('Kilo Kaydet'));
    await tester.enterText(find.byKey(const ValueKey('weight-input')), '75,9');
    await tapVisible(tester, find.text('Kaydet'));
    expect((await env.nutrition.latestWeight())!.kg, 75.9);
    expect((await env.settings.loadProfile()).weightKg, 75.9);
    await tester.scrollUntilVisible(
      find.text('MEVCUT KİLO'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('75,9'), findsWidgets);
  });

  testWidgets('geçersiz kilo kaydedilmez, uyarı gösterilir', (tester) async {
    final env = await pumpWeight(tester);
    await scrollTo(tester, find.text('Kilo Kaydet'));
    await tapVisible(tester, find.text('Kilo Kaydet'));
    await tester.enterText(find.byKey(const ValueKey('weight-input')), '10');
    await tapVisible(tester, find.text('Kaydet'));
    expect(find.text('Geçerli bir kilo gir (30-300)'), findsOneWidget);
    expect((await env.nutrition.latestWeight())!.kg, 76.4);
  });

  testWidgets('VKİ kartı değer ve kategori gösterir', (tester) async {
    await pumpWeight(tester);
    await scrollTo(tester, find.text('Vücut Kitle İndeksi'));
    expect(find.text('25,8'), findsOneWidget);
    expect(find.text('Kilolu'), findsWidgets);
  });

  testWidgets('son kayıtlar: tarih, saat, kilo ve fark', (tester) async {
    await pumpWeight(tester);
    await scrollTo(tester, find.text('Son Kayıtlar'));
    expect(find.text('Bugün, 24 Eki'), findsOneWidget);
    expect(find.text('Çarşamba, 21 Eki'), findsOneWidget);
    expect(find.text('07:45'), findsOneWidget);
    expect(find.text('76,4 kg'), findsWidgets);
  });

  testWidgets('Tüm Geçmiş tüm kayıtları açar', (tester) async {
    await pumpWeight(tester);
    await scrollTo(tester, find.text('Tüm Geçmiş'));
    expect(find.text('Cuma, 25 Eyl'), findsNothing);
    await tapVisible(tester, find.text('Tüm Geçmiş'));
    await scrollTo(tester, find.text('Cuma, 25 Eyl'));
    expect(find.text('Cuma, 25 Eyl'), findsOneWidget);
    expect(find.text('İlk kayıt'), findsOneWidget);
  });

  testWidgets('kayıt yokken boş durum, profil kilosu gösterilir', (
    tester,
  ) async {
    await pumpWeight(tester, weights: false);
    expect(find.byKey(const ValueKey('weight-chart')), findsNothing);
    expect(find.text('76,4'), findsOneWidget);
    await scrollTo(tester, find.textContaining('Henüz kilo kaydı yok'));
    expect(find.textContaining('Henüz kilo kaydı yok'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hedef kilo belirsizse hedef satırı gizlenir, çökmez', (
    tester,
  ) async {
    await pumpWeight(
      tester,
      profile: _profile.copyWith(goalWeightKg: 0, startWeightKg: 0),
    );
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Kalan:'), findsNothing);
  });

  testWidgets('imperial birimde lb gösterir ve lb girişini kg olarak saklar', (
    tester,
  ) async {
    final env = await pumpWeight(
      tester,
      profile: _profile.copyWith(units: Units.imperial),
    );
    expect(find.text('168,4'), findsOneWidget); // 76.4 kg
    await scrollTo(tester, find.text('Kilo Kaydet'));
    await tapVisible(tester, find.text('Kilo Kaydet'));
    await tester.enterText(find.byKey(const ValueKey('weight-input')), '168');
    await tapVisible(tester, find.text('Kaydet'));
    expect((await env.nutrition.latestWeight())!.kg, closeTo(76.2, 0.05));
  });

  testWidgets('taşma yok', (tester) async {
    await pumpWeight(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hedef kilo belirlenmemişse Hedef belirle görünür ve kaydeder', (
    tester,
  ) async {
    final env = await pumpWeight(
      tester,
      profile: _profile.copyWith(goalWeightKg: 0, startWeightKg: 0),
    );
    expect(find.text('Hedef belirle'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('weight-goal')));
    await tester.enterText(find.byKey(const ValueKey('goal-kg')), '70');
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    final p = await env.settings.loadProfile();
    expect(p.goalWeightKg, 70);
    expect(p.startWeightKg, greaterThan(0)); // başlangıç yoksa mevcut kilo olur
    expect(find.text('Hedef belirle'), findsNothing);
  });

  testWidgets('hedef kilo düzenlenir', (tester) async {
    final env = await pumpWeight(tester);
    await tapVisible(tester, find.byKey(const ValueKey('weight-goal')));
    await tester.enterText(find.byKey(const ValueKey('goal-kg')), '74,5');
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect((await env.settings.loadProfile()).goalWeightKg, 74.5);
    expect(find.text('Hedef: 74,5 kg'), findsOneWidget);
  });

  testWidgets('geçersiz hedef kilo reddedilir', (tester) async {
    final env = await pumpWeight(tester);
    await tapVisible(tester, find.byKey(const ValueKey('weight-goal')));
    await tester.enterText(find.byKey(const ValueKey('goal-kg')), '5');
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();
    expect((await env.settings.loadProfile()).goalWeightKg, 72);
    expect(find.textContaining('arasında'), findsOneWidget);
  });
}
