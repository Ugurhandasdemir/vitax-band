import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/features/hydration/hydration_screen.dart';

import '../../support/pump.dart';
import '../../support/seed.dart';

Future<void> scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('başlık, hedef düzenleme ve durum kartı', (tester) async {
    await pumpScreen(tester, const HydrationScreen());
    expect(find.text('GÜNLÜK HİDRASYON'), findsOneWidget);
    expect(find.text('Hedefi Düzenle (2,5 L)'), findsOneWidget);
    expect(find.text('Stabil'), findsOneWidget);
    expect(find.textContaining('dengeli'), findsOneWidget);
  });

  testWidgets('toplam, yüzde ve kalan gösterilir', (tester) async {
    await pumpScreen(tester, const HydrationScreen());
    expect(find.text('%48'), findsOneWidget);
    expect(find.text('1,2'), findsOneWidget);
    expect(find.textContaining('/ 2,5 L Hedef'), findsOneWidget);
    expect(find.textContaining('Hedefe 1,3 L kaldı'), findsOneWidget);
    expect(find.textContaining('%48 tamamlandı'), findsOneWidget);
  });

  testWidgets('hızlı ekle: 200, 300, 500', (tester) async {
    await pumpScreen(tester, const HydrationScreen());
    await tester.tap(find.byKey(const ValueKey('quick-200')));
    await tester.pumpAndSettle();
    expect(find.text('1,4'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quick-500')));
    await tester.pumpAndSettle();
    expect(find.text('1,9'), findsOneWidget);
    expect(find.text('%76'), findsOneWidget);
  });

  testWidgets('özel miktar: varsayılan 250, ±50 ile değişir, Ekle kaydeder', (
    tester,
  ) async {
    final env = await pumpScreen(tester, const HydrationScreen());
    await scrollTo(tester, find.byKey(const ValueKey('custom-add')));
    expect(find.text('250'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('custom-plus')));
    expect(find.text('300'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('custom-minus')));
    await tapVisible(tester, find.byKey(const ValueKey('custom-minus')));
    expect(find.text('200'), findsOneWidget);
    await tapVisible(tester, find.byKey(const ValueKey('custom-add')));
    expect(await env.nutrition.waterForDay(demoDay), 1400);
  });

  testWidgets('özel miktar 50 ml altına inmez', (tester) async {
    await pumpScreen(tester, const HydrationScreen());
    await scrollTo(tester, find.byKey(const ValueKey('custom-add')));
    for (var i = 0; i < 10; i++) {
      await tapVisible(tester, find.byKey(const ValueKey('custom-minus')));
    }
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('bugünün kayıtları: liste, sayı ve saat', (tester) async {
    await pumpScreen(tester, const HydrationScreen());
    await scrollTo(tester, find.text('Bugünün Kayıtları'));
    expect(find.text('4 Giriş'), findsOneWidget);
    expect(find.text('300 ml (Kupa)'), findsOneWidget);
    expect(find.textContaining('14:15'), findsOneWidget);
    expect(find.text('500 ml (Şişe)'), findsOneWidget);
  });

  testWidgets('Geri Al kaydı siler ve toplamı düşürür', (tester) async {
    final env = await pumpScreen(tester, const HydrationScreen());
    await scrollTo(tester, find.text('Bugünün Kayıtları'));
    final entries = await env.nutrition.waterEntries(demoDay);
    final kupa = entries.firstWhere((e) => e.ml == 300);
    await tester.tap(find.byKey(ValueKey('undo-water-${kupa.id}')));
    await tester.pumpAndSettle();
    expect(find.text('300 ml (Kupa)'), findsNothing);
    expect(await env.nutrition.waterForDay(demoDay), 900);
    expect(find.text('3 Giriş'), findsOneWidget);
  });

  testWidgets('kayıt yokken boş durum', (tester) async {
    await pumpScreen(tester, const HydrationScreen(), seeded: false);
    expect(find.text('Düşük'), findsOneWidget);
    await scrollTo(tester, find.text('Bugünün Kayıtları'));
    expect(find.textContaining('Henüz su kaydı yok'), findsOneWidget);
  });

  testWidgets('hedefi düzenle: yeni hedef kaydedilir', (tester) async {
    final env = await pumpScreen(tester, const HydrationScreen());
    await tester.tap(find.textContaining('Hedefi Düzenle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('goal-ml')), '3000');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect((await env.settings.loadProfile()).waterGoalMl, 3000);
    expect(find.text('Hedefi Düzenle (3 L)'), findsOneWidget);
  });

  testWidgets('haftalık su dengesi: başarı ve ortalama', (tester) async {
    await pumpScreen(tester, const HydrationScreen());
    await scrollTo(tester, find.text('Haftalık Su Dengesi'));
    expect(find.textContaining('Haftalık Başarı: 0/7 Gün'), findsOneWidget);
    expect(find.textContaining('ORT.'), findsOneWidget);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpScreen(tester, const HydrationScreen());
    expect(tester.takeException(), isNull);
    await pumpScreen(tester, const HydrationScreen(), seeded: false);
    expect(tester.takeException(), isNull);
  });
}
