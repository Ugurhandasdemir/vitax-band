import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/features/add_food/add_food_screen.dart';

import '../../support/pump.dart';
import '../../support/seed.dart';

void main() {
  testWidgets(
    'sekmeler ve başlangıç: Son Kullanılan, kayıtlı yiyecekleri listeler',
    (tester) async {
      await pumpScreen(tester, const AddFoodScreen());
      expect(find.text('Son Kullanılan'), findsOneWidget);
      expect(find.text('Favoriler'), findsOneWidget);
      expect(find.text('Tümü'), findsOneWidget);
      expect(find.text('SON TÜKETİLENLER'), findsOneWidget);
      expect(find.text('Çiğ Badem'), findsOneWidget);
      expect(find.text('Haşlanmış Yumurta'), findsOneWidget);
    },
  );

  testWidgets('son kullanılanlar yinelenmez ve en yeni önce gelir', (
    tester,
  ) async {
    final env = await pumpScreen(tester, const AddFoodScreen());
    await env.nutrition.addFood(
      FoodEntry(
        date: DateTime(2026, 10, 23),
        meal: MealType.lunch,
        name: 'Çiğ Badem',
        portion: '25g',
        kcal: 150,
      ),
    );
    env.container.invalidate(recentFoodsProvider);
    await tester.pumpAndSettle();
    expect(find.text('Çiğ Badem'), findsOneWidget);
  });

  testWidgets('varsayılan öğün saate göre: 14:30 -> Öğle', (tester) async {
    await pumpScreen(tester, const AddFoodScreen());
    final chip = tester.widget<Container>(
      find.byKey(const ValueKey('meal-chip-lunch')),
    );
    expect((chip.decoration as BoxDecoration).color, isNot(Colors.transparent));
    expect(find.text('Öğle'), findsWidgets);
  });

  testWidgets('başlangıç öğünü verilirse onu kullanır', (tester) async {
    await pumpScreen(tester, const AddFoodScreen(initialMeal: MealType.dinner));
    final chip = tester.widget<Container>(
      find.byKey(const ValueKey('meal-chip-dinner')),
    );
    expect((chip.decoration as BoxDecoration).color, isNot(Colors.transparent));
  });

  testWidgets('+ düğmesi seçili öğüne, seçili güne kayıt ekler', (
    tester,
  ) async {
    final env = await pumpScreen(
      tester,
      const AddFoodScreen(initialMeal: MealType.dinner),
    );
    final before = (await env.nutrition.foodForDay(demoDay)).length;
    await tapVisible(
      tester,
      find.byKey(const ValueKey('add-recent-Haşlanmış Yumurta')),
    );
    final after = await env.nutrition.foodForDay(demoDay);
    expect(after.length, before + 1);
    expect(after.last.name, 'Haşlanmış Yumurta');
    expect(after.last.meal, MealType.dinner);
    expect(find.text('Eklendi'), findsOneWidget);
  });

  testWidgets('arama kataloğu tarar (Türkçe harften bağımsız)', (tester) async {
    await pumpScreen(tester, const AddFoodScreen(), seeded: false);
    await tester.enterText(
      find.byKey(const ValueKey('food-search')),
      'YUMURTA',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('umurta'), findsWidgets);
    expect(find.text('SON TÜKETİLENLER'), findsNothing);
    expect(find.text('ARAMA SONUÇLARI'), findsOneWidget);
  });

  testWidgets('sonuç yoksa bilgi mesajı', (tester) async {
    await pumpScreen(tester, const AddFoodScreen(), seeded: false);
    await tester.enterText(find.byKey(const ValueKey('food-search')), 'xqzw');
    await tester.pumpAndSettle();
    expect(find.text('Sonuç bulunamadı'), findsOneWidget);
  });

  testWidgets('katalogdan bir yiyecek eklenebilir', (tester) async {
    final env = await pumpScreen(tester, const AddFoodScreen(), seeded: false);
    await tester.enterText(
      find.byKey(const ValueKey('food-search')),
      'yumurta',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-result-0')));
    await tester.pumpAndSettle();
    final list = await env.nutrition.foodForDay(demoDay);
    expect(list, hasLength(1));
    expect(list.first.kcal, greaterThan(0));
  });

  testWidgets('favori yıldızı: ekler, Favoriler sekmesinde görünür', (
    tester,
  ) async {
    await pumpScreen(tester, const AddFoodScreen());
    await tester.tap(find.byKey(const ValueKey('fav-Çiğ Badem')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Favoriler'));
    await tester.pumpAndSettle();
    expect(find.text('Çiğ Badem'), findsOneWidget);
    expect(find.text('Haşlanmış Yumurta'), findsNothing);
  });

  testWidgets('Favoriler boşken yönlendirici mesaj', (tester) async {
    await pumpScreen(tester, const AddFoodScreen());
    await tester.tap(find.text('Favoriler'));
    await tester.pumpAndSettle();
    expect(find.textContaining('yıldız'), findsOneWidget);
  });

  testWidgets('Tümü sekmesi kataloğu gösterir', (tester) async {
    await pumpScreen(tester, const AddFoodScreen(), seeded: false);
    await tester.tap(find.text('Tümü'));
    await tester.pumpAndSettle();
    expect(find.byType(ListView), findsWidgets);
    expect(find.byKey(const ValueKey('add-result-0')), findsOneWidget);
  });

  testWidgets('Özel Yemek: form doldurulup kaydedilir', (tester) async {
    final env = await pumpScreen(tester, const AddFoodScreen(), seeded: false);
    await tester.tap(find.text('Özel Yemek'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('custom-name')),
      'Annemin mantısı',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-portion')),
      '1 tabak',
    );
    await tester.enterText(find.byKey(const ValueKey('custom-kcal')), '420');
    await tester.enterText(find.byKey(const ValueKey('custom-protein')), '18');
    await tester.enterText(find.byKey(const ValueKey('custom-carbs')), '52');
    await tester.enterText(find.byKey(const ValueKey('custom-fat')), '14');
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    final list = await env.nutrition.foodForDay(demoDay);
    expect(list, hasLength(1));
    expect(list.first.name, 'Annemin mantısı');
    expect(list.first.kcal, 420);
    expect(list.first.protein, 18);
  });

  testWidgets('Özel Yemek: ad veya kalori yoksa kaydetmez', (tester) async {
    final env = await pumpScreen(tester, const AddFoodScreen(), seeded: false);
    await tester.tap(find.text('Özel Yemek'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();
    expect(await env.nutrition.foodForDay(demoDay), isEmpty);
    expect(find.text('Ad ve kalori gerekli'), findsOneWidget);
  });

  testWidgets('Hızlı Kalori kartı hızlı ekleme sayfasını açar', (tester) async {
    await pumpScreen(tester, const AddFoodScreen(), seeded: false);
    await tester.tap(find.text('Hızlı Kalori'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('quick-kcal')), findsOneWidget);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpScreen(tester, const AddFoodScreen());
    expect(tester.takeException(), isNull);
  });
}
