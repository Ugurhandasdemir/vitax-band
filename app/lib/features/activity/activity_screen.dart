import 'dart:math' as math;
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';
import '../../data/models.dart';
import '../band/band_connect_screen.dart';
import '../band/band_status.dart';
import '../weight/weight_screen.dart';
import '../workout/workout_history_screen.dart';
import 'extra_sensors_screen.dart';
import 'heart_health_screen.dart';
import 'sleep_analysis_screen.dart';

class ActivityScreen extends ConsumerStatefulWidget {
  const ActivityScreen({super.key});

  @override
  ConsumerState<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends ConsumerState<ActivityScreen> {
  int _selectedSegment = 0;
  static const _segments = ['Bugün', 'Kalp', 'Uyku', 'Antrenman', 'Kilo'];

  bool _isSyncing = false;

  Future<void> _handleSync() async {
    setState(() => _isSyncing = true);
    try {
      await ref.read(bandControllerProvider).pollNow();
    } catch (_) {}
    if (mounted) {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final band = ref.watch(bandStatusProvider);
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final profile = ref.watch(profileProvider).value ?? const Profile();
    final liveHr = ref.watch(liveHrProvider).value?.bpm ?? 74;

    final int steps = (band.steps != null && band.steps! > 0) ? band.steps! : 8432;
    const stepGoal = 10000;
    final km = (steps * 0.00075).toStringAsFixed(1);
    final int remainingSteps = math.max(0, stepGoal - steps);

    final burnedKcal = ref.watch(burnedKcalProvider(today)).value ?? 412;
    const burnedGoal = 500;
    final burnedPct = ((burnedKcal / burnedGoal) * 100).toInt().clamp(0, 100);

    return Scaffold(
      key: const ValueKey('screen-activity'),
      backgroundColor: VColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.xs),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: VColors.primary,
                          borderRadius: BorderRadius.circular(VRadius.sm),
                        ),
                        child: const Icon(PhosphorIconsRegular.lightning, color: VColors.onPrimary, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Text('Vital Precision', style: VText.headlineMd),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(VRadius.pill),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: band.connected ? VColors.tertiary : VColors.outlineVariant,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          PhosphorIconsBold.watch,
                          size: 15,
                          color: band.connected ? VColors.tertiary : VColors.outlineVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          band.connected ? '%${band.battery ?? 92}' : 'Bağlı değil',
                          style: VText.microTag.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VSpace.xs),

            // Segmented Top Filter Bar
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: VSpace.margin),
                itemCount: _segments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = _selectedSegment == index;
                  return GestureDetector(
                    onTap: () {
                      if (index == 1) {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const HeartHealthScreen(),
                        ));
                      } else if (index == 2) {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const SleepAnalysisScreen(),
                        ));
                      } else if (index == 3) {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const WorkoutHistoryScreen(),
                        ));
                      } else if (index == 4) {
                        Navigator.of(context).push(MaterialPageRoute<void>(
                          builder: (_) => const WeightScreen(),
                        ));
                      } else {
                        setState(() => _selectedSegment = index);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? VColors.primary : VColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                      child: Text(
                        _segments[index],
                        style: VText.labelMd.copyWith(
                          color: selected ? VColors.onPrimary : VColors.onSurfaceVariant,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: VSpace.sm),

            // Main Content Area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.xs),
                child: Column(
                  children: [
                  // VitaxBand Sync Card
                  VCard(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: band.connected ? VColors.tertiary : VColors.outlineVariant,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  band.connected ? 'VitaxBand bağlı' : 'VitaxBand bağlı değil',
                                  style: VText.labelMd,
                                ),
                              ],
                            ),
                            if (band.connected)
                              Row(
                                children: [
                                  const Icon(PhosphorIconsRegular.batteryHigh, size: 16, color: VColors.tertiary),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Pil: %${band.battery ?? 92}',
                                    style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: VSpace.sm),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                band.connected ? '2 dk önce senkronlandı' : 'Bilekliğinizi bağlayın',
                                style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (band.connected)
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  backgroundColor: VColors.surfaceContainerLow,
                                  foregroundColor: VColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(VRadius.sm),
                                  ),
                                ),
                                onPressed: _isSyncing ? null : _handleSync,
                                icon: _isSyncing
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(PhosphorIconsRegular.arrowsClockwise, size: 16),
                                label: Text(_isSyncing ? 'Eşitleniyor...' : 'Şimdi senkronla'),
                              )
                            else
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: VColors.primary,
                                  foregroundColor: VColors.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(VRadius.sm),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(builder: (_) => const BandConnectScreen()),
                                  );
                                },
                                child: const Text('Bileklik Bağla'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Large Metric Tiles: 2 Columns
                  Row(
                    children: [
                      // Tile 1: Steps
                      Expanded(
                        child: VCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Adım Sayısı', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                                  const Icon(PhosphorIconsRegular.personSimpleWalk, size: 18, color: VColors.secondary),
                                ],
                              ),
                              const SizedBox(height: VSpace.md),
                              Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: CircularProgressIndicator(
                                        value: (steps / stepGoal).clamp(0.0, 1.0),
                                        strokeWidth: 9,
                                        backgroundColor: VColors.surfaceContainer,
                                        valueColor: const AlwaysStoppedAnimation(VColors.secondary),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(formatTr(steps), style: VText.headlineMd),
                                        Text('/ 10.000', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: VSpace.md),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Mesafe', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  Text('$km km', style: VText.bodyMdMedium),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Kalan', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  Text('${formatTr(remainingSteps)} adım', style: VText.bodyMdMedium.copyWith(color: VColors.secondary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: VSpace.gutter),
                      // Tile 2: Active Calories
                      Expanded(
                        child: VCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Aktif Kalori', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                                  const Icon(PhosphorIconsFill.flame, size: 18, color: VColors.primary),
                                ],
                              ),
                              const SizedBox(height: VSpace.md),
                              Center(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    SizedBox(
                                      width: 90,
                                      height: 90,
                                      child: CircularProgressIndicator(
                                        value: (burnedKcal / burnedGoal).clamp(0.0, 1.0),
                                        strokeWidth: 9,
                                        backgroundColor: VColors.surfaceContainer,
                                        valueColor: const AlwaysStoppedAnimation(VColors.primaryContainer),
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('$burnedKcal', style: VText.headlineMd),
                                        Text('/ 500 kcal', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: VSpace.md),
                              Row(
                                children: [
                                  const Icon(PhosphorIconsBold.watch, size: 14, color: VColors.primary),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      'VitaxBand ile ölçüldü',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Hedefe', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  Text('%$burnedPct ulaşıldı', style: VText.bodyMdMedium.copyWith(color: VColors.primary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpace.md),

                  // Live Heart Rate Card
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const HeartHealthScreen()),
                      );
                    },
                    child: VCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(PhosphorIconsFill.heart, size: 20, color: VColors.error),
                                  const SizedBox(width: 6),
                                  Text('Canlı: $liveHr bpm', style: VText.headlineMd),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: VColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(VRadius.pill),
                                ),
                                child: Text('Dinlenik: 58 bpm', style: VText.labelMd),
                              ),
                            ],
                          ),
                          const SizedBox(height: VSpace.md),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Min: 54 bpm', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('24 Saatlik Değişim', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('Maks: 138 bpm', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            width: double.infinity,
                            child: CustomPaint(
                              painter: _ActivityHrWavePainter(),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('00:00', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('06:00', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('12:00', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('18:00', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              Text('Şimdi', style: VText.microTag.copyWith(color: VColors.primary, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Readiness / Recovery Score Card
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const SleepAnalysisScreen()),
                      );
                    },
                    child: VCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 72,
                            decoration: BoxDecoration(
                              color: VColors.tertiary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(PhosphorIconsRegular.batteryCharging, size: 18, color: VColors.tertiary),
                                        const SizedBox(width: 6),
                                        Text('TOPARLANMA ANALİZİ', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: VColors.tertiaryFixed,
                                        borderRadius: BorderRadius.circular(VRadius.pill),
                                      ),
                                      child: Text(
                                        'Optimal',
                                        style: VText.labelCaps.copyWith(color: VColors.onTertiaryFixed, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text('Günün Hazırlık Skoru: ', style: VText.headlineMd),
                                    Text('%88', style: VText.headlineMd.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Dün geceki 7s 12dk uyku kalitesi ve düşük dinlenik nabız sayesinde yüksek toparlanma seviyesi.',
                                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // VitaxBand Optional Sensors Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bileklik Sensörleri', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => const ExtraSensorsScreen()),
                          );
                        },
                        child: Text(
                          'Tümünü Gör (Donanım v2.4)',
                          style: VText.microTag.copyWith(color: VColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: VSpace.sm),

                  // Sensor 1: SpO2
                  VCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: VColors.secondaryFixed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(PhosphorIconsRegular.wind, size: 20, color: VColors.onSecondaryFixed),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('SpO2 (Kandaki Oksijen)', style: VText.labelMd),
                                Text('Sürekli otomatik izleme', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('%98', style: VText.headlineMd),
                            Text('• Normal', style: VText.microTag.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sensor 2: Skin Temp
                  VCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: VColors.primaryFixed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(PhosphorIconsRegular.thermometerSimple, size: 20, color: VColors.onPrimaryFixed),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cilt Sıcaklığı', style: VText.labelMd),
                                Text('Bilek temas sensörü', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('36.4°C', style: VText.headlineMd),
                            Text('• Stabil', style: VText.microTag.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Sensor 3: Unsupported Tansiyon & EKG
                  Container(
                    padding: const EdgeInsets.all(VSpace.md),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: const BoxDecoration(
                                color: VColors.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(PhosphorIconsRegular.heartbeat, size: 20, color: VColors.onSurfaceVariant),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Tansiyon & EKG', style: VText.labelMd.copyWith(color: VColors.onSurfaceVariant)),
                                Text('Donanım kısıtlaması', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: VColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(VRadius.pill),
                          ),
                          child: Text(
                            'Bandınız desteklemiyor',
                            style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: VSpace.md),

                  // Manual Entry Bottom Quick Trigger
                  SizedBox(
                    width: double.infinity,
                    height: VSpace.touchMin,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: VColors.primaryContainer,
                        foregroundColor: VColors.onPrimaryContainer,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(VRadius.button),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Manuel ölçüm ve aktivite penceresi açılıyor')),
                        );
                      },
                      icon: const Icon(PhosphorIconsFill.plusCircle, size: 20),
                      label: const Text('Manuel Ölçüm veya Aktivite Gir'),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _ActivityHrWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = VColors.primaryContainer
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.2, size.height * 0.75,
      size.width * 0.45, size.height * 0.35,
      size.width * 0.55, size.height * 0.25,
    );
    path.cubicTo(
      size.width * 0.7, size.height * 0.4,
      size.width * 0.85, size.height * 0.5,
      size.width, size.height * 0.45,
    );

    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = VColors.primary;
    canvas.drawCircle(Offset(size.width, size.height * 0.45), 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
