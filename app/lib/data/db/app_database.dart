import 'package:drift/drift.dart';

part 'app_database.g.dart';

@DataClassName('FoodRow')
class FoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayKey => integer()();
  IntColumn get meal => integer()();
  TextColumn get name => text()();
  TextColumn get portion => text()();
  IntColumn get kcal => integer()();
  RealColumn get protein => real()();
  RealColumn get carbs => real()();
  RealColumn get fat => real()();
}

@DataClassName('WaterRow')
class WaterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get dayKey => integer()();
  IntColumn get atMs => integer()();
  IntColumn get ml => integer()();
  TextColumn get label => text().nullable()();
}

@DataClassName('WeightRow')
class WeightLogs extends Table {
  IntColumn get dayKey => integer()();
  IntColumn get whenMs => integer()();
  RealColumn get kg => real()();
  @override
  Set<Column> get primaryKey => {dayKey};
}

/// Ham nabız akışı. Zaman damgası birincil anahtar: senkron tekrarlanabilir.
@DataClassName('HrRow')
class HrSamples extends Table {
  IntColumn get atMs => integer()();
  IntColumn get bpm => integer()();
  @override
  Set<Column> get primaryKey => {atMs};
}

@DataClassName('StepRow')
class StepSamples extends Table {
  IntColumn get atMs => integer()();
  IntColumn get total => integer()();
  @override
  Set<Column> get primaryKey => {atMs};
}

@DataClassName('RoutineRow')
class Routines extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

@DataClassName('RoutineItemRow')
class RoutineItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get routineId => integer()();
  IntColumn get pos => integer()();
  TextColumn get exerciseId => text()();

  /// Set planı: JSON listesi [{"r":12,"w":60.0}, ...]
  TextColumn get plan => text()();
  IntColumn get restSec => integer().withDefault(const Constant(90))();
}

@DataClassName('SessionRow')
class WorkoutSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get routineId => integer().nullable()();
  IntColumn get startedAtMs => integer()();
  IntColumn get endedAtMs => integer().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
}

@DataClassName('SetRow')
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer()();
  TextColumn get exerciseId => text()();
  IntColumn get setNo => integer()();
  IntColumn get reps => integer()();
  RealColumn get weightKg => real()();
  IntColumn get startedAtMs => integer()();
  IntColumn get endedAtMs => integer()();
  IntColumn get avgHr => integer().nullable()();
  IntColumn get peakHr => integer().nullable()();
  IntColumn get recoveryBpm => integer().nullable()();
}

/// Basit anahtar-değer deposu (profil, hedefler, tercihler).
@DataClassName('SettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    FoodEntries,
    WaterEntries,
    WeightLogs,
    HrSamples,
    StepSamples,
    AppSettings,
    Routines,
    RoutineItems,
    WorkoutSessions,
    WorkoutSets,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;
}
