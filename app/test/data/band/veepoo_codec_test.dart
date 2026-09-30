import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/band/veepoo_codec.dart';

Uint8List hex(String h) => Uint8List.fromList([
      for (var i = 0; i < h.length; i += 2) int.parse(h.substring(i, i + 2), radix: 16),
    ]);

String toHex(Uint8List b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

String pad20(String h) => h.padRight(40, '0');

void main() {
  group('istek paketleri (20 bayt)', () {
    test('pil, adım, nabız başlat/durdur', () {
      expect(toHex(buildBatteryRequest()), pad20('a000'));
      expect(toHex(buildStepsRequest()), pad20('a800'));
      expect(toHex(buildHrStart()), pad20('d001'));
      expect(toHex(buildHrStop()), pad20('d000'));
      expect(buildStepsRequest().length, 20);
    });

    test('parola paketi: gerçek bantta çalışan Python çıktısıyla aynı', () {
      // 2026-09-30 21:30:15, UTC+3 (12 x 15 dk), 24 saat, parola 0000
      final p = buildPasswordPacket(
          now: DateTime(2026, 9, 30, 21, 30, 15), timezoneOffsetMinutes: 180);
      expect(toHex(p), pad20('a100000007ea091e15 1e0f01010c00'.replaceAll(' ', '')));
      expect(p.length, 20);
    });

    test('parola 16 bit küçük-uçlu yazılır', () {
      final p = buildPasswordPacket(
          now: DateTime(2026, 1, 2, 3, 4, 5), timezoneOffsetMinutes: 0, pwd: '1234');
      expect(p[1], 0xD2);
      expect(p[2], 0x04);
    });

    test('12 saat modu işareti', () {
      final p = buildPasswordPacket(
          now: DateTime(2026, 1, 2, 3, 4, 5), timezoneOffsetMinutes: 0, is24h: false);
      expect(p[11], 0);
    });

    test('negatif saat dilimi ikili tümleyen bayt olur', () {
      final p = buildPasswordPacket(
          now: DateTime(2026, 1, 2, 3, 4, 5), timezoneOffsetMinutes: -300); // UTC-5
      expect(p[13], (-20) & 0xFF);
    });

    test('geçersiz parola reddedilir', () {
      expect(() => buildPasswordPacket(now: DateTime(2026), timezoneOffsetMinutes: 0, pwd: 'abcd'),
          throwsArgumentError);
      expect(() => buildPasswordPacket(now: DateTime(2026), timezoneOffsetMinutes: 0, pwd: '12345'),
          throwsArgumentError);
    });
  });

  group('çerçeve sınıflandırma', () {
    test('ilk bayta göre', () {
      expect(classifyFrame(hex(pad20('a1'))), BandFrameKind.password);
      expect(classifyFrame(hex(pad20('a0'))), BandFrameKind.battery);
      expect(classifyFrame(hex(pad20('a8'))), BandFrameKind.steps);
      expect(classifyFrame(hex(pad20('d0'))), BandFrameKind.heartRate);
      expect(classifyFrame(hex(pad20('a7'))), BandFrameKind.deviceInfo);
      expect(classifyFrame(hex(pad20('ad'))), BandFrameKind.deviceInfo);
      expect(classifyFrame(hex(pad20('b8'))), BandFrameKind.deviceInfo);
      expect(classifyFrame(hex(pad20('77'))), BandFrameKind.unknown);
      expect(classifyFrame(Uint8List(0)), BandFrameKind.unknown);
    });
  });

  group('adım', () {
    test('bayt 1-4 büyük-uçlu sayaç', () {
      expect(parseSteps(hex(pad20('a800000126'))), 294);
      expect(parseSteps(hex(pad20('a800000158'))), 344);
      expect(parseSteps(hex(pad20('a8000027f0'))), 10224);
    });
    test('kısa çerçeve null', () {
      expect(parseSteps(hex('a80000')), isNull);
    });
  });

  group('pil', () {
    test('yüzde modu: bayt6 yüzde', () {
      final b = parseBattery(hex(pad20('a000000062016201')));
      expect(b!.percent, 98);
    });
    test('kısa çerçeve null', () => expect(parseBattery(hex('a00000')), isNull));
  });

  group('nabız', () {
    test('bpm 0: ölçülüyor', () {
      final h = parseHr(hex(pad20('d000')));
      expect(h.status, HrStatus.measuring);
      expect(h.bpm, isNull);
    });
    test('bpm 1 ve 2: bant takılı değil', () {
      expect(parseHr(hex(pad20('d001'))).status, HrStatus.notWorn);
      expect(parseHr(hex(pad20('d002'))).status, HrStatus.notWorn);
    });
    test('30..210 geçerli değer', () {
      final h = parseHr(hex(pad20('d078')));
      expect(h.status, HrStatus.value);
      expect(h.bpm, 120);
      expect(parseHr(hex(pad20('d01e'))).bpm, 30);
      expect(parseHr(hex(pad20('d0d2'))).bpm, 210);
    });
    test('210 üstü ve 3..29 arası ölçülüyor sayılır', () {
      expect(parseHr(hex(pad20('d0d3'))).status, HrStatus.measuring);
      expect(parseHr(hex(pad20('d00a'))).status, HrStatus.measuring);
    });
  });

  group('gerçek yürüyüş kaydı (band_frames.json)', () {
    final frames = (jsonDecode(File('test/fixtures/band_frames.json').readAsStringSync())
            as List)
        .map((e) => hex((e as Map)['hex'] as String))
        .toList();

    test('her çerçeve bilinen türde ve 20 bayt', () {
      for (final f in frames) {
        expect(f.length, 20);
        expect(classifyFrame(f), isNot(BandFrameKind.unknown), reason: toHex(f));
      }
    });

    test('adım çerçeveleri 294 ve 344 verir', () {
      final steps = frames
          .where((f) => classifyFrame(f) == BandFrameKind.steps)
          .map(parseSteps)
          .toList();
      expect(steps, containsAll([294, 344]));
    });

    test('pil %98', () {
      final b = frames.where((f) => classifyFrame(f) == BandFrameKind.battery).first;
      expect(parseBattery(b)!.percent, 98);
    });

    test('nabız çerçeveleri: ölçülüyor, takılı değil ve geçerli değerler görülür', () {
      final hr = frames.where((f) => classifyFrame(f) == BandFrameKind.heartRate).map(parseHr).toList();
      expect(hr.any((h) => h.status == HrStatus.measuring), isTrue);
      final values = hr.where((h) => h.status == HrStatus.value).map((h) => h.bpm!).toList();
      expect(values, isNotEmpty);
      expect(values.every((v) => v >= 100 && v <= 140), isTrue);
    });
  });
}
