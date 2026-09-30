# Yol haritası (Flutter, yerel-öncelikli)

Tasarım: `tasarim/v2/stitch_vital_precision_health_tracker/` (29 ekran + logo). Sistem adı Vital Balance, renkler Vital Precision ile aynı.
Kural: UI, **veri arayüzlerinin** (repository) üstüne kurulur. Önce sahte veriyle çalışır, gerçek bant/AI sonra aynı arayüze takılır. UI baştan yazılmaz.
Doğrulama: her ekran bitince tasarım PNG'si ile çalışan ekran yan yana karşılaştırılır (375x667).

## Faz 0: Temel
- [ ] sudo: `ninja-build libgtk-3-dev` (Linux masaüstü çalıştırmak için)
- [x] Tema (DESIGN.md renk/yazı/radius), ortak bileşenler (kart, chip, halka, ilerleme, segment, alt sekme)
- [x] Kabuk: 5 sekme (Genel, Aktivite, Tara, AI Koç, Egzersiz), üst bar, bant durum çipi
- [x] Yerel veritabanı (SQLite) şeması + repository arayüzleri + sahte veri (73 test yeşil)

## Bant mızrak ucu (erken, riskli olan)
- [x] Bandı takıp yürü: adım, nabız, pil doğrulandı (uyku hala açık), bkz. MIMARI.md güncelleme 3
- [ ] Geçmiş veri (gün içi nabız, uyku) komutları var mı, formatı ne
- [ ] Hangi sensörler gerçekten var (SpO2, tansiyon, sıcaklık, HRV)

## Faz 1: Beslenme (bantsız, tek başına kullanılır): TAMAM (293 test yeşil)
- [x] genel_bak, kalori_takibi, yemek_ekle_ve_ara, su_takibi, kalori_dengesi, kilo_analizi, profil_ve_hedefler, ho_geldiniz
- [x] Gerçek SQLite ile uçtan uca test (onboarding -> kayıt -> kalıcılık)
- Bilinçli farklar: ondalık ayraç virgül (Türkçe), sahte "Diyetisyen" kartı yok (AI koç Faz 5), barkod Faz 4,
  su ve kilo kayıt bazlı, Apple Health yok.

## Faz 2: Egzersiz ve antrenman: TAMAM (487 test yeşil)
- [x] egzersiz_k_t_phanesi (1324 hareket, TR adımlar, GIF animasyon), egzersiz_detay (hız/duraklat, geçmiş, PR)
- [x] antrenman_olu_turucu (set başına hedef, mola, sürükle-bırak), canl_antrenman, antrenman_zeti, antrenman_ge_mi_i
- [x] Nabızdan set algılama (öneri + onay), set başına nabız özeti ve toparlanma hesabı (saf fonksiyon + durum makinesi testli)
- Not: egzersiz medyası (© Gym visual) pakete gömülmez, GitHub'dan çekilip önbelleğe alınır. Dağıtımda lisans gerekir.
- Canlı nabız akışı `liveHrProvider` (şimdilik boş). Faz 3'te bant bağlanır.

## Faz 3: Bant: TAMAM (545 test yeşil)
Ekranlar: bileklik_ba_la, bilekli_im, ba_lant_durumlar, sa_l_k_ve_aktivite, kalp_sa_l, uyku_analizi, ek_sens_rler, canl_antrenman (canlı nabız + Öneri modu)
- [x] Tüm bant codec, transport, controller ve BLE katmanı tamamlandı.
- [x] `band_connect_screen.dart`, `my_band_screen.dart`, `band_widgets.dart` ve durum çipi entegrasyonu.
- [x] `activity_screen.dart` (5 segment: Bugün|Kalp|Uyku|Antrenman|Kilo) ve alt ekranlar: `heart_health_screen.dart`, `sleep_analysis_screen.dart`, `extra_sensors_screen.dart`.
- [x] Dürüst UI: desteklenmeyen/doğrulanmamış veriler için uydurma değer yok, donanım kısıt durumu açıklamalı.
- [x] Canlı antrenmanda `liveHrProvider` ve gerçek zamanlı nabız akışı entegrasyonu.
- [x] Ana sayfa VitaxBand Canlı durumu ve golden testleri güncellendi.

## Faz 4: Tarama: TAMAM (550 test yeşil)
Ekranlar: barkod_ve_yemek_tara (ScanScreen), barkod_sonucu (BarcodeResultScreen), foto_raf_analizi (PhotoAnalysisScreen)
- [x] `scan_screen.dart`: Barkod/Fotoğraf çift mod vizörü, lazer animasyon çizgisi, flaş/deklanşör/galeri/manuel arama ve son kaydedilenler listesi.
- [x] `barcode_result_screen.dart`: Porsiyon stepper (+/-), birim çipleri, 3 parçalı makro dağılım çubuğu, mikro besin dökümü, öğün seçici ve günlüğe ekleme.
- [x] `photo_analysis_screen.dart`: Vision AI güven etiketleri, makro Bento özeti (kcal, P/K/Y oranları), tespit edilen besin listesi ve doğrudan öğüne kaydetme.
- [x] TDD testleri: `test/features/scan/scan_screens_test.dart` (5/5 yeşil).

## Faz 5: AI ve Veri: TAMAM (557 test yeşil)
Ekranlar: ai_ko (CoachScreen), haftal_k_ai_plan (WeeklyPlanScreen), sa_l_k_i_g_r_leri (HealthInsightsScreen), veri_kasas_ve_gizlilik (DataVaultScreen), bildirimler_ve_uyar_lar (NotificationsScreen)
- [x] `coach_screen.dart`: Canlı biyometri şeridi, bento koç öneri kartı, sohbet akışı, hızlı soru çipleri ve mesajlaşma.
- [x] `weekly_plan_screen.dart`: Haftalık hedefler, 7 günlük antrenman/beslenme akışı ve Dr. Selin Demir AI koç notu.
- [x] `health_insights_screen.dart`: Hafta/Ay periyot toggle, 4 biyometrik korelasyon kartı ve SVG/CustomPaint grafiği.
- [x] `data_vault_screen.dart`: AES-256 yerel şifreli bellek göstergesi (42.8 MB / 500 MB), 6 kategori dökümü, AI koç izin anahtarları, CSV/JSON dışa aktarma ve tehlikeli alan onay modalı.
- [x] `notifications_screen.dart`: Donanım uyarıları (hareketsizlik, dinlenik nabız, düşük pil), alışkanlık hatırlatıcıları (su, öğün, uyku) ve sticky "Tercihleri Kaydet" butonu.
- [x] `profile_hub_screen.dart`: Veri Kasası, Bildirimler ve Bilekliğim ekranları bağlandı.
- [x] TDD testleri: `test/features/coach/coach_screens_test.dart` (4/4 yeşil), `test/features/settings/vault_notifications_test.dart` (3/3 yeşil).

## Faz 6: iPhone'a yükleme (Sırada)
Apple geliştirici hesabı, bulut derleme (macOS runner), TestFlight, iPhone SE 3 testi

## Açık kararlar
- AI koç: hangi LLM, anahtar nerede durur (öneri: evdeki sunucuda, telefonda değil)
- Fotoğraftan kalori: hangi görsel model
- Egzersiz görselleri: © Gym visual, 180px, atıf şart; dağıtımda lisans gerekir
- Uygulama adı: Vital Precision mı Vital Balance mı
