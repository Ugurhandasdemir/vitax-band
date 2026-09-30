import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/features/coach/coach_screen.dart';
import 'package:vitax_app/features/coach/health_insights_screen.dart';
import 'package:vitax_app/features/coach/weekly_plan_screen.dart';

import '../../support/pump.dart';

void main() {
  group('Faz 5 — AI Koç ve İçgörü Ekranları Testleri', () {
    testWidgets('CoachScreen: üst durum çipleri, koç öneri kartı ve hızlı sorular görüntülenir', (tester) async {
      await pumpScreen(
        tester,
        const CoachScreen(),
      );

      // Üst Durum Çipleri
      expect(find.text('VitaxBand Canlı'), findsOneWidget);
      expect(find.textContaining('Uyku'), findsWidgets);
      expect(find.textContaining('Dinlenik'), findsWidgets);
      expect(find.textContaining('Adım', skipOffstage: false), findsWidgets);

      // Koç Mesajı & Günün Önerisi
      expect(find.text('Vital AI Koç'), findsWidgets);
      expect(find.text('Günün Önerisi'), findsOneWidget);
      expect(find.text('Aktif Toparlanma'), findsOneWidget);
      expect(find.text('Akşam Menüsü Odağı'), findsOneWidget);
      expect(find.text('Antrenmanı Başlat'), findsOneWidget);

      // Hızlı soru çipleri
      expect(find.text('Proteinimi nasıl tamamlarım?'), findsOneWidget);
      expect(find.text('VitaxBand verimi özetle'), findsOneWidget);

      // Giriş alanı
      expect(find.byKey(const ValueKey('coach-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('coach-send-btn')), findsOneWidget);
    });

    testWidgets('CoachScreen: hızlı soru çipine dokununca veya mesaj yazınca yeni mesaj eklenir', (tester) async {
      await pumpScreen(
        tester,
        const CoachScreen(),
      );

      // Hızlı soru çipine tıkla
      await tester.tap(find.text('Proteinimi nasıl tamamlarım?'));
      await tester.pumpAndSettle();

      // Soru gönderilmiş olmalı
      expect(find.text('Proteinimi nasıl tamamlarım?'), findsWidgets);

      // Yeni mesaj yaz ve gönder
      await tester.enterText(find.byKey(const ValueKey('coach-input')), 'Bugün kaç kalori yakmalıyım?');
      await tester.tap(find.byKey(const ValueKey('coach-send-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Bugün kaç kalori yakmalıyım?'), findsOneWidget);
    });

    testWidgets('WeeklyPlanScreen: hedefler, 7 günlük akış ve Dr. Selin Demir AI notu görüntülenir', (tester) async {
      await pumpScreen(
        tester,
        const WeeklyPlanScreen(),
      );

      expect(find.text('Bu Haftanın Programı'), findsOneWidget);
      expect(find.text('7 Günlük Akış'), findsOneWidget);

      // Hedefler
      expect(find.text('Kalori Ort.'), findsOneWidget);
      expect(find.text('Protein'), findsWidgets);
      expect(find.text('Hidrasyon'), findsOneWidget);

      // 7 gün
      expect(find.text('Pzt'), findsOneWidget);
      expect(find.text('Sal'), findsOneWidget);
      expect(find.text('Çar'), findsOneWidget);
      expect(find.text('Per'), findsOneWidget);
      expect(find.text('Cum'), findsOneWidget);
      expect(find.text('Cmt'), findsOneWidget);
      expect(find.text('Paz'), findsOneWidget);

      // Dr. Selin Demir AI Biyometrik Koçu
      expect(find.text('Dr. Selin Demir'), findsOneWidget);
      expect(find.text('Vitax AI Biyometrik Koçu'), findsOneWidget);
      expect(find.text('Bu Plan Neden Oluşturuldu?'), findsOneWidget);
      expect(find.text('Planı Kabul Et ve Takvime Ekle'), findsOneWidget);
    });

    testWidgets('HealthInsightsScreen: Hafta/Ay toggle ve 4 biyometrik korelasyon kartı görüntülenir', (tester) async {
      await pumpScreen(
        tester,
        const HealthInsightsScreen(),
      );

      expect(find.text('Biyometrik Korelasyon Raporu'), findsOneWidget);
      expect(find.text('Hafta'), findsOneWidget);
      expect(find.text('Ay'), findsOneWidget);

      // 4 Korelasyon Kartı
      expect(find.text('Uyku Süresi & Ertesi Gün Nabız'), findsOneWidget);
      expect(find.text('Günlük Adım Sayısı & Kilo'), findsOneWidget);
      expect(find.text('Kalori & Enerji Dengesi'), findsOneWidget);
      expect(find.text('Toparlanma Trendi (HRV)'), findsOneWidget);

      // Dışa aktarma butonları
      expect(find.text('Detaylı PDF Raporu Paylaş'), findsOneWidget);
      expect(find.text('Ham Verileri İndir (.CSV)'), findsOneWidget);

      // Ay seçeneğine geçiş
      await tester.tap(find.text('Ay'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-health-insights')), findsOneWidget);
    });
  });
}
