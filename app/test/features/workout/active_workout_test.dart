import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/core/hr_detect.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/workout_repository.dart';
import 'package:vitax_app/features/workout/active_workout.dart';

class _Env {
  _Env(this.container, this.repo, this.clock);
  final ProviderContainer container;
  final InMemoryWorkoutRepository repo;
  final _Clock clock;
  ActiveWorkoutController get ctl =>
      container.read(activeWorkoutProvider.notifier);
  ActiveWorkoutState? get state => container.read(activeWorkoutProvider);
}

class _Clock {
  DateTime now = DateTime(2026, 10, 24, 18, 0, 0);
  void advance(int seconds) => now = now.add(Duration(seconds: seconds));
}

_Env make() {
  final repo = InMemoryWorkoutRepository();
  final clock = _Clock();
  final c = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => clock.now),
      workoutRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  return _Env(c, repo, clock);
}

final _routine = Routine(
  id: 1,
  name: 'Push Day',
  items: [
    RoutineItem(
      exerciseId: '0001',
      restSec: 60,
      sets: const [
        PlannedSet(reps: 12, weightKg: 60),
        PlannedSet(reps: 10, weightKg: 75),
        PlannedSet(reps: 8, weightKg: 80),
      ],
    ),
    RoutineItem.uniform(exerciseId: '0002', sets: 2, reps: 12, weightKg: 20),
  ],
);

void main() {
  test('başlat: ilk egzersiz ve ilk set hedefi taslağa yüklenir', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    final s = e.state!;
    expect(s.name, 'Push Day');
    expect(s.exerciseIndex, 0);
    expect(s.setIndex, 0);
    expect(s.phase, WorkoutPhase.idle);
    expect(s.draftReps, 12);
    expect(s.draftWeightKg, 60);
    expect(s.currentExerciseId, '0001');
    expect(s.sessionId, isNotNull);
  });

  test('set başlat ve bitir: kayıt, sonraki sete geçiş, dinlenme', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    e.ctl.startSet();
    expect(e.state!.phase, WorkoutPhase.working);
    e.clock.advance(40);
    await e.ctl.endSet();
    final s = e.state!;
    expect(s.phase, WorkoutPhase.resting);
    expect(s.loggedSets, hasLength(1));
    expect(s.loggedSets.first.setNo, 1);
    expect(s.loggedSets.first.reps, 12);
    expect(s.loggedSets.first.weightKg, 60);
    expect(
      s.loggedSets.first.endedAt
          .difference(s.loggedSets.first.startedAt)
          .inSeconds,
      40,
    );
    expect(s.setIndex, 1);
    expect(s.draftReps, 10);
    expect(s.draftWeightKg, 75);
    expect((await e.repo.session(s.sessionId!))!.sets, hasLength(1));
  });

  test(
    'taslak tekrar ve ağırlık düzenlenir, set o değerlerle kaydedilir',
    () async {
      final e = make();
      await e.ctl.start(routine: _routine);
      e.ctl.setDraft(reps: 9, weightKg: 62.5);
      e.ctl.startSet();
      e.clock.advance(30);
      await e.ctl.endSet();
      expect(e.state!.loggedSets.single.reps, 9);
      expect(e.state!.loggedSets.single.weightKg, 62.5);
    },
  );

  test('endSet parametreleri taslağı geçersiz kılar', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    e.ctl.startSet();
    e.clock.advance(30);
    await e.ctl.endSet(reps: 7, weightKg: 70);
    expect(e.state!.loggedSets.single.reps, 7);
  });

  test('setBitirmeden endSet çağrılırsa hata vermez, kayıt eklemez', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    await e.ctl.endSet();
    expect(e.state!.loggedSets, isEmpty);
  });

  test('dinlenme süresi ve kalan hesaplanır, atlanır', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    e.ctl.startSet();
    e.clock.advance(30);
    await e.ctl.endSet();
    e.clock.advance(20);
    expect(e.state!.restElapsed(e.clock.now), const Duration(seconds: 20));
    expect(
      e.state!.restRemaining(e.clock.now),
      const Duration(seconds: 40),
    ); // 60 sn mola
    e.ctl.skipRest();
    expect(e.state!.phase, WorkoutPhase.idle);
  });

  test('plandaki setler bitince sonraki egzersize geçilir', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    for (var i = 0; i < 3; i++) {
      e.ctl.startSet();
      e.clock.advance(30);
      await e.ctl.endSet();
      e.ctl.skipRest();
    }
    expect(e.state!.exerciseIndex, 0);
    expect(e.state!.setIndex, 3);
    expect(e.state!.exerciseDone, isTrue);
    e.ctl.nextExercise();
    expect(e.state!.exerciseIndex, 1);
    expect(e.state!.setIndex, 0);
    expect(e.state!.draftReps, 12);
    expect(e.state!.draftWeightKg, 20);
    expect(e.state!.currentExerciseId, '0002');
  });

  test('plan dışı ekstra set son hedefle devam eder', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    for (var i = 0; i < 4; i++) {
      e.ctl.startSet();
      e.clock.advance(30);
      await e.ctl.endSet();
      e.ctl.skipRest();
    }
    expect(e.state!.loggedSets, hasLength(4));
    expect(e.state!.loggedSets.last.setNo, 4);
    expect(e.state!.draftWeightKg, 80); // son hedef
  });

  test('son egzersizin son seti sonrası isLastExercise', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    expect(e.state!.isLastExercise, isFalse);
    e.ctl.nextExercise();
    expect(e.state!.isLastExercise, isTrue);
  });

  test('nabız: set özeti (ort/tepe) sete yazılır', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    e.ctl.startSet();
    for (final bpm in [120, 135, 150, 145]) {
      e.clock.advance(10);
      e.ctl.recordHr(bpm);
    }
    await e.ctl.endSet();
    final set = e.state!.loggedSets.single;
    expect(set.avgHr, 138); // (120+135+150+145)/4=137.5 -> 138
    expect(set.peakHr, 150);
  });

  test(
    'toparlanma: set bittikten 60 sn sonraki nabızla hesaplanır ve kaydedilir',
    () async {
      final e = make();
      await e.ctl.start(routine: _routine);
      e.ctl.startSet();
      for (final bpm in [130, 150]) {
        e.clock.advance(10);
        e.ctl.recordHr(bpm);
      }
      await e.ctl.endSet();
      e.clock.advance(30);
      e.ctl.recordHr(140);
      e.clock.advance(31); // toplam 61 sn
      e.ctl.recordHr(126);
      await Future<void>.delayed(Duration.zero);
      expect(e.state!.loggedSets.single.recoveryBpm, 24); // 150 - 126
      final saved = (await e.repo.session(e.state!.sessionId!))!.sets.single;
      expect(saved.recoveryBpm, 24);
    },
  );

  test(
    'Öneri modu: nabız yükselince setStarted önerisi, onaylayınca set başlar',
    () async {
      final e = make();
      await e.ctl.start(routine: _routine);
      e.ctl.setMode(WorkoutMode.auto);
      for (final bpm in [85, 92, 100, 108]) {
        e.ctl.recordHr(bpm);
        e.clock.advance(10);
      }
      expect(e.state!.suggestion, HrSuggestion.setStarted);
      e.ctl.acceptSuggestion();
      expect(e.state!.phase, WorkoutPhase.working);
      expect(e.state!.suggestion, isNull);
    },
  );

  test('Elle modda öneri üretilmez', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    for (final bpm in [85, 92, 100, 108]) {
      e.ctl.recordHr(bpm);
      e.clock.advance(10);
    }
    expect(e.state!.suggestion, isNull);
  });

  test('öneri yoksayılınca bir süre tekrar önerilmez', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    e.ctl.setMode(WorkoutMode.auto);
    for (final bpm in [85, 92, 100, 108]) {
      e.ctl.recordHr(bpm);
      e.clock.advance(10);
    }
    expect(e.state!.suggestion, HrSuggestion.setStarted);
    e.ctl.dismissSuggestion();
    e.ctl.recordHr(112);
    expect(e.state!.suggestion, isNull);
  });

  test(
    'Öneri modu: set sırasında nabız düşünce restStarted, onay seti bitirir',
    () async {
      final e = make();
      await e.ctl.start(routine: _routine);
      e.ctl.setMode(WorkoutMode.auto);
      e.ctl.startSet();
      for (final bpm in [130, 146, 140, 132]) {
        e.ctl.recordHr(bpm);
        e.clock.advance(10);
      }
      expect(e.state!.suggestion, HrSuggestion.restStarted);
      await e.ctl.acceptSuggestion();
      expect(e.state!.phase, WorkoutPhase.resting);
      expect(e.state!.loggedSets, hasLength(1));
    },
  );

  test('bitir: seans kapanır, not kaydedilir, durum temizlenir', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    e.ctl.startSet();
    e.clock.advance(30);
    await e.ctl.endSet();
    e.clock.advance(600);
    final id = await e.ctl.finish(note: 'Zor ama iyi');
    expect(e.state, isNull);
    final s = (await e.repo.session(id!))!;
    expect(s.endedAt, e.clock.now);
    expect(s.note, 'Zor ama iyi');
    expect(s.sets, hasLength(1));
  });

  test('vazgeç: seans ve setleri silinir', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    final id = e.state!.sessionId!;
    e.ctl.startSet();
    e.clock.advance(30);
    await e.ctl.endSet();
    await e.ctl.cancel();
    expect(e.state, isNull);
    expect(await e.repo.session(id), isNull);
  });

  test('rutinsiz serbest antrenman: egzersiz eklenir', () async {
    final e = make();
    await e.ctl.start(name: 'Serbest Antrenman');
    expect(e.state!.items, isEmpty);
    e.ctl.addExercise('0005');
    expect(e.state!.currentExerciseId, '0005');
    expect(e.state!.draftReps, 10);
  });

  test('toplam süre ve hacim durumdan hesaplanır', () async {
    final e = make();
    await e.ctl.start(routine: _routine);
    e.ctl.startSet();
    e.clock.advance(30);
    await e.ctl.endSet(); // 12x60 = 720
    e.clock.advance(90);
    expect(e.state!.elapsed(e.clock.now), const Duration(seconds: 120));
    expect(e.state!.totalVolume, 720);
  });
}
