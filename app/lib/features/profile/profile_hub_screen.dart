import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

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
        PhosphorIconsRegular.user,
        'Profil ve Hedefler',
        () => open(const ProfileScreen()),
      ),
      (
        PhosphorIconsRegular.scales,
        'Kilo Analizi',
        () => open(const WeightScreen()),
      ),
      (
        PhosphorIconsRegular.watch,
        'Bilekliğim',
        () => open(const BandConnectScreen()),
      ),
      (
        PhosphorIconsRegular.lock,
        'Veri Kasası ve Gizlilik',
        () => open(const DataVaultScreen()),
      ),
      (
        PhosphorIconsRegular.bell,
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
                        PhosphorIconsRegular.caretRight,
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
