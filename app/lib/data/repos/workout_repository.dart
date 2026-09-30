import 'dart:convert';

import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models.dart';

abstract class WorkoutRepository {
  Future<int> saveRoutine(Routine r);
  Future<Routine?> routine(int id);
  Future<List<Routine>> routines();
  Future<void> deleteRoutine(int id);

  Future<int> startSession({
    required String name,
    required DateTime startedAt,
    int? routineId,
  });
  Future<int> addSet(int sessionId, SetLog set);
  Future<void> deleteSet(int setId);
  Future<void> updateSetHr(
    int setId, {
    int? avgHr,
    int? peakHr,
    int? recoveryBpm,
  });
  Future<void> finishSession(
    int sessionId,
    DateTime endedAt, {
    String note = '',
  });
  Future<void> updateSessionNote(int sessionId, String note);
  Future<WorkoutSession?> session(int id);

  /// [from] dahil, [to] hariç; en yeni önce.
  Future<List<WorkoutSession>> sessions({
    required DateTime from,
    required DateTime to,
  });
  Future<void> deleteSession(int id);

  Future<LastPerformance?> lastPerformance(String exerciseId);

  /// Bir hareketteki en yüksek ağırlık. [excludeSessionId] seansı hariç tutar.
  Future<double?> bestWeight(String exerciseId, {int? excludeSessionId});
  Future<void> close();
}

LastPerformance? _lastPerf(List<(WorkoutSession, List<SetLog>)> bySession) {
  if (bySession.isEmpty) return null;
  bySession.sort((a, b) => b.$1.startedAt.compareTo(a.$1.startedAt));
  final (s, sets) = bySession.first;
  var best = sets.first;
  for (final x in sets) {
    if (x.weightKg > best.weightKg ||
        (x.weightKg == best.weightKg && x.reps > best.reps)) {
      best = x;
    }
  }
  return LastPerformance(
    sessionDate: DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day),
    sets: sets,
    best: best,
  );
}

class InMemoryWorkoutRepository implements WorkoutRepository {
  final Map<int, Routine> _routines = {};
  final Map<int, WorkoutSession> _sessions = {};
  final Map<int, List<SetLog>> _sets = {};
  int _rid = 1, _sid = 1, _setId = 1;

  @override
  Future<int> saveRoutine(Routine r) async {
    final id = r.id ?? _rid++;
    _routines[id] = Routine(id: id, name: r.name, items: List.of(r.items));
    return id;
  }

  @override
  Future<Routine?> routine(int id) async => _routines[id];

  @override
  Future<List<Routine>> routines() async {
    final ids = _routines.keys.toList()..sort();
    return [for (final i in ids) _routines[i]!];
  }

  @override
  Future<void> deleteRoutine(int id) async => _routines.remove(id);

  @override
  Future<int> startSession({
    required String name,
    required DateTime startedAt,
    int? routineId,
  }) async {
    final id = _sid++;
    _sessions[id] = WorkoutSession(
      id: id,
      name: name,
      routineId: routineId,
      startedAt: startedAt,
    );
    _sets[id] = [];
    return id;
  }

  @override
  Future<int> addSet(int sessionId, SetLog set) async {
    final id = _setId++;
    _sets[sessionId]!.add(
      SetLog(
        id: id,
        exerciseId: set.exerciseId,
        setNo: set.setNo,
        reps: set.reps,
        weightKg: set.weightKg,
        startedAt: set.startedAt,
        endedAt: set.endedAt,
        avgHr: set.avgHr,
        peakHr: set.peakHr,
        recoveryBpm: set.recoveryBpm,
      ),
    );
    return id;
  }

  @override
  Future<void> deleteSet(int setId) async {
    for (final l in _sets.values) {
      l.removeWhere((s) => s.id == setId);
    }
  }

  @override
  Future<void> updateSetHr(
    int setId, {
    int? avgHr,
    int? peakHr,
    int? recoveryBpm,
  }) async {
    for (final l in _sets.values) {
      final i = l.indexWhere((s) => s.id == setId);
      if (i < 0) continue;
      final o = l[i];
      l[i] = SetLog(
        id: o.id,
        exerciseId: o.exerciseId,
        setNo: o.setNo,
        reps: o.reps,
        weightKg: o.weightKg,
        startedAt: o.startedAt,
        endedAt: o.endedAt,
        avgHr: avgHr ?? o.avgHr,
        peakHr: peakHr ?? o.peakHr,
        recoveryBpm: recoveryBpm ?? o.recoveryBpm,
      );
    }
  }

  @override
  Future<void> finishSession(
    int sessionId,
    DateTime endedAt, {
    String note = '',
  }) async {
    final s = _sessions[sessionId]!;
    _sessions[sessionId] = WorkoutSession(
      id: s.id,
      name: s.name,
      routineId: s.routineId,
      startedAt: s.startedAt,
      endedAt: endedAt,
      note: note,
    );
  }

  @override
  Future<void> updateSessionNote(int sessionId, String note) async {
    final s = _sessions[sessionId];
    if (s == null) return;
    _sessions[sessionId] = WorkoutSession(
      id: s.id,
      name: s.name,
      routineId: s.routineId,
      startedAt: s.startedAt,
      endedAt: s.endedAt,
      note: note,
    );
  }

  WorkoutSession _full(int id) {
    final s = _sessions[id]!;
    return WorkoutSession(
      id: s.id,
      name: s.name,
      routineId: s.routineId,
      startedAt: s.startedAt,
      endedAt: s.endedAt,
      note: s.note,
      sets: List.of(_sets[id]!),
    );
  }

  @override
  Future<WorkoutSession?> session(int id) async =>
      _sessions.containsKey(id) ? _full(id) : null;

  @override
  Future<List<WorkoutSession>> sessions({
    required DateTime from,
    required DateTime to,
  }) async {
    final l =
        _sessions.values
            .where(
              (s) => !s.startedAt.isBefore(from) && s.startedAt.isBefore(to),
            )
            .map((s) => _full(s.id!))
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return l;
  }

  @override
  Future<void> deleteSession(int id) async {
    _sessions.remove(id);
    _sets.remove(id);
  }

  @override
  Future<LastPerformance?> lastPerformance(String exerciseId) async {
    final by = <(WorkoutSession, List<SetLog>)>[];
    for (final s in _sessions.values) {
      final sets = _sets[s.id]!
          .where((x) => x.exerciseId == exerciseId)
          .toList();
      if (sets.isNotEmpty) by.add((s, sets));
    }
    return _lastPerf(by);
  }

  @override
  Future<double?> bestWeight(String exerciseId, {int? excludeSessionId}) async {
    double? best;
    _sets.forEach((sid, list) {
      if (sid == excludeSessionId) return;
      for (final s in list.where((x) => x.exerciseId == exerciseId)) {
        if (best == null || s.weightKg > best!) best = s.weightKg;
      }
    });
    return best;
  }

  @override
  Future<void> close() async {}
}

class DriftWorkoutRepository implements WorkoutRepository {
  DriftWorkoutRepository(this._db);
  final AppDatabase _db;

  DateTime _t(int ms) => DateTime.fromMillisecondsSinceEpoch(ms);

  @override
  Future<int> saveRoutine(Routine r) => _db.transaction(() async {
    int id;
    if (r.id == null) {
      id = await _db
          .into(_db.routines)
          .insert(RoutinesCompanion.insert(name: r.name));
    } else {
      id = r.id!;
      await (_db.update(_db.routines)..where((t) => t.id.equals(id))).write(
        RoutinesCompanion(name: Value(r.name)),
      );
      await (_db.delete(
        _db.routineItems,
      )..where((t) => t.routineId.equals(id))).go();
    }
    for (var i = 0; i < r.items.length; i++) {
      final it = r.items[i];
      await _db
          .into(_db.routineItems)
          .insert(
            RoutineItemsCompanion.insert(
              routineId: id,
              pos: i,
              exerciseId: it.exerciseId,
              plan: jsonEncode([
                for (final x in it.sets) {'r': x.reps, 'w': x.weightKg},
              ]),
              restSec: Value(it.restSec),
            ),
          );
    }
    return id;
  });

  Future<Routine> _routine(RoutineRow r) async {
    final items =
        await (_db.select(_db.routineItems)
              ..where((t) => t.routineId.equals(r.id))
              ..orderBy([(t) => OrderingTerm.asc(t.pos)]))
            .get();
    return Routine(
      id: r.id,
      name: r.name,
      items: [
        for (final i in items)
          RoutineItem(
            exerciseId: i.exerciseId,
            restSec: i.restSec,
            sets: [
              for (final x in (jsonDecode(i.plan) as List))
                PlannedSet(
                  reps: (x['r'] as num).toInt(),
                  weightKg: (x['w'] as num).toDouble(),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Future<Routine?> routine(int id) async {
    final r = await (_db.select(
      _db.routines,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _routine(r);
  }

  @override
  Future<List<Routine>> routines() async {
    final rows = await (_db.select(
      _db.routines,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return [for (final r in rows) await _routine(r)];
  }

  @override
  Future<void> deleteRoutine(int id) => _db.transaction(() async {
    await (_db.delete(
      _db.routineItems,
    )..where((t) => t.routineId.equals(id))).go();
    await (_db.delete(_db.routines)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<int> startSession({
    required String name,
    required DateTime startedAt,
    int? routineId,
  }) => _db
      .into(_db.workoutSessions)
      .insert(
        WorkoutSessionsCompanion.insert(
          name: name,
          routineId: Value(routineId),
          startedAtMs: startedAt.millisecondsSinceEpoch,
        ),
      );

  @override
  Future<int> addSet(int sessionId, SetLog s) => _db
      .into(_db.workoutSets)
      .insert(
        WorkoutSetsCompanion.insert(
          sessionId: sessionId,
          exerciseId: s.exerciseId,
          setNo: s.setNo,
          reps: s.reps,
          weightKg: s.weightKg,
          startedAtMs: s.startedAt.millisecondsSinceEpoch,
          endedAtMs: s.endedAt.millisecondsSinceEpoch,
          avgHr: Value(s.avgHr),
          peakHr: Value(s.peakHr),
          recoveryBpm: Value(s.recoveryBpm),
        ),
      );

  @override
  Future<void> deleteSet(int setId) =>
      (_db.delete(_db.workoutSets)..where((t) => t.id.equals(setId))).go();

  @override
  Future<void> updateSetHr(
    int setId, {
    int? avgHr,
    int? peakHr,
    int? recoveryBpm,
  }) => (_db.update(_db.workoutSets)..where((t) => t.id.equals(setId))).write(
    WorkoutSetsCompanion(
      avgHr: avgHr == null ? const Value.absent() : Value(avgHr),
      peakHr: peakHr == null ? const Value.absent() : Value(peakHr),
      recoveryBpm: recoveryBpm == null
          ? const Value.absent()
          : Value(recoveryBpm),
    ),
  );

  @override
  Future<void> finishSession(
    int sessionId,
    DateTime endedAt, {
    String note = '',
  }) => (_db.update(_db.workoutSessions)..where((t) => t.id.equals(sessionId)))
      .write(
        WorkoutSessionsCompanion(
          endedAtMs: Value(endedAt.millisecondsSinceEpoch),
          note: Value(note),
        ),
      );

  @override
  Future<void> updateSessionNote(int sessionId, String note) =>
      (_db.update(_db.workoutSessions)..where((t) => t.id.equals(sessionId)))
          .write(WorkoutSessionsCompanion(note: Value(note)));

  SetLog _set(SetRow r) => SetLog(
    id: r.id,
    exerciseId: r.exerciseId,
    setNo: r.setNo,
    reps: r.reps,
    weightKg: r.weightKg,
    startedAt: _t(r.startedAtMs),
    endedAt: _t(r.endedAtMs),
    avgHr: r.avgHr,
    peakHr: r.peakHr,
    recoveryBpm: r.recoveryBpm,
  );

  Future<WorkoutSession> _full(SessionRow r) async {
    final sets =
        await (_db.select(_db.workoutSets)
              ..where((t) => t.sessionId.equals(r.id))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
            .get();
    return WorkoutSession(
      id: r.id,
      name: r.name,
      routineId: r.routineId,
      startedAt: _t(r.startedAtMs),
      endedAt: r.endedAtMs == null ? null : _t(r.endedAtMs!),
      note: r.note,
      sets: sets.map(_set).toList(),
    );
  }

  @override
  Future<WorkoutSession?> session(int id) async {
    final r = await (_db.select(
      _db.workoutSessions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return r == null ? null : _full(r);
  }

  @override
  Future<List<WorkoutSession>> sessions({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows =
        await (_db.select(_db.workoutSessions)
              ..where(
                (t) =>
                    t.startedAtMs.isBiggerOrEqualValue(
                      from.millisecondsSinceEpoch,
                    ) &
                    t.startedAtMs.isSmallerThanValue(to.millisecondsSinceEpoch),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.startedAtMs)]))
            .get();
    return [for (final r in rows) await _full(r)];
  }

  @override
  Future<void> deleteSession(int id) => _db.transaction(() async {
    await (_db.delete(
      _db.workoutSets,
    )..where((t) => t.sessionId.equals(id))).go();
    await (_db.delete(_db.workoutSessions)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<LastPerformance?> lastPerformance(String exerciseId) async {
    final sets = await (_db.select(
      _db.workoutSets,
    )..where((t) => t.exerciseId.equals(exerciseId))).get();
    if (sets.isEmpty) return null;
    final bySession = <int, List<SetLog>>{};
    for (final s in sets) {
      bySession.putIfAbsent(s.sessionId, () => []).add(_set(s));
    }
    final list = <(WorkoutSession, List<SetLog>)>[];
    for (final e in bySession.entries) {
      final s = await session(e.key);
      if (s != null) list.add((s, e.value));
    }
    return _lastPerf(list);
  }

  @override
  Future<double?> bestWeight(String exerciseId, {int? excludeSessionId}) async {
    final max = _db.workoutSets.weightKg.max();
    final q = _db.selectOnly(_db.workoutSets)
      ..addColumns([max])
      ..where(
        _db.workoutSets.exerciseId.equals(exerciseId) &
            (excludeSessionId == null
                ? const Constant(true)
                : _db.workoutSets.sessionId.equals(excludeSessionId).not()),
      );
    return (await q.getSingle()).read(max);
  }

  @override
  Future<void> close() => _db.close();
}
