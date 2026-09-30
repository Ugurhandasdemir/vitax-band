// Türkçe biçimlendirme yardımcıları (binlik nokta, ondalık virgül, tarih).

String formatTr(int n) {
  final neg = n < 0;
  final s = n.abs().toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return neg ? '-$b' : b.toString();
}

String formatDecimalTr(double v, {int digits = 1}) =>
    v.toStringAsFixed(digits).replaceAll('.', ',');

String formatHm(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  return h > 0 ? '${h}s ${m}dk' : '${m}dk';
}

String formatClock(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours;
  final m = d.inMinutes % 60;
  final s = d.inSeconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}

const _months = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

String formatDayMonth(DateTime d) => '${d.day} ${_months[d.month - 1]}';

const _weekdays = ['PZT', 'SAL', 'ÇAR', 'PER', 'CUM', 'CMT', 'PAZ'];

String shortWeekday(DateTime d) => _weekdays[d.weekday - 1];

/// 1200 ml -> "1,2"; 3000 ml -> "3"
String formatLiters(int ml) =>
    ml % 1000 == 0 ? '${ml ~/ 1000}' : formatDecimalTr(ml / 1000);

/// "2 dk önce", "3 sa önce" gibi göreli zaman.
String formatAgo(Duration d) {
  if (d.inMinutes < 1) return 'az önce';
  if (d.inMinutes < 60) return '${d.inMinutes} dk önce';
  if (d.inHours < 24) return '${d.inHours} sa önce';
  return '${d.inDays} gün önce';
}

const _shortMonths = [
  'Oca',
  'Şub',
  'Mar',
  'Nis',
  'May',
  'Haz',
  'Tem',
  'Ağu',
  'Eyl',
  'Eki',
  'Kas',
  'Ara',
];

/// 24 Ekim -> "24 Eki"
String formatDayShortMonth(DateTime d) =>
    '${d.day} ${_shortMonths[d.month - 1]}';

const _weekdayNames = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];

String weekdayName(DateTime d) => _weekdayNames[d.weekday - 1];

/// 07:05
String formatClockTime(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Türkçe büyük harf: "ekim" -> "EKİM", "ısı" -> "ISI".
String upperTr(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

/// Takvim günü farkı: "Bugün", "Dün", "3 gün önce".
String formatDaysAgo(DateTime now, DateTime then) {
  final d = DateTime(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime(then.year, then.month, then.day)).inDays;
  if (d <= 0) return 'Bugün';
  if (d == 1) return 'Dün';
  return '$d gün önce';
}
