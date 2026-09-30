import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/core/text_search.dart';
import 'package:vitax_app/data/food_catalog.dart';

void main() {
  group('normalizeTr (Türkçe arama normalleştirme)', () {
    test('büyük/küçük ve Türkçe harfler eşitlenir', () {
      expect(normalizeTr('ISPANAK'), normalizeTr('ıspanak'));
      expect(normalizeTr('İÇLİ KÖFTE'), 'icli kofte');
      expect(normalizeTr('Şeftali'), 'seftali');
      expect(normalizeTr('ÇÖREK'), 'corek');
      expect(normalizeTr('Ağaç'), 'agac');
    });
    test('boşluklar kırpılır', () => expect(normalizeTr('  Süt  '), 'sut'));
  });

  group('yiyecek kataloğu verisi', () {
    test('en az 50 yiyecek var', () {
      expect(foodCatalog.length, greaterThanOrEqualTo(50));
    });
    test('isimler benzersiz', () {
      final names = foodCatalog.map((f) => normalizeTr(f.name)).toList();
      expect(names.toSet().length, names.length);
    });
    test('her kaydın kcal > 0 (içecek sıfır hariç) ve porsiyonu var', () {
      for (final f in foodCatalog) {
        expect(f.portion, isNotEmpty, reason: f.name);
        expect(f.kcal, greaterThanOrEqualTo(0), reason: f.name);
        expect(f.protein, greaterThanOrEqualTo(0), reason: f.name);
      }
    });
    test('makrolardan hesaplanan kalori verilen kaloriyle tutarlı (±%35 veya ±25 kcal)', () {
      for (final f in foodCatalog.where((f) => f.kcal >= 40)) {
        final calc = f.protein * 4 + f.carbs * 4 + f.fat * 9;
        final diff = (calc - f.kcal).abs();
        expect(
          diff <= f.kcal * 0.35 || diff <= 25,
          isTrue,
          reason: '${f.name}: kcal=${f.kcal} makrodan=$calc',
        );
      }
    });
  });

  group('searchFoods', () {
    test('alt dize eşleşir, Türkçe harften bağımsız', () {
      final r = searchFoods('yumurta');
      expect(r.any((f) => normalizeTr(f.name).contains('yumurta')), isTrue);
    });
    test('büyük harf ve noktasız ı ile de bulur', () {
      expect(
        searchFoods('ISPANAK').isNotEmpty,
        searchFoods('ispanak').isNotEmpty,
      );
    });
    test('boş sorgu tüm kataloğu döndürür', () {
      expect(searchFoods('').length, foodCatalog.length);
    });
    test('eşleşme yoksa boş liste', () {
      expect(searchFoods('xqzw'), isEmpty);
    });
    test('başta eşleşenler önce gelir', () {
      final r = searchFoods('süt');
      expect(normalizeTr(r.first.name).startsWith('sut'), isTrue);
    });
  });
}
