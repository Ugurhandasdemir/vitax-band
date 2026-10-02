import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../band/band_connect_screen.dart';
import '../band/band_status.dart';
import '../band/my_band_screen.dart';

/// Üst çubuk: avatar (profil merkezi), başlık, bant durum çipi.
class VTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const VTopBar({super.key, required this.subtitle, required this.onAvatarTap});

  final String subtitle;
  final VoidCallback onAvatarTap;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final band = ref.watch(bandStatusProvider);
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.symmetric(horizontal: VSpace.margin),
      decoration: const BoxDecoration(
        color: VColors.surface,
        border: Border(
          bottom: BorderSide(color: VColors.surfaceContainerHighest),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            key: const ValueKey('top-avatar'),
            onTap: onAvatarTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: VColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(PhosphorIconsFill.user, color: VColors.primary),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Vital Precision',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VText.headlineMd,
                ),
                Text(
                  subtitle.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VText.microTag.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => band.connected || band.battery != null
                    ? const MyBandScreen()
                    : const BandConnectScreen(),
              ),
            ),
            child: Container(
              key: const ValueKey('band-status-chip'),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: VColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(VRadius.pill),
                border: Border.all(color: VColors.surfaceContainerHighest),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: band.connected ? VColors.tertiary : VColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    band.battery == null ? '--' : '%${band.battery}',
                    style: VText.microTag,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
