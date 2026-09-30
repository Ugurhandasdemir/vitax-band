import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/workout_repository.dart';

void workoutContract(String name, Future<WorkoutRepository> Function() create) {
  group('WorkoutRepository[$name]', () {
    late WorkoutRepository repo;
    final t0 = DateTime(2026, 10, 24, 18, 0);

    setUp(() async => repo = await create());
    tearDown(() async => repo.close());

    SetLog set(
      String ex,
      int no,
      int reps,
      double kg, {
      int minute = 0,
      int? avg,
      int? peak,
      int? rec,
    }) => SetLog(
      exerciseId: ex,
      setNo: no,
      reps: reps,
      weightKg: kg,
      startedAt: t0.add(Duration(minutes: minute)),
      endedAt: t0.add(Duration(minutes: minute, seconds: 40)),
      avgHr: avg,
      peakHr: peak,
      recoveryBpm: rec,
    );

    group('rutinler', () {
      test('kaydedilir, sırası ve değerleri korunur', () async {
        final id = await repo.saveRoutine(
          Routine(
            name: 'Push Day',
            items: [
              RoutineItem.uniform(
                exerciseId: '0001',
                sets: 4,
                reps: 8,
                weightKg: 80,
              ),
              RoutineItem.uniform(
                exerciseId: '0002',
                sets: 3,
                reps: 12,
                weightKg: 20,
              ),
            ],
          ),
        );
        expect(id, greaterThan(0));
        final r = await repo.routine(id);
        expect(r!.name, 'Push Day');
        expect(r.items.map((i) => i.exerciseId), ['0001', '0002']);
        expect(r.items.first.sets, hasLength(4));
        expect(r.items.first.sets.first.weightKg, 80);
        expect(r.items.first.sets.first.reps, 8);
        expect(r.items.first.restSec, 90);
      });

      test(
        'set başına farklı hedef ve mola süresi korunur (piramit)',
        () async {
          final id = await repo.saveRoutine(
            Routine(
              name: 'Piramit',
              items: [
                RoutineItem(
                  exerciseId: '0001',
                  restSec: 120,
                  sets: [
                    PlannedSet(reps: 12, weightKg: 60),
                    PlannedSet(reps: 10, weightKg: 75),
                    PlannedSet(reps: 8, weightKg: 80),
                    PlannedSet(reps: 6, weightKg: 85),
                  ],
                ),
              ],
            ),
          );
          final it = (await repo.routine(id))!.items.single;
          expect(it.restSec, 120);
          expect(it.sets.map((x) => x.reps), [12, 10, 8, 6]);
          expect(it.sets.map((x) => x.weightKg), [60, 75, 80, 85]);
        },
      );

      test('id ile tekrar kaydetmek günceller (öğeler değişir)', () async {
        final id = await repo.saveRoutine(
          Routine(
            name: 'A',
            items: [
              RoutineItem.uniform(
                exerciseId: '0001',
                sets: 3,
                reps: 10,
                weightKg: 50,
              ),
            ],
          ),
        );
        await repo.saveRoutine(
          Routine(
            id: id,
            name: 'B',
            items: [
              RoutineItem.uniform(
                exerciseId: '0009',
                sets: 5,
                reps: 5,
                weightKg: 100,
              ),
              RoutineItem.uniform(
                exerciseId: '0008',
                sets: 2,
                reps: 15,
                weightKg: 0,
              ),
            ],
          ),
        );
        final r = await repo.routine(id);
        expect(r!.name, 'B');
        expect(r.items.map((i) => i.exerciseId), ['0009', '0008']);
        expect(await repo.routines(), hasLength(1));
      });

      test('listelenir ve silinir', () async {
        final a = await repo.saveRoutine(Routine(name: 'A', items: []));
        await repo.saveRoutine(Routine(name: 'B', items: []));
        expect((await repo.routines()).map((r) => r.name), ['A', 'B']);
        await repo.deleteRoutine(a);
        expect((await repo.routines()).map((r) => r.name), ['B']);
        expect(await repo.routine(a), isNull);
      });
    });

    group('seanslar', () {
      test('başlat, set ekle, bitir', () async {
        final s = await repo.startSession(name: 'Push Day', startedAt: t0);
        await repo.addSet(s, set('0001', 1, 12, 60, avg: 128, peak: 140));
        await repo.addSet(s, set('0001', 2, 10, 75, minute: 3));
        await repo.finishSession(
          s,
          t0.add(const Duration(minutes: 50)),
          note: 'İyi geçti',
        );
        final x = (await repo.session(s))!;
        expect(x.name, 'Push Day');
        expect(x.note, 'İyi geçti');
        expect(x.endedAt, t0.add(const Duration(minutes: 50)));
        expect(x.sets, hasLength(2));
        expect(x.sets.first.reps, 12);
        expect(x.sets.first.avgHr, 128);
        expect(x.sets.first.peakHr, 140);
        expect(x.sets.last.avgHr, isNull);
        expect(x.duration, const Duration(minutes: 50));
      });

      test('bitmemiş seansın süresi null, endedAt null', () async {
        final s = await repo.startSession(name: 'X', startedAt: t0);
        final x = (await repo.session(s))!;
        expect(x.endedAt, isNull);
        expect(x.duration, isNull);
      });

      test('updateSessionNote notu günceller', () async {
        final s = await repo.startSession(name: 'X', startedAt: t0);
        await repo.finishSession(s, t0.add(const Duration(minutes: 30)));
        await repo.updateSessionNote(s, 'Omuz biraz ağrıdı');
        expect((await repo.session(s))!.note, 'Omuz biraz ağrıdı');
      });

      test('updateSetHr nabız alanlarını günceller', () async {
        final s = await repo.startSession(name: 'X', startedAt: t0);
        final id = await repo.addSet(s, set('0001', 1, 10, 50));
        await repo.updateSetHr(id, avgHr: 130, peakHr: 150, recoveryBpm: 24);
        final x = (await repo.session(s))!.sets.single;
        expect(x.avgHr, 130);
        expect(x.peakHr, 150);
        expect(x.recoveryBpm, 24);
      });

      test('set silinir', () async {
        final s = await repo.startSession(name: 'X', startedAt: t0);
        final a = await repo.addSet(s, set('0001', 1, 10, 50));
        await repo.addSet(s, set('0001', 2, 10, 50, minute: 2));
        await repo.deleteSet(a);
        expect((await repo.session(s))!.sets, hasLength(1));
      });

      test('seans aralıkla listelenir, en yeni önce', () async {
        final a = await repo.startSession(
          name: 'A',
          startedAt: DateTime(2026, 10, 20, 18),
        );
        final b = await repo.startSession(
          name: 'B',
          startedAt: DateTime(2026, 10, 22, 18),
        );
        await repo.startSession(name: 'C', startedAt: DateTime(2026, 9, 1, 18));
        final list = await repo.sessions(
          from: DateTime(2026, 10, 1),
          to: DateTime(2026, 11, 1),
        );
        expect(list.map((s) => s.id), [b, a]);
      });

      test('seans silinince setleri de silinir', () async {
        final s = await repo.startSession(name: 'X', startedAt: t0);
        await repo.addSet(s, set('0001', 1, 10, 50));
        await repo.deleteSession(s);
        expect(await repo.session(s), isNull);
        expect(await repo.lastPerformance('0001'), isNull);
      });

      test('rutin bağlantısı saklanır', () async {
        final rid = await repo.saveRoutine(Routine(name: 'R', items: []));
        final s = await repo.startSession(
          name: 'R',
          startedAt: t0,
          routineId: rid,
        );
        expect((await repo.session(s))!.routineId, rid);
      });
    });

    group('geçmiş performans ve rekorlar', () {
      test(
        'lastPerformance son seansın setlerini ve en iyi seti verir',
        () async {
          final old = await repo.startSession(
            name: 'Eski',
            startedAt: DateTime(2026, 10, 10, 18),
          );
          await repo.addSet(
            old,
            SetLog(
              exerciseId: '0001',
              setNo: 1,
              reps: 10,
              weightKg: 60,
              startedAt: DateTime(2026, 10, 10, 18),
              endedAt: DateTime(2026, 10, 10, 18, 1),
            ),
          );
          final s = await repo.startSession(name: 'Yeni', startedAt: t0);
          await repo.addSet(s, set('0001', 1, 12, 60));
          await repo.addSet(s, set('0001', 2, 8, 80, minute: 3));
          final p = (await repo.lastPerformance('0001'))!;
          expect(p.sessionDate, DateTime(2026, 10, 24));
          expect(p.sets, hasLength(2));
          expect(p.best.weightKg, 80);
        },
      );

      test(
        'bestWeight önceki en yüksek ağırlığı verir (belirtilen seans hariç)',
        () async {
          final old = await repo.startSession(
            name: 'Eski',
            startedAt: DateTime(2026, 10, 10, 18),
          );
          await repo.addSet(
            old,
            SetLog(
              exerciseId: '0001',
              setNo: 1,
              reps: 5,
              weightKg: 90,
              startedAt: DateTime(2026, 10, 10, 18),
              endedAt: DateTime(2026, 10, 10, 18, 1),
            ),
          );
          final s = await repo.startSession(name: 'Yeni', startedAt: t0);
          await repo.addSet(s, set('0001', 1, 5, 100));
          expect(await repo.bestWeight('0001', excludeSessionId: s), 90);
          expect(await repo.bestWeight('0001'), 100);
          expect(await repo.bestWeight('9999'), isNull);
        },
      );

      test('lastPerformance hiç kayıt yoksa null', () async {
        expect(await repo.lastPerformance('0001'), isNull);
      });
    });
  });
}
