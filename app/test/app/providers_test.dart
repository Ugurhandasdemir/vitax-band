import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/features/weight/weight_screen.dart' show WeightRange;
import 'package:vitax_app/core/nutrition_calc.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/band_sample_repository.dart';
import 'package:vitax_app/data/repos/nutrition_repository.dart';
import 'package:vitax_app/data/repos/settings_repository.dart';

import '../support/seed.dart';

ProviderContainer makeContainer({
  NutritionRepository? nutrition,
  BandSampleRepository? band,
  SettingsRepository? settings,
}) {
  final c = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 24, 14, 30)),
      if (nutrition != null)
        nutritionRepositoryProvider.overrideWithValue(nutrition),
      if (band != null) bandSampleRepositoryProvider.overrideWithValue(band),
      if (settings != null)
        settingsRepositoryProvider.overrideWithValue(settings),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  test('seçili gün varsayılan olarak saat 00:00 bugün', () {
    final c = makeContainer();
    expect(c.read(selectedDayProvider), DateTime(2026, 10, 24));
  });

  test('seçili gün değişebilir ve saati sıfırlar', () {
    final c = makeContainer();
    c.read(selectedDayProvider.notifier).set(DateTime(2026, 10, 22, 18, 5));
    expect(c.read(selectedDayProvider), DateTime(2026, 10, 22));
  });

  test('profil yoksa varsayılan hedefler okunur', () async {
    final c = makeContainer();
    final p = await c.read(profileProvider.future);
    expect(p.kcalGoal, 2100);
  });

  test('addFood toplamları günceller', () async {
    final repo = InMemoryNutritionRepository();
    final c = makeContainer(nutrition: repo);
    final day = c.read(selectedDayProvider);
    expect((await c.read(dayTotalsProvider(day).future)).kcal, 0);
    await c
        .read(nutritionActionsProvider)
        .addFood(
          FoodEntry(
            date: day,
            meal: MealType.lunch,
            name: 'Pilav',
            portion: '1 tabak',
            kcal: 300,
            carbs: 60,
          ),
        );
    expect((await c.read(dayTotalsProvider(day).future)).kcal, 300);
    expect((await c.read(dayFoodProvider(day).future)), hasLength(1));
  });

  test('deleteFood siler, restoreFood geri alır', () async {
    final repo = InMemoryNutritionRepository();
    await seedDemoDay(repo);
    final c = makeContainer(nutrition: repo);
    final day = demoDay;
    final actions = c.read(nutritionActionsProvider);
    final list = await c.read(dayFoodProvider(day).future);
    final target = list.first;
    await actions.deleteFood(target);
    expect((await c.read(dayFoodProvider(day).future)).length, list.length - 1);
    await actions.restoreFood(target);
    final after = await c.read(dayFoodProvider(day).future);
    expect(after.length, list.length);
    expect(after.map((e) => e.name), contains(target.name));
  });

  test('su kayıtları listelenir, silinince toplam düşer', () async {
    final repo = InMemoryNutritionRepository();
    await seedDemoDay(repo);
    final c = makeContainer(nutrition: repo);
    final actions = c.read(nutritionActionsProvider);
    var list = await c.read(waterEntriesProvider(demoDay).future);
    expect(list.length, 4);
    expect(list.first.ml, 300); // en yeni önce
    await actions.deleteWater(list.first);
    list = await c.read(waterEntriesProvider(demoDay).future);
    expect(list.length, 3);
    expect(await c.read(waterProvider(demoDay).future), 900);
  });

  test(
    'addWater etiket ve saatle kaydeder (bugünse saat şimdiki zaman)',
    () async {
      final repo = InMemoryNutritionRepository();
      final c = makeContainer(nutrition: repo);
      final day = c.read(selectedDayProvider);
      await c.read(nutritionActionsProvider).addWater(day, 300, label: 'Kupa');
      final e = (await c.read(waterEntriesProvider(day).future)).single;
      expect(e.label, 'Kupa');
      expect(e.at, DateTime(2026, 10, 24, 14, 30));
    },
  );

  test('haftalık su serisi 7 gün', () async {
    final repo = InMemoryNutritionRepository();
    await seedDemoDay(repo);
    final c = makeContainer(nutrition: repo);
    final week = await c.read(waterWeekProvider(DateTime(2026, 10, 19)).future);
    expect(week, hasLength(7));
    expect(week[5], 1200); // Cumartesi 24 Ekim
    expect(week[0], 0);
  });

  test('addWater su toplamını günceller', () async {
    final repo = InMemoryNutritionRepository();
    final c = makeContainer(nutrition: repo);
    final day = c.read(selectedDayProvider);
    expect(await c.read(waterProvider(day).future), 0);
    await c.read(nutritionActionsProvider).addWater(day, 200);
    await c.read(nutritionActionsProvider).addWater(day, 300);
    expect(await c.read(waterProvider(day).future), 500);
  });

  test('yakılan kalori adımdan tahmin edilir (bant kalori vermez)', () async {
    final band = InMemoryBandSampleRepository();
    await band.insertSteps([
      StepSample(at: DateTime(2026, 10, 24, 9), total: 8000),
    ]);
    final settings = InMemorySettingsRepository();
    await settings.saveProfile(const Profile(weightKg: 70));
    final c = makeContainer(band: band, settings: settings);
    final burned = await c.read(
      burnedKcalProvider(DateTime(2026, 10, 24)).future,
    );
    expect(burned, estimateStepKcal(steps: 8000, weightKg: 70));
  });

  test('enerji özeti: alınan, hedef, yakılan, kalan, net', () async {
    final repo = InMemoryNutritionRepository();
    await seedDemoDay(repo);
    final band = InMemoryBandSampleRepository();
    await band.insertSteps([
      StepSample(at: DateTime(2026, 10, 24, 9), total: 11250),
    ]);
    final settings = InMemorySettingsRepository();
    await settings.saveProfile(const Profile(weightKg: 70, kcalGoal: 2100));
    final c = makeContainer(nutrition: repo, band: band, settings: settings);
    final e = await c.read(energySummaryProvider(demoDay).future);
    expect(e.eaten, 1420);
    expect(e.goal, 2100);
    expect(e.burned, 450);
    expect(e.remaining, 680);
    expect(e.net, 970);
  });

  test('bant durum sağlayıcısı: son nabız ve bugünkü adım', () async {
    final band = InMemoryBandSampleRepository();
    await band.insertHr([HrSample(at: DateTime(2026, 10, 24, 14, 0), bpm: 72)]);
    await band.insertSteps([
      StepSample(at: DateTime(2026, 10, 24, 14, 0), total: 8432),
    ]);
    final c = makeContainer(band: band);
    expect((await c.read(latestHrProvider.future))!.bpm, 72);
    expect(await c.read(stepsProvider(DateTime(2026, 10, 24)).future), 8432);
  });

  group('kilo sağlayıcıları', () {
    test('aralığa göre seri: 7G son 7 gün, 30G son 30 gün', () async {
      final repo = InMemoryNutritionRepository();
      await seedWeights(repo);
      final c = makeContainer(nutrition: repo);
      final d7 = await c.read(weightSeriesProvider(WeightRange.d7).future);
      final d30 = await c.read(weightSeriesProvider(WeightRange.d30).future);
      final d90 = await c.read(weightSeriesProvider(WeightRange.d90).future);
      expect(d7.map((p) => p.kg), [76.6, 76.4]);
      expect(d30.length, 6);
      expect(d90.length, 6);
    });

    test(
      'logWeight: en son kilo, profil kilosu ve başlangıç kilosu güncellenir',
      () async {
        final repo = InMemoryNutritionRepository();
        final settings = InMemorySettingsRepository();
        await settings.saveProfile(const Profile(weightKg: 80));
        final c = makeContainer(nutrition: repo, settings: settings);
        await c.read(weightActionsProvider).logWeight(79.5);
        expect((await c.read(latestWeightProvider.future))!.kg, 79.5);
        final p = await c.read(profileProvider.future);
        expect(p.weightKg, 79.5);
        expect(p.startWeightKg, 79.5); // ilk kayıt başlangıç olur
        await c.read(weightActionsProvider).logWeight(78.9);
        final q = await c.read(profileProvider.future);
        expect(q.weightKg, 78.9);
        expect(q.startWeightKg, 79.5); // başlangıç değişmez
      },
    );

    test('logWeight geçersiz kiloyu reddeder', () async {
      final repo = InMemoryNutritionRepository();
      final c = makeContainer(nutrition: repo);
      expect(await c.read(weightActionsProvider).logWeight(10), isFalse);
      expect(await c.read(weightActionsProvider).logWeight(400), isFalse);
      expect(await c.read(latestWeightProvider.future), isNull);
    });
  });

  test('enerji aralığı: gün gün alınan ve toplam harcama', () async {
    final repo = InMemoryNutritionRepository();
    await seedDemoDay(repo);
    final band = InMemoryBandSampleRepository();
    await band.insertSteps([
      StepSample(at: DateTime(2026, 10, 24, 9), total: 8000),
    ]);
    final settings = InMemorySettingsRepository();
    const prof = Profile(sex: Sex.male, weightKg: 70, heightCm: 175, age: 30);
    await settings.saveProfile(prof);
    final c = makeContainer(nutrition: repo, band: band, settings: settings);
    final days = await c.read(
      energyRangeProvider((DateTime(2026, 10, 19), 7)).future,
    );
    expect(days, hasLength(7));
    expect(days[5].intake, 1420); // 24 Ekim
    expect(days[5].burn, dailyBurnKcal(prof, 8000));
    expect(days[0].intake, 0);
    expect(days[0].burn, dailyBurnKcal(prof, 0));
  });
}
