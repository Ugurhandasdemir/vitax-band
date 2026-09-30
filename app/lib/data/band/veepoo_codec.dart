import 'dart:typed_data';

/// Veepoo ham 20 baytlık paket kodeği (GATT f008 kanalı).
/// Yalnız gerçek bantta doğrulanan opcode'lar: A1 parola, A0 pil, A8 adım, D0 nabız.

const int packetLength = 20;

Uint8List _packet(List<int> head) {
  final b = Uint8List(packetLength);
  for (var i = 0; i < head.length; i++) {
    b[i] = head[i] & 0xFF;
  }
  return b;
}

Uint8List buildBatteryRequest() => _packet([0xA0]);
Uint8List buildStepsRequest() => _packet([0xA8]);
Uint8List buildHrStart() => _packet([0xD0, 0x01]);
Uint8List buildHrStop() => _packet([0xD0, 0x00]);

/// Parola + saat senkronu. Saat dilimi 15 dakikalık birim olarak gönderilir.
Uint8List buildPasswordPacket({
  required DateTime now,
  required int timezoneOffsetMinutes,
  String pwd = '0000',
  bool is24h = true,
}) {
  if (!RegExp(r'^\d{4}$').hasMatch(pwd)) {
    throw ArgumentError.value(pwd, 'pwd', '4 haneli rakam olmalı');
  }
  final n = int.parse(pwd);
  return _packet([
    0xA1,
    n & 0xFF,
    (n >> 8) & 0xFF,
    0,
    now.year >> 8,
    now.year & 0xFF,
    now.month,
    now.day,
    now.hour,
    now.minute,
    now.second,
    is24h ? 1 : 0,
    1,
    (timezoneOffsetMinutes ~/ 15) & 0xFF,
    0,
  ]);
}

enum BandFrameKind { password, battery, steps, heartRate, deviceInfo, unknown }

BandFrameKind classifyFrame(Uint8List f) {
  if (f.isEmpty) return BandFrameKind.unknown;
  switch (f[0]) {
    case 0xA1:
      return BandFrameKind.password;
    case 0xA0:
      return BandFrameKind.battery;
    case 0xA8:
      return BandFrameKind.steps;
    case 0xD0:
      return BandFrameKind.heartRate;
    case 0xA7:
    case 0xAD:
    case 0xB8:
      return BandFrameKind.deviceInfo;
    default:
      return BandFrameKind.unknown;
  }
}

/// Günlük adım sayacı: bayt 1-4 büyük-uçlu.
int? parseSteps(Uint8List f) {
  if (f.length < 5) return null;
  return (f[1] << 24) | (f[2] << 16) | (f[3] << 8) | f[4];
}

class BatteryInfo {
  const BatteryInfo(this.percent);
  final int percent;
}

/// Bayt 5 == 1 → bayt 6 yüzde.
BatteryInfo? parseBattery(Uint8List f) {
  if (f.length < 7 || f[5] != 1) return null;
  return BatteryInfo(f[6]);
}

enum HrStatus { measuring, notWorn, value }

class HrFrame {
  const HrFrame(this.status, [this.bpm]);
  final HrStatus status;
  final int? bpm;
}

/// Bayt 1 = bpm. 0 ölçülüyor, 1/2 takılı değil, 30..210 geçerli; kalan ölçülüyor.
HrFrame parseHr(Uint8List f) {
  final v = f.length > 1 ? f[1] : 0;
  if (v == 1 || v == 2) return const HrFrame(HrStatus.notWorn);
  if (v >= 30 && v <= 210) return HrFrame(HrStatus.value, v);
  return const HrFrame(HrStatus.measuring);
}
