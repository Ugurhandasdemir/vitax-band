# vitax-band

[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
![Flutter](https://img.shields.io/badge/Flutter-Dart%203.13-02569B)
![Tests](https://img.shields.io/badge/tests-557%20passing-brightgreen)
![Status](https://img.shields.io/badge/status-alpha-orange)

VitaxBand akıllı bileklik için açık kaynak, yerel-öncelikli sağlık ve fitness uygulaması.
Resmi uygulamaya ihtiyaç duymadan bilekliğe bağlanır; verin telefonda kalır, hesap ve bulut yoktur.

*Open-source, local-first companion app and BLE client for the VitaxBand fitness band
(Flutter app + Python reference client). Documentation is in Turkish.*

> **Durum: alfa.** Yalnızca tek bir VitaxBand bileklikte denendi. Bu proje Vitax ile bağlantılı
> değildir, resmi bir ürün değildir ve tıbbi cihaz değildir.

## İçindekiler

- [Özellikler](#özellikler)
- [Uyumluluk](#uyumluluk)
- [Kurulum](#kurulum)
- [Python istemcisi](#python-istemcisi)
- [Protokol](#protokol)
- [Proje yapısı](#proje-yapısı)
- [Yol haritası](#yol-haritası)
- [Katkı](#katkı)
- [Lisans ve kaynaklar](#lisans-ve-kaynaklar)

## Özellikler

| Alan | Ne var | Durum |
| --- | --- | --- |
| Bileklik | BLE bağlantı, adım, canlı nabız, pil | Gerçek donanımda doğrulandı |
| Bileklik | Uyku evreleri, SpO2, tansiyon, sıcaklık, HRV | Ekranlar hazır, veri doğrulanmadı |
| Beslenme | Kalori günlüğü, yemek arama, su, kilo, kalori dengesi | Çalışıyor |
| Egzersiz | 1324 hareketlik kütüphane (Türkçe adımlar), antrenman oluşturucu, canlı antrenman, nabızdan set algılama | Çalışıyor |
| Tarama | Barkod ve fotoğraftan besin analizi ekranları | Arayüz hazır, görsel model bağlı değil |
| AI Koç | Sohbet, haftalık plan, sağlık içgörüleri | Arayüz hazır, LLM bağlı değil (örnek veri) |
| Veri | Yerel SQLite, veri kasası, CSV/JSON dışa aktarma, bildirim tercihleri | Çalışıyor |

Uygulama desteklenmeyen veya doğrulanmamış ölçümler için değer uydurmaz; ilgili ekranda kısıt
açıkça yazılır.

## Uyumluluk

- **Denenen cihaz:** VitaxBand (Jieli çip, Veepoo protokolü).
- **Başka bileklikler:** aynı Veepoo servisini (`F0080001-…`) yayınlayan cihazlarda çalışabilir,
  ama doğrulanmadı. Sensör seti ve paket düzeni modele göre değişir.
- **Cihaz araması:** uygulama adı `Vitax` ile başlayan cihazları arar
  (`app/lib/data/band/ble_band_transport.dart`). Farklı adla yayın yapan bir bileklik için bu öneki
  değiştirmen gerekir.
- **Platformlar:** iOS, Linux masaüstü ve web hedefleri depoda var. Android hedefi henüz eklenmedi.
- Bileklik aynı anda tek bağlantı kabul eder; resmi uygulama bağlıyken bu uygulama bağlanamaz.

Başka bir modelde denediysen sonucu (çalışan ve çalışmayan ölçümlerle) issue olarak yazman çok işe yarar.

## Kurulum

Gerekenler: [Flutter](https://docs.flutter.dev/get-started/install) (Dart SDK 3.13+). Linux
masaüstü için ayrıca `clang cmake ninja-build libgtk-3-dev`.

```bash
git clone https://github.com/Ugurhandasdemir/vitax-band.git
cd vitax-band/app
flutter pub get
flutter run -d linux        # veya bağlı bir iOS cihazı
```

Testler ve statik analiz:

```bash
flutter analyze
flutter test
```

## Python istemcisi

`vitax_ble/`, protokolü denemek için küçük bir referans istemcidir (Jieli RCSP kanalı).

```bash
pip install -r requirements.txt
export VITAX_ADDR=AA:BB:CC:DD:EE:FF   # kendi bilekliğinin adresi
python -m vitax_ble.client            # bağlan + auth + cihaz bilgisi
```

```python
import asyncio
from vitax_ble import VitaxBand

async def main():
    b = VitaxBand("AA:BB:CC:DD:EE:FF")
    await b.connect()
    assert await b.authenticate()
    print(await b.send_cmd(0x03, bytes([0x00])))  # cihaz bilgisi
    await b.disconnect()

asyncio.run(main())
```

`tools/walktest.py` yürüyüş sırasında ham paketleri kaydeder, `tools/analyze_walk.py` kaydı çözer.

## Protokol

Bileklikte iki ayrı kanal var:

| Kanal | Servis | Yazma / Bildirim | Kullanım |
| --- | --- | --- | --- |
| Veepoo veri | `F0080001-0451-4000-B000-000000000000` | `F0080003` / `F0080002` | Adım, nabız, pil, uyku. Flutter uygulaması bunu kullanır, auth gerekmez. |
| Jieli RCSP | `0xAE00` | `0xAE01` / `0xAE02` | Cihaz bilgisi. Python istemcisi bunu kullanır, auth gerekir. |

- **Veepoo komutları:** ham 20 baytlık paket, ilk bayt opcode.
- **RCSP auth:** Jieli'ye özel blok şifresi (AES değil) ve statik 16 baytlık anahtarla karşılıklı
  el sıkışma.
  1. telefon → `00 + random[16]`, cihaz → `01 + enc[16]`
  2. telefon → `02 "pass"`, cihaz → `00 + challenge[16]`
  3. telefon → `01 + enc(challenge)`, cihaz → `02 "pass"`
- **RCSP çerçevesi:** `FE DC BA | flag | cmd | len_hi | len_lo | body | EF`
  (flag `0xC0` komut, `0x00` cevap, `0x80` veri).
- Bağlantı için eşleştirme (bond) gerekmez.

Ayrıntılar: [`MIMARI.md`](MIMARI.md) ve [`vitax_ble/opcodes.md`](vitax_ble/opcodes.md).

## Proje yapısı

```
app/                 Flutter uygulaması
  lib/core/          tema ve ortak bileşenler
  lib/data/          SQLite (drift), repository'ler, bileklik codec ve BLE katmanı
  lib/features/      ekranlar (home, activity, band, diary, workout, scan, coach, …)
  test/              557 test
vitax_ble/           Python referans istemcisi (RCSP auth + çerçeve)
tools/               yürüyüş testi, kayıt analizi, egzersiz verisi derleyici
tasarim/             ekran tasarımları
MIMARI.md            protokol ve mimari notları
ROADMAP.md           fazlar ve açık kararlar
```

## Yol haritası

- [x] Beslenme, egzersiz, bileklik, tarama ve AI ekranları (Faz 1–5)
- [ ] iPhone'a yükleme ve TestFlight (Faz 6)
- [ ] Uyku ve gün içi geçmiş veri komutlarının doğrulanması
- [ ] Hangi ek sensörlerin gerçekten var olduğunun doğrulanması
- [ ] AI koç ve fotoğraftan kalori için model bağlantısı
- [ ] Android hedefi

Tam liste: [`ROADMAP.md`](ROADMAP.md).

## Katkı

Katkılar açık. Başlamadan önce:

1. Büyük değişiklikler için önce bir issue aç.
2. `flutter analyze` temiz ve `flutter test` yeşil olmalı.
3. Bileklikten gelen yeni bir veriyi eklerken gerçek cihazda nasıl doğruladığını PR'da yaz.
4. Kişisel veri (cihaz adresi, kendi ölçüm kayıtların) commit etme; `data/` bu yüzden `.gitignore`'da.

Hata bildirirken bileklik modelini, platformu ve mümkünse ham paket kaydını ekle.

## Lisans ve kaynaklar

Kod [MIT](LICENSE) lisanslıdır.

- Jieli RCSP kripto: [hybridherbst/web-bluetooth-e87](https://github.com/hybridherbst/web-bluetooth-e87)
- Egzersiz verisi: [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset)
  (veri MIT). Hareket görselleri © Gym visual; pakete gömülü değildir, uygulama çalışırken indirir.
  Ticari dağıtımda ayrıca lisans gerekir.
- Inter yazı tipi: SIL Open Font License (`app/assets/fonts/Inter-LICENSE.txt`)

"Vitax" ve "VitaxBand" ilgili sahiplerinin markalarıdır; burada yalnızca uyumluluğu belirtmek için
kullanılır.
