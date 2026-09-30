# VitaxBand RCSP opcode haritası (kara-kutu probe, 2026-09-30)

Auth sonrası FE-frame ile `flag=0xC0`, `body=[seq]` gönderildi. Cevap body formatı:
`[status][echoed_seq][payload...]` — `status=0x00` destekleniyor, `0x02` desteklenmiyor.

## Desteklenen opcode'lar (status=00)

| cmd | payload (boş=param yok) | tahmin / not |
|-----|-------------------------|--------------|
| 0x03 | — | device info (param gerekebilir) |
| 0x06 | — | ? |
| 0x0b | — | ? |
| 0x0c | — | ? |
| 0x12 | `01` | boolean ayar |
| 0x14 | `01` | boolean ayar |
| 0x15 | `01` | boolean ayar |
| 0x19 | — | ? |
| 0x1e | — | ? |
| 0x21 | — | ? |
| 0x23 | — | ? |
| 0x26 | `ef00` | ? |
| 0xd4 | — | ? |
| **0xd5** | `00 00 00 00 00 00` | aktivite/adım verisi (band boştayken 0) |
| **0xd9** | `00 00 1f 00 17 00 11 00 02 00 03 02 01 03 02 02 01 02 fe 0c 02 ff db` | feature/capability listesi (TLV?) |
| **0xe1** | `00 00 00 00 00 00` | nabız/aktivite verisi (0) |
| 0xff | — | ? |

## Canlı test bulguları (2026-09-30)
- 0xd5 / 0xe1 payload'ları band sallanınca DEĞİŞMEDİ (byte[1]=echoed seq hariç sabit).
  → bu opcode'lar ya takılıyken/gerçek yürüyüşte dolar ya da sync dizisi gerektirir.
- 0x0c ve 0x19 gönderince cihaz `cmd 0x0d body=0502` PUSH etti (flag 0x80) — küçük
  ack/status, bulk veri değil.
- Sonuç: fitness verisi kara-kutu ile sıfır dönüyor; net semantik için app trafiği
  (iOS BLE sniff / IPA) veya gerçek yürüyüş+sync dizisi lazım.

## Yapılacak
- 0xd5 / 0xe1: band takılı + hareketliyken oku → değişen bayt = adım/nabız (canlı korelasyon).
- 0xd9 payload'unu decode et (desteklenen fonksiyon listesi).
- Boş dönen get'lere doğru param/sub-cmd bul (0x03 device-info dahil).
- Not: kesin semantik app olmadan zor; korelasyon + gözlemle ilerlenecek.
