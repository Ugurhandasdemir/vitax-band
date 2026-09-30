import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/band_sample_repository.dart';

/// Bandtan gelen ham verinin saklanması. Senkron tekrarlanabilir olmalı.
void bandSampleContract(
  String name,
  Future<BandSampleRepository> Function() create,
) {
  group('BandSampleRepository[$name]', () {
    late BandSampleRepository repo;
    final t0 = DateTime(2026, 10, 24, 10, 0, 0);

    HrSample hr(int sec, int bpm) => HrSample(
      at: t0.add(Duration(seconds: sec)),
      bpm: bpm,
    );

    setUp(() async => repo = await create());
    tearDown(() async => repo.close());

    test('nabız örnekleri kaydedilir ve aralıkla okunur (başlangıç dahil, bitiş hariç)', () async {
      await repo.insertHr([hr(0, 70), hr(1, 72), hr(2, 75), hr(3, 80)]);
      final r = await repo.hrBetween(
        t0.add(const Duration(seconds: 1)),
        t0.add(const Duration(seconds: 3)),
      );
      expect(r.map((s) => s.bpm), [72, 75]);
    });

    test('nabız zamana göre artan sırada döner', () async {
      await repo.insertHr([hr(5, 90), hr(1, 70), hr(3, 80)]);
      final r = await repo.hrBetween(t0, t0.add(const Duration(minutes: 1)));
      expect(r.map((s) => s.bpm), [70, 80, 90]);
    });

    test(
      'aynı zaman damgası tekrar eklenirse yinelenmez (idempotent senkron)',
      () async {
        await repo.insertHr([hr(0, 70), hr(1, 72)]);
        await repo.insertHr([hr(1, 72), hr(2, 75)]);
        final r = await repo.hrBetween(t0, t0.add(const Duration(minutes: 1)));
        expect(r.map((s) => s.bpm), [70, 72, 75]);
      },
    );

    test('latestHr en yeni örneği verir, boşsa null', () async {
      expect(await repo.latestHr(), isNull);
      await repo.insertHr([hr(0, 70), hr(9, 88)]);
      expect((await repo.latestHr())!.bpm, 88);
    });

    test('dinlenik nabız: günün geçerli örneklerinin alt yüzdeliği', () async {
      final samples = <HrSample>[
        for (var i = 0; i < 100; i++) hr(i, 60 + i), // 60..159
      ];
      await repo.insertHr(samples);
      final rest = await repo.restingHr(DateTime(2026, 10, 24));
      // alt %10 ortalaması: 60..69 => 64.5
      expect(rest, closeTo(64.5, 0.6));
    });

    test('dinlenik nabız: veri yoksa null', () async {
      expect(await repo.restingHr(DateTime(2026, 10, 24)), isNull);
    });

    test(
      'adım sayacı kaydedilir, gün içindeki adım = en büyük sayaç',
      () async {
        await repo.insertSteps([
          StepSample(at: t0, total: 294),
          StepSample(at: t0.add(const Duration(minutes: 5)), total: 344),
          StepSample(at: t0.add(const Duration(minutes: 9)), total: 420),
        ]);
        expect(await repo.stepsForDay(DateTime(2026, 10, 24)), 420);
        expect(await repo.stepsForDay(DateTime(2026, 10, 25)), 0);
      },
    );

    test(
      'adım sayacı gün sonunda sıfırlanırsa yeni gün kendi değerini alır',
      () async {
        await repo.insertSteps([
          StepSample(at: DateTime(2026, 10, 24, 23, 50), total: 9000),
          StepSample(at: DateTime(2026, 10, 25, 0, 10), total: 40),
        ]);
        expect(await repo.stepsForDay(DateTime(2026, 10, 24)), 9000);
        expect(await repo.stepsForDay(DateTime(2026, 10, 25)), 40);
      },
    );

    test('stepsDaily gün gün adım verir', () async {
      await repo.insertSteps([
        StepSample(at: DateTime(2026, 10, 24, 10), total: 500),
        StepSample(at: DateTime(2026, 10, 24, 20), total: 900),
        StepSample(at: DateTime(2026, 10, 26, 9), total: 100),
      ]);
      expect(await repo.stepsDaily(DateTime(2026, 10, 24), 4), [
        900,
        0,
        100,
        0,
      ]);
    });

    test('yinelenen adım örneği tekrar eklenmez', () async {
      final s = StepSample(at: t0, total: 294);
      await repo.insertSteps([s]);
      await repo.insertSteps([s]);
      expect(await repo.stepCount(), 1);
    });
  });
}
