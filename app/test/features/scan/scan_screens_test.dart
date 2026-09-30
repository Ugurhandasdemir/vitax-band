import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/core/theme/app_theme.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/nutrition_repository.dart';
import 'package:vitax_app/data/repos/settings_repository.dart';
import 'package:vitax_app/features/scan/barcode_result_screen.dart';
import 'package:vitax_app/features/scan/photo_analysis_screen.dart';
import 'package:vitax_app/features/scan/scan_screen.dart';

import '../../support/pump.dart';

void main() {
  group('Faz 4 — Tarama Ekranları Testleri', () {
    testWidgets('ScanScreen: vizör, mod seçici, butonlar ve son kaydedilenler listelenir', (tester) async {
      await pumpScreen(
        tester,
        const ScanScreen(),
      );

      // Mod seçici
      expect(find.text('Barkod'), findsOneWidget);
      expect(find.text('Fotoğraf'), findsOneWidget);

      // Vizör ve etiketler
      expect(find.text('Barkodu veya yemeği çerçeveye alın'), findsOneWidget);
      expect(find.text('Canlı Algılama Aktif'), findsOneWidget);

      // Alt kontroller
      expect(find.byKey(const ValueKey('scan-flash-btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('scan-shutter-btn')), findsOneWidget);
      expect(find.byKey(const ValueKey('scan-gallery-btn')), findsOneWidget);
      expect(find.text('Elle ara'), findsOneWidget);

      // Son Kaydedilenler
      expect(find.text('Son Kaydedilenler'), findsOneWidget);
      expect(find.text('Pınar Protein Süt 500ml'), findsOneWidget);
      expect(find.text('Wasa Sade Çavdar Gevreği'), findsOneWidget);
      expect(find.text('Züber Fıstık Ezmeli Bar'), findsOneWidget);
    });

    testWidgets('ScanScreen: deklanşör moduna göre ilgili sonuç ekranına yönlendirir', (tester) async {
      await pumpScreen(
        tester,
        const ScanScreen(),
      );

      // Barkod modundayken deklanşöre basınca BarcodeResultScreen açılır
      await tester.tap(find.byKey(const ValueKey('scan-shutter-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('screen-barcode-result')), findsOneWidget);
      expect(find.text('8690504123456'), findsOneWidget);

      // Geri dön
      await tester.tap(find.byKey(const ValueKey('barcode-back-btn')));
      await tester.pumpAndSettle();

      // Fotoğraf moduna geç
      await tester.tap(find.text('Fotoğraf'));
      await tester.pumpAndSettle();

      // Fotoğraf modunda deklanşöre basınca PhotoAnalysisScreen açılır
      await tester.tap(find.byKey(const ValueKey('scan-shutter-btn')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('screen-photo-analysis')), findsOneWidget);
      expect(find.text('AI Besin Tanıma • VitaxVision AI'), findsOneWidget);
    });

    testWidgets('ScanScreen: son kaydedilenlerden hızlı ekleme çalışır', (tester) async {
      final env = await pumpScreen(
        tester,
        const ScanScreen(),
      );

      final addBtns = find.byKey(const ValueKey('quick-add-btn'));
      expect(addBtns, findsWidgets);

      await tester.tap(addBtns.first);
      await tester.pumpAndSettle();

      expect(find.textContaining('eklendi'), findsOneWidget);

      final foods = await env.nutrition.foodForDay(DateTime(2026, 10, 24));
      expect(foods.any((f) => f.name.contains('Pınar Protein')), isTrue);
    });

    testWidgets('BarcodeResultScreen: porsiyon ayarı, makrolar ve öğüne ekleme çalışır', (tester) async {
      final env = await pumpScreen(
        tester,
        const BarcodeResultScreen(),
      );

      expect(find.text('8690504123456'), findsOneWidget);
      expect(find.text('Doğrulandı'), findsOneWidget);
      expect(find.text('Pınar Protein'), findsOneWidget);
      expect(find.text('Kakaolu Protein Sütü'), findsOneWidget);

      // Varsayılan kalori 260 kcal
      expect(find.text('260'), findsWidgets);

      // Stepper ile porsiyonu artır
      await tester.tap(find.byKey(const ValueKey('portion-plus-btn')));
      await tester.pumpAndSettle();

      // 2 adet olunca kalori 520 olur
      expect(find.text('2'), findsOneWidget);
      expect(find.text('520'), findsWidgets);

      // Öğüne Ekle butonuna bas
      await tester.tap(find.byKey(const ValueKey('barcode-add-btn')));
      await tester.pumpAndSettle();

      final foods = await env.nutrition.foodForDay(DateTime(2026, 10, 24));
      expect(foods.any((f) => f.name.contains('Kakaolu Protein Sütü') && f.kcal == 520), isTrue);
    });

    testWidgets('PhotoAnalysisScreen: Vision AI etiketleri, tespit edilen kalemler ve onay çalışır', (tester) async {
      final env = await pumpScreen(
        tester,
        const PhotoAnalysisScreen(),
      );

      // AI etiketleri
      expect(find.text('AI Besin Tanıma • VitaxVision AI'), findsOneWidget);
      expect(find.text('Izgara Tavuk'), findsOneWidget);
      expect(find.text('Kinoa Salatası'), findsOneWidget);
      expect(find.text('Avokado'), findsOneWidget);

      // Tespit edilen yiyecekler
      expect(find.text('Izgara Tavuk Göğsü'), findsOneWidget);
      expect(find.text('Haşlanmış Kinoa & Nar'), findsOneWidget);
      expect(find.text('Dilim Avokado'), findsOneWidget);

      // Toplam kalori
      expect(find.text('524'), findsOneWidget);

      // Onayla ve Öğle Yemeğine Ekle butonuna bas
      await tester.tap(find.byKey(const ValueKey('photo-confirm-btn')));
      await tester.pumpAndSettle();

      final foods = await env.nutrition.foodForDay(DateTime(2026, 10, 24));
      expect(foods.any((f) => f.name.contains('Izgara Tavuk Göğsü')), isTrue);
    });
  });
}
