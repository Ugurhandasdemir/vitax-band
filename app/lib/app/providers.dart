import 'package:flutter/material.dart' show DateUtils;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/nutrition_calc.dart';
import '../data/band/band_controller.dart';
import '../data/band/band_transport.dart';
import '../data/band/offline_band_transport.dart';
import '../data/models.dart';
import '../data/repos/band_sample_repository.dart';
import '../data/repos/nutrition_repository.dart';
import '../data/repos/settings_repository.dart';
import '../data/repos/workout_repository.dart';

/// Bant taşıyıcısı. Varsayılan: bant yok. main.dart gerçek BLE ile değiştirir.
final bandTransportProvider = Provider<BandTransport>(
  (ref) => OfflineBandTransport(),
);

final bandControllerProvider = Provider<BandController>((ref) {
  final c = BandController(
    transport: ref.watch(bandTransportProvider),
    repo: ref.watch(bandSampleRepositoryProvider),
    clock: ref.watch(clockProvider),
  );
  ref.onDispose(c.dispose);
  return c;
});

/// Şimdiki zaman. Testlerde sabitlenir.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Varsayılanlar bellek içi; main.dart gerçek SQLite ile değiştirir.
final nutritionRepositoryProvider = Provider<NutritionRepository>(
  (ref) => InMemoryNutritionRepository(),
);
final bandSampleRepositoryProvider = Provider<BandSampleRepository>(
  (ref) => InMemoryBandSampleRepository(),
);
final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => InMemoryWorkoutRepository(),
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => InMemorySettingsRepository(),
);

class SelectedDay extends Notifier<DateTime> {
  @override
  DateTime build() {
    final n = ref.read(clockProvider)();
    return DateTime(n.year, n.month, n.day);
  }

  void set(DateTime d) => state = DateTime(d.year, d.month, d.day);
}

final selectedDayProvider = NotifierProvider<SelectedDay, DateTime>(
  SelectedDay.new,
);

final profileProvider = FutureProvider<Profile>(
  (ref) => ref.watch(settingsRepositoryProvider).loadProfile(),
);

final dayFoodProvider = FutureProvider.family<List<FoodEntry>, DateTime>(
  (ref, day) => ref.watch(nutritionRepositoryProvider).foodForDay(day),
);

final dayTotalsProvider = FutureProvider.family<DayTotals, DateTime>(
  (ref, day) => ref.watch(nutritionRepositoryProvider).totalsForDay(day),
);

final waterProvider = FutureProvider.family<int, DateTime>(
  (ref, day) => ref.watch(nutritionRepositoryProvider).waterForDay(day),
);

final waterEntriesProvider = FutureProvider.family<List<WaterEntry>, DateTime>(
  (ref, day) => ref.watch(nutritionRepositoryProvider).waterEntries(day),
);

/// [monday] gününden başlayan 7 günün su toplamları.
final waterWeekProvider = FutureProvider.family<List<int>, DateTime>(
  (ref, monday) => ref.watch(nutritionRepositoryProvider).waterDaily(monday, 7),
);

final stepsProvider = FutureProvider.family<int, DateTime>(
  (ref, day) => ref.watch(bandSampleRepositoryProvider).stepsForDay(day),
);

final latestHrProvider = FutureProvider<HrSample?>(
  (ref) => ref.watch(bandSampleRepositoryProvider).latestHr(),
);

/// Dün geceki uyku süresi. Faz 3'te bant uyku verisiyle dolacak.
final lastNightSleepProvider = FutureProvider<Duration?>((ref) async => null);

/// Bantın gönderdiği tek nabız okuması. Bilerek `==` tanımlı değil: art arda gelen
/// aynı değerler (72, 72) de dinleyiciyi tetiklemeli.
class HrReading {
  HrReading(this.bpm);
  final int bpm;
}

/// Bant canlı nabız akışı (~1 Hz), [BandController] üzerinden.
final liveHrProvider = StreamProvider<HrReading>(
  (ref) => ref.watch(bandControllerProvider).liveHr.map(HrReading.new),
);

/// Bant kalori vermez: adımdan tahmin edilir.
final burnedKcalProvider = FutureProvider.family<int, DateTime>((
  ref,
  day,
) async {
  final steps = await ref.watch(stepsProvider(day).future);
  final profile = await ref.watch(profileProvider.future);
  return estimateStepKcal(steps: steps, weightKg: profile.weightKg);
});

class EnergySummary {
  const EnergySummary({
    required this.eaten,
    required this.goal,
    required this.burned,
  });
  final int eaten;
  final int goal;
  final int burned;
  int get remaining => remainingKcal(goal: goal, eaten: eaten);
  int get net => netCalories(eaten: eaten, burned: burned);
}

final energySummaryProvider = FutureProvider.family<EnergySummary, DateTime>((
  ref,
  day,
) async {
  final totals = await ref.watch(dayTotalsProvider(day).future);
  final profile = await ref.watch(profileProvider.future);
  final burned = await ref.watch(burnedKcalProvider(day).future);
  return EnergySummary(
    eaten: totals.kcal,
    goal: profile.kcalGoal,
    burned: burned,
  );
});

/// AI koç günlük özeti (Faz 5'te dolacak). Null = henüz yeterli veri yok.
class CoachBriefing {
  const CoachBriefing({
    this.readiness,
    required this.plan,
    required this.insight,
  });
  final int? readiness;
  final String plan;
  final String insight;
}

final coachBriefingProvider = FutureProvider<CoachBriefing?>(
  (ref) async => null,
);

enum WeightRange {
  d7(7, '7G'),
  d30(30, '30G'),
  d90(90, '90G'),
  y1(365, '1 Yıl');

  const WeightRange(this.days, this.label);
  final int days;
  final String label;
}

final weightSeriesProvider =
    FutureProvider.family<List<WeightPoint>, WeightRange>((ref, range) {
      final now = ref.watch(clockProvider)();
      return ref
          .watch(nutritionRepositoryProvider)
          .weightSeries(
            now.subtract(Duration(days: range.days)),
            now.add(const Duration(days: 1)),
          );
    });

final latestWeightProvider = FutureProvider<WeightPoint?>(
  (ref) => ref.watch(nutritionRepositoryProvider).latestWeight(),
);

final weightActionsProvider = Provider<WeightActions>(
  (ref) => WeightActions(ref),
);

class WeightActions {
  WeightActions(this._ref);
  final Ref _ref;

  /// Kiloyu kaydeder (gün başına tek kayıt). Geçersizse false döner.
  Future<bool> logWeight(double kg) async {
    if (kg < 30 || kg > 300) return false;
    final repo = _ref.read(nutritionRepositoryProvider);
    final now = _ref.read(clockProvider)();
    final first = await repo.weightSeries(
      DateTime(2000),
      now.add(const Duration(days: 1)),
    );
    await repo.logWeight(now, kg);
    final profile = await _ref.read(profileProvider.future);
    final start = profile.startWeightKg > 0
        ? profile.startWeightKg
        : (first.isEmpty ? kg : first.first.kg);
    await _ref
        .read(settingsRepositoryProvider)
        .saveProfile(profile.copyWith(weightKg: kg, startWeightKg: start));
    _ref.invalidate(profileProvider);
    _ref.invalidate(latestWeightProvider);
    for (final r in WeightRange.values) {
      _ref.invalidate(weightSeriesProvider(r));
    }
    return true;
  }
}

/// [range] = (başlangıç günü, gün sayısı). Gün gün alınan kalori ve toplam harcama.
final energyRangeProvider =
    FutureProvider.family<List<DayEnergy>, (DateTime, int)>((ref, range) async {
      final (start, days) = range;
      final nutrition = ref.watch(nutritionRepositoryProvider);
      final band = ref.watch(bandSampleRepositoryProvider);
      final profile = await ref.watch(profileProvider.future);
      final intake = await nutrition.kcalDaily(start, days);
      final steps = await band.stepsDaily(start, days);
      return [
        for (var i = 0; i < days; i++)
          DayEnergy(
            day: DateTime(start.year, start.month, start.day + i),
            intake: intake[i],
            burn: dailyBurnKcal(profile, steps[i]),
          ),
      ];
    });

/// Profil ve hedef yazma işlemleri.
final profileActionsProvider = Provider<ProfileActions>(
  (ref) => ProfileActions(ref),
);

class ProfileActions {
  ProfileActions(this._ref);
  final Ref _ref;

  Future<void> save(Profile p) async {
    await _ref.read(settingsRepositoryProvider).saveProfile(p);
    _ref.invalidate(profileProvider);
  }
}

/// Yazma işlemleri: repo'ya yazar, ilgili sağlayıcıları yeniler.
final nutritionActionsProvider = Provider<NutritionActions>(
  (ref) => NutritionActions(ref),
);

class NutritionActions {
  NutritionActions(this._ref);
  final Ref _ref;

  NutritionRepository get _repo => _ref.read(nutritionRepositoryProvider);

  void _refresh(DateTime day) {
    _ref.invalidate(dayFoodProvider(day));
    _ref.invalidate(dayTotalsProvider(day));
    _ref.invalidate(energySummaryProvider(day));
    _ref.invalidate(waterProvider(day));
    _ref.invalidate(waterEntriesProvider(day));
    final monday = day.subtract(Duration(days: day.weekday - 1));
    _ref.invalidate(
      waterWeekProvider(DateTime(monday.year, monday.month, monday.day)),
    );
  }

  Future<int> addFood(FoodEntry e) async {
    final id = await _repo.addFood(e);
    _refresh(e.date);
    return id;
  }

  Future<void> deleteFood(FoodEntry e) async {
    if (e.id == null) return;
    await _repo.deleteFood(e.id!);
    _refresh(e.date);
  }

  /// Silmeyi geri al: yeni id ile sona eklenir.
  Future<void> restoreFood(FoodEntry e) async {
    await _repo.addFood(e.copyWith(id: null));
    _refresh(e.date);
  }

  Future<int> copyDay(DateTime from, DateTime to) async {
    final n = await _repo.copyDay(from, to);
    _refresh(to);
    return n;
  }

  /// Bugünse saat şimdiki zaman, başka günse öğlen 12:00 olarak kaydedilir.
  Future<int> addWater(DateTime day, int ml, {String? label}) async {
    final now = _ref.read(clockProvider)();
    final at = DateUtils.isSameDay(day, now)
        ? now
        : DateTime(day.year, day.month, day.day, 12);
    final id = await _repo.addWater(day, ml, at: at, label: label);
    _refresh(day);
    return id;
  }

  Future<void> deleteWater(WaterEntry e) async {
    if (e.id == null) return;
    await _repo.deleteWater(e.id!);
    _refresh(DateTime(e.at.year, e.at.month, e.at.day));
  }
}
