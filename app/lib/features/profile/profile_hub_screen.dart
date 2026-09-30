import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';
import '../band/band_connect_screen.dart';
import '../settings/data_vault_screen.dart';
import '../settings/notifications_screen.dart';
import '../weight/weight_screen.dart';
import 'profile_screen.dart';

class ProfileHubScreen extends StatelessWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => screen));

    final entries = <(IconData, String, VoidCallback?)>[
      (
        Icons.person_outline,
        'Profil ve Hedefler',
        () => open(const ProfileScreen()),
      ),
      (
        Icons.monitor_weight_outlined,
        'Kilo Analizi',
        () => open(const WeightScreen()),
      ),
      (
        Icons.watch_outlined,
        'Bilekliğim',
        () => open(const BandConnectScreen()),
      ),
      (
        Icons.lock_outline,
        'Veri Kasası ve Gizlilik',
        () => open(const DataVaultScreen()),
      ),
      (
        Icons.notifications_none,
        'Bildirimler ve Uyarılar',
        () => open(const NotificationsScreen()),
      ),
    ];
    return Scaffold(
      key: const ValueKey('screen-profile-hub'),
      backgroundColor: VColors.background,
      appBar: AppBar(
        backgroundColor: VColors.surface,
        elevation: 0,
        title: Text('Profil', style: VText.headlineMd),
      ),
      body: ListView(
        padding: const EdgeInsets.all(VSpace.margin),
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: VSpace.gutter),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: e.$3,
                child: VCard(
                  child: Row(
                    children: [
                      Icon(e.$1, color: VColors.primary),
                      const SizedBox(width: VSpace.md),
                      Expanded(child: Text(e.$2, style: VText.labelMd)),
                      Icon(
                        Icons.chevron_right,
                        color: e.$3 == null
                            ? VColors.outlineVariant
                            : VColors.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
