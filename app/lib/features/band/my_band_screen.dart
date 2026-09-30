import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../core/widgets/v_progress_bar.dart';
import 'band_status.dart';
import 'band_widgets.dart';

enum _Support { verified, unverified }

class MyBandScreen extends ConsumerWidget {
  const MyBandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bandStatusProvider);
    final c = ref.read(bandControllerProvider);
    final now = ref.watch(clockProvider)();
    return VDetailScaffold(
      title: 'Bilekliğim',
      body: ListView(
        key: const ValueKey('screen-my-band'),
        padding: const EdgeInsets.all(VSpace.margin),
        children: [
          const BandStatusBanner(),
          if (!s.connected) const SizedBox(height: VSpace.md),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundColor: VColors.surfaceContainer,
                      child: Icon(Icons.watch, color: VColors.primary),
                    ),
                    const SizedBox(width: VSpace.gutter),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('KAYITLI CİHAZ', style: VText.labelCaps),
                          Text('VitaxBand', style: VText.headlineMd),
                          Text(
                            s.connected
                                ? 'Bağlı (Bluetooth BLE)'
                                : 'Bağlı değil',
                            style: VText.bodyMd.copyWith(
                              color: s.connected
                                  ? VColors.tertiary
                                  : VColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      s.battery == null ? '--' : '%${s.battery}',
                      style: VText.headlineLg,
                    ),
                    const SizedBox(width: VSpace.sm),
                    Text('Pil Seviyesi', style: VText.bodyMd),
                  ],
                ),
                const SizedBox(height: VSpace.sm),
                VProgressBar(
                  value: (s.battery ?? 0) / 100,
                  color: VColors.tertiary,
                ),
                const SizedBox(height: VSpace.md),
                Text('SON SENKRONİZASYON', style: VText.labelCaps),
                Text(
                  s.lastSync == null
                      ? 'Henüz yok'
                      : formatAgo(now.difference(s.lastSync!)),
                  style: VText.bodyMd,
                ),
                const SizedBox(height: VSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const ValueKey('band-sync-btn'),
                        onPressed: s.connected ? c.pollNow : null,
                        icon: const Icon(Icons.sync),
                        label: Text('Şimdi Senkronla'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bant Sensörleri', style: VText.bodyLgMedium),
                const SizedBox(height: 2),
                Text(
                  'Yalnız gerçek bantta denenenler "Destekleniyor" görünür.',
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                ),
                const SizedBox(height: VSpace.sm),
                const _SensorRow('Nabız sensörü (PPG)', _Support.verified),
                const _SensorRow('Adım sayacı', _Support.verified),
                const _SensorRow('Pil bilgisi', _Support.verified),
                const _SensorRow('Uyku', _Support.unverified),
                const _SensorRow('SpO2 (kan oksijeni)', _Support.unverified),
                const _SensorRow('Cilt sıcaklığı', _Support.unverified),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          Center(
            child: TextButton.icon(
              key: const ValueKey('band-disconnect-btn'),
              onPressed: s.connected ? c.disconnect : null,
              icon: const Icon(Icons.link_off),
              label: Text('Cihazın Bağlantısını Kes'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorRow extends StatelessWidget {
  const _SensorRow(this.name, this.support);
  final String name;
  final _Support support;

  @override
  Widget build(BuildContext context) {
    final ok = support == _Support.verified;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(name, style: VText.bodyMd)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: ok ? VColors.tertiary : VColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(VRadius.pill),
            ),
            child: Text(
              ok ? 'Destekleniyor' : 'Doğrulanmadı',
              style: VText.microTag.copyWith(
                color: ok ? VColors.onTertiary : VColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
