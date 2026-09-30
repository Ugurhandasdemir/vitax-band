import 'workout_calc.dart';

/// Zaman damgalı nabız örneği (bant ~1 Hz verir).
class HrPoint {
  const HrPoint(this.at, this.bpm);
  final DateTime at;
  final int bpm;
}

enum HrSuggestion { setStarted, restStarted }

bool _valid(int bpm) => bpm >= 30 && bpm <= 210;

List<HrPoint> _clean(List<HrPoint> s, DateTime now) =>
    (s.where((p) => _valid(p.bpm) && !p.at.isAfter(now)).toList()
      ..sort((a, b) => a.at.compareTo(b.at)));

/// Nabız eğiliminden set başlangıcı/bitişi önerisi. Öneri kesin kayıt değildir,
/// kullanıcı onaylar. Bilek nabzı gerçek değişimden 10-30 sn geç kalabilir.
///
/// - [setRunning] false: son [riseWindow] içinde [riseBpm] artış ve nabız ≥ [minWorkBpm]
///   -> [HrSuggestion.setStarted]
/// - [setRunning] true: son [dropWindow] tepesinden [dropBpm] düşüş
///   -> [HrSuggestion.restStarted]
HrSuggestion? detectHrTrend(
  List<HrPoint> samples,
  DateTime now, {
  required bool setRunning,
  int riseBpm = 15,
  Duration riseWindow = const Duration(seconds: 30),
  int minWorkBpm = 100,
  int dropBpm = 12,
  Duration dropWindow = const Duration(seconds: 30),
  Duration staleAfter = const Duration(seconds: 10),
}) {
  final v = _clean(samples, now);
  if (v.length < 3) return null;
  final last = v.last;
  if (now.difference(last.at) > staleAfter) return null;

  if (!setRunning) {
    final win = v
        .where((p) => !p.at.isBefore(now.subtract(riseWindow)))
        .toList();
    if (win.length < 3) return null;
    final lowest = win.map((p) => p.bpm).reduce((a, b) => a < b ? a : b);
    if (last.bpm - lowest >= riseBpm && last.bpm >= minWorkBpm) {
      return HrSuggestion.setStarted;
    }
    return null;
  }
  final win = v.where((p) => !p.at.isBefore(now.subtract(dropWindow))).toList();
  if (win.length < 3) return null;
  final highest = win.map((p) => p.bpm).reduce((a, b) => a > b ? a : b);
  if (highest - last.bpm >= dropBpm) return HrSuggestion.restStarted;
  return null;
}

/// [from]..[to] (dahil) aralığındaki geçerli örneklerin ortalaması ve tepesi.
HrSummary? summarizeHr(List<HrPoint> samples, DateTime from, DateTime to) {
  final v = samples
      .where((p) => _valid(p.bpm) && !p.at.isBefore(from) && !p.at.isAfter(to))
      .toList();
  if (v.isEmpty) return null;
  final sum = v.fold<int>(0, (a, p) => a + p.bpm);
  final peak = v.map((p) => p.bpm).reduce((a, b) => a > b ? a : b);
  return HrSummary((sum / v.length).round(), peak);
}

/// Set bitiminden 60 sn sonraki nabız düşüşü (tepe - o andaki nabız). ±5 sn içinde
/// örnek yoksa null.
int? recoveryDrop(
  List<HrPoint> samples, {
  required int peak,
  required DateTime endedAt,
  Duration after = const Duration(seconds: 60),
  Duration tolerance = const Duration(seconds: 5),
}) {
  final target = endedAt.add(after);
  HrPoint? best;
  for (final p in samples) {
    if (!_valid(p.bpm)) continue;
    final d = p.at.difference(target).abs();
    if (d <= tolerance &&
        (best == null || d < best.at.difference(target).abs())) {
      best = p;
    }
  }
  if (best == null) return null;
  final drop = peak - best.bpm;
  return drop < 0 ? 0 : drop;
}

int maxHrForAge(int age) => 220 - age;

/// Nabız bölgesi 1-5 (maksimum nabzın yüzdesine göre: %60/%70/%80/%90).
int hrZone(int bpm, {required int maxHr}) {
  final r = bpm / maxHr;
  if (r < 0.6) return 1;
  if (r < 0.7) return 2;
  if (r < 0.8) return 3;
  if (r < 0.9) return 4;
  return 5;
}
