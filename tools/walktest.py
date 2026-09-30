"""Yürüyüş testi: bant bileğdeyken adım + nabız + pil ham kaydı (JSONL).

Kullanım: python tools/walktest.py [süre_sn]
Çıktı: data/walktest_<zaman>.jsonl  (her satır: t, tx/rx, hex)
Protokol: Veepoo ham 20 baytlık paket, servis F0080001 (yaz F0080003, bildirim F0080002).
  A1 parola onayı, A8 adım, D0 01 nabız başlat / D0 00 durdur, A0 pil.
"""
import asyncio
import datetime
import json
import sys
import time
from pathlib import Path

from bleak import BleakClient

ADDR = "AA:BB:CC:DD:EE:FF"
NOTIFY = "f0080002-0451-4000-b000-000000000000"
WRITE = "f0080003-0451-4000-b000-000000000000"


def pad(b, n=20):
    return bytes(b) + bytes(n - len(b))


def pwd_packet(pwd="0000", is24=True):
    n = int(pwd)
    now = datetime.datetime.now()
    yh, yl = divmod(now.year, 256)
    tzmin = -(time.altzone if time.localtime().tm_isdst > 0 else time.timezone) // 60
    b = bytearray(20)
    b[0] = 0xA1
    b[1], b[2], b[3] = n & 0xFF, (n >> 8) & 0xFF, 0
    b[4:11] = bytes([yh, yl, now.month, now.day, now.hour, now.minute, now.second])
    b[11], b[12], b[13], b[14] = (1 if is24 else 0), 1, (tzmin // 15) & 0xFF, 0
    return bytes(b)


async def main(duration):
    out_dir = Path(__file__).resolve().parent.parent / "data"
    out_dir.mkdir(exist_ok=True)
    path = out_dir / f"walktest_{datetime.datetime.now():%Y%m%d_%H%M%S}.jsonl"
    f = path.open("w", encoding="utf-8")
    t0 = time.time()

    def log(kind, data):
        f.write(json.dumps({"t": round(time.time() - t0, 2), "k": kind, "hex": bytes(data).hex()}) + "\n")
        f.flush()

    def on_notify(_h, d):
        log("rx", d)

    async with BleakClient(ADDR, timeout=30.0) as c:
        await c.start_notify(NOTIFY, on_notify)

        async def tx(payload):
            log("tx", payload)
            await c.write_gatt_char(WRITE, payload, response=False)

        await tx(pwd_packet())
        await asyncio.sleep(2)
        await tx(pad([0xA0, 0x00]))          # pil
        await tx(pad([0xD0, 0x01]))          # nabız ölçümünü başlat
        i = 0
        while time.time() - t0 < duration:
            await tx(pad([0xA8, 0x00]))      # adım
            i += 1
            if i % 20 == 0:
                await tx(pad([0xD0, 0x01]))  # nabız ölçümü açık kalsın
            await asyncio.sleep(3)
        await tx(pad([0xD0, 0x00]))          # nabız durdur
        await asyncio.sleep(1)
    f.close()
    print(path)


if __name__ == "__main__":
    asyncio.run(main(int(sys.argv[1]) if len(sys.argv) > 1 else 240))
