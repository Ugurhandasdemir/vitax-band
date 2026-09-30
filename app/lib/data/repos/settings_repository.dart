import '../db/app_database.dart';
import '../models.dart';

abstract class SettingsRepository {
  Future<Profile> loadProfile();
  Future<void> saveProfile(Profile p);

  /// Serbest anahtar-değer deposu (favoriler vb.).
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> close();
}

Map<String, String> _toMap(Profile p) => {
  'heightCm': p.heightCm.toString(),
  'weightKg': p.weightKg.toString(),
  'age': p.age.toString(),
  'sex': p.sex.name,
  'activity': p.activity.name,
  'goal': p.goal.name,
  'kcalGoal': p.kcalGoal.toString(),
  'proteinGoal': p.proteinGoal.toString(),
  'carbsGoal': p.carbsGoal.toString(),
  'fatGoal': p.fatGoal.toString(),
  'waterGoalMl': p.waterGoalMl.toString(),
  'stepGoal': p.stepGoal.toString(),
  'onboarded': p.onboarded.toString(),
  'name': p.name,
  'goalWeightKg': p.goalWeightKg.toString(),
  'startWeightKg': p.startWeightKg.toString(),
  'units': p.units.name,
};

Profile _fromMap(Map<String, String> m) {
  const d = Profile();
  T enumOf<T extends Enum>(List<T> values, String? n, T fallback) =>
      values.firstWhere((e) => e.name == n, orElse: () => fallback);
  return Profile(
    heightCm: double.tryParse(m['heightCm'] ?? '') ?? d.heightCm,
    weightKg: double.tryParse(m['weightKg'] ?? '') ?? d.weightKg,
    age: int.tryParse(m['age'] ?? '') ?? d.age,
    sex: enumOf(Sex.values, m['sex'], d.sex),
    activity: enumOf(ActivityLevel.values, m['activity'], d.activity),
    goal: enumOf(GoalType.values, m['goal'], d.goal),
    kcalGoal: int.tryParse(m['kcalGoal'] ?? '') ?? d.kcalGoal,
    proteinGoal: int.tryParse(m['proteinGoal'] ?? '') ?? d.proteinGoal,
    carbsGoal: int.tryParse(m['carbsGoal'] ?? '') ?? d.carbsGoal,
    fatGoal: int.tryParse(m['fatGoal'] ?? '') ?? d.fatGoal,
    waterGoalMl: int.tryParse(m['waterGoalMl'] ?? '') ?? d.waterGoalMl,
    stepGoal: int.tryParse(m['stepGoal'] ?? '') ?? d.stepGoal,
    onboarded: m['onboarded'] == 'true',
    name: m['name'] ?? '',
    goalWeightKg: double.tryParse(m['goalWeightKg'] ?? '') ?? 0,
    startWeightKg: double.tryParse(m['startWeightKg'] ?? '') ?? 0,
    units: enumOf(Units.values, m['units'], Units.metric),
  );
}

class InMemorySettingsRepository implements SettingsRepository {
  final Map<String, String> _m = {};

  @override
  Future<Profile> loadProfile() async => _fromMap(_m);

  @override
  Future<void> saveProfile(Profile p) async => _m.addAll(_toMap(p));

  @override
  Future<String?> getString(String key) async => _m[key];

  @override
  Future<void> setString(String key, String value) async => _m[key] = value;

  @override
  Future<void> close() async {}
}

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db);
  final AppDatabase _db;

  @override
  Future<Profile> loadProfile() async {
    final rows = await _db.select(_db.appSettings).get();
    return _fromMap({for (final r in rows) r.key: r.value});
  }

  @override
  Future<void> saveProfile(Profile p) => _db.batch((b) {
    b.insertAllOnConflictUpdate(_db.appSettings, [
      for (final e in _toMap(p).entries)
        AppSettingsCompanion.insert(key: e.key, value: e.value),
    ]);
  });

  @override
  Future<String?> getString(String key) async {
    final r = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return r?.value;
  }

  @override
  Future<void> setString(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );

  @override
  Future<void> close() => _db.close();
}
