import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/features/add_food/add_food_screen.dart';
import 'package:vitax_app/features/diary/diary_screen.dart';

import '../../support/pump.dart';
import '../../support/seed.dart';

void main() {
  testWidgets(
    'hafta şeridi: 7 gün, seçili gün vurgulu, dokununca gün değişir',
    (tester) async {
      final env = await pumpScreen(tester, const DiaryScreen());
      for (final d in ['PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CMT', 'PAZ']) {
        expect(find.text(d), findsOneWidget);
      }
      expect(find.byKey(const ValueKey('day-chip-24')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('day-chip-22')));
      await tester.pumpAndSettle();
      expect(env.container.read(selectedDayProvider), DateTime(2026, 10, 22));
      expect(find.text('Haşlanmış Yumurta'), findsNothing); // o gün kayıt yok
    },
  );

  testWidgets('özet: alınan, kalan, net ve bant yakımı', (tester) async {
    await pumpScreen(tester, const DiaryScreen(), steps: 11250);
    expect(find.text('GÜNLÜK ENERJİ DENGESİ'), findsOneWidget);
    expect(find.text('Hedef: 2.100 kcal'), findsOneWidget);
    expect(find.text('1.420'), findsOneWidget); // alınan
    expect(find.text('680'), findsOneWidget); // kalan
    expect(find.text('970'), findsOneWidget); // net
    expect(find.text('VitaxBand ile 450 kcal yakıldı.'), findsOneWidget);
  });

  testWidgets('makro çubukları değer / hedef gösterir', (tester) async {
    await pumpScreen(tester, const DiaryScreen());
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('112g / 150g'), findsOneWidget);
    expect(find.text('Karbonhidrat'), findsOneWidget);
    expect(find.text('150g / 250g'), findsOneWidget);
    expect(find.text('32g / 70g'), findsOneWidget);
  });

  testWidgets('öğün bölümleri ve önerilen aralıklar', (tester) async {
    await pumpScreen(tester, const DiaryScreen());
    final scroll = find.byType(Scrollable).first;
    for (final r in [
      'Önerilen: 400-500 kcal',
      'Önerilen: 600-750 kcal',
      'Önerilen: 500-650 kcal',
      'Önerilen: 150-300 kcal',
    ]) {
      await tester.scrollUntilVisible(find.text(r), 300, scrollable: scroll);
      expect(find.text(r), findsOneWidget);
    }
  });

  testWidgets('yiyecek satırı ad, porsiyon, makro ve kcal gösterir', (
    tester,
  ) async {
    await pumpScreen(tester, const DiaryScreen());
    expect(find.text('Yulaf ezmesi & Badem sütü'), findsOneWidget);
    expect(find.text('1 kase • P: 10g K: 42g Y: 5g'), findsOneWidget);
    expect(find.text('240 kcal'), findsOneWidget);
    expect(find.text('420 kcal'), findsOneWidget); // kahvaltı toplamı
  });

  testWidgets('boş akşam öğünü yönlendirici boş durum gösterir', (
    tester,
  ) async {
    await pumpScreen(tester, const DiaryScreen());
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('empty-dinner')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.textContaining('henüz girilmedi'), findsOneWidget);
    expect(find.text('Akşam Yemeği Ekle'), findsOneWidget);
  });

  testWidgets('sola kaydırınca siler, Geri Al ile geri gelir', (tester) async {
    final env = await pumpScreen(tester, const DiaryScreen());
    await tester.ensureVisible(find.text('Haşlanmış Yumurta'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Haşlanmış Yumurta'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Haşlanmış Yumurta'), findsNothing);
    expect((await env.nutrition.foodForDay(demoDay)).length, 5);
    expect(find.text('Silindi'), findsOneWidget);
    await tester.tap(find.text('Geri Al'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Haşlanmış Yumurta'));
    expect(find.text('Haşlanmış Yumurta'), findsOneWidget);
    expect((await env.nutrition.foodForDay(demoDay)).length, 6);
  });

  testWidgets('Dünü Kopyala dünkü kayıtları bugüne kopyalar', (tester) async {
    final env = await pumpScreen(tester, const DiaryScreen());
    env.container
        .read(selectedDayProvider.notifier)
        .set(DateTime(2026, 10, 25));
    await tester.pumpAndSettle();
    expect(find.text('Haşlanmış Yumurta'), findsNothing);
    await tester.tap(find.text('Dünü Kopyala'));
    await tester.pumpAndSettle();
    expect(find.text('Haşlanmış Yumurta'), findsOneWidget);
    expect(find.text('6 yemek kopyalandı'), findsOneWidget);
  });

  testWidgets('Dünü Kopyala: dün kayıt yoksa bilgi verir', (tester) async {
    await pumpScreen(tester, const DiaryScreen(), seeded: false);
    await tester.tap(find.text('Dünü Kopyala'));
    await tester.pumpAndSettle();
    expect(find.text('Dün için kayıt yok'), findsOneWidget);
  });

  testWidgets('Hızlı Ekle: kalori girip öğüne ekler', (tester) async {
    final env = await pumpScreen(tester, const DiaryScreen(), seeded: false);
    await tester.tap(find.text('Hızlı Ekle'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('quick-kcal')), '300');
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();
    final list = await env.nutrition.foodForDay(DateTime(2026, 10, 24));
    expect(list, hasLength(1));
    expect(list.first.kcal, 300);
    expect(list.first.name, 'Hızlı kalori');
    expect(find.text('300'), findsWidgets); // alınan hücresi
  });

  testWidgets('Hızlı Ekle: kalori boşsa eklemez', (tester) async {
    final env = await pumpScreen(tester, const DiaryScreen(), seeded: false);
    await tester.tap(find.text('Hızlı Ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ekle'));
    await tester.pumpAndSettle();
    expect(await env.nutrition.foodForDay(DateTime(2026, 10, 24)), isEmpty);
  });

  testWidgets('su satırı toplamı gösterir ve + ile 200 ml ekler', (
    tester,
  ) async {
    await pumpScreen(tester, const DiaryScreen());
    await tester.scrollUntilVisible(
      find.text('Günlük Su Tüketimi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1,2 L / 2,5 L (Kalan: 1,3 L)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('diary-water-add')));
    await tester.pumpAndSettle();
    expect(find.text('1,4 L / 2,5 L (Kalan: 1,1 L)'), findsOneWidget);
  });

  testWidgets('+ Yemek Ekle ilgili öğünle Yemek Ekle ekranını açar', (
    tester,
  ) async {
    await pumpScreen(tester, const DiaryScreen());
    await tapVisible(tester, find.byKey(const ValueKey('add-to-breakfast')));
    expect(find.byType(AddFoodScreen), findsOneWidget);
    final s = tester.widget<AddFoodScreen>(find.byType(AddFoodScreen));
    expect(s.initialMeal, MealType.breakfast);
  });

  testWidgets('alttaki sabit Yemek Ekle düğmesi Yemek Ekle ekranını açar', (
    tester,
  ) async {
    await pumpScreen(tester, const DiaryScreen());
    await tester.tap(find.byKey(const ValueKey('diary-bottom-add')));
    await tester.pumpAndSettle();
    expect(find.byType(AddFoodScreen), findsOneWidget);
  });

  testWidgets('taşma yok: dolu ve boş', (tester) async {
    await pumpScreen(tester, const DiaryScreen());
    expect(tester.takeException(), isNull);
    await pumpScreen(tester, const DiaryScreen(), seeded: false);
    expect(tester.takeException(), isNull);
  });
}
