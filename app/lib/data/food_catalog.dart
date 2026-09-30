import '../core/text_search.dart';

/// Yerleşik yiyecek kataloğu. Değerler yaklaşıktır (porsiyon başına),
/// gerçek ürün için barkod veya "Özel Yemek" kullanılmalıdır.
class FoodItem {
  const FoodItem(
    this.name,
    this.portion,
    this.kcal,
    this.protein,
    this.carbs,
    this.fat,
  );
  final String name;
  final String portion;
  final int kcal;
  final double protein;
  final double carbs;
  final double fat;

  Map<String, Object> toJson() => {
    'name': name,
    'portion': portion,
    'kcal': kcal,
    'protein': protein,
    'carbs': carbs,
    'fat': fat,
  };

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
    j['name'] as String,
    j['portion'] as String,
    (j['kcal'] as num).toInt(),
    (j['protein'] as num).toDouble(),
    (j['carbs'] as num).toDouble(),
    (j['fat'] as num).toDouble(),
  );
}

const foodCatalog = <FoodItem>[
  FoodItem('Haşlanmış Yumurta', '1 adet (50g)', 78, 6.3, 0.6, 5.3),
  FoodItem('Omlet (2 yumurta)', '1 porsiyon', 190, 13, 1.5, 15),
  FoodItem('Menemen', '1 porsiyon', 220, 11, 8, 16),
  FoodItem('Sucuklu Yumurta', '1 porsiyon', 340, 20, 3, 28),
  FoodItem('Yulaf Ezmesi', '40g kuru', 152, 5.3, 27, 2.6),
  FoodItem('Granola', '40g', 180, 4, 26, 7),
  FoodItem('Mısır Gevreği', '30g', 115, 2, 25, 0.3),
  FoodItem('Tam Buğday Ekmeği', '1 dilim (30g)', 75, 3.5, 13.5, 1),
  FoodItem('Beyaz Ekmek', '1 dilim (30g)', 80, 2.6, 15, 1),
  FoodItem('Simit', '1 adet (120g)', 330, 10, 58, 7),
  FoodItem('Kaşarlı Tost', '1 adet', 320, 14, 32, 15),
  FoodItem('Beyaz Peynir', '30g', 80, 4.5, 0.8, 6.5),
  FoodItem('Kaşar Peyniri', '30g', 105, 7, 0.3, 8.5),
  FoodItem('Lor Peyniri (Az Yağlı)', '100g', 98, 18, 3, 1.5),
  FoodItem('Siyah Zeytin', '5 adet (20g)', 40, 0.3, 1, 3.8),
  FoodItem('Bal', '1 yemek kaşığı', 64, 0.1, 17, 0),
  FoodItem('Reçel', '1 yemek kaşığı', 50, 0, 13, 0),
  FoodItem('Tereyağı', '1 tatlı kaşığı (5g)', 36, 0, 0, 4),
  FoodItem('Fıstık Ezmesi', '1 yemek kaşığı (16g)', 95, 4, 3, 8),
  FoodItem('Çiğ Badem', '25g', 145, 5, 5.5, 12.5),
  FoodItem('Ceviz', '25g', 165, 3.8, 3.5, 16.5),
  FoodItem('Fındık', '25g', 157, 3.7, 4.2, 15.7),
  FoodItem('Muz (Orta Boy)', '1 adet (118g)', 105, 1.3, 27, 0.4),
  FoodItem('Elma', '1 orta (180g)', 95, 0.5, 25, 0.3),
  FoodItem('Portakal', '1 orta (130g)', 62, 1.2, 15, 0.2),
  FoodItem('Çilek', '1 kase (150g)', 48, 1, 11, 0.5),
  FoodItem('Üzüm', '1 avuç (100g)', 69, 0.7, 18, 0.2),
  FoodItem('Karpuz', '1 dilim (280g)', 84, 1.7, 21, 0.4),
  FoodItem('Avokado', '1/2 adet (100g)', 160, 2, 9, 15),
  FoodItem('Kuru Kayısı', '5 adet (40g)', 96, 1.2, 25, 0.1),
  FoodItem('Hurma', '3 adet (60g)', 165, 1.3, 44, 0.2),
  FoodItem('Mevsim Salata (Zeytinyağlı)', '1 kase', 130, 2, 8, 10),
  FoodItem('Haşlanmış Patates', '1 orta (150g)', 130, 3, 30, 0.2),
  FoodItem('Pirinç Pilavı', '1 kase (150g)', 195, 3.6, 42, 2),
  FoodItem('Bulgur Pilavı', '1 kase (150g)', 170, 5.6, 34, 1),
  FoodItem('Kinoa (Pişmiş)', '1 kase (150g)', 180, 6.7, 31.5, 2.9),
  FoodItem('Makarna (Haşlanmış)', '1 tabak (200g)', 310, 11, 62, 2),
  FoodItem('Mercimek Çorbası', '1 kase (250ml)', 150, 8, 22, 3.5),
  FoodItem('Ezogelin Çorbası', '1 kase (250ml)', 160, 6, 24, 4.5),
  FoodItem('Izgara Tavuk Göğsü', '100g', 165, 31, 0, 3.6),
  FoodItem('Izgara Tavuk But', '1 adet', 210, 23, 0, 13),
  FoodItem('Tavuk Sote', '1 porsiyon (200g)', 300, 30, 10, 16),
  FoodItem('Izgara Köfte', '4 adet (100g)', 250, 18, 6, 17),
  FoodItem('Biftek', '100g', 250, 26, 0, 15),
  FoodItem('Izgara Somon Balığı', '150g', 310, 34, 0, 18),
  FoodItem('Ton Balığı (Suda)', '1 kutu (80g)', 90, 20, 0, 1),
  FoodItem('Kuru Fasulye', '1 porsiyon (250g)', 280, 14, 40, 7),
  FoodItem('Nohut Yemeği', '1 porsiyon (250g)', 300, 14, 42, 9),
  FoodItem('Haşlanmış Nohut', '100g', 164, 8.9, 27, 2.6),
  FoodItem('Ispanak Yemeği', '1 porsiyon (250g)', 120, 8, 10, 6),
  FoodItem('Humus', '2 yemek kaşığı (30g)', 80, 2.4, 6, 5),
  FoodItem('Lahmacun', '1 adet', 270, 12, 35, 9),
  FoodItem('Tavuk Döner Dürüm', '1 adet', 480, 28, 42, 22),
  FoodItem('Kıymalı Pide', '1/4 pide', 280, 14, 34, 10),
  FoodItem('Mantı', '1 tabak (200g)', 380, 14, 50, 13),
  FoodItem('Patates Kızartması', '1 porsiyon (150g)', 450, 5, 58, 22),
  FoodItem('Pizza (Margherita)', '1 dilim', 270, 11, 34, 10),
  FoodItem('Hamburger', '1 adet', 500, 25, 40, 26),
  FoodItem('Baklava', '1 dilim (60g)', 260, 3.5, 30, 14),
  FoodItem('Sütlaç', '1 kase (150g)', 210, 5, 35, 5),
  FoodItem('Sütlü Çikolata', '25g', 135, 2, 14, 8),
  FoodItem('Bisküvi', '3 adet (25g)', 110, 2, 18, 3.3),
  FoodItem('Süt (Tam Yağlı)', '1 bardak (200ml)', 122, 6.4, 9.4, 6.6),
  FoodItem('Yoğurt (Tam Yağlı)', '1 kase (150g)', 95, 5, 7, 5),
  FoodItem('Ayran', '1 bardak (200ml)', 70, 3.5, 5, 3.5),
  FoodItem('Kefir', '1 bardak (200ml)', 100, 6, 8, 4),
  FoodItem('Protein Tozu (Whey)', '1 ölçek (30g)', 120, 24, 3, 1.5),
  FoodItem('Latte', '1 orta boy', 150, 8, 12, 8),
  FoodItem('Portakal Suyu', '1 bardak (200ml)', 110, 1.7, 26, 0.5),
  FoodItem('Kola', '330 ml', 140, 0, 35, 0),
  FoodItem('Şekersiz Çay', '1 bardak', 2, 0, 0, 0),
  FoodItem('Türk Kahvesi (Şekersiz)', '1 fincan', 5, 0.3, 0.6, 0.1),
];

/// Kataloğu ada göre arar. Başta eşleşenler önce gelir. Boş sorgu tümünü döndürür.
List<FoodItem> searchFoods(
  String query, {
  List<FoodItem> source = foodCatalog,
}) {
  final q = normalizeTr(query);
  if (q.isEmpty) return List.of(source);
  final starts = <FoodItem>[];
  final contains = <FoodItem>[];
  for (final f in source) {
    final n = normalizeTr(f.name);
    if (n.startsWith(q)) {
      starts.add(f);
    } else if (n.contains(q)) {
      contains.add(f);
    }
  }
  return [...starts, ...contains];
}
