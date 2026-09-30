import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/features/band/band_connect_screen.dart';
import 'package:vitax_app/features/band/my_band_screen.dart';
import 'package:vitax_app/features/shell/top_bar.dart';

import '../../support/fake_band_transport.dart';
import '../../support/pump.dart';

Future<void> settle(WidgetTester t) async {
  await t.runAsync(() => Future<void>.delayed(Duration.zero));
  await t.pumpAndSettle();
}

void main() {
  late FakeBandTransport transport;
  setUp(() => transport = FakeBandTransport());

  Future<TestEnv> open(WidgetTester t, Widget screen) => pumpScreen(
    t,
    screen,
    overrides: [bandTransportProvider.overrideWithValue(transport)],
  );

  Future<void> handshake(WidgetTester t, TestEnv env) async {
    await t.runAsync(() async {
      await env.container.read(bandControllerProvider).connect();
      transport.emit('a100000006176c0373');
      await Future<void>.delayed(Duration.zero);
    });
    await t.pumpAndSettle();
  }

  group('Bileklik Bağla', () {
    testWidgets('bağlı değilken açıklama, Bağlan düğmesi ve unut ipucu görünür', (t) async {
      await open(t, const BandConnectScreen());
      expect(find.byKey(const ValueKey('screen-band-connect')), findsOneWidget);
      expect(find.text('Bileklik Bağla'), findsOneWidget);
      expect(find.byKey(const ValueKey('band-connect-btn')), findsOneWidget);
      expect(find.textContaining('Bu Cihazı Unut'), findsOneWidget);
      expect(find.textContaining('telefonunda'), findsWidgets);
    });

    testWidgets('Bağlan: taşıyıcı bağlanır, parola cevabı gelince başarı kartı', (t) async {
      final env = await open(t, const BandConnectScreen());
      await t.runAsync(() async {
        await t.tap(find.byKey(const ValueKey('band-connect-btn')));
        await Future<void>.delayed(Duration.zero);
      });
      await t.pump();
      expect(find.textContaining('Bağlanıyor'), findsWidgets);
      expect(transport.written.first[0], 0xA1);

      await t.runAsync(() async {
        transport.emit('a100000006176c0373');
        transport.emit('a0000000620162');
        await Future<void>.delayed(Duration.zero);
      });
      await t.pumpAndSettle();
      expect(find.text('Bağlantı Başarılı!'), findsOneWidget);
      expect(find.text('%98'), findsWidgets);
      expect(env.container.read(bandControllerProvider).state.connected, isTrue);
    });

    testWidgets('bağlanma hatası mesajı ve Tekrar Dene görünür', (t) async {
      transport.failConnect = true;
      await open(t, const BandConnectScreen());
      await t.runAsync(() async {
        await t.tap(find.byKey(const ValueKey('band-connect-btn')));
        await Future<void>.delayed(Duration.zero);
      });
      await t.pumpAndSettle();
      expect(find.textContaining('bağlanılamadı'), findsOneWidget);
      expect(find.text('Tekrar Dene'), findsOneWidget);
    });

    testWidgets('bağlıyken Kurulumu Tamamla ekranı kapatır', (t) async {
      late TestEnv env;
      await t.pumpWidget(const SizedBox());
      env = await open(
        t,
        Builder(
          builder: (c) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(c).push(
                MaterialPageRoute<void>(builder: (_) => const BandConnectScreen()),
              ),
              child: const Text('aç'),
            ),
          ),
        ),
      );
      await t.tap(find.text('aç'));
      await t.pumpAndSettle();
      await handshake(t, env);
      await tapVisible(t, find.byKey(const ValueKey('band-finish-btn')));
      expect(find.byKey(const ValueKey('screen-band-connect')), findsNothing);
    });
  });

  group('Bilekliğim', () {
    testWidgets('bağlıyken pil, son senkron ve dürüst sensör listesi', (t) async {
      final env = await open(t, const MyBandScreen());
      await handshake(t, env);
      await t.runAsync(() async {
        transport.emit('a0000000620162');
        transport.emit('a800000126');
        await Future<void>.delayed(Duration.zero);
      });
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-my-band')), findsOneWidget);
      expect(find.text('%98'), findsWidgets);
      expect(find.text('Bağlı (Bluetooth BLE)'), findsOneWidget);
      expect(find.text('az önce'), findsOneWidget);
      await t.scrollUntilVisible(find.text('Nabız sensörü (PPG)'), 200);
      expect(find.text('Nabız sensörü (PPG)'), findsOneWidget);
      expect(find.text('Adım sayacı'), findsOneWidget);
      expect(find.text('Doğrulanmadı'), findsWidgets);
      // uydurma ayar yok
      expect(find.byType(Switch), findsNothing);
    });

    testWidgets('Şimdi Senkronla pil ve adım ister', (t) async {
      final env = await open(t, const MyBandScreen());
      await handshake(t, env);
      final before = transport.written.length;
      await t.runAsync(() async {
        await t.tap(find.byKey(const ValueKey('band-sync-btn')));
        await Future<void>.delayed(Duration.zero);
      });
      expect(transport.writtenOpcodes.skip(before), containsAll(['a0', 'a8']));
    });

    testWidgets('bağlı değilken Bağlantı Kesildi şeridi ve Yeniden Bağlan', (t) async {
      await open(t, const MyBandScreen());
      expect(find.text('Bağlantı Kesildi'), findsOneWidget);
      await t.runAsync(() async {
        await t.tap(find.text('Yeniden Bağlan'));
        await Future<void>.delayed(Duration.zero);
      });
      await t.pump();
      expect(transport.written, isNotEmpty);
    });

    testWidgets('Bağlantıyı Kes: bağlantı kapanır', (t) async {
      final env = await open(t, const MyBandScreen());
      await handshake(t, env);
      await t.scrollUntilVisible(find.byKey(const ValueKey('band-disconnect-btn')), 300);
      await t.runAsync(() async {
        await t.tap(find.byKey(const ValueKey('band-disconnect-btn')));
        await Future<void>.delayed(Duration.zero);
      });
      await t.pumpAndSettle();
      expect(env.container.read(bandControllerProvider).state.connected, isFalse);
    });
  });

  group('Üst bar bant çipi', () {
    testWidgets('dokununca bant hiç bağlanmadıysa Bileklik Bağla açılır', (t) async {
      await open(
        t,
        const Scaffold(appBar: VTopBar(subtitle: 'test', onAvatarTap: _noop)),
      );
      await t.tap(find.byKey(const ValueKey('band-status-chip')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-band-connect')), findsOneWidget);
    });

    testWidgets('bağlıyken Bilekliğim açılır', (t) async {
      final env = await open(
        t,
        const Scaffold(appBar: VTopBar(subtitle: 'test', onAvatarTap: _noop)),
      );
      await handshake(t, env);
      await t.tap(find.byKey(const ValueKey('band-status-chip')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('screen-my-band')), findsOneWidget);
    });
  });
}

void _noop() {}
