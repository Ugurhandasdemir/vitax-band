import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/features/profile/profile_screen.dart';

import '../../support/pump.dart';

const _base = Profile(
  name: 'Uğurhan',
  heightCm: 172,
  weightKg: 76.4,
  age: 28,
  sex: Sex.male,
  activity: ActivityLevel.moderate,
  goal: GoalType.lose,
  kcalGoal: 2100,
  proteinGoal: 150,
  carbsGoal: 250,
  fatGoal: 55,
  waterGoalMl: 2500,
  stepGoal: 10000,
);

Future<TestEnv> pumpProfile(WidgetTester tester, {Profile profile = _base}) =>
    pumpScreen(tester, const ProfileScreen(), seeded: false, profile: profile);

Future<void> scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

Future<void> editNumber(WidgetTester tester, Finder tile, String value) async {
  await tapVisible(tester, tile);
  await tester.enterText(find.byKey(const ValueKey('edit-value')), value);
  await tester.tap(find.text('Tamam'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('isim gösterilir', (tester) async {
    await pumpProfile(tester);
    expect(find.text('Uğurhan'), findsOneWidget);
  });

  testWidgets('isim boşsa Kullanıcı yazar', (tester) async {
    await pumpProfile(tester, profile: _base.copyWith(name: ''));
    expect(find.text('Kullanıcı'), findsOneWidget);
  });

  testWidgets('bant durumu satırı', (tester) async {
    await pumpProfile(tester);
    expect(find.textContaining('VİTAXBAND'), findsWidgets);
  });

  testWidgets('biyometrik değerler', (tester) async {
    await pumpProfile(tester);
    expect(find.text('BİYOMETRİK ÖLÇÜMLER'), findsOneWidget);
    expect(find.text('172'), findsOneWidget);
    expect(find.text('76,4'), findsOneWidget);
    expect(find.text('28'), findsOneWidget);
    expect(find.text('Erkek'), findsOneWidget);
  });

  testWidgets('boy düzenlenir ve kaydedilir', (tester) async {
    final env = await pumpProfile(tester);
    await editNumber(tester, find.byKey(const ValueKey('tile-height')), '180');
    expect(find.text('180'), findsOneWidget);
    await scrollTo(tester, find.text('Hedefleri Güncelle ve Kaydet'));
    await tapVisible(tester, find.text('Hedefleri Güncelle ve Kaydet'));
    expect((await env.settings.loadProfile()).heightCm, 180);
  });

  testWidgets('kaydetmeden çıkınca değişiklik yazılmaz', (tester) async {
    final env = await pumpProfile(tester);
    await editNumber(tester, find.byKey(const ValueKey('tile-height')), '180');
    expect((await env.settings.loadProfile()).heightCm, 172);
  });

  testWidgets('geçersiz değer reddedilir (boy 10 cm)', (tester) async {
    await pumpProfile(tester);
    await editNumber(tester, find.byKey(const ValueKey('tile-height')), '10');
    expect(find.text('172'), findsOneWidget);
    expect(find.textContaining('arasında'), findsOneWidget);
  });

  testWidgets('cinsiyet dokununca değişir', (tester) async {
    await pumpProfile(tester);
    await tapVisible(tester, find.byKey(const ValueKey('tile-sex')));
    expect(find.text('Kadın'), findsOneWidget);
  });

  testWidgets('aktivite seviyesi listesinden seçilir', (tester) async {
    await pumpProfile(tester);
    expect(find.text('Orta Düzey (3-4 gün/hafta)'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('tile-activity')));
    expect(find.text('Hareketsiz (masa başı)'), findsOneWidget);
    await tester.tap(find.text('Çok Aktif (5-6 gün/hafta)'));
    await tester.pumpAndSettle();
    expect(find.text('Çok Aktif (5-6 gün/hafta)'), findsOneWidget);
  });

  testWidgets('ana hedef kartları: Kilo Ver seçili, Koru seçilebilir', (
    tester,
  ) async {
    await pumpProfile(tester);
    await scrollTo(tester, find.text('Kiloyu Koru'));
    bool selected(String k) =>
        (tester
                    .widget<Container>(
                      find.byKey(ValueKey('goal-$k'), skipOffstage: false),
                    )
                    .decoration
                as BoxDecoration)
            .color !=
        VColors0.white;
    expect(selected('lose'), isTrue);
    expect(selected('maintain'), isFalse);
    await tapVisible(tester, find.text('Kiloyu Koru'));
    expect(selected('maintain'), isTrue);
    expect(selected('lose'), isFalse);
    expect(find.text('-500 kcal', skipOffstage: false), findsOneWidget);
    expect(find.text('+300 kcal', skipOffstage: false), findsOneWidget);
  });

  testWidgets('Otomatik Plan biyometriden kalori hesaplar', (tester) async {
    await pumpProfile(
      tester,
      profile: _base.copyWith(
        weightKg: 80,
        heightCm: 180,
        age: 30,
        goal: GoalType.maintain,
      ),
    );
    await scrollTo(tester, find.text('Otomatik Plan'));
    await tapVisible(tester, find.text('Otomatik Plan'));
    expect(find.text('2.759'), findsOneWidget);
    expect(find.text('160 g'), findsOneWidget); // protein 2 g/kg
  });

  testWidgets('makro kutuları gram, kcal ve yüzde gösterir', (tester) async {
    await pumpProfile(tester);
    await scrollTo(tester, find.text('PROTEİN'));
    expect(find.text('150 g'), findsOneWidget);
    expect(find.text('600 kcal (%29)'), findsOneWidget);
    expect(find.text('1000 kcal (%48)'), findsOneWidget);
    expect(find.text('495 kcal (%24)'), findsOneWidget);
  });

  testWidgets('kalori hedefi elle düzenlenir', (tester) async {
    await pumpProfile(tester);
    await scrollTo(tester, find.byKey(const ValueKey('edit-kcal')));
    await editNumber(tester, find.byKey(const ValueKey('edit-kcal')), '2300');
    expect(find.text('2.300'), findsOneWidget);
  });

  testWidgets('su ve adım hedefi düzenlenir', (tester) async {
    await pumpProfile(tester);
    await scrollTo(tester, find.text('GÜNLÜK SU'));
    expect(find.text('2,5'), findsOneWidget);
    expect(find.text('10.000'), findsOneWidget);
    await editNumber(tester, find.byKey(const ValueKey('tile-steps')), '12000');
    expect(find.text('12.000'), findsOneWidget);
    await editNumber(tester, find.byKey(const ValueKey('tile-water')), '3000');
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('birim: imperial seçilince lb ve ft gösterilir', (tester) async {
    await pumpProfile(tester);
    await scrollTo(tester, find.text('Imperial (lb, ft)'));
    await tapVisible(tester, find.text('Imperial (lb, ft)'));
    await tester.scrollUntilVisible(
      find.text('BİYOMETRİK ÖLÇÜMLER'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('168,4'), findsOneWidget);
    expect(find.text('5\' 8"'), findsOneWidget);
  });

  testWidgets('kaydet: snackbar ve kalıcı yazım', (tester) async {
    final env = await pumpProfile(tester);
    await tapVisible(tester, find.byKey(const ValueKey('tile-sex')));
    await scrollTo(tester, find.text('Hedefleri Güncelle ve Kaydet'));
    await tapVisible(tester, find.text('Hedefleri Güncelle ve Kaydet'));
    expect(find.text('Kaydedildi'), findsOneWidget);
    final p = await env.settings.loadProfile();
    expect(p.sex, Sex.female);
    expect(p.onboarded, isTrue);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpProfile(tester);
    expect(tester.takeException(), isNull);
  });
}

class VColors0 {
  static const white = Color(0xFFFFFFFF);
}
