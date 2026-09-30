import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/nutrition_repository.dart';
import 'package:vitax_app/data/repos/workout_repository.dart';

/// Tasarımdaki örnek güne benzer demo veri: 24 Ekim 2026.
final demoDay = DateTime(2026, 10, 24);

FoodEntry _f(
  String name,
  MealType m,
  int kcal,
  double p,
  double c,
  double f, [
  String portion = '1 porsiyon',
]) => FoodEntry(
  date: demoDay,
  meal: m,
  name: name,
  portion: portion,
  kcal: kcal,
  protein: p,
  carbs: c,
  fat: f,
);

/// Toplam: 1420 kcal, protein 112, karb 150, yağ 32.
Future<void> seedDemoDay(NutritionRepository repo) async {
  await repo.addFood(
    _f(
      'Yulaf ezmesi & Badem sütü',
      MealType.breakfast,
      240,
      10,
      42,
      5,
      '1 kase',
    ),
  );
  await repo.addFood(
    _f('Haşlanmış Yumurta', MealType.breakfast, 180, 14, 1, 12, '2 adet'),
  );
  await repo.addFood(
    _f('Izgara Tavuk Göğsü & Kinoa', MealType.lunch, 520, 52, 58, 6),
  );
  await repo.addFood(
    _f('Mevsim Yeşillikleri Salatası', MealType.lunch, 130, 6, 8, 3, '1 kase'),
  );
  await repo.addFood(_f('Çiğ Badem', MealType.snack, 150, 10, 5, 4, '25g'));
  await repo.addFood(
    _f('Yeşil Elma & Fıstık Ezmesi', MealType.snack, 200, 20, 36, 2),
  );
  await repo.addWater(
    demoDay,
    200,
    at: DateTime(2026, 10, 24, 7, 45),
    label: 'Bardak',
  );
  await repo.addWater(
    demoDay,
    200,
    at: DateTime(2026, 10, 24, 9, 0),
    label: 'Bardak',
  );
  await repo.addWater(
    demoDay,
    500,
    at: DateTime(2026, 10, 24, 11, 30),
    label: 'Şişe',
  );
  await repo.addWater(
    demoDay,
    300,
    at: DateTime(2026, 10, 24, 14, 15),
    label: 'Kupa',
  );
}

/// Son 30 günde 78,2 -> 76,4 kg (30 günlük değişim -1,8; 7 günlük -0,2).
Future<void> seedWeights(NutritionRepository repo) async {
  for (final (d, h, m, kg) in [
    (DateTime(2026, 9, 25), 8, 0, 78.2),
    (DateTime(2026, 10, 1), 8, 0, 77.9),
    (DateTime(2026, 10, 12), 9, 15, 77.5),
    (DateTime(2026, 10, 17), 7, 30, 77.0),
    (DateTime(2026, 10, 21), 8, 10, 76.6),
    (DateTime(2026, 10, 24), 7, 45, 76.4),
  ]) {
    await repo.logWeight(DateTime(d.year, d.month, d.day, h, m), kg);
  }
}

SetLog _set(
  String ex,
  int no,
  int reps,
  double kg,
  DateTime t, {
  int? avg,
  int? peak,
  int? rec,
}) => SetLog(
  exerciseId: ex,
  setNo: no,
  reps: reps,
  weightKg: kg,
  startedAt: t,
  endedAt: t.add(const Duration(seconds: 40)),
  avgHr: avg,
  peakHr: peak,
  recoveryBpm: rec,
);

/// Rutin (id 1) + 3 geçmiş seans (21, 22, 23 Ekim). Egzersiz kimlikleri test fixture'ından.
Routine demoRoutine() => Routine(
  id: 1,
  name: 'Push Day (İtiş A)',
  items: [
    RoutineItem(
      exerciseId: '0001',
      restSec: 90,
      sets: const [
        PlannedSet(reps: 12, weightKg: 60),
        PlannedSet(reps: 10, weightKg: 75),
        PlannedSet(reps: 8, weightKg: 80),
        PlannedSet(reps: 6, weightKg: 85),
      ],
    ),
    RoutineItem.uniform(
      exerciseId: '0002',
      sets: 3,
      reps: 12,
      weightKg: 20,
      restSec: 60,
    ),
  ],
);

Future<void> seedWorkouts(WorkoutRepository repo) async {
  final rid = await repo.saveRoutine(demoRoutine());
  final t1 = DateTime(2026, 10, 21, 18);
  final s1 = await repo.startSession(
    name: 'Göğüs & Triceps',
    startedAt: t1,
    routineId: rid,
  );
  await repo.addSet(
    s1,
    _set('0001', 1, 12, 60, t1, avg: 128, peak: 140, rec: 20),
  );
  await repo.addSet(
    s1,
    _set(
      '0001',
      2,
      10,
      75,
      t1.add(const Duration(minutes: 3)),
      avg: 134,
      peak: 146,
      rec: 22,
    ),
  );
  await repo.addSet(
    s1,
    _set(
      '0001',
      3,
      8,
      80,
      t1.add(const Duration(minutes: 6)),
      avg: 140,
      peak: 150,
      rec: 26,
    ),
  );
  await repo.addSet(
    s1,
    _set(
      '0001',
      4,
      6,
      85,
      t1.add(const Duration(minutes: 9)),
      avg: 146,
      peak: 152,
      rec: 24,
    ),
  );
  for (var i = 1; i <= 3; i++) {
    await repo.addSet(
      s1,
      _set(
        '0002',
        i,
        12,
        20,
        t1.add(Duration(minutes: 12 + i * 2)),
        avg: 124,
        peak: 138,
      ),
    );
  }
  await repo.finishSession(
    s1,
    t1.add(const Duration(minutes: 46)),
    note: 'İyi geçti',
  );

  final t2 = DateTime(2026, 10, 22, 18);
  final s2 = await repo.startSession(name: 'Bacak & Karın', startedAt: t2);
  for (var i = 1; i <= 3; i++) {
    await repo.addSet(
      s2,
      _set(
        '0004',
        i,
        10,
        100,
        t2.add(Duration(minutes: i * 3)),
        avg: 142,
        peak: 156,
      ),
    );
  }
  for (var i = 1; i <= 3; i++) {
    await repo.addSet(
      s2,
      _set('0006', i, 15, 0, t2.add(Duration(minutes: 12 + i * 2))),
    );
  }
  await repo.finishSession(s2, t2.add(const Duration(minutes: 52)));

  final t3 = DateTime(2026, 10, 23, 18);
  final s3 = await repo.startSession(name: 'Sırt & Biseps', startedAt: t3);
  for (var i = 1; i <= 3; i++) {
    await repo.addSet(
      s3,
      _set(
        '0003',
        i,
        8,
        0,
        t3.add(Duration(minutes: i * 3)),
        avg: 130,
        peak: 144,
      ),
    );
    await repo.addSet(
      s3,
      _set(
        '0005',
        i,
        12,
        15,
        t3.add(Duration(minutes: 12 + i * 2)),
        avg: 118,
        peak: 130,
      ),
    );
  }
  await repo.finishSession(s3, t3.add(const Duration(minutes: 44)));
}
