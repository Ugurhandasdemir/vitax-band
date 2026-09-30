import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/core/nutrition_calc.dart';
import 'package:vitax_app/data/models.dart';

void main() {
  group('BMR (Mifflin-St Jeor)', () {
    test('erkek 80 kg 180 cm 30 yaş', () {
      expect(
        bmr(sex: Sex.male, weightKg: 80, heightCm: 180, age: 30),
        closeTo(1780, 0.01),
      );
    });
    test('kadın 60 kg 165 cm 28 yaş', () {
      expect(
        bmr(sex: Sex.female, weightKg: 60, heightCm: 165, age: 28),
        closeTo(1330.25, 0.01),
      );
    });
  });

  group('TDEE ve hedef kalori', () {
    test('orta aktif katsayısı 1.55', () {
      expect(tdee(1780, ActivityLevel.moderate), 2759);
    });
    test('ver: -500 kcal', () {
      expect(calorieTarget(2759, GoalType.lose), 2259);
    });
    test('koru: aynı', () {
      expect(calorieTarget(2759, GoalType.maintain), 2759);
    });
    test('al: +300 kcal', () {
      expect(calorieTarget(2759, GoalType.gain), 3059);
    });
    test('hedef asla 1200 kcal altına inmez', () {
      expect(calorieTarget(1500, GoalType.lose), 1200);
    });
  });

  group('makro hedefleri', () {
    test('protein 2 g/kg, yağ %30, karbonhidrat kalan', () {
      final m = macroTargets(kcal: 2100, weightKg: 76);
      expect(m.protein, 152);
      expect(m.fat, 70);
      expect(m.carbs, 216);
    });
    test('kalori dağılımı hedefi aşmaz (yuvarlama payı içinde)', () {
      final m = macroTargets(kcal: 2500, weightKg: 90);
      final total = m.protein * 4 + m.carbs * 4 + m.fat * 9;
      expect((total - 2500).abs(), lessThan(15));
    });
    test('karbonhidrat negatif olmaz', () {
      final m = macroTargets(kcal: 1200, weightKg: 150);
      expect(m.carbs, greaterThanOrEqualTo(0));
    });
  });

  group('yüzde', () {
    test('112/150 -> 75', () => expect(percent(112, 150), 75));
    test('hedef 0 -> 0', () => expect(percent(10, 0), 0));
    test(
      '%100 üstü sınırlanmaz, gösterimde gerçek değer',
      () => expect(percent(300, 150), 200),
    );
  });

  group('net kalori', () {
    test(
      'alınan - yakılan',
      () => expect(netCalories(eaten: 1420, burned: 450), 970),
    );
    test(
      'kalan hedef = hedef - alınan',
      () => expect(remainingKcal(goal: 2100, eaten: 1420), 680),
    );
    test(
      'kalan negatif olabilir (hedef aşıldı)',
      () => expect(remainingKcal(goal: 2000, eaten: 2300), -300),
    );
  });

  group('adım tabanlı enerji tahmini (bant kalori vermez)', () {
    test('adım başına ~0.04 kcal/kg (kilo arttıkça artar)', () {
      final a = estimateStepKcal(steps: 10000, weightKg: 60);
      final b = estimateStepKcal(steps: 10000, weightKg: 90);
      expect(b, greaterThan(a));
      expect(a, inInclusiveRange(200, 600));
    });
    test(
      '0 adım 0 kcal',
      () => expect(estimateStepKcal(steps: 0, weightKg: 70), 0),
    );
  });

  group('önerilen öğün aralığı', () {
    test('2100 kcal hedef için tasarımdaki aralıklar', () {
      expect(recommendedRange(MealType.breakfast, 2100), (400, 500));
      expect(recommendedRange(MealType.lunch, 2100), (600, 750));
      expect(recommendedRange(MealType.dinner, 2100), (500, 650));
      expect(recommendedRange(MealType.snack, 2100), (150, 300));
    });
    test('50 kcal katlarına yuvarlanır', () {
      final r = recommendedRange(MealType.lunch, 1800);
      expect(r.$1 % 50, 0);
      expect(r.$2 % 50, 0);
      expect(r.$1, lessThan(r.$2));
    });
  });

  group('hidrasyon durumu', () {
    test('eşikler', () {
      expect(hydrationStatus(0).label, 'Düşük');
      expect(hydrationStatus(24).label, 'Düşük');
      expect(hydrationStatus(48).label, 'Stabil');
      expect(hydrationStatus(99).label, 'Stabil');
      expect(hydrationStatus(100).label, 'Hedefte');
      expect(hydrationStatus(140).label, 'Hedefte');
    });
    test('her durumun açıklaması var', () {
      for (final p in [0, 50, 100]) {
        expect(hydrationStatus(p).message, isNotEmpty);
      }
    });
  });

  group('haftalık su özeti', () {
    test('hedefe ulaşılan gün sayısı ve ortalama', () {
      final s = weekWaterSummary([2400, 2600, 2500, 1200, 2200, 2700, 0], 2500);
      expect(s.daysReached, 3); // 2600, 2500, 2700
      expect(s.averageMl, 1943); // toplam 13600 / 7
    });
    test('veri yoksa sıfır', () {
      final s = weekWaterSummary([0, 0, 0], 2500);
      expect(s.daysReached, 0);
      expect(s.averageMl, 0);
    });
    test('ortalama sadece kayıtlı günlerden değil, tüm günlerden', () {
      expect(weekWaterSummary([3500, 0], 2500).averageMl, 1750);
    });
  });

  group('VKİ (BMI)', () {
    test('hesap', () {
      expect(bmi(70, 175), closeTo(22.86, 0.01));
      expect(bmi(76.4, 172), closeTo(25.82, 0.01));
    });
    test('boy 0 ise 0', () => expect(bmi(70, 0), 0));
    test('kategori sınırları', () {
      expect(bmiCategory(16.3), BmiCategory.underweight);
      expect(bmiCategory(18.4), BmiCategory.underweight);
      expect(bmiCategory(18.5), BmiCategory.normal);
      expect(bmiCategory(24.9), BmiCategory.normal);
      expect(bmiCategory(25.0), BmiCategory.overweight);
      expect(bmiCategory(29.9), BmiCategory.overweight);
      expect(bmiCategory(30.0), BmiCategory.obese);
    });
    test('kategori etiketleri Türkçe', () {
      expect(BmiCategory.normal.label, 'Normal');
      expect(BmiCategory.underweight.label, 'Zayıf');
      expect(BmiCategory.overweight.label, 'Kilolu');
      expect(BmiCategory.obese.label, 'Obezite');
    });
  });

  group('kilo hedefi ilerlemesi', () {
    test('verme yönünde', () {
      final p = weightProgress(start: 81, current: 76.4, goal: 72);
      expect(p.percent, 51);
      expect(p.remainingKg, closeTo(4.4, 0.001));
    });
    test('alma yönünde', () {
      final p = weightProgress(start: 60, current: 63, goal: 70);
      expect(p.percent, 30);
      expect(p.remainingKg, closeTo(7, 0.001));
    });
    test('hedefe ulaşıldı -> %100, kalan 0', () {
      final p = weightProgress(start: 81, current: 71.5, goal: 72);
      expect(p.percent, 100);
      expect(p.remainingKg, 0);
    });
    test('yanlış yöne gidiş %0 olur, negatif olmaz', () {
      expect(weightProgress(start: 81, current: 83, goal: 72).percent, 0);
    });
    test('hedef başlangıca eşitse çökmez', () {
      expect(weightProgress(start: 75, current: 75, goal: 75).percent, 0);
    });
  });

  group('kilo değişimi', () {
    final now = DateTime(2026, 10, 24, 12);
    WeightPoint w(int daysAgo, double kg) => WeightPoint(
      when: now.subtract(Duration(days: daysAgo)),
      kg: kg,
    );
    test('pencere içindeki ilk ve son fark (negatif = verilen)', () {
      final series = [w(30, 77.4), w(20, 77.0), w(10, 76.8), w(0, 76.4)];
      expect(
        weightChange(series, const Duration(days: 30), now),
        closeTo(-1.0, 0.001),
      );
      expect(
        weightChange(series, const Duration(days: 7), now),
        0,
      ); // tek nokta
      expect(
        weightChange(series, const Duration(days: 12), now),
        closeTo(-0.4, 0.001),
      );
    });
    test(
      'veri yoksa 0',
      () => expect(weightChange([], const Duration(days: 7), now), 0),
    );
  });

  group('otomatik plan', () {
    test('biyometriden kalori ve makro hedefleri', () {
      const p = Profile(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        age: 30,
        activity: ActivityLevel.moderate,
        goal: GoalType.lose,
      );
      final q = applyAutoPlan(p);
      expect(q.kcalGoal, 2259);
      expect(q.proteinGoal, 160);
      expect(q.fatGoal, 75);
      expect(q.carbsGoal, 236);
    });
    test('diğer alanlara dokunmaz', () {
      const p = Profile(waterGoalMl: 3000, stepGoal: 12000, name: 'Uğurhan');
      final q = applyAutoPlan(p);
      expect(q.waterGoalMl, 3000);
      expect(q.stepGoal, 12000);
      expect(q.name, 'Uğurhan');
    });
  });

  group('birimler', () {
    test('kg <-> lb', () {
      expect(kgToLb(76.4), closeTo(168.43, 0.01));
      expect(lbToKg(168.43), closeTo(76.4, 0.01));
    });
    test('cm -> ft/in', () {
      expect(cmToFeetInches(172), (5, 8)); // 5'7.7" -> 5'8"
      expect(cmToFeetInches(180), (5, 11));
    });
    test(
      'ft/in -> cm',
      () => expect(feetInchesToCm(5, 8), closeTo(172.72, 0.01)),
    );
    test('formatWeight birime göre', () {
      expect(formatWeight(76.4, Units.metric), '76,4 kg');
      expect(formatWeight(76.4, Units.imperial), '168,4 lb');
    });
  });

  group('günlük toplam harcama', () {
    test('bazal + adımdan aktif enerji', () {
      const p = Profile(sex: Sex.male, weightKg: 80, heightCm: 180, age: 30);
      expect(dailyBurnKcal(p, 10000), 1780 + 457);
    });
    test('adım yoksa sadece bazal', () {
      const p = Profile(sex: Sex.male, weightKg: 80, heightCm: 180, age: 30);
      expect(dailyBurnKcal(p, 0), 1780);
    });
  });

  group('enerji dengesi özeti', () {
    DayEnergy d(int day, int intake, int burn) =>
        DayEnergy(day: DateTime(2026, 10, day), intake: intake, burn: burn);
    test('sadece kayıtlı günler sayılır', () {
      final s = summarizeEnergy([
        d(19, 2000, 2300),
        d(20, 2100, 2400),
        d(21, 0, 2300), // kayıt yok, dışarıda
        d(22, 2200, 2200),
      ]);
      expect(s.loggedDays, 3);
      expect(s.totalIn, 6300);
      expect(s.totalOut, 6900);
      expect(s.net, -600);
      expect(s.avgNet, -200);
      expect(s.avgIn, 2100);
      expect(s.avgOut, 2300);
    });
    test('hiç kayıt yoksa sıfır, çökmez', () {
      final s = summarizeEnergy([d(19, 0, 2300)]);
      expect(s.loggedDays, 0);
      expect(s.net, 0);
      expect(s.avgNet, 0);
    });
    test('başlık: açık, fazla, denge', () {
      expect(
        energyHeadline(summarizeEnergy([d(19, 2000, 2320)])),
        'Ortalama 320 kcal Açık',
      );
      expect(
        energyHeadline(summarizeEnergy([d(19, 2500, 2200)])),
        'Ortalama 300 kcal Fazla',
      );
      expect(
        energyHeadline(summarizeEnergy([d(19, 2210, 2200)])),
        'Enerji dengede',
      );
      expect(
        energyHeadline(summarizeEnergy([d(19, 0, 2200)])),
        'Henüz yeterli kayıt yok',
      );
    });
  });

  group('enerji yorumu', () {
    EnergySummary2 sum(int i, int o) => summarizeEnergy([
      DayEnergy(day: DateTime(2026, 10, 19), intake: i, burn: o),
    ]);
    test('hedefe göre açık/fazla yorumu', () {
      expect(
        energyAdvice(sum(2000, 2400), GoalType.lose),
        contains('kilo verme'),
      );
      expect(
        energyAdvice(sum(2000, 2400), GoalType.gain),
        contains('daha yemelisin'),
      );
      expect(
        energyAdvice(sum(2600, 2200), GoalType.gain),
        contains('kas kazanımını'),
      );
      expect(
        energyAdvice(sum(2600, 2200), GoalType.lose),
        contains('azaltmayı'),
      );
    });
    test('denge ve veri yok', () {
      expect(energyAdvice(sum(2200, 2210), GoalType.lose), contains('dengede'));
      expect(energyAdvice(sum(0, 2200), GoalType.lose), contains('kaydet'));
    });
  });
}
