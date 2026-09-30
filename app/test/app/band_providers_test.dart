import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/data/band/band_transport.dart';
import 'package:vitax_app/features/band/band_status.dart';

import '../support/fake_band_transport.dart';

void main() {
  late FakeBandTransport transport;
  late ProviderContainer container;

  setUp(() {
    transport = FakeBandTransport();
    container = ProviderContainer(
      overrides: [
        bandTransportProvider.overrideWithValue(transport),
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 24, 10)),
      ],
    );
  });
  tearDown(() => container.dispose());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('varsayılan durum: bağlı değil, pil bilinmiyor', () {
    final s = container.read(bandStatusProvider);
    expect(s.connected, isFalse);
    expect(s.battery, isNull);
  });

  test('bant durumu controller ile güncellenir', () async {
    container.read(bandStatusProvider);
    final c = container.read(bandControllerProvider);
    await c.connect();
    transport.emit('a100000006176c0373');
    transport.emit('a0000000620162');
    await settle();
    final s = container.read(bandStatusProvider);
    expect(s.connected, isTrue);
    expect(s.battery, 98);
    expect(s.link, BandLink.connected);
  });

  test('liveHrProvider geçerli nabızları HrReading olarak akıtır', () async {
    final got = <int>[];
    container.listen(liveHrProvider, (_, n) {
      final v = n.value;
      if (v != null) got.add(v.bpm);
    });
    final c = container.read(bandControllerProvider);
    await c.connect();
    transport.emit('a100000006176c0373');
    await settle();
    await c.startLiveHr();
    transport.emit('d067');
    await settle();
    expect(got, [103]);
  });

  test('bant yokken (varsayılan taşıyıcı) bağlanma hata verir, çökmez', () async {
    final c2 = ProviderContainer();
    addTearDown(c2.dispose);
    await c2.read(bandControllerProvider).connect();
    expect(c2.read(bandControllerProvider).state.connected, isFalse);
    expect(c2.read(bandControllerProvider).state.error, isNotNull);
  });
}
