import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../models.dart';

/// Bandtan gelen ham verinin yerel kasası. Senkron tekrarlanabilir (idempotent).
abstract class BandSampleRepository {
  Future<void> insertHr(List<HrSample> samples);
  Future<List<HrSample>> hrBetween(DateTime from, DateTime to);
  Future<HrSample?> latestHr();
  Future<double?> restingHr(DateTime day);
  Future<void> insertSteps(List<StepSample> samples);
  Future<int> stepsForDay(DateTime day);
  Future<int> stepCount();

  /// [from] gününden başlayarak [days] günün adım sayısı (kayıtsız gün 0).
  Future<List<int>> stepsDaily(DateTime from, int days);
  Future<void> close();
}

bool _validBpm(int b) => b >= 30 && b <= 210;

double? _resting(Iterable<int> bpms) {
  final v = bpms.where(_validBpm).toList()..sort();
  if (v.isEmpty) return null;
  final n = (v.length * 0.1).ceil().clamp(1, v.length);
  return v.take(n).reduce((a, b) => a + b) / n;
}

class InMemoryBandSampleRepository implements BandSampleRepository {
  final Map<int, int> _hr = {};
  final Map<int, int> _steps = {};

  @override
  Future<void> insertHr(List<HrSample> s) async {
    for (final x in s) {
      _hr.putIfAbsent(x.at.millisecondsSinceEpoch, () => x.bpm);
    }
  }

  List<HrSample> _sortedHr() {
    final k = _hr.keys.toList()..sort();
    return [
      for (final ms in k)
        HrSample(at: DateTime.fromMillisecondsSinceEpoch(ms), bpm: _hr[ms]!),
    ];
  }

  @override
  Future<List<HrSample>> hrBetween(DateTime from, DateTime to) async =>
      _sortedHr()
          .where((s) => !s.at.isBefore(from) && s.at.isBefore(to))
          .toList();

  @override
  Future<HrSample?> latestHr() async {
    final l = _sortedHr();
    return l.isEmpty ? null : l.last;
  }

  @override
  Future<double?> restingHr(DateTime day) async => _resting(
    _sortedHr().where((s) => dayKeyOf(s.at) == dayKeyOf(day)).map((s) => s.bpm),
  );

  @override
  Future<void> insertSteps(List<StepSample> s) async {
    for (final x in s) {
      _steps.putIfAbsent(x.at.millisecondsSinceEpoch, () => x.total);
    }
  }

  @override
  Future<int> stepsForDay(DateTime day) async {
    var best = 0;
    _steps.forEach((ms, total) {
      final d = DateTime.fromMillisecondsSinceEpoch(ms);
      if (dayKeyOf(d) == dayKeyOf(day) && total > best) best = total;
    });
    return best;
  }

  @override
  Future<int> stepCount() async => _steps.length;

  @override
  Future<List<int>> stepsDaily(DateTime from, int days) async => [
    for (var i = 0; i < days; i++)
      await stepsForDay(DateTime(from.year, from.month, from.day + i)),
  ];

  @override
  Future<void> close() async {}
}

class DriftBandSampleRepository implements BandSampleRepository {
  DriftBandSampleRepository(this._db);
  final AppDatabase _db;

  @override
  Future<void> insertHr(List<HrSample> s) => _db.batch((b) {
    b.insertAll(_db.hrSamples, [
      for (final x in s)
        HrSamplesCompanion.insert(
          atMs: Value(x.at.millisecondsSinceEpoch),
          bpm: x.bpm,
        ),
    ], mode: InsertMode.insertOrIgnore);
  });

  HrSample _h(HrRow r) =>
      HrSample(at: DateTime.fromMillisecondsSinceEpoch(r.atMs), bpm: r.bpm);

  @override
  Future<List<HrSample>> hrBetween(DateTime from, DateTime to) async {
    final rows =
        await (_db.select(_db.hrSamples)
              ..where(
                (t) =>
                    t.atMs.isBiggerOrEqualValue(from.millisecondsSinceEpoch) &
                    t.atMs.isSmallerThanValue(to.millisecondsSinceEpoch),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.atMs)]))
            .get();
    return rows.map(_h).toList();
  }

  @override
  Future<HrSample?> latestHr() async {
    final r =
        await (_db.select(_db.hrSamples)
              ..orderBy([(t) => OrderingTerm.desc(t.atMs)])
              ..limit(1))
            .getSingleOrNull();
    return r == null ? null : _h(r);
  }

  @override
  Future<double?> restingHr(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final list = await hrBetween(start, end);
    return _resting(list.map((s) => s.bpm));
  }

  @override
  Future<void> insertSteps(List<StepSample> s) => _db.batch((b) {
    b.insertAll(_db.stepSamples, [
      for (final x in s)
        StepSamplesCompanion.insert(
          atMs: Value(x.at.millisecondsSinceEpoch),
          total: x.total,
        ),
    ], mode: InsertMode.insertOrIgnore);
  });

  @override
  Future<int> stepsForDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows =
        await (_db.select(_db.stepSamples)..where(
              (t) =>
                  t.atMs.isBiggerOrEqualValue(start.millisecondsSinceEpoch) &
                  t.atMs.isSmallerThanValue(end.millisecondsSinceEpoch),
            ))
            .get();
    var best = 0;
    for (final r in rows) {
      if (r.total > best) best = r.total;
    }
    return best;
  }

  @override
  Future<int> stepCount() async {
    final c = _db.stepSamples.atMs.count();
    final r = await (_db.selectOnly(
      _db.stepSamples,
    )..addColumns([c])).getSingle();
    return r.read(c) ?? 0;
  }

  @override
  Future<List<int>> stepsDaily(DateTime from, int days) async => [
    for (var i = 0; i < days; i++)
      await stepsForDay(DateTime(from.year, from.month, from.day + i)),
  ];

  @override
  Future<void> close() => _db.close();
}
