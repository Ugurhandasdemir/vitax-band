"""
VitaxBand BLE client — Jieli RCSP transport + auth.

Cihaz: VitaxBand (Jieli/杰理 çip, com.vitaxgo.vitaxband).
Servis 0xAE00, write=0xAE01, notify=0xAE02.

Kanıtlanmış (2026-09-30, gerçek donanım):
  - Bond/pairing GEREKMEZ.
  - Auth = Jieli RCSP özel blok şifresi (bkz. auth.py), statik anahtar gömülü.
  - Komut çerçevesi: FE DC BA | flag | cmd | len_hi | len_lo | body | EF
      flag 0xC0 = komut (cevap bekle), 0x00 = cevap/ack, 0x80 = data/notify
  - cmd 0x03 (device info) cevap veriyor → transport doğrulandı.

Eksik: fitness opcode seti (adım/nabız/uyku). App decompile veya sniff gerektirir.
"""
import asyncio
import os

from bleak import BleakClient

from .auth import get_encrypted_auth_data

ADDR_DEFAULT = "AA:BB:CC:DD:EE:FF"
SVC = "0000ae00-0000-1000-8000-00805f9b34fb"
AE01 = "0000ae01-0000-1000-8000-00805f9b34fb"  # write-without-response
AE02 = "0000ae02-0000-1000-8000-00805f9b34fb"  # notify

AUTH_OK = bytes.fromhex("0270617373")  # 0x02 + "pass"

FE_MAGIC = b"\xfe\xdc\xba"
FE_END = 0xEF
FLAG_CMD = 0xC0
FLAG_RESP = 0x00
FLAG_DATA = 0x80


def build_frame(flag: int, cmd: int, body: bytes = b"") -> bytes:
    """FE DC BA | flag | cmd | len_hi | len_lo | body | EF"""
    n = len(body)
    return (FE_MAGIC + bytes([flag & 0xFF, cmd & 0xFF, (n >> 8) & 0xFF, n & 0xFF])
            + body + bytes([FE_END]))


def parse_frame(data: bytes):
    """-> (flag, cmd, body) veya None."""
    if len(data) < 8 or data[:3] != FE_MAGIC or data[-1] != FE_END:
        return None
    flag, cmd = data[3], data[4]
    length = (data[5] << 8) | data[6]
    body = data[7:-1]
    if len(body) != length:
        return None
    return flag, cmd, body


class VitaxBand:
    def __init__(self, address: str = ADDR_DEFAULT):
        self.address = address
        self._client: BleakClient | None = None
        self._q: asyncio.Queue = asyncio.Queue()

    def _on_notify(self, _handle, data: bytearray):
        self._q.put_nowait(bytes(data))

    async def _rx(self, timeout: float = 4.0):
        try:
            return await asyncio.wait_for(self._q.get(), timeout)
        except asyncio.TimeoutError:
            return None

    async def connect(self):
        self._client = BleakClient(self.address, timeout=25.0)
        await self._client.connect()
        await self._client.start_notify(AE02, self._on_notify)
        return self._client.is_connected

    async def authenticate(self) -> bool:
        """Jieli RCSP karşılıklı handshake. True = auth ok."""
        c = self._client
        # 1) telefon -> 00 + random16 ; cihaz -> 01 + enc(random)
        await c.write_gatt_char(AE01, bytes([0x00]) + os.urandom(16), response=False)
        await self._rx()
        # 2) telefon -> 02 "pass" ; cihaz -> 00 + challenge16
        await c.write_gatt_char(AE01, bytes([0x02]) + b"pass", response=False)
        chal = await self._rx()
        if not chal or chal[0] != 0x00 or len(chal) < 17:
            return False
        # 3) telefon -> 01 + enc(challenge) ; cihaz -> 02 "pass" (=ok)
        resp = bytes(get_encrypted_auth_data(chal[:17]))
        await c.write_gatt_char(AE01, resp, response=False)
        ack = await self._rx()
        # drain
        while not self._q.empty():
            self._q.get_nowait()
        return ack == AUTH_OK

    async def send_cmd(self, cmd: int, body: bytes = b"", flag: int = FLAG_CMD,
                       timeout: float = 3.0):
        """FE-frame komut gönder, ilk gelen frame'i (flag,cmd,body) döndür."""
        await self._client.write_gatt_char(AE01, build_frame(flag, cmd, body),
                                            response=False)
        raw = await self._rx(timeout)
        return parse_frame(raw) if raw else None

    async def disconnect(self):
        if self._client and self._client.is_connected:
            await self._client.disconnect()


async def _demo():
    b = VitaxBand()
    print("connect:", await b.connect())
    print("auth   :", await b.authenticate())
    print("dev-info 0x03:", await b.send_cmd(0x03, bytes([0x00])))
    await b.disconnect()


if __name__ == "__main__":
    asyncio.run(_demo())
