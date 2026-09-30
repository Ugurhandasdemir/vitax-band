import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';
import '../../data/band/band_transport.dart';
import 'band_status.dart';

/// Kırmızı/mavi sol şeritli kompakt durum bildirimi (Bağlantı Durumları tasarımı).
class BandBanner extends StatelessWidget {
  BandBanner({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    required this.message,
    this.tag,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String message;
  final String? tag;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: VColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(VRadius.card),
      border: Border(
        left: BorderSide(color: color, width: 4),
        top: const BorderSide(color: VColors.surfaceContainerHighest),
        right: const BorderSide(color: VColors.surfaceContainerHighest),
        bottom: const BorderSide(color: VColors.surfaceContainerHighest),
      ),
    ),
    padding: const EdgeInsets.all(VSpace.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: VSpace.sm),
            Expanded(
              child: Text(
                title,
                style: VText.bodyLgMedium.copyWith(color: color),
              ),
            ),
            if (tag != null) Text(tag!, style: VText.microTag),
          ],
        ),
        const SizedBox(height: VSpace.sm),
        Text(message, style: VText.bodyMd),
        if (actionLabel != null) ...[
          const SizedBox(height: VSpace.gutter),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                shape: const StadiumBorder(),
              ),
              child: Text(actionLabel!),
            ),
          ),
        ],
      ],
    ),
  );
}

/// Bant durumuna göre şerit: kopuk / bağlanıyor / hata. Bağlıysa boş.
class BandStatusBanner extends ConsumerWidget {
  const BandStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(bandStatusProvider);
    final c = ref.read(bandControllerProvider);
    if (s.link == BandLink.connected) return const SizedBox.shrink();
    if (s.link == BandLink.connecting) {
      return BandBanner(
        color: VColors.primary,
        icon: Icons.sync,
        title: 'Bağlanıyor',
        message: 'VitaxBand aranıyor, bilekliği telefona yaklaştır.',
      );
    }
    if (s.error != null) {
      return BandBanner(
        color: VColors.error,
        icon: Icons.sync_problem,
        title: 'Bağlantı Başarısız',
        message: s.error!,
        actionLabel: 'Tekrar Dene',
        onAction: c.connect,
      );
    }
    return BandBanner(
      color: VColors.error,
      icon: Icons.bluetooth_disabled,
      title: 'Bağlantı Kesildi',
      tag: 'Kritik',
      message: 'VitaxBand bağlantısı yok (menzil dışı veya Bluetooth kapalı).',
      actionLabel: 'Yeniden Bağlan',
      onAction: c.connect,
    );
  }
}

class BandMetricTile extends StatelessWidget {
  const BandMetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => VCard(
    padding: const EdgeInsets.all(VSpace.sm),
    child: Column(
      children: [
        Icon(icon, size: 18, color: VColors.error),
        const SizedBox(height: 2),
        Text(label, style: VText.microTag),
        Text(value, style: VText.bodyMdMedium),
      ],
    ),
  );
}
