import '../data/models.dart';

double setVolume(SetLog s) => s.reps * s.weightKg;

double sessionVolume(WorkoutSession s) =>
    s.sets.fold(0.0, (a, x) => a + setVolume(x));

/// Epley formülü ile tahmini 1 tekrar maksimumu.
double estimateOneRm(SetLog s) {
  if (s.weightKg <= 0) return 0;
  if (s.reps <= 1) return s.weightKg;
  return s.weightKg * (1 + s.reps / 30);
}

class HrSummary {
  const HrSummary(this.avg, this.peak);
  final int avg;
  final int peak;
}

/// Setlerdeki nabız değerlerinden ortalama ve tepe. Hiç yoksa null.
HrSummary? sessionHr(List<SetLog> sets) {
  final avgs = [
    for (final s in sets)
      if (s.avgHr != null) s.avgHr!,
  ];
  final peaks = [
    for (final s in sets)
      if (s.peakHr != null) s.peakHr!,
  ];
  if (avgs.isEmpty && peaks.isEmpty) return null;
  final avg = avgs.isEmpty
      ? 0
      : (avgs.reduce((a, b) => a + b) / avgs.length).round();
  final peak = peaks.isEmpty ? 0 : peaks.reduce((a, b) => a > b ? a : b);
  return HrSummary(avg, peak);
}

/// Önceki en iyi ağırlığı aşıyorsa kişisel rekor. İlk kez yapılan hareket rekor sayılmaz.
bool isPersonalRecord(SetLog s, {required double? previousBestKg}) =>
    previousBestKg != null && s.weightKg > 0 && s.weightKg > previousBestKg;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Son [weeks] haftanın toplam hacmi, eskiden yeniye (son eleman içinde bulunulan hafta).
List<double> weeklyVolume(
  List<WorkoutSession> sessions,
  DateTime now, {
  int weeks = 4,
}) {
  final today = _day(now);
  final thisMonday = today.subtract(Duration(days: today.weekday - 1));
  final out = List<double>.filled(weeks, 0);
  for (final s in sessions) {
    final d = _day(s.startedAt);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    final diffWeeks = thisMonday.difference(monday).inDays ~/ 7;
    if (diffWeeks >= 0 && diffWeeks < weeks) {
      out[weeks - 1 - diffWeeks] += sessionVolume(s);
    }
  }
  return out;
}

/// Bugün ya da dünden geriye doğru ardışık antrenman günü sayısı.
int workoutStreak(List<WorkoutSession> sessions, DateTime now) {
  final days = {for (final s in sessions) _day(s.startedAt)};
  var d = _day(now);
  if (!days.contains(d)) d = d.subtract(const Duration(days: 1));
  var n = 0;
  while (days.contains(d)) {
    n++;
    d = d.subtract(const Duration(days: 1));
  }
  return n;
}

/// Kuvvet antrenmanı enerji tahmini: MET x kilo x saat. Nabız varsa MET ayarlanır.
int estimateWorkoutKcal(Duration d, double weightKg, {int? avgHr}) {
  final met = avgHr == null ? 5.0 : (3.5 + (avgHr - 90) * 0.04).clamp(3.0, 9.0);
  return (met * weightKg * d.inSeconds / 3600).round();
}

int routineSetCount(Routine r) => r.items.fold(0, (a, i) => a + i.sets.length);

/// Tahmini süre (dk): set başına 45 sn çalışma + egzersizin mola süresi.
int routineEstimatedMinutes(Routine r) {
  final secs = r.items.fold<int>(
    0,
    (a, i) => a + i.sets.length * (45 + i.restSec),
  );
  return (secs / 60).floor();
}

/// Ortalama hedef tekrara göre rutin amacı.
String routineGoal(Routine r) {
  final reps = [
    for (final i in r.items)
      for (final s in i.sets) s.reps,
  ];
  if (reps.isEmpty) return 'Genel';
  final avg = reps.reduce((a, b) => a + b) / reps.length;
  if (avg <= 5) return 'Kuvvet';
  if (avg <= 12) return 'Hipertrofi';
  return 'Dayanıklılık';
}

/// Planlanan toplam hacim (kg).
double routineVolume(Routine r) => r.items.fold(
  0.0,
  (a, i) => a + i.sets.fold(0.0, (b, s) => b + s.reps * s.weightKg),
);
