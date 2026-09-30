import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/features/profile/profile_hub_screen.dart';
import 'package:vitax_app/features/settings/data_vault_screen.dart';
import 'package:vitax_app/features/settings/notifications_screen.dart';

import '../../support/pump.dart';

void main() {
  group('Faz 5 — Veri Kasası, Gizlilik ve Bildirim Ekranları Testleri', () {
    testWidgets('DataVaultScreen: şifreli bellek, 6 kategori, izinler ve silme modalı', (tester) async {
      await pumpScreen(
        tester,
        const DataVaultScreen(),
      );

      // Şifreli Bellek & Gizlilik
      expect(find.text('Cihaz İçi Şifreli Bellek'), findsOneWidget);
      expect(find.text('AES-256'), findsOneWidget);
      expect(find.textContaining('Apple Health veya üçüncü taraf'), findsOneWidget);

      // 6 Kategori
      expect(find.text('Canlı Nabız Akışı'), findsOneWidget);
      expect(find.text('Adım & Hareket Verileri'), findsOneWidget);
      expect(find.text('Uyku Evreleri ve Hipnogram'), findsOneWidget);
      expect(find.text('Antrenman ve Efor Kayıtları'), findsOneWidget);
      expect(find.text('Beslenme ve Öğün Günlüğü'), findsOneWidget);
      expect(find.text('Kilo ve Beden Ölçüleri'), findsOneWidget);

      // AI Koç İzinleri
      expect(find.text('AI Koç Veri İzinleri'), findsOneWidget);
      expect(find.text('Nabız ve Biyometri'), findsOneWidget);
      expect(find.text('Uyku ve Toparlanma'), findsOneWidget);

      // Dışa Aktar ve Sil
      expect(find.text('Verileri Dışa Aktar'), findsOneWidget);
      expect(find.text('Şifreli Yerel Yedek Oluştur'), findsOneWidget);
      expect(find.text('Veri Kasasını Kalıcı Olarak Temizle'), findsOneWidget);

      // Temizle butonuna basınca onay modalı açılır
      await tester.ensureVisible(find.text('Veri Kasasını Kalıcı Olarak Temizle'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Veri Kasasını Kalıcı Olarak Temizle'));
      await tester.pumpAndSettle();

      expect(find.text('Emin misiniz?'), findsOneWidget);
      expect(find.text('Evet, Sil'), findsOneWidget);
      expect(find.text('Vazgeç'), findsOneWidget);

      // Vazgeç'e basınca modal kapanır
      await tester.tap(find.text('Vazgeç'));
      await tester.pumpAndSettle();
      expect(find.text('Emin misiniz?'), findsNothing);
    });

    testWidgets('NotificationsScreen: donanım uyarıları, alışkanlıklar ve tercihleri kaydet', (tester) async {
      await pumpScreen(
        tester,
        const NotificationsScreen(),
      );

      // Donanım & Sağlık Uyarıları
      expect(find.text('Hareketsizlik Uyarısı'), findsOneWidget);
      expect(find.text('Yüksek Dinlenik Nabız'), findsOneWidget);
      expect(find.text('Düşük Pil Uyarısı'), findsOneWidget);

      // Alışkanlık & Takip Hatırlatıcıları
      expect(find.text('Su Tüketim Hatırlatıcısı'), findsOneWidget);
      expect(find.text('Öğün Girişi Bildirimi'), findsOneWidget);
      expect(find.text('Akıllı Uyku Vakti (Wind-down)'), findsOneWidget);
      expect(find.text('Gece Uykusu Algılama'), findsOneWidget);

      // Tercihleri Kaydet butonu
      expect(find.byKey(const ValueKey('notifications-save-btn')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('notifications-save-btn')));
      await tester.pumpAndSettle();

      expect(find.text('Kaydedildi!'), findsOneWidget);
    });

    testWidgets('ProfileHubScreen: Veri Kasası ve Bildirimler ekranlarına yönlendirir', (tester) async {
      await pumpScreen(
        tester,
        const ProfileHubScreen(),
      );

      // Veri Kasası ve Gizlilik tıkla
      await tester.tap(find.text('Veri Kasası ve Gizlilik'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-data-vault')), findsOneWidget);

      // Geri dön
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Bildirimler ve Uyarılar tıkla
      await tester.tap(find.text('Bildirimler ve Uyarılar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-notifications')), findsOneWidget);
    });
  });
}
