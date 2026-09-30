import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models.dart';

abstract class NutritionRepository {
  Future<int> addFood(FoodEntry e);
  Future<void> deleteFood(int id);
  Future<List<FoodEntry>> foodForDay(DateTime day);
  Future<DayTotals> totalsForDay(DateTime day);
  Future<Map<MealType, int>> kcalByMeal(DateTime day);
  Future<int> copyDay(DateTime from, DateTime to);
  Future<int> addWater(DateTime day, int ml, {DateTime? at, String? label});
  Future<void> deleteWater(int id);
  Future<List<WaterEntry>> waterEntries(DateTime day);
  Future<int> waterForDay(DateTime day);

  /// [from] gününden başlayarak [days] günün toplam su miktarı (kayıtsız gün 0).
  Future<List<int>> waterDaily(DateTime from, int days);
  Future<void> logWeight(DateTime when, double kg);
  Future<List<WeightPoint>> weightSeries(DateTime from, DateTime to);
  Future<WeightPoint?> latestWeight();

  /// [from] gününden başlayarak [days] günün toplam kalorisi (kayıtsız gün 0).
  Future<List<int>> kcalDaily(DateTime from, int days);

  /// Son kullanılan yiyecekler: benzersiz ad, en yeni önce.
  Future<List<FoodEntry>> recentFoods({int limit = 20});
  Future<void> close();
}

DayTotals _sum(Iterable<FoodEntry> list) {
  var kcal = 0;
  var p = 0.0, c = 0.0, f = 0.0;
  for (final e in list) {
    kcal += e.kcal;
    p += e.protein;
    c += e.carbs;
    f += e.fat;
  }
  return DayTotals(kcal: kcal, protein: p, carbs: c, fat: f);
}

Map<MealType, int> _byMeal(Iterable<FoodEntry> list) {
  final m = <MealType, int>{};
  for (final e in list) {
    m[e.meal] = (m[e.meal] ?? 0) + e.kcal;
  }
  return m;
}

/// Bellek içi uygulama: testler ve UI geliştirmesi için.
class InMemoryNutritionRepository implements NutritionRepository {
  final List<FoodEntry> _food = [];
  final List<WaterEntry> _water = [];
  int _nextWaterId = 1;
  final Map<int, WeightPoint> _weight = {};
  int _nextId = 1;

  @override
  Future<int> addFood(FoodEntry e) async {
    final id = _nextId++;
    _food.add(e.copyWith(id: id));
    return id;
  }

  @override
  Future<void> deleteFood(int id) async => _food.removeWhere((e) => e.id == id);

  @override
  Future<List<FoodEntry>> foodForDay(DateTime day) async =>
      _food.where((e) => dayKeyOf(e.date) == dayKeyOf(day)).toList();

  @override
  Future<DayTotals> totalsForDay(DateTime day) async =>
      _sum(await foodForDay(day));

  @override
  Future<Map<MealType, int>> kcalByMeal(DateTime day) async =>
      _byMeal(await foodForDay(day));

  @override
  Future<int> copyDay(DateTime from, DateTime to) async {
    final src = await foodForDay(from);
    for (final e in src) {
      await addFood(e.copyWith(id: null, date: to));
    }
    return src.length;
  }

  @override
  Future<int> addWater(
    DateTime day,
    int ml, {
    DateTime? at,
    String? label,
  }) async {
    final id = _nextWaterId++;
    _water.add(
      WaterEntry(
        id: id,
        at: at ?? DateTime(day.year, day.month, day.day, 12),
        ml: ml,
        label: label,
      ),
    );
    return id;
  }

  @override
  Future<void> deleteWater(int id) async =>
      _water.removeWhere((e) => e.id == id);

  @override
  Future<List<WaterEntry>> waterEntries(DateTime day) async {
    final l = _water.where((e) => dayKeyOf(e.at) == dayKeyOf(day)).toList()
      ..sort((a, b) => b.at.compareTo(a.at));
    return l;
  }

  @override
  Future<int> waterForDay(DateTime day) async =>
      (await waterEntries(day)).fold<int>(0, (a, e) => a + e.ml);

  @override
  Future<List<int>> waterDaily(DateTime from, int days) async => [
    for (var i = 0; i < days; i++)
      await waterForDay(DateTime(from.year, from.month, from.day + i)),
  ];

  @override
  Future<void> logWeight(DateTime when, double kg) async =>
      _weight[dayKeyOf(when)] = WeightPoint(when: when, kg: kg);

  @override
  Future<List<WeightPoint>> weightSeries(DateTime from, DateTime to) async {
    final l =
        _weight.values
            .where((p) => !p.when.isBefore(from) && p.when.isBefore(to))
            .toList()
          ..sort((a, b) => a.when.compareTo(b.when));
    return l;
  }

  @override
  Future<WeightPoint?> latestWeight() async {
    if (_weight.isEmpty) return null;
    return _weight.values.reduce((a, b) => a.when.isAfter(b.when) ? a : b);
  }

  @override
  Future<List<int>> kcalDaily(DateTime from, int days) async => [
    for (var i = 0; i < days; i++)
      (await totalsForDay(DateTime(from.year, from.month, from.day + i))).kcal,
  ];

  @override
  Future<List<FoodEntry>> recentFoods({int limit = 20}) async {
    final sorted = _food.toList()
      ..sort((a, b) {
        final c = dayKeyOf(b.date).compareTo(dayKeyOf(a.date));
        return c != 0 ? c : (b.id ?? 0).compareTo(a.id ?? 0);
      });
    return _distinctByName(sorted, limit);
  }

  @override
  Future<void> close() async {}
}

List<FoodEntry> _distinctByName(Iterable<FoodEntry> sorted, int limit) {
  final seen = <String>{};
  final out = <FoodEntry>[];
  for (final e in sorted) {
    if (seen.add(e.name)) out.add(e);
    if (out.length >= limit) break;
  }
  return out;
}

/// SQLite (drift) uygulaması.
class DriftNutritionRepository implements NutritionRepository {
  DriftNutritionRepository(this._db);
  final AppDatabase _db;

  FoodEntry _fromRow(FoodRow r) {
    final s = r.dayKey.toString();
    return FoodEntry(
      id: r.id,
      date: DateTime(
        int.parse(s.substring(0, 4)),
        int.parse(s.substring(4, 6)),
        int.parse(s.substring(6, 8)),
      ),
      meal: MealType.values[r.meal],
      name: r.name,
      portion: r.portion,
      kcal: r.kcal,
      protein: r.protein,
      carbs: r.carbs,
      fat: r.fat,
    );
  }

  @override
  Future<int> addFood(FoodEntry e) => _db
      .into(_db.foodEntries)
      .insert(
        FoodEntriesCompanion.insert(
          dayKey: dayKeyOf(e.date),
          meal: e.meal.index,
          name: e.name,
          portion: e.portion,
          kcal: e.kcal,
          protein: e.protein,
          carbs: e.carbs,
          fat: e.fat,
        ),
      );

  @override
  Future<void> deleteFood(int id) =>
      (_db.delete(_db.foodEntries)..where((t) => t.id.equals(id))).go();

  @override
  Future<List<FoodEntry>> foodForDay(DateTime day) async {
    final rows =
        await (_db.select(_db.foodEntries)
              ..where((t) => t.dayKey.equals(dayKeyOf(day)))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return rows.map(_fromRow).toList();
  }

  @override
  Future<DayTotals> totalsForDay(DateTime day) async =>
      _sum(await foodForDay(day));

  @override
  Future<Map<MealType, int>> kcalByMeal(DateTime day) async =>
      _byMeal(await foodForDay(day));

  @override
  Future<int> copyDay(DateTime from, DateTime to) async {
    final src = await foodForDay(from);
    for (final e in src) {
      await addFood(e.copyWith(id: null, date: to));
    }
    return src.length;
  }

  @override
  Future<int> addWater(DateTime day, int ml, {DateTime? at, String? label}) {
    final when = at ?? DateTime(day.year, day.month, day.day, 12);
    return _db
        .into(_db.waterEntries)
        .insert(
          WaterEntriesCompanion.insert(
            dayKey: dayKeyOf(when),
            atMs: when.millisecondsSinceEpoch,
            ml: ml,
            label: Value(label),
          ),
        );
  }

  @override
  Future<void> deleteWater(int id) =>
      (_db.delete(_db.waterEntries)..where((t) => t.id.equals(id))).go();

  @override
  Future<List<WaterEntry>> waterEntries(DateTime day) async {
    final rows =
        await (_db.select(_db.waterEntries)
              ..where((t) => t.dayKey.equals(dayKeyOf(day)))
              ..orderBy([(t) => OrderingTerm.desc(t.atMs)]))
            .get();
    return [
      for (final r in rows)
        WaterEntry(
          id: r.id,
          at: DateTime.fromMillisecondsSinceEpoch(r.atMs),
          ml: r.ml,
          label: r.label,
        ),
    ];
  }

  @override
  Future<int> waterForDay(DateTime day) async {
    final sum = _db.waterEntries.ml.sum();
    final q = _db.selectOnly(_db.waterEntries)
      ..addColumns([sum])
      ..where(_db.waterEntries.dayKey.equals(dayKeyOf(day)));
    return (await q.getSingle()).read(sum) ?? 0;
  }

  @override
  Future<List<int>> waterDaily(DateTime from, int days) async => [
    for (var i = 0; i < days; i++)
      await waterForDay(DateTime(from.year, from.month, from.day + i)),
  ];

  @override
  Future<void> logWeight(DateTime when, double kg) => _db
      .into(_db.weightLogs)
      .insertOnConflictUpdate(
        WeightLogsCompanion.insert(
          dayKey: Value(dayKeyOf(when)),
          whenMs: when.millisecondsSinceEpoch,
          kg: kg,
        ),
      );

  WeightPoint _w(WeightRow r) => WeightPoint(
    when: DateTime.fromMillisecondsSinceEpoch(r.whenMs),
    kg: r.kg,
  );

  @override
  Future<List<WeightPoint>> weightSeries(DateTime from, DateTime to) async {
    final rows =
        await (_db.select(_db.weightLogs)
              ..where(
                (t) =>
                    t.whenMs.isBiggerOrEqualValue(from.millisecondsSinceEpoch) &
                    t.whenMs.isSmallerThanValue(to.millisecondsSinceEpoch),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.whenMs)]))
            .get();
    return rows.map(_w).toList();
  }

  @override
  Future<WeightPoint?> latestWeight() async {
    final r =
        await (_db.select(_db.weightLogs)
              ..orderBy([(t) => OrderingTerm.desc(t.whenMs)])
              ..limit(1))
            .getSingleOrNull();
    return r == null ? null : _w(r);
  }

  @override
  Future<List<int>> kcalDaily(DateTime from, int days) async => [
    for (var i = 0; i < days; i++)
      (await totalsForDay(DateTime(from.year, from.month, from.day + i))).kcal,
  ];

  @override
  Future<List<FoodEntry>> recentFoods({int limit = 20}) async {
    final rows =
        await (_db.select(_db.foodEntries)
              ..orderBy([
                (t) => OrderingTerm.desc(t.dayKey),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(500))
            .get();
    return _distinctByName(rows.map(_fromRow), limit);
  }

  @override
  Future<void> close() => _db.close();
}
