import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/band/band_controller.dart';
import 'package:vitax_app/data/band/band_transport.dart';
import 'package:vitax_app/data/band/veepoo_codec.dart';
import 'package:vitax_app/data/repos/band_sample_repository.dart';

import '../../support/fake_band_transport.dart';

void main() {
  late FakeBandTransport transport;
  late InMemoryBandSampleRepository repo;
  late DateTime now;
  late BandController c;
  late List<BandState> states;
  late StreamController<void> ticks;

  setUp(() {
    transport = FakeBandTransport();
    ticks = StreamController<void>.broadcast();
    repo = InMemoryBandSampleRepository();
    now = DateTime(2026, 10, 24, 10, 0, 0);
    c = BandController(
      transport: transport,
      repo: repo,
      clock: () => now,
      pollTicks: ticks.stream,
      timezoneOffsetMinutes: () => 180,
    );
    states = [];
    c.states.listen(states.add);
  });
  tearDown(() => c.dispose());

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  Future<void> connected() async {
    await c.connect();
    transport.emit('a100000006176c0373');
    await settle();
  }

  test('başlangıçta bağlı değil', () {
    expect(c.state.link, BandLink.disconnected);
    expect(c.state.battery, isNull);
  });

  test('bağlanınca ilk paket parola + saat, bağlantı parola cevabıyla tamamlanır', () async {
    await c.connect();
    await settle();
    expect(transport.written.first[0], 0xA1);
    expect(transport.written.first[4], 2026 >> 8);
    expect(c.state.link, BandLink.connecting, reason: 'parola cevabı gelmeden hazır değil');
    transport.emit('a100000006176c0373');
    await settle();
    expect(c.state.link, BandLink.connected);
  });

  test('hazır olunca pil ve adım istenir', () async {
    await connected();
    expect(transport.writtenOpcodes, containsAllInOrder(['a1', 'a0', 'a8']));
  });

  test('bağlanma hatası durumu kopuk bırakır ve hata taşır', () async {
    transport.failConnect = true;
    await c.connect();
    expect(c.state.link, BandLink.disconnected);
    expect(c.state.error, isNotNull);
  });

  test('pil paketi yüzdeyi günceller', () async {
    await connected();
    transport.emit('a0000000620162');
    await settle();
    expect(c.state.battery, 98);
  });

  test('adım paketi kaydedilir ve son eşitleme güncellenir', () async {
    await connected();
    transport.emit('a800000126');
    await settle();
    expect(await repo.stepsForDay(DateTime(2026, 10, 24)), 294);
    expect(c.state.lastSync, now);
    expect(c.state.steps, 294);
  });

  test('değişmeyen adım sayacı tekrar kaydedilmez', () async {
    await connected();
    transport.emit('a800000126');
    await settle();
    now = now.add(const Duration(seconds: 60));
    transport.emit('a800000126');
    await settle();
    expect(await repo.stepCount(), 1);
    expect(c.state.lastSync, now, reason: 'eşitleme zamanı yine de ilerler');
    now = now.add(const Duration(seconds: 60));
    transport.emit('a800000158');
    await settle();
    expect(await repo.stepCount(), 2);
  });

  test('canlı nabız: başlat komutu, geçerli değer kaydedilir ve yayınlanır', () async {
    await connected();
    final bpms = <int>[];
    c.liveHr.listen(bpms.add);
    await c.startLiveHr();
    expect(transport.writtenOpcodes.last, 'd0');
    expect(transport.written.last[1], 1);
    expect(c.state.hr, HrStatus.measuring);

    transport.emit('d000');
    await settle();
    expect(c.state.hr, HrStatus.measuring);
    expect(bpms, isEmpty);

    transport.emit('d067');
    await settle();
    expect(bpms, [103]);
    expect(c.state.hr, HrStatus.value);
    expect(c.state.lastBpm, 103);
    expect((await repo.latestHr())!.bpm, 103);
  });

  test('aynı bpm art arda gelirse de yayınlanır (farklı saniye)', () async {
    await connected();
    final bpms = <int>[];
    c.liveHr.listen(bpms.add);
    await c.startLiveHr();
    transport.emit('d067');
    await settle();
    now = now.add(const Duration(seconds: 1));
    transport.emit('d067');
    await settle();
    expect(bpms, [103, 103]);
  });

  test('bant takılı değil paketi durumu notWorn yapar, örnek kaydetmez', () async {
    await connected();
    await c.startLiveHr();
    transport.emit('d001');
    await settle();
    expect(c.state.hr, HrStatus.notWorn);
    expect(await repo.latestHr(), isNull);
  });

  test('nabızı durdur komutu gönderir ve durumu temizler', () async {
    await connected();
    await c.startLiveHr();
    transport.emit('d067');
    await settle();
    await c.stopLiveHr();
    expect(transport.written.last[0], 0xD0);
    expect(transport.written.last[1], 0);
    expect(c.state.hr, isNull);
    expect(c.state.lastBpm, isNull);
  });

  test('bağlı değilken nabız başlatılamaz', () async {
    await c.startLiveHr();
    expect(transport.written, isEmpty);
  });

  test('periyodik yoklama: her tikte pil ve adım yeniden istenir', () async {
    await connected();
    final before = transport.written.length;
    ticks.add(null);
    await settle();
    expect(transport.writtenOpcodes.skip(before), ['a0', 'a8']);
  });

  test('kopukken yoklama tiki komut göndermez', () async {
    await connected();
    transport.dropLink();
    await settle();
    final before = transport.written.length;
    ticks.add(null);
    await settle();
    expect(transport.written.length, before);
  });

  test('bağlantı kopunca durum kopuk olur ve yoklama durur', () async {
    await connected();
    transport.dropLink();
    await settle();
    expect(c.state.link, BandLink.disconnected);
    expect(c.state.hr, isNull);
  });

  test('disconnect canlı nabız açıksa önce durdurur', () async {
    await connected();
    await c.startLiveHr();
    await c.disconnect();
    expect(transport.written.any((w) => w[0] == 0xD0 && w[1] == 0), isTrue);
    expect(c.state.link, BandLink.disconnected);
  });
}
