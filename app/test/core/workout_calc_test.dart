import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/core/workout_calc.dart';
import 'package:vitax_app/data/models.dart';

SetLog _s(int reps, double kg, {int min = 0, int? avg, int? peak, int? rec}) =>
    SetLog(
      exerciseId: '0001',
      setNo: 1,
      reps: reps,
      weightKg: kg,
      startedAt: DateTime(2026, 10, 24, 18, min),
      endedAt: DateTime(2026, 10, 24, 18, min, 40),
      avgHr: avg,
      peakHr: peak,
      recoveryBpm: rec,
    );

WorkoutSession _sess(int day, List<SetLog> sets, {int dur = 45}) =>
    WorkoutSession(
      id: day,
      name: 'S$day',
      startedAt: DateTime(2026, 10, day, 18),
      endedAt: DateTime(2026, 10, day, 18, dur),
      sets: sets,
    );

void main() {
  group('hacim', () {
    test('set hacmi = tekrar x kg', () => expect(setVolume(_s(10, 60)), 600));
    test('seans hacmi setlerin toplamı', () {
      expect(sessionVolume(_sess(24, [_s(10, 60), _s(8, 80)])), 600 + 640);
    });
    test('vücut ağırlığı (0 kg) hacme sıfır katar', () {
      expect(setVolume(_s(15, 0)), 0);
    });
  });

  group('1 tekrar maksimumu (Epley)', () {
    test('tek tekrar = ağırlık', () => expect(estimateOneRm(_s(1, 100)), 100));
    test(
      '5 tekrar x 100 kg ≈ 116.7',
      () => expect(estimateOneRm(_s(5, 100)), closeTo(116.7, 0.1)),
    );
    test('0 kg için 0', () => expect(estimateOneRm(_s(10, 0)), 0));
  });

  group('nabız özeti', () {
    test('ortalama ve tepe, olmayan değerler atlanır', () {
      final sets = [
        _s(10, 60, avg: 120, peak: 140),
        _s(10, 60, avg: 130, peak: 148),
        _s(10, 60),
      ];
      final h = sessionHr(sets);
      expect(h!.avg, 125);
      expect(h.peak, 148);
    });
    test('hiç nabız yoksa null', () => expect(sessionHr([_s(10, 60)]), isNull));
  });

  group('kişisel rekor', () {
    test('önceki en iyi ağırlıktan fazlaysa rekor', () {
      expect(isPersonalRecord(_s(5, 100), previousBestKg: 90), isTrue);
      expect(isPersonalRecord(_s(5, 90), previousBestKg: 90), isFalse);
    });
    test('ilk kez yapılıyorsa rekor sayılmaz', () {
      expect(isPersonalRecord(_s(5, 100), previousBestKg: null), isFalse);
    });
    test('vücut ağırlığı hareketi (0 kg) rekor olmaz', () {
      expect(isPersonalRecord(_s(20, 0), previousBestKg: 0), isFalse);
    });
  });

  group('haftalık hacim ve seri', () {
    final now = DateTime(2026, 10, 24, 12); // Cumartesi
    test('haftalık hacim: son 4 hafta, eskiden yeniye', () {
      final sessions = [
        _sess(22, [_s(10, 60)]), // bu hafta (19-25): 600
        _sess(20, [_s(10, 50)]), // bu hafta: 500
        _sess(14, [_s(10, 40)]), // geçen hafta (12-18): 400
      ];
      final w = weeklyVolume(sessions, now, weeks: 4);
      expect(w, hasLength(4));
      expect(w[3], 1100);
      expect(w[2], 400);
      expect(w[1], 0);
      expect(w[0], 0);
    });

    test('seri: ardışık antrenman günleri', () {
      final sessions = [
        _sess(24, []),
        _sess(23, []),
        _sess(22, []),
        _sess(20, []),
      ];
      expect(workoutStreak(sessions, now), 3);
    });

    test('bugün yoksa dünden sayar', () {
      final sessions = [_sess(23, []), _sess(22, [])];
      expect(workoutStreak(sessions, now), 2);
    });

    test('dünden önceyse seri sıfırlanır', () {
      expect(workoutStreak([_sess(21, [])], now), 0);
    });

    test('aynı gün iki seans tek gün sayılır', () {
      expect(workoutStreak([_sess(24, []), _sess(24, [])], now), 1);
    });
  });

  group('antrenman süresi ve kalori', () {
    test('kcal: MET x kilo x saat (kuvvet antrenmanı MET 5)', () {
      // 60 dk, 80 kg -> 5 * 80 * 1 = 400
      expect(estimateWorkoutKcal(const Duration(minutes: 60), 80), 400);
    });
    test(
      'nabız varsa ortalama nabıza göre ayarlanır (yüksek nabız daha fazla)',
      () {
        final low = estimateWorkoutKcal(
          const Duration(minutes: 60),
          80,
          avgHr: 100,
        );
        final high = estimateWorkoutKcal(
          const Duration(minutes: 60),
          80,
          avgHr: 150,
        );
        expect(high, greaterThan(low));
      },
    );
  });

  group('rutin özeti', () {
    final r = Routine(
      name: 'Push',
      items: [
        RoutineItem.uniform(
          exerciseId: 'a',
          sets: 4,
          reps: 8,
          weightKg: 80,
          restSec: 90,
        ),
        RoutineItem.uniform(
          exerciseId: 'b',
          sets: 3,
          reps: 12,
          weightKg: 20,
          restSec: 60,
        ),
      ],
    );
    test('toplam set', () => expect(routineSetCount(r), 7));
    test('tahmini süre: set başına 45 sn + mola', () {
      // a: 4*(45+90)=540 ; b: 3*(45+60)=315 ; toplam 855 sn = 14.25 dk -> 14
      expect(routineEstimatedMinutes(r), 14);
    });
    test('boş rutin 0 dk ve 0 set', () {
      const e = Routine(name: 'Boş', items: []);
      expect(routineEstimatedMinutes(e), 0);
      expect(routineSetCount(e), 0);
    });
    test('hedef etiketi ortalama tekrara göre', () {
      Routine withReps(int reps) => Routine(
        name: 'x',
        items: [
          RoutineItem.uniform(
            exerciseId: 'a',
            sets: 3,
            reps: reps,
            weightKg: 50,
          ),
        ],
      );
      expect(routineGoal(withReps(4)), 'Kuvvet');
      expect(routineGoal(withReps(8)), 'Hipertrofi');
      expect(routineGoal(withReps(15)), 'Dayanıklılık');
      expect(routineGoal(const Routine(name: 'e', items: [])), 'Genel');
    });
    test('rutin hacmi plan ağırlık x tekrar toplamı', () {
      expect(routineVolume(r), 4 * 8 * 80 + 3 * 12 * 20);
    });
  });
}
