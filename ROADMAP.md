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

## Faz 3: Bant (YARIM, 2026-09-30'da Antigravity/Gemini'ye devredildi)
Ekranlar: bileklik_ba_la, bilekli_im, ba_lant_durumlar, sa_l_k_ve_aktivite, kalp_sa_l, uyku_analizi, ek_sens_rler, canl_antrenman (canlı nabız + Öneri modu)

Bitti (testli, 530 test yeşildi, son tam koşu BandScreens eklenmeden önce):
- [x] `lib/data/band/veepoo_codec.dart` (A1 parola/saat, A0 pil, A8 adım, D0 nabız; gerçek kayıt `test/fixtures/band_frames.json` ile doğrulandı)
- [x] `band_transport.dart` (arayüz), `offline_band_transport.dart` (varsayılan, bağlanınca hata), `ble_band_transport.dart` (flutter_blue_plus 2.x, `License.nonprofit`, f008 servisi; GERÇEK CİHAZDA DENENMEDİ)
- [x] `band_controller.dart` (parola el sıkışması, 60 sn pil+adım yoklaması, canlı nabız, ham örnek SQLite'a; `test/data/band/band_controller_test.dart`)
- [x] `providers.dart`: `bandTransportProvider`, `bandControllerProvider`, `liveHrProvider` gerçek akış; `bandStatusProvider` artık `BandState` (varsayılan: bağlı değil). `main.dart` BLE taşıyıcısını bağlar. Home golden yenilendi.

Yarım (kod yazıldı, testler KOŞTURULMADI/doğrulanmadı):
- [ ] `lib/features/band/band_connect_screen.dart`, `my_band_screen.dart`, `band_widgets.dart` + üst bar bant çipi dokununca açma (`top_bar.dart`) + `test/features/band/band_screens_test.dart`. Son adım: `const` hatası giderildi (VText `final`, const değil), `flutter test test/features/band` tekrar koşulacaktı.
  Sonra: `flutter test` (tam), `flutter analyze` (lib'de yeni uyarı kalmasın).

Kalan:
- [ ] sa_l_k_ve_aktivite (segmentler Bugün|Kalp|Uyku|Antrenman|Kilo), kalp_sa_l, uyku_analizi, ek_sens_rler: desteklenmeyen/doğrulanmamış veri için dürüst boş durum (uydurma değer yok)
- [ ] Canlı antrenmanda `liveHrProvider` + "Nabız hazırlanıyor" (ilk geçerli nabız ~70 sn sonra gelir)
- [ ] Uyku, gün içi nabız geçmişi, SpO2/sıcaklık opcode'ları gerçek bantta araştırılacak
- [ ] Bant hiç bağlanmamışken ana sayfa "VİTAXBAND CANLI" noktası gri olsun (küçük cila)

Devir notları (Gemini için):
- Proje kökü `/mnt/windows/linux/Python/vitax-band/`, Flutter `app/`, PATH: `$HOME/development/flutter/bin`. Flutter 3.47.5, Riverpod 3, Drift.
- Kural: önce test yaz (TDD), UI'yı Stitch tasarımından (`tasarim/v2/...`) uygula, tasarım uydurma. Bant verisi dışında kaynak yok (Apple Health yok).
- Sahte bant testte: `test/support/fake_band_transport.dart`; ekran testlerinde `bandTransportProvider.overrideWithValue(...)`.
- Gerçek bant protokolü: `MIMARI.md` (güncelleme 1-3), `tools/walktest.py`. Bant telefonun BT ayarlarında bağlıysa taramada görünmez ("Bu cihazı unut").
- `flutter test` bir kez ~5 dk sürüp zaman aşımına uğradı; `test/features/band` tek başına koşulup bakılsın, asılıysa `pkill flutter_tester`.

## Faz 4: Tarama
barkod_ve_yemek_tara, barkod_sonucu (Open Food Facts), foto_raf_analizi (model kararı bekliyor)

## Faz 5: AI ve veri
ai_ko, haftal_k_ai_plan, sa_l_k_i_g_r_leri, veri_kasas_ve_gizlilik, bildirimler_ve_uyar_lar

## Faz 6: iPhone'a yükleme
Apple geliştirici hesabı, bulut derleme (macOS runner), TestFlight, iPhone SE 3 testi

## Açık kararlar
- AI koç: hangi LLM, anahtar nerede durur (öneri: evdeki sunucuda, telefonda değil)
- Fotoğraftan kalori: hangi görsel model
- Egzersiz görselleri: © Gym visual, 180px, atıf şart; dağıtımda lisans gerekir
- Uygulama adı: Vital Precision mı Vital Balance mı
