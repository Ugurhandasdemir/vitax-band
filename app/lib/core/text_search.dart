/// Türkçe harflerden bağımsız, büyük/küçük harf duyarsız arama için normalleştirme.
/// "ISPANAK", "ıspanak" ve "Ispanak" aynı sonucu verir.
String normalizeTr(String s) {
  final b = StringBuffer();
  for (final r in s.trim().runes) {
    final c = String.fromCharCode(r);
    b.write(switch (c) {
      'İ' || 'I' || 'ı' || 'î' => 'i',
      'Ş' || 'ş' => 's',
      'Ğ' || 'ğ' => 'g',
      'Ü' || 'ü' || 'û' => 'u',
      'Ö' || 'ö' => 'o',
      'Ç' || 'ç' => 'c',
      'â' || 'Â' => 'a',
      _ => c.toLowerCase(),
    });
  }
  return b.toString();
}
