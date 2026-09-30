# VitaxBand — Kesin Mimari (APK decompile, 2026-09-30)

APK `com.vitaxgo.vitaxband_1.4.0.xapk` jadx ile decompile edildi. Sonuç net.

## Katmanlar
```
┌─ Uygulama: native Kotlin + kendi backend (VitaxBandApi, DailiesApi, Firebase)
├─ Health protokolü: VEEPOO VPProtocol SDK v2.3.59.15  (com.veepoo.protocol)
│    VPOperateManager = tüm API. Adım/nabız/uyku/SpO2/tansiyon/kanşekeri/ECG/HRV...
├─ Transport köprüsü: com.veepoo.protocol.jl.classic  (Veepoo'nun Jieli varyantı)
│    UUID: ae00 (service) / ae01 (write) / ae02 (notify), header {0x05,0xD6}
└─ Çip + auth: Jieli (杰理), libjl_auth.so — Jieli RCSP özel blok şifresi
     (bu katmanı Python'da kırdık ve donanımda doğruladık)
```

## Kritik sonuç
- Band **Veepoo bandı**. Jieli sadece çip + auth + transport; sağlık verisinin TAMAMI
  Veepoo protokolünde (obfuscated, com.veepoo.protocol).
- Jieli watch health komutları (0xA0/0xA6) firmware'de YOK → `STATUS_UNKOWN_CMD=2`.
  Bu yüzden kara-kutu probe'da veri çıkmadı; veri Veepoo paketleriyle akıyor.

## Veepoo VPOperateManager — işe yarar API
| İş | Metod |
|----|-------|
| Bağlan | `connectDevice` / `startScanDevice` |
| Auth (parola genelde "0000") | `confirmDevicePwd(..., pwd, is24Hour, DeviceTimeSetting)` |
| Adım/mesafe/kalori | `readSportStep` |
| Nabız (canlı ölç) | `startDetectHeart` |
| Uyku | `readSleepData` / `readSleepDataSingleDay` |
| Tüm sağlık verisi | `readAllHealthData` |
| Pil | `readBattery` |
| SpO2/tansiyon/kanşekeri/ECG/HRV/sıcaklık | `startDetect*` aynı desende |

## App yapım stratejisi (öneri)
Veepoo protokolünü sıfırdan RE etmek yerine **resmi Veepoo SDK üstüne kur**:
- Cross-platform (iOS+Android tek kod): Veepoo **Flutter** plugin — önerilen.
- Native Android: Veepoo AAR (vpprotocol 2.3.59.15; bu XAPK'dan da çıkarılabilir).
- iOS: Veepoo iOS framework.
SDK auth + transport + tüm health parsing'i hazır veriyor; sen sadece iyi bir UI + kendi
backend'ini (istersen) yazarsın. Resmi app "kötü" olan sadece UI; protokol sağlam.

## Python katmanının rolü
`vitax_ble/` = düşük seviye kanıt/debug aracı (bağlantı + Jieli auth + FE-frame).
Veepoo health paket formatı Python'a taşınmadı (obfuscated, ROI düşük — SDK var).
Gerekirse Veepoo komut baytları com.veepoo.protocol'den çıkarılabilir ama önerilmez.

## GÜNCELLEME 2 — Veepoo veri kanalı bulundu ve bantta çalıştı (2026-09-30)
- Veepoo komutları **ham 20 baytlık paket**, ilk bayt opcode. Yazma: servis
  `F0080001-0451-4000-B000-000000000000`, karakteristik `F0080003` (write),
  bildirim `F0080002` (notify). UI/kadran kanalı: `F0030001` (`F0030003` write, `F0030002` notify).
- ÖNCEKİ NOT YANLIŞTI: f008/f003 "TI OAD, elleme" değil; Veepoo veri/UI kanalları.
  (OAD/firmware güncelleme ayrı: SDK içinde JLOTAManager, yine de firmware'e dokunma.)
- Jieli auth (ae00) bu kanal için GEREKMEDİ: `A8 00` yazınca cevap geldi.
  Cevap: `a1 00 00 00 17 6c 03 73 00 01 00 01 00 00...` — içerik henüz doğrulanmadı
  (SDK ayrıştırıcısı bayt5==0 ise adımı bayt1-4'ten okur; burada bayt5=0x6c).
- Komut sabitleri: decompile `com/veepoo/protocol/profile/vp_a.java`; sınıf eşlemesi
  `com/veepoo/protocol/profile/vp_b.java` ("read_current_sport_oprate"→vp_cj, pil→vp_h, saat→vp_cp).

## GÜNCELLEME 3: Bant doğrulama, yürüyüş testi (2026-09-30)
Kayıt: `data/walktest_20260930_221811.jsonl`, çözümleyici `tools/analyze_walk.py`.
- Adım (A8 00): bayt1-4 büyük-uçlu toplam sayaç. Durağanken sabit, hareketle artıyor (294→344). Kalori/mesafe bantta YOK (SDK adım+boydan hesaplıyor).
- Nabız (D0 01 başlat, D0 00 durdur): ~1 Hz, bayt1=bpm. 0 = ölçülüyor, 1/2 = bant takılı değil, 30..210 geçerli. İlk geçerli değer ~70 sn sonra.
- Pil (A0 00): `a0 00 00 00 62 01 62 01`: bayt5=1 yüzde modu, bayt6=0x62=%98.
- Adım paketinde ivmeölçer baytları (6-8, 11-13) hep sıfır. Antrenmanda tekrar sayımı için başka kaynak lazım (F1 head_gsensor veya spor modu denenmedi).
- Doğrulanmadı: nabız doğruluğu (dinlenikte ortalama ~119 şüpheli), uyku, gün içi nabız geçmişi, SpO2/tansiyon/sıcaklık.
