import '../data/models.dart';

/// Bazal metabolizma hızı (Mifflin-St Jeor).
double bmr({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int age,
}) {
  final base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return sex == Sex.male ? base + 5 : base - 161;
}

/// Günlük toplam enerji harcaması.
int tdee(double bmrValue, ActivityLevel level) =>
    (bmrValue * level.factor).round();

/// Hedefe göre günlük kalori. Asla 1200 kcal altına inmez.
int calorieTarget(int tdeeValue, GoalType goal) {
  final v = switch (goal) {
    GoalType.lose => tdeeValue - 500,
    GoalType.maintain => tdeeValue,
    GoalType.gain => tdeeValue + 300,
  };
  return v < 1200 ? 1200 : v;
}

class MacroTargets {
  const MacroTargets(this.protein, this.carbs, this.fat);
  final int protein;
  final int carbs;
  final int fat;
}

/// Protein 2 g/kg, yağ kalorinin %30'u, kalan karbonhidrat.
MacroTargets macroTargets({required int kcal, required double weightKg}) {
  final protein = (weightKg * 2).round();
  final fat = (kcal * 0.3 / 9).round();
  final carbs = ((kcal - protein * 4 - fat * 9) / 4).round();
  return MacroTargets(protein, carbs < 0 ? 0 : carbs, fat);
}

int percent(num value, num goal) =>
    goal <= 0 ? 0 : (value / goal * 100).round();

int netCalories({required int eaten, required int burned}) => eaten - burned;

int remainingKcal({required int goal, required int eaten}) => goal - eaten;

/// Bant kalori vermez, adımdan tahmin edilir (~0.04 kcal/adım, 70 kg için).
int estimateStepKcal({required int steps, required double weightKg}) =>
    (steps * weightKg * 0.04 / 70).round();

/// Öğün için önerilen kalori aralığı (günlük hedefin payı, 50 kcal'e yuvarlı).
(int, int) recommendedRange(MealType meal, int dailyGoal) {
  final (lo, hi) = switch (meal) {
    MealType.breakfast => (0.19, 0.24),
    MealType.lunch => (0.29, 0.36),
    MealType.dinner => (0.24, 0.31),
    MealType.snack => (0.07, 0.14),
  };
  int r50(double v) => ((v / 50).round() * 50);
  return (r50(dailyGoal * lo), r50(dailyGoal * hi));
}

class HydrationStatus {
  const HydrationStatus(this.label, this.message);
  final String label;
  final String message;
}

/// Günlük su hedefine göre durum. [percent]: tamamlanma yüzdesi.
HydrationStatus hydrationStatus(int percent) {
  if (percent >= 100) {
    return const HydrationStatus(
      'Hedefte',
      'Harika! Bugünkü su hedefini tamamladın.',
    );
  }
  if (percent >= 25) {
    return const HydrationStatus('Stabil', 'Vücudun bugün dengeli ve uyanık.');
  }
  return const HydrationStatus(
    'Düşük',
    'Su içmeyi unutma, vücudun susamış olabilir.',
  );
}

class WeekWaterSummary {
  const WeekWaterSummary(this.daysReached, this.averageMl);
  final int daysReached;
  final int averageMl;
}

/// Gün gün su toplamlarından başarı (hedefe ulaşılan gün) ve ortalama.
WeekWaterSummary weekWaterSummary(List<int> dailyMl, int goalMl) {
  if (dailyMl.isEmpty) return const WeekWaterSummary(0, 0);
  final reached = dailyMl.where((v) => goalMl > 0 && v >= goalMl).length;
  final avg = dailyMl.fold<int>(0, (a, v) => a + v) / dailyMl.length;
  return WeekWaterSummary(reached, avg.round());
}

/// Vücut kitle indeksi.
double bmi(double kg, double cm) {
  if (cm <= 0) return 0;
  final m = cm / 100;
  return kg / (m * m);
}

enum BmiCategory {
  underweight('Zayıf'),
  normal('Normal'),
  overweight('Kilolu'),
  obese('Obezite');

  const BmiCategory(this.label);
  final String label;
}

BmiCategory bmiCategory(double v) {
  if (v < 18.5) return BmiCategory.underweight;
  if (v < 25) return BmiCategory.normal;
  if (v < 30) return BmiCategory.overweight;
  return BmiCategory.obese;
}

class WeightProgress {
  const WeightProgress(this.percent, this.remainingKg);
  final int percent;
  final double remainingKg;
}

/// Hedefe ilerleme (verme ya da alma yönünde). Yanlış yön %0, hedef aşımı %100.
WeightProgress weightProgress({
  required double start,
  required double current,
  required double goal,
}) {
  final total = start - goal;
  if (total == 0) return const WeightProgress(0, 0);
  final done = (start - current) / total;
  final remaining = (current - goal) * (total > 0 ? 1 : -1);
  return WeightProgress(
    (done.clamp(0.0, 1.0) * 100).round(),
    remaining < 0 ? 0 : remaining,
  );
}

/// [window] içindeki ilk ve son kayıt farkı (negatif = verilen kilo). <2 kayıt ise 0.
double weightChange(List<WeightPoint> series, Duration window, DateTime now) {
  final from = now.subtract(window);
  final inWindow =
      series
          .where((p) => !p.when.isBefore(from) && !p.when.isAfter(now))
          .toList()
        ..sort((a, b) => a.when.compareTo(b.when));
  if (inWindow.length < 2) return 0;
  return inWindow.last.kg - inWindow.first.kg;
}

/// Biyometri, aktivite ve hedefe göre kalori ve makro hedeflerini yeniden hesaplar.
Profile applyAutoPlan(Profile p) {
  final base = bmr(
    sex: p.sex,
    weightKg: p.weightKg,
    heightCm: p.heightCm,
    age: p.age,
  );
  final kcal = calorieTarget(tdee(base, p.activity), p.goal);
  final m = macroTargets(kcal: kcal, weightKg: p.weightKg);
  return p.copyWith(
    kcalGoal: kcal,
    proteinGoal: m.protein,
    carbsGoal: m.carbs,
    fatGoal: m.fat,
  );
}

double kgToLb(double kg) => kg * 2.20462;
double lbToKg(double lb) => lb / 2.20462;

/// 172 cm -> (5, 8). Kalan inç en yakına yuvarlanır.
(int, int) cmToFeetInches(double cm) {
  final totalIn = (cm / 2.54).round();
  return (totalIn ~/ 12, totalIn % 12);
}

double feetInchesToCm(int ft, int inch) => (ft * 12 + inch) * 2.54;

String formatWeight(double kg, Units u) => u == Units.metric
    ? '${kg.toStringAsFixed(1).replaceAll('.', ',')} kg'
    : '${kgToLb(kg).toStringAsFixed(1).replaceAll('.', ',')} lb';

/// Birime göre kilo değeri (birim eki olmadan): "76,4" veya "168,4".
String weightValue(double kg, Units u) => (u == Units.metric ? kg : kgToLb(kg))
    .toStringAsFixed(1)
    .replaceAll('.', ',');

String weightUnit(Units u) => u == Units.metric ? 'kg' : 'lb';

/// Günlük toplam harcama: bazal metabolizma + adımdan tahmini aktif enerji.
int dailyBurnKcal(Profile p, int steps) {
  final base = bmr(
    sex: p.sex,
    weightKg: p.weightKg,
    heightCm: p.heightCm,
    age: p.age,
  );
  return base.round() + estimateStepKcal(steps: steps, weightKg: p.weightKg);
}

class DayEnergy {
  const DayEnergy({
    required this.day,
    required this.intake,
    required this.burn,
  });
  final DateTime day;
  final int intake;
  final int burn;
  int get net => intake - burn;

  /// O gün yemek kaydı girilmiş mi.
  bool get logged => intake > 0;
}

class EnergySummary2 {
  const EnergySummary2({
    required this.loggedDays,
    required this.totalIn,
    required this.totalOut,
  });
  final int loggedDays;
  final int totalIn;
  final int totalOut;
  int get net => totalIn - totalOut;
  int get avgIn => loggedDays == 0 ? 0 : (totalIn / loggedDays).round();
  int get avgOut => loggedDays == 0 ? 0 : (totalOut / loggedDays).round();
  int get avgNet => loggedDays == 0 ? 0 : (net / loggedDays).round();
}

/// Sadece yemek kaydı olan günleri sayar (kaydı girilmeyen gün açık gibi görünmesin).
EnergySummary2 summarizeEnergy(List<DayEnergy> days) {
  final logged = days.where((d) => d.logged).toList();
  return EnergySummary2(
    loggedDays: logged.length,
    totalIn: logged.fold(0, (a, d) => a + d.intake),
    totalOut: logged.fold(0, (a, d) => a + d.burn),
  );
}

String energyHeadline(EnergySummary2 s) {
  if (s.loggedDays == 0) return 'Henüz yeterli kayıt yok';
  if (s.avgNet.abs() < 50) return 'Enerji dengede';
  return s.avgNet < 0
      ? 'Ortalama ${-s.avgNet} kcal Açık'
      : 'Ortalama ${s.avgNet} kcal Fazla';
}

/// Özete ve ana hedefe göre kısa yorum.
String energyAdvice(EnergySummary2 s, GoalType goal) {
  if (s.loggedDays == 0) {
    return 'Kalori dengesini görmek için öğünlerini kaydet ve bilekliğini tak.';
  }
  if (s.avgNet.abs() < 50) return 'Alınan ve harcanan enerji dengede.';
  if (s.avgNet < 0) {
    return switch (goal) {
      GoalType.lose => 'Harika bir kalori açığı yakaladın! Bu, kilo verme hedefini destekliyor.',
      GoalType.gain =>
        'Kalori açığı var. Kas kazanmak için biraz daha yemelisin.',
      GoalType.maintain =>
        'Kalori açığı var. Kilonu korumak için alımını artırabilirsin.',
    };
  }
  return switch (goal) {
    GoalType.gain => 'Kalori fazlan kas kazanımını destekliyor.',
    GoalType.lose =>
      'Kalori fazlası var. Kilo verme hedefin için alımı azaltmayı düşün.',
    GoalType.maintain => 'Kalori fazlası var, kilon artabilir.',
  };
}
