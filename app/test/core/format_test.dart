import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/core/format.dart';

void main() {
  group('formatTr (Türkçe binlik ayracı)', () {
    test('binlik nokta', () {
      expect(formatTr(1420), '1.420');
      expect(formatTr(2100), '2.100');
      expect(formatTr(8432), '8.432');
      expect(formatTr(1234567), '1.234.567');
    });
    test('küçük sayılar ve sıfır', () {
      expect(formatTr(0), '0');
      expect(formatTr(999), '999');
    });
    test('negatif', () {
      expect(formatTr(-1420), '-1.420');
    });
  });

  group('ondalık', () {
    test('virgül kullanır', () {
      expect(formatDecimalTr(76.4), '76,4');
      expect(formatDecimalTr(2.5), '2,5');
      expect(formatDecimalTr(72, digits: 1), '72,0');
    });
  });

  group('süre', () {
    test('saat ve dakika', () {
      expect(formatHm(const Duration(hours: 7, minutes: 12)), '7s 12dk');
      expect(formatHm(const Duration(minutes: 45)), '45dk');
    });
    test('saat:dakika:saniye kronometre', () {
      expect(formatClock(const Duration(minutes: 24, seconds: 15)), '24:15');
      expect(
        formatClock(const Duration(hours: 1, minutes: 2, seconds: 3)),
        '1:02:03',
      );
    });
  });

  group('tarih', () {
    test('gün ve ay adı', () {
      expect(formatDayMonth(DateTime(2026, 10, 24)), '24 Ekim');
      expect(formatDayMonth(DateTime(2026, 1, 5)), '5 Ocak');
    });
    test('kısa gün adı büyük harf', () {
      // 24 Ekim 2026 Cumartesi
      expect(shortWeekday(DateTime(2026, 10, 24)), 'CMT');
      expect(shortWeekday(DateTime(2026, 10, 19)), 'PZT');
      expect(shortWeekday(DateTime(2026, 10, 25)), 'PAZ');
    });
  });

  group('su', () {
    test('ml litreye', () {
      expect(formatLiters(1200), '1,2');
      expect(formatLiters(2500), '2,5');
      expect(formatLiters(3000), '3');
      expect(formatLiters(0), '0');
    });
  });

  group('göreli zaman', () {
    test('az önce, dakika, saat, gün', () {
      expect(formatAgo(const Duration(seconds: 20)), 'az önce');
      expect(formatAgo(const Duration(minutes: 2)), '2 dk önce');
      expect(formatAgo(const Duration(minutes: 125)), '2 sa önce');
      expect(formatAgo(const Duration(hours: 50)), '2 gün önce');
    });
  });

  group('tarih (uzun gün / kısa ay)', () {
    test('kısa ay', () {
      expect(formatDayShortMonth(DateTime(2026, 10, 24)), '24 Eki');
      expect(formatDayShortMonth(DateTime(2026, 9, 5)), '5 Eyl');
      expect(formatDayShortMonth(DateTime(2026, 1, 1)), '1 Oca');
    });
    test('Türkçe gün adı', () {
      expect(weekdayName(DateTime(2026, 10, 24)), 'Cumartesi');
      expect(weekdayName(DateTime(2026, 10, 21)), 'Çarşamba');
      expect(weekdayName(DateTime(2026, 10, 25)), 'Pazar');
    });
    test('saat:dakika', () {
      expect(formatClockTime(DateTime(2026, 10, 24, 7, 5)), '07:05');
      expect(formatClockTime(DateTime(2026, 10, 24, 14, 30)), '14:30');
    });
  });

  group('Türkçe büyük harf', () {
    test('i -> İ ve ı -> I', () {
      expect(upperTr('Ekim'), 'EKİM');
      expect(upperTr('Perşembe'), 'PERŞEMBE');
      expect(upperTr('Çarşamba'), 'ÇARŞAMBA');
      expect(upperTr('ıspanak'), 'ISPANAK');
    });
  });

  group('takvim günü farkı', () {
    final now = DateTime(2026, 10, 24, 14, 30);
    test('bugün, dün, N gün önce (saate değil takvim gününe bakar)', () {
      expect(formatDaysAgo(now, DateTime(2026, 10, 24, 6)), 'Bugün');
      expect(formatDaysAgo(now, DateTime(2026, 10, 23, 23, 59)), 'Dün');
      expect(formatDaysAgo(now, DateTime(2026, 10, 21, 18)), '3 gün önce');
      expect(formatDaysAgo(now, DateTime(2026, 9, 24)), '30 gün önce');
    });
  });
}
