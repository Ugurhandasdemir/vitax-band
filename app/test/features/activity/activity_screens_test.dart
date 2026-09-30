import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/data/band/band_controller.dart';
import 'package:vitax_app/data/band/band_transport.dart';
import 'package:vitax_app/features/activity/activity_screen.dart';
import 'package:vitax_app/features/activity/extra_sensors_screen.dart';
import 'package:vitax_app/features/activity/heart_health_screen.dart';
import 'package:vitax_app/features/activity/sleep_analysis_screen.dart';
import 'package:vitax_app/features/band/band_status.dart';
import '../../support/fake_band_transport.dart';
import '../../support/pump.dart';

class _FakeBandNotifier extends BandStatusNotifier {
  _FakeBandNotifier(this._initial);
  final BandState _initial;

  @override
  BandState build() => _initial;
}

void main() {
  group('ActivityScreen & Alt Ekranlar (Faz 3)', () {
    testWidgets('ActivityScreen: segmentler, bant kartı ve metrikler görünür',
        (tester) async {
      final fakeTransport = FakeBandTransport();
      await pumpScreen(
        tester,
        const ActivityScreen(),
        overrides: [
          bandTransportProvider.overrideWithValue(fakeTransport),
          bandStatusProvider.overrideWith(() => _FakeBandNotifier(const BandState(
                link: BandLink.connected,
                battery: 92,
                steps: 8432,
              ))),
          liveHrProvider.overrideWith(
              (ref) => Stream.value(HrReading(74))),
        ],
      );

      // Üst segmentler
      expect(find.text('Bugün'), findsOneWidget);
      expect(find.text('Kalp'), findsOneWidget);
      expect(find.text('Uyku'), findsOneWidget);
      expect(find.text('Antrenman'), findsOneWidget);
      expect(find.text('Kilo'), findsOneWidget);

      // VitaxBand kartı
      expect(find.text('VitaxBand bağlı'), findsOneWidget);
      expect(find.textContaining('%92'), findsWidgets);
      expect(find.text('Şimdi senkronla'), findsOneWidget);

      // Metrikler
      expect(find.text('8.432'), findsOneWidget);
      expect(find.text('Adım Sayısı'), findsOneWidget);
      expect(find.text('Aktif Kalori'), findsOneWidget);

      // Canlı Nabız
      expect(find.textContaining('74 bpm'), findsOneWidget);

      // Dürüst Sensör Durumları
      expect(find.text('Bileklik Sensörleri', skipOffstage: false), findsOneWidget);
      expect(find.text('Bandınız desteklemiyor', skipOffstage: false), findsWidgets);
    });

    testWidgets('ActivityScreen: bant bağlı değilken bağlan butonu gösterilir',
        (tester) async {
      await pumpScreen(
        tester,
        const ActivityScreen(),
        overrides: [
          bandStatusProvider.overrideWith(() => _FakeBandNotifier(const BandState())),
        ],
      );

      expect(find.text('VitaxBand bağlı değil'), findsOneWidget);
      expect(find.text('Bileklik Bağla'), findsOneWidget);
    });

    testWidgets('HeartHealthScreen: canlı nabız, 24 saatlik grafik ve zonlar',
        (tester) async {
      await pumpScreen(
        tester,
        const HeartHealthScreen(),
        overrides: [
          liveHrProvider.overrideWith(
              (ref) => Stream.value(HrReading(74))),
          bandStatusProvider.overrideWith(() => _FakeBandNotifier(const BandState(
                link: BandLink.connected,
                battery: 88,
              ))),
        ],
      );

      expect(find.text('Kalp Sağlığı'), findsOneWidget);
      expect(find.text('Canlı Ölçüm'), findsOneWidget);
      expect(find.text('74'), findsWidgets);
      expect(find.text('BPM'), findsWidgets);
      expect(find.text('Şimdi Ölç (30s PPG)'), findsOneWidget);
      expect(find.text('24-Saatlik Nabız Çizelgesi', skipOffstage: false), findsOneWidget);
      expect(find.text('Kalp Hızı Bölgeleri', skipOffstage: false), findsOneWidget);
      expect(find.text('HRV & Stres Seviyesi', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('Tıbbi cihaz değildir', skipOffstage: false), findsOneWidget);
    });

    testWidgets('SleepAnalysisScreen: süre, evreler ve dürüst boş durum',
        (tester) async {
      await pumpScreen(
        tester,
        const SleepAnalysisScreen(),
      );

      expect(find.text('Uyku Analizi'), findsOneWidget);
      expect(find.text('Geçen Geceki Uyku'), findsOneWidget);
      expect(find.text('Uyku Evreleri', skipOffstage: false), findsOneWidget);
      expect(find.text('7 Gecelik Eğilim', skipOffstage: false), findsOneWidget);
      expect(find.text('VitaxBand AI Koç Notu', skipOffstage: false), findsOneWidget);
    });

    testWidgets('ExtraSensorsScreen: desteklenmeyen sensörler dürüstçe belirtilir',
        (tester) async {
      await pumpScreen(
        tester,
        const ExtraSensorsScreen(),
      );

      expect(find.text('Ek Sensörler'), findsOneWidget);
      expect(find.text('SpO2 (Kandaki Oksijen)', skipOffstage: false), findsOneWidget);
      expect(find.text('Tansiyon Ölçümü', skipOffstage: false), findsOneWidget);
      expect(find.text('Cilt Sıcaklığı', skipOffstage: false), findsOneWidget);
      expect(find.text('Tıbbi EKG & Aritmi Tespiti', skipOffstage: false), findsOneWidget);
      expect(find.textContaining('Bandınız desteklemiyor', skipOffstage: false), findsWidgets);
    });
  });
}
