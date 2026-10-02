import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';

class ExtraSensorsScreen extends StatefulWidget {
  const ExtraSensorsScreen({super.key});

  @override
  State<ExtraSensorsScreen> createState() => _ExtraSensorsScreenState();
}

class _ExtraSensorsScreenState extends State<ExtraSensorsScreen> {
  bool _showSupported = true;

  @override
  Widget build(BuildContext context) {
    return VDetailScaffold(
      title: 'Ek Sensörler',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.md),
        children: [
          // Subtitle & Device Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DONANIM & TEŞHİS', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: VColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: VColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('VitaxBand Pro • BLE 5.2', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'VitaxBand ek biyometrik sensör durumları ve donanım desteği.',
            style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
          ),
          const SizedBox(height: VSpace.md),

          // Toggle Mode
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.slidersHorizontal, size: 18, color: VColors.secondary),
                    const SizedBox(width: 6),
                    Text('Önizleme Modu', style: VText.labelMd),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: VColors.surface,
                    borderRadius: BorderRadius.circular(VRadius.sm),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showSupported = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _showSupported ? VColors.primaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(VRadius.sm),
                            ),
                            child: Text(
                              'DESTEKLENEN',
                              style: VText.labelCaps.copyWith(
                                color: _showSupported ? VColors.onPrimaryContainer : VColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _showSupported = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !_showSupported ? VColors.primaryContainer : Colors.transparent,
                              borderRadius: BorderRadius.circular(VRadius.sm),
                            ),
                            child: Text(
                              'DESTEKLENMEYEN',
                              style: VText.labelCaps.copyWith(
                                color: !_showSupported ? VColors.onPrimaryContainer : VColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),

          // SENSOR 1: SpO2
          _buildSensorSection(
            title: 'SpO2 (Kandaki Oksijen)',
            icon: PhosphorIconsRegular.drop,
            iconColor: VColors.secondary,
            badge: _showSupported ? 'AKTİF MODÜL' : 'DOĞRULANMADI',
            badgeBg: _showSupported ? VColors.secondary : VColors.surfaceContainerHighest,
            badgeTextColor: _showSupported ? VColors.onSecondary : VColors.onSurfaceVariant,
            child: _showSupported
                ? Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('DOYGUNLUK ORANI', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('%97 ', style: VText.displayLg.copyWith(fontWeight: FontWeight.w800)),
                                  Text('Normal Düzey', style: VText.labelMd.copyWith(color: VColors.tertiary)),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('HEDEF ARALIK', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('%95 - %100', style: VText.bodyMdMedium),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: VSpace.sm),
                      Container(
                        padding: const EdgeInsets.all(VSpace.sm),
                        decoration: BoxDecoration(
                          color: VColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(VRadius.sm),
                        ),
                        child: Row(
                          children: [
                            const Icon(PhosphorIconsRegular.broadcast, size: 16, color: VColors.primary),
                            const SizedBox(width: 6),
                            Text('Son: 12 dk önce • Kızılötesi Sensör', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  )
                : _buildUnsupportedCard(
                    title: 'Bandınız desteklemiyor',
                    tag: 'DONANIM YOK',
                    desc: 'SpO2 sensörü donanımınızda henüz protokol olarak doğrulanmadı. Temel modelde yer almamaktadır.',
                  ),
          ),
          const SizedBox(height: VSpace.md),

          // SENSOR 2: Tansiyon
          _buildSensorSection(
            title: 'Tansiyon Ölçümü',
            icon: PhosphorIconsFill.heartbeat,
            iconColor: VColors.primary,
            badge: 'MEVCUT MODELDE YOK',
            badgeBg: VColors.surfaceContainerHighest,
            badgeTextColor: VColors.onSurfaceVariant,
            child: _buildUnsupportedCard(
              title: 'Bandınız desteklemiyor',
              tag: 'DONANIM KISITLAMASI',
              desc: 'Bağlı olan VitaxBand donanımınız optik tansiyon (PTT) sensörüne sahip değildir. Bu özelliği harici aletle takip edebilirsiniz.',
              action: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Manuel tansiyon girişi açılıyor')),
                    );
                  },
                  icon: const Icon(PhosphorIconsRegular.plus, size: 18),
                  label: const Text('Manuel Tansiyon Gir'),
                ),
              ),
            ),
          ),
          const SizedBox(height: VSpace.md),

          // SENSOR 3: Cilt Sıcaklığı
          _buildSensorSection(
            title: 'Cilt Sıcaklığı',
            icon: PhosphorIconsRegular.thermometerSimple,
            iconColor: VColors.tertiary,
            badge: _showSupported ? 'AKTİF MODÜL' : 'DOĞRULANMADI',
            badgeBg: _showSupported ? VColors.tertiary : VColors.surfaceContainerHighest,
            badgeTextColor: _showSupported ? VColors.onTertiary : VColors.onSurfaceVariant,
            child: _showSupported
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text('36.4 ', style: VText.displayLg.copyWith(fontWeight: FontWeight.w800)),
                              Text('°C', style: VText.headlineMd),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: VColors.tertiary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(VRadius.sm),
                            ),
                            child: Text('±0.1 °C BAZAL NORMAL', style: VText.labelCaps.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Bileklik temas sensörü ile gece boyunca ideal metabolizma ritmi izlenir.', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                    ],
                  )
                : _buildUnsupportedCard(
                    title: 'Bandınız desteklemiyor',
                    tag: 'DİJİTAL TERMİSTÖR YOK',
                    desc: 'Bileklik donanımında sürekli temaslı termistör modülü doğrulanmamıştır.',
                  ),
          ),
          const SizedBox(height: VSpace.md),

          // SENSOR 4: EKG
          _buildSensorSection(
            title: 'Tıbbi EKG & Aritmi Tespiti',
            icon: PhosphorIconsRegular.heart,
            iconColor: VColors.error,
            badge: 'EK DONANIM GEREKLİ',
            badgeBg: VColors.surfaceContainerHighest,
            badgeTextColor: VColors.onSurfaceVariant,
            child: _buildUnsupportedCard(
              title: 'Bandınız desteklemiyor',
              tag: 'MEDİKAL SÜRÜM',
              desc: 'VitaxBand EKG donanım modülü gerektirir. Tek derivasyonlu elektrokardiyogram yalnızca titanyum gövde elektrotuna sahip medikal sürümde mevcuttur.',
            ),
          ),
          const SizedBox(height: VSpace.md),

          // Legal footnote
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(PhosphorIconsRegular.shieldCheck, size: 16, color: VColors.outline),
                const SizedBox(width: 6),
                Text(
                  'Tıbbi cihaz değildir. Ölçümler referans ve zindelik amaçlıdır.',
                  style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSensorSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String badge,
    required Color badgeBg,
    required Color badgeTextColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 6),
                Text(title, style: VText.headlineMd),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: badgeBg,
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
              child: Text(
                badge,
                style: VText.microTag.copyWith(color: badgeTextColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpace.sm),
        VCard(child: child),
      ],
    );
  }

  Widget _buildUnsupportedCard({
    required String title,
    required String tag,
    required String desc,
    Widget? action,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: VColors.errorContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(VRadius.sm),
              ),
              child: const Icon(PhosphorIconsRegular.warning, color: VColors.error, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VText.labelMd.copyWith(color: VColors.error, fontWeight: FontWeight.bold)),
                Text(tag, style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(desc, style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
        if (action != null) ...[
          const SizedBox(height: VSpace.sm),
          action,
        ],
      ],
    );
  }
}
