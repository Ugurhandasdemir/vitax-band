import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/core/hr_detect.dart';

final _t0 = DateTime(2026, 10, 24, 18, 0, 0);

/// (saniye, bpm) çiftlerinden örnek listesi.
List<HrPoint> series(List<(int, int)> v) => [
  for (final (s, b) in v) HrPoint(_t0.add(Duration(seconds: s)), b),
];

void main() {
  group('set başlangıcı: nabız yükseliyor', () {
    test('düz nabız öneri üretmez', () {
      final s = series([for (var i = 0; i <= 30; i += 5) (i, 80)]);
      expect(
        detectHrTrend(
          s,
          _t0.add(const Duration(seconds: 30)),
          setRunning: false,
        ),
        isNull,
      );
    });

    test('30 sn içinde +20 ve ≥100 bpm -> setStarted', () {
      final s = series([(0, 85), (10, 92), (20, 100), (30, 108)]);
      final r = detectHrTrend(
        s,
        _t0.add(const Duration(seconds: 30)),
        setRunning: false,
      );
      expect(r, HrSuggestion.setStarted);
    });

    test('yükselme var ama nabız 100 altındaysa öneri yok (yürüme/sakin)', () {
      final s = series([(0, 70), (10, 78), (20, 86), (30, 92)]);
      expect(
        detectHrTrend(
          s,
          _t0.add(const Duration(seconds: 30)),
          setRunning: false,
        ),
        isNull,
      );
    });

    test('yavaş yükseliş (15 bpm altı) öneri üretmez', () {
      final s = series([(0, 100), (15, 106), (30, 112)]);
      expect(
        detectHrTrend(
          s,
          _t0.add(const Duration(seconds: 30)),
          setRunning: false,
        ),
        isNull,
      );
    });

    test('set zaten çalışıyorsa setStarted önerilmez', () {
      final s = series([(0, 85), (10, 92), (20, 100), (30, 108)]);
      expect(
        detectHrTrend(
          s,
          _t0.add(const Duration(seconds: 30)),
          setRunning: true,
        ),
        isNull,
      );
    });
  });

  group('dinlenme başlangıcı: nabız düşüyor', () {
    test('set sırasında tepeden -12 düşüş -> restStarted', () {
      final s = series([(0, 130), (10, 146), (20, 140), (30, 132)]);
      final r = detectHrTrend(
        s,
        _t0.add(const Duration(seconds: 30)),
        setRunning: true,
      );
      expect(r, HrSuggestion.restStarted);
    });

    test('küçük düşüş (12 altı) öneri üretmez', () {
      final s = series([(0, 140), (10, 145), (20, 142), (30, 138)]);
      expect(
        detectHrTrend(
          s,
          _t0.add(const Duration(seconds: 30)),
          setRunning: true,
        ),
        isNull,
      );
    });

    test('set çalışmıyorsa restStarted önerilmez', () {
      final s = series([(0, 130), (10, 146), (20, 140), (30, 132)]);
      expect(
        detectHrTrend(
          s,
          _t0.add(const Duration(seconds: 30)),
          setRunning: false,
        ),
        isNull,
      );
    });
  });

  group('veri kalitesi', () {
    test('3 örnekten azsa öneri yok', () {
      final s = series([(20, 90), (30, 120)]);
      expect(
        detectHrTrend(
          s,
          _t0.add(const Duration(seconds: 30)),
          setRunning: false,
        ),
        isNull,
      );
    });

    test('son örnek 10 sn\'den eskiyse öneri yok (bağlantı koptu)', () {
      final s = series([(0, 85), (5, 95), (10, 110)]);
      expect(
        detectHrTrend(
          s,
          _t0.add(const Duration(seconds: 40)),
          setRunning: false,
        ),
        isNull,
      );
    });

    test('bant takılı değil değerleri (0,1,2) ve geçersizler yok sayılır', () {
      final s = series([
        (0, 0),
        (5, 1),
        (10, 2),
        (15, 88),
        (20, 96),
        (25, 104),
        (30, 110),
      ]);
      expect(
        detectHrTrend(
          s,
          _t0.add(const Duration(seconds: 30)),
          setRunning: false,
        ),
        HrSuggestion.setStarted,
      );
    });
  });

  group('set özeti ve toparlanma', () {
    test('aralıktaki ortalama ve tepe', () {
      final s = series([(0, 100), (10, 120), (20, 140), (30, 130), (40, 90)]);
      final h = summarizeHr(
        s,
        _t0.add(const Duration(seconds: 5)),
        _t0.add(const Duration(seconds: 35)),
      );
      expect(h!.avg, 130); // 120,140,130
      expect(h.peak, 140);
    });

    test('aralıkta örnek yoksa null', () {
      final s = series([(0, 100)]);
      expect(
        summarizeHr(
          s,
          _t0.add(const Duration(seconds: 10)),
          _t0.add(const Duration(seconds: 20)),
        ),
        isNull,
      );
    });

    test('toparlanma: tepe - 60 sn sonraki nabız', () {
      final s = series([(0, 150), (30, 140), (60, 126), (65, 124)]);
      expect(recoveryDrop(s, peak: 150, endedAt: _t0), 24); // t=60: 126
    });

    test('60 sn sonrası örnek yoksa null', () {
      final s = series([(0, 150), (30, 140)]);
      expect(recoveryDrop(s, peak: 150, endedAt: _t0), isNull);
    });

    test('toparlanma negatif olmaz', () {
      final s = series([(0, 100), (60, 120)]);
      expect(recoveryDrop(s, peak: 100, endedAt: _t0), 0);
    });
  });

  group('nabız bölgeleri', () {
    test('%max nabız eşikleri', () {
      // maks 190 (220-30): z1<%60=114, z2<%70=133, z3<%80=152, z4<%90=171, z5
      expect(hrZone(100, maxHr: 190), 1);
      expect(hrZone(120, maxHr: 190), 2);
      expect(hrZone(140, maxHr: 190), 3);
      expect(hrZone(160, maxHr: 190), 4);
      expect(hrZone(180, maxHr: 190), 5);
    });
    test('maksimum nabız 220-yaş', () => expect(maxHrForAge(30), 190));
  });
}
