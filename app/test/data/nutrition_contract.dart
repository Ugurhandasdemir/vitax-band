import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/nutrition_repository.dart';

/// Hem bellek içi hem SQLite uygulaması bu sözleşmeyi geçmek zorunda.
void nutritionContract(
  String name,
  Future<NutritionRepository> Function() create,
) {
  group('NutritionRepository[$name]', () {
    late NutritionRepository repo;
    final d = DateTime(2026, 10, 24);
    final d2 = DateTime(2026, 10, 25);

    setUp(() async => repo = await create());
    tearDown(() async => repo.close());

    FoodEntry e(
      String n,
      MealType m,
      int kcal, {
      double p = 0,
      double c = 0,
      double f = 0,
      DateTime? day,
    }) => FoodEntry(
      date: day ?? d,
      meal: m,
      name: n,
      portion: '1 porsiyon',
      kcal: kcal,
      protein: p,
      carbs: c,
      fat: f,
    );

    test('addFood id döndürür ve foodForDay geri verir', () async {
      final id = await repo.addFood(e('Yulaf', MealType.breakfast, 240, p: 10));
      expect(id, greaterThan(0));
      final list = await repo.foodForDay(d);
      expect(list, hasLength(1));
      expect(list.first.id, id);
      expect(list.first.name, 'Yulaf');
      expect(list.first.meal, MealType.breakfast);
      expect(list.first.kcal, 240);
    });

    test('foodForDay sadece istenen günü döndürür', () async {
      await repo.addFood(e('A', MealType.lunch, 100));
      await repo.addFood(e('B', MealType.lunch, 200, day: d2));
      expect((await repo.foodForDay(d)).map((x) => x.name), ['A']);
      expect((await repo.foodForDay(d2)).map((x) => x.name), ['B']);
    });

    test('totalsForDay kcal ve makroları öğünler arası toplar', () async {
      await repo.addFood(
        e('Yulaf', MealType.breakfast, 240, p: 10, c: 42, f: 5),
      );
      await repo.addFood(
        e('Yumurta', MealType.breakfast, 180, p: 14, c: 1, f: 12),
      );
      await repo.addFood(e('Tavuk', MealType.lunch, 520, p: 48, c: 38, f: 11));
      final t = await repo.totalsForDay(d);
      expect(t.kcal, 940);
      expect(t.protein, closeTo(72, 0.001));
      expect(t.carbs, closeTo(81, 0.001));
      expect(t.fat, closeTo(28, 0.001));
    });

    test('boş günün toplamı sıfır', () async {
      final t = await repo.totalsForDay(d);
      expect(t.kcal, 0);
      expect(t.protein, 0);
    });

    test('deleteFood kaydı siler ve toplamı düşürür', () async {
      final a = await repo.addFood(e('A', MealType.snack, 150));
      await repo.addFood(e('B', MealType.snack, 200));
      await repo.deleteFood(a);
      expect((await repo.foodForDay(d)).map((x) => x.name), ['B']);
      expect((await repo.totalsForDay(d)).kcal, 200);
    });

    test('olmayan id silmek hata vermez', () async {
      await repo.deleteFood(9999);
    });

    test('foodForDay eklenme sırasını korur', () async {
      await repo.addFood(e('1', MealType.breakfast, 1));
      await repo.addFood(e('2', MealType.lunch, 2));
      await repo.addFood(e('3', MealType.breakfast, 3));
      expect((await repo.foodForDay(d)).map((x) => x.name), ['1', '2', '3']);
    });

    test('kcalByMeal öğün bazında toplar', () async {
      await repo.addFood(e('1', MealType.breakfast, 100));
      await repo.addFood(e('2', MealType.breakfast, 50));
      await repo.addFood(e('3', MealType.dinner, 400));
      final m = await repo.kcalByMeal(d);
      expect(m[MealType.breakfast], 150);
      expect(m[MealType.dinner], 400);
      expect(m[MealType.lunch] ?? 0, 0);
    });

    test('copyDay hedef güne kopyalar ve adedi döndürür', () async {
      await repo.addFood(e('A', MealType.breakfast, 100, p: 5));
      await repo.addFood(e('B', MealType.lunch, 200));
      final n = await repo.copyDay(d, d2);
      expect(n, 2);
      final copied = await repo.foodForDay(d2);
      expect(copied.map((x) => x.name), ['A', 'B']);
      expect(copied.first.protein, 5);
      expect((await repo.foodForDay(d)), hasLength(2)); // kaynak değişmez
    });

    test('su günlük birikir, günler karışmaz', () async {
      await repo.addWater(d, 200);
      await repo.addWater(d, 300);
      await repo.addWater(d2, 500);
      expect(await repo.waterForDay(d), 500);
      expect(await repo.waterForDay(d2), 500);
      expect(await repo.waterForDay(DateTime(2026, 10, 26)), 0);
    });

    test(
      'addWater kayıt döndürür; waterEntries yeniden eskiye sıralı',
      () async {
        final a = await repo.addWater(
          d,
          200,
          at: DateTime(2026, 10, 24, 9),
          label: 'Bardak',
        );
        final b = await repo.addWater(
          d,
          500,
          at: DateTime(2026, 10, 24, 11, 30),
          label: 'Şişe',
        );
        final list = await repo.waterEntries(d);
        expect(list.map((e) => e.id), [b, a]);
        expect(list.first.ml, 500);
        expect(list.first.label, 'Şişe');
        expect(list.first.at, DateTime(2026, 10, 24, 11, 30));
      },
    );

    test('deleteWater kaydı siler ve toplamı düşürür', () async {
      final a = await repo.addWater(d, 200);
      await repo.addWater(d, 300);
      await repo.deleteWater(a);
      expect(await repo.waterForDay(d), 300);
      expect(await repo.waterEntries(d), hasLength(1));
    });

    test('olmayan su kaydını silmek hata vermez', () async {
      await repo.deleteWater(12345);
    });

    test('waterDaily gün gün toplar, kayıtsız günler 0', () async {
      await repo.addWater(d, 200);
      await repo.addWater(d, 300);
      await repo.addWater(d2, 500);
      expect(await repo.waterDaily(d, 3), [500, 500, 0]);
    });

    test('kilo serisi aralıkta ve artan sırada', () async {
      await repo.logWeight(DateTime(2026, 10, 1, 8), 77.4);
      await repo.logWeight(DateTime(2026, 10, 15, 8), 76.8);
      await repo.logWeight(DateTime(2026, 10, 24, 8), 76.4);
      await repo.logWeight(DateTime(2026, 9, 1, 8), 80.0);
      final s = await repo.weightSeries(
        DateTime(2026, 10, 1),
        DateTime(2026, 10, 31),
      );
      expect(s.map((p) => p.kg), [77.4, 76.8, 76.4]);
      expect(s.first.when.isBefore(s.last.when), isTrue);
    });

    test('latestWeight en yeni kaydı verir, boşsa null', () async {
      expect(await repo.latestWeight(), isNull);
      await repo.logWeight(DateTime(2026, 10, 1, 8), 77.4);
      await repo.logWeight(DateTime(2026, 10, 24, 8), 76.4);
      expect((await repo.latestWeight())!.kg, 76.4);
    });

    test('kcalDaily gün gün kalori toplar, kayıtsız gün 0', () async {
      await repo.addFood(e('A', MealType.lunch, 500));
      await repo.addFood(e('B', MealType.dinner, 300));
      await repo.addFood(
        e('C', MealType.lunch, 700, day: DateTime(2026, 10, 26)),
      );
      expect(await repo.kcalDaily(d, 4), [800, 0, 700, 0]);
    });

    test('recentFoods benzersiz adlar, en yeni önce, limitli', () async {
      await repo.addFood(
        e('Eski', MealType.lunch, 1, day: DateTime(2026, 10, 20)),
      );
      await repo.addFood(
        e('Badem', MealType.snack, 150, day: DateTime(2026, 10, 22)),
      );
      await repo.addFood(
        e('Yumurta', MealType.breakfast, 78, day: DateTime(2026, 10, 23)),
      );
      await repo.addFood(
        e('Badem', MealType.snack, 150, day: DateTime(2026, 10, 24)),
      );
      final r = await repo.recentFoods(limit: 10);
      expect(r.map((x) => x.name), ['Badem', 'Yumurta', 'Eski']);
      final limited = await repo.recentFoods(limit: 2);
      expect(limited.map((x) => x.name), ['Badem', 'Yumurta']);
    });

    test('recentFoods boşken boş liste', () async {
      expect(await repo.recentFoods(), isEmpty);
    });

    test('aynı gün ikinci kilo kaydı öncekinin yerine geçer', () async {
      await repo.logWeight(DateTime(2026, 10, 24, 7), 76.9);
      await repo.logWeight(DateTime(2026, 10, 24, 21), 76.4);
      final s = await repo.weightSeries(
        DateTime(2026, 10, 24),
        DateTime(2026, 10, 25),
      );
      expect(s, hasLength(1));
      expect(s.first.kg, 76.4);
    });
  });
}
