# vitax-band

VitaxBand akıllı bileklik için açık kaynak uygulama ve bağlantı katmanı: Flutter uygulaması
(`app/`) ve Python BLE istemcisi (`vitax_ble/`). Resmi app (`com.vitaxgo.vitaxband`) kötü olduğu
için sıfırdan yazıldı.

> **Uyumluluk:** yalnızca tek bir VitaxBand bileklikte denendi. Aynı çipi/protokolü kullanan başka
> bilekliklerde çalışabilir ama doğrulanmadı; sensör ve paket düzeni modele göre değişebilir.
> Bu proje Vitax ile bağlantılı değildir, resmi bir ürün değildir ve tıbbi cihaz değildir.

Bileklik adresini `VITAX_ADDR` ortam değişkeniyle ver: `export VITAX_ADDR=AA:BB:CC:DD:EE:FF`

## Ne çözüldü (2026-09-30, gerçek donanımda kanıtlı)

- **Çip:** Jieli (杰理). BLE servis `0xAE00`, write `0xAE01`, notify `0xAE02`.
- **Bağlantı:** bond/pairing gerekmez. Band boştayken `VitaxBand` adıyla advertise eder;
  telefon bağlıyken başka cihaz bağlanamaz (tek bağlantı).
- **Auth:** Jieli RCSP özel blok şifresi (AES değil) — 256-bayt SBOX/ISBOX/KS tablo +
  statik 16-bayt anahtar. `auth.py` içinde, bilinen test vektörüyle doğrulandı.
  Handshake:
  1. telefon → `00 + random[16]` ; cihaz → `01 + enc[16]`
  2. telefon → `02 "pass"`       ; cihaz → `00 + challenge[16]`
  3. telefon → `01 + enc(challenge)` ; cihaz → `02 "pass"` = **AUTH OK**
- **Transport:** FE-frame `FE DC BA | flag | cmd | len_hi | len_lo | body | EF`.
  flag `0xC0`=komut, `0x00`=cevap, `0x80`=data. cmd `0x03` (device info) cevap veriyor.

Kripto kaynağı: hybridherbst/web-bluetooth-e87 (aynı Jieli çip ailesi, RE edilmiş).

## Eksik (yapılacak)

- **Fitness opcode seti**: adım, nabız, uyku, pil, saat-senkron. RCSP fitness komutları
  firmware'e özel; kör tarama düşük verim. En hızlı yol: resmi app'i decompile edip
  opcode + payload formatlarını çıkarmak (APK: `com.vitaxgo.vitaxband`).
- Mobil app (Flutter/React Native önerilir) — bu Python katmanı referans protokol.

## Kullanım

```bash
pip install -r requirements.txt
python -m vitax_ble.client   # connect + auth + device-info demo
```

```python
import asyncio
from vitax_ble import VitaxBand

async def main():
    b = VitaxBand("AA:BB:CC:DD:EE:FF")
    await b.connect()
    assert await b.authenticate()
    print(await b.send_cmd(0x03, bytes([0x00])))  # device info
    await b.disconnect()

asyncio.run(main())
```

## Dosyalar

- `vitax_ble/tables.py` — Jieli SBOX/ISBOX/KS_TABLE (256'şar bayt)
- `vitax_ble/auth.py`   — RCSP blok şifresi + handshake yardımcıları
- `vitax_ble/client.py` — BLE bağlantı, auth handshake, FE-frame gönder/ayrıştır

## Lisans ve kaynaklar

Kod [MIT](LICENSE) lisanslıdır.

- Jieli RCSP kripto: [hybridherbst/web-bluetooth-e87](https://github.com/hybridherbst/web-bluetooth-e87)
- Egzersiz verisi: [hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset) (veri MIT; görsel/GIF © Gym visual, pakete gömülü değil)
- Inter yazı tipi: SIL Open Font License (`app/assets/fonts/Inter-LICENSE.txt`)
