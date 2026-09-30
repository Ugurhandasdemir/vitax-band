// Veri katmanı modelleri (saf Dart, UI'dan bağımsız).

enum MealType {
  breakfast('Kahvaltı', 'Kahvaltı'),
  lunch('Öğle Yemeği', 'Öğle'),
  dinner('Akşam Yemeği', 'Akşam'),
  snack('Ara Öğün / Atıştırmalık', 'Atıştırmalık');

  const MealType(this.label, this.shortLabel);
  final String label;
  final String shortLabel;
}

class FoodEntry {
  const FoodEntry({
    this.id,
    required this.date,
    required this.meal,
    required this.name,
    required this.portion,
    required this.kcal,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });

  final int? id;
  final DateTime date;
  final MealType meal;
  final String name;
  final String portion;
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;

  FoodEntry copyWith({int? id, DateTime? date}) => FoodEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    meal: meal,
    name: name,
    portion: portion,
    kcal: kcal,
    protein: protein,
    carbs: carbs,
    fat: fat,
  );
}

class DayTotals {
  const DayTotals({
    this.kcal = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
  });
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;
}

/// Tek bir su içme kaydı.
class WaterEntry {
  const WaterEntry({this.id, required this.at, required this.ml, this.label});
  final int? id;
  final DateTime at;
  final int ml;
  final String? label;
}

class WeightPoint {
  const WeightPoint({required this.when, required this.kg});
  final DateTime when;
  final double kg;
}

/// Bandtan gelen nabız örneği (ham, ~1 Hz). Geçerli aralık 30..210 bpm.
class HrSample {
  const HrSample({required this.at, required this.bpm});
  final DateTime at;
  final int bpm;
}

/// Bandın günlük toplam adım sayacı anlık görüntüsü.
class StepSample {
  const StepSample({required this.at, required this.total});
  final DateTime at;
  final int total;
}

int dayKeyOf(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

enum Sex { male, female }

enum ActivityLevel {
  sedentary(1.2),
  light(1.375),
  moderate(1.55),
  active(1.725),
  veryActive(1.9);

  const ActivityLevel(this.factor);
  final double factor;
}

enum GoalType { lose, maintain, gain }

enum Units { metric, imperial }

/// Kullanıcı profili ve günlük hedefler.
class Profile {
  const Profile({
    this.heightCm = 175,
    this.weightKg = 75,
    this.age = 30,
    this.sex = Sex.male,
    this.activity = ActivityLevel.moderate,
    this.goal = GoalType.maintain,
    this.kcalGoal = 2100,
    this.proteinGoal = 150,
    this.carbsGoal = 250,
    this.fatGoal = 70,
    this.waterGoalMl = 2500,
    this.stepGoal = 10000,
    this.onboarded = false,
    this.name = '',
    this.goalWeightKg = 0,
    this.startWeightKg = 0,
    this.units = Units.metric,
  });

  final double heightCm;
  final double weightKg;
  final int age;
  final Sex sex;
  final ActivityLevel activity;
  final GoalType goal;
  final int kcalGoal;
  final int proteinGoal;
  final int carbsGoal;
  final int fatGoal;
  final int waterGoalMl;
  final int stepGoal;
  final bool onboarded;
  final String name;

  /// 0 = belirlenmemiş.
  final double goalWeightKg;

  /// 0 = belirlenmemiş (ilk kilo kaydı kullanılır).
  final double startWeightKg;
  final Units units;

  Profile copyWith({
    double? heightCm,
    double? weightKg,
    int? age,
    Sex? sex,
    ActivityLevel? activity,
    GoalType? goal,
    int? kcalGoal,
    int? proteinGoal,
    int? carbsGoal,
    int? fatGoal,
    int? waterGoalMl,
    int? stepGoal,
    bool? onboarded,
    String? name,
    double? goalWeightKg,
    double? startWeightKg,
    Units? units,
  }) => Profile(
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    age: age ?? this.age,
    sex: sex ?? this.sex,
    activity: activity ?? this.activity,
    goal: goal ?? this.goal,
    kcalGoal: kcalGoal ?? this.kcalGoal,
    proteinGoal: proteinGoal ?? this.proteinGoal,
    carbsGoal: carbsGoal ?? this.carbsGoal,
    fatGoal: fatGoal ?? this.fatGoal,
    waterGoalMl: waterGoalMl ?? this.waterGoalMl,
    stepGoal: stepGoal ?? this.stepGoal,
    onboarded: onboarded ?? this.onboarded,
    name: name ?? this.name,
    goalWeightKg: goalWeightKg ?? this.goalWeightKg,
    startWeightKg: startWeightKg ?? this.startWeightKg,
    units: units ?? this.units,
  );
}

/// Planlanan tek set: hedef tekrar ve ağırlık.
class PlannedSet {
  const PlannedSet({required this.reps, required this.weightKg});
  final int reps;
  final double weightKg;

  PlannedSet copyWith({int? reps, double? weightKg}) =>
      PlannedSet(reps: reps ?? this.reps, weightKg: weightKg ?? this.weightKg);
}

/// Rutindeki bir egzersiz: set başına hedefler ve setler arası mola.
class RoutineItem {
  const RoutineItem({
    required this.exerciseId,
    required this.sets,
    this.restSec = 90,
  });

  /// Tüm setleri aynı hedefle üretir.
  factory RoutineItem.uniform({
    required String exerciseId,
    required int sets,
    required int reps,
    required double weightKg,
    int restSec = 90,
  }) => RoutineItem(
    exerciseId: exerciseId,
    restSec: restSec,
    sets: List.generate(
      sets,
      (_) => PlannedSet(reps: reps, weightKg: weightKg),
    ),
  );

  final String exerciseId;
  final List<PlannedSet> sets;
  final int restSec;

  RoutineItem copyWith({List<PlannedSet>? sets, int? restSec}) => RoutineItem(
    exerciseId: exerciseId,
    sets: sets ?? this.sets,
    restSec: restSec ?? this.restSec,
  );
}

class Routine {
  const Routine({this.id, required this.name, required this.items});
  final int? id;
  final String name;
  final List<RoutineItem> items;
}

/// Yapılmış tek set. Nabız alanları bant bağlıysa dolar.
class SetLog {
  const SetLog({
    this.id,
    required this.exerciseId,
    required this.setNo,
    required this.reps,
    required this.weightKg,
    required this.startedAt,
    required this.endedAt,
    this.avgHr,
    this.peakHr,
    this.recoveryBpm,
  });
  final int? id;
  final String exerciseId;
  final int setNo;
  final int reps;
  final double weightKg;
  final DateTime startedAt;
  final DateTime endedAt;
  final int? avgHr;
  final int? peakHr;

  /// Setten sonra 60 sn içindeki nabız düşüşü.
  final int? recoveryBpm;
}

class WorkoutSession {
  const WorkoutSession({
    this.id,
    required this.name,
    this.routineId,
    required this.startedAt,
    this.endedAt,
    this.note = '',
    this.sets = const [],
  });
  final int? id;
  final String name;
  final int? routineId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String note;
  final List<SetLog> sets;

  Duration? get duration => endedAt?.difference(startedAt);
}

class LastPerformance {
  const LastPerformance({
    required this.sessionDate,
    required this.sets,
    required this.best,
  });
  final DateTime sessionDate;
  final List<SetLog> sets;
  final SetLog best;
}
