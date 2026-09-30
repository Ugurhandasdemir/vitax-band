import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../data/band/band_transport.dart';
import 'band_status.dart';
import 'band_widgets.dart';

class BandConnectScreen extends ConsumerWidget {
  const BandConnectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bandStatusProvider);
    final c = ref.read(bandControllerProvider);
    return VDetailScaffold(
      title: 'Bileklik Bağla',
      body: ListView(
        key: const ValueKey('screen-band-connect'),
        padding: const EdgeInsets.all(VSpace.margin),
        children: [
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bluetooth İzni Gerekli', style: VText.bodyLgMedium),
                SizedBox(height: VSpace.sm),
                Text(
                  'VitaxBand doğrudan düşük enerjili Bluetooth (BLE) ile bağlanır. '
                  'Veriler yalnızca telefonunda saklanır, buluta gitmez.',
                  style: VText.bodyMd,
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          if (s.connected)
            _Success(s: s)
          else
            _Hero(s: s, onConnect: c.connect),
          const SizedBox(height: VSpace.md),
          VCard(
            color: VColors.surfaceContainerLow,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.help_outline, color: VColors.onSurfaceVariant),
                SizedBox(width: VSpace.gutter),
                Expanded(
                  child: Text(
                    'Cihazın görünmüyor mu? Bilekliği şarja takıp dene. '
                    'iPhone Ayarlar > Bluetooth\'ta VitaxBand kayıtlıysa '
                    '"Bu Cihazı Unut" de; bant aynı anda tek telefona bağlanır.',
                    style: VText.bodyMd,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottom: s.connected
          ? Padding(
              padding: const EdgeInsets.all(VSpace.margin),
              child: FilledButton(
                key: const ValueKey('band-finish-btn'),
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text('Kurulumu Tamamla'),
              ),
            )
          : null,
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.s, required this.onConnect});
  final BandState s;
  final Future<void> Function() onConnect;

  @override
  Widget build(BuildContext context) {
    final busy = s.link == BandLink.connecting;
    return VCard(
      child: Column(
        children: [
          const SizedBox(height: VSpace.sm),
          const CircleAvatar(
            radius: 44,
            backgroundColor: VColors.primaryFixed,
            child: Icon(Icons.watch, size: 40, color: VColors.primary),
          ),
          const SizedBox(height: VSpace.md),
          Text(
            busy ? 'VitaxBand Bağlanıyor…' : 'VitaxBand Bağlı Değil',
            style: VText.headlineMd,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: VSpace.sm),
          Text(
            busy ? 'Bilekliğini telefonuna 30 cm mesafede tut.' : 'Adım, canlı nabız ve antrenman verisi için bilekliği Bluetooth ile bağla.',
            style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (s.error != null) ...[
            const SizedBox(height: VSpace.sm),
            Text(
              s.error!,
              style: VText.bodyMd.copyWith(color: VColors.error),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: VSpace.md),
          if (busy)
            const CircularProgressIndicator()
          else
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('band-connect-btn'),
                onPressed: onConnect,
                icon: const Icon(Icons.bluetooth),
                label: Text(s.error != null ? 'Tekrar Dene' : 'Bağlan'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Success extends StatelessWidget {
  const _Success({required this.s});
  final BandState s;

  @override
  Widget build(BuildContext context) => VCard(
    color: VColors.tertiaryFixed,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle, color: VColors.tertiary),
            const SizedBox(width: VSpace.sm),
            Expanded(
              child: Text('Bağlantı Başarılı!', style: VText.headlineMd),
            ),
            if (s.battery != null)
              Text('%${s.battery}', style: VText.bodyMdMedium),
          ],
        ),
        const SizedBox(height: VSpace.md),
        Row(
          children: [
            Expanded(
              child: BandMetricTile(
                icon: Icons.battery_std,
                label: 'PİL',
                value: s.battery == null ? '--' : '%${s.battery}',
              ),
            ),
            const SizedBox(width: VSpace.sm),
            Expanded(
              child: BandMetricTile(
                icon: Icons.directions_walk,
                label: 'ADIM',
                value: s.steps == null ? 'Bekleniyor' : formatTr(s.steps!),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
