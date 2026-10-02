import 'dart:async';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../band/band_status.dart';

class HeartHealthScreen extends ConsumerStatefulWidget {
  const HeartHealthScreen({super.key});

  @override
  ConsumerState<HeartHealthScreen> createState() => _HeartHealthScreenState();
}

class _HeartHealthScreenState extends ConsumerState<HeartHealthScreen> {
  bool _isMeasuring = false;
  double _measureProgress = 0.0;
  Timer? _measureTimer;

  @override
  void dispose() {
    _measureTimer?.cancel();
    super.dispose();
  }

  void _startMeasurement() {
    if (_isMeasuring) return;
    setState(() {
      _isMeasuring = true;
      _measureProgress = 0.0;
    });

    _measureTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _measureProgress += 0.01;
        if (_measureProgress >= 1.0) {
          _measureProgress = 1.0;
          _isMeasuring = false;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final liveHr = ref.watch(liveHrProvider).value?.bpm ?? 74;
    final band = ref.watch(bandStatusProvider);

    return VDetailScaffold(
      title: 'Kalp Sağlığı',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.md),
        child: Column(
          children: [
          // 1. Canlı Ölçüm (Live Measure Hero Card)
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: VColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: VColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Canlı Ölçüm',
                            style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIconsRegular.broadcast,
                          size: 16,
                          color: band.connected ? VColors.tertiary : VColors.outlineVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          band.connected ? 'VitaxBand Bağlı' : 'Bant bağlı değil',
                          style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$liveHr',
                          style: VText.displayLg.copyWith(fontSize: 44, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'BPM',
                          style: VText.labelMd.copyWith(
                            color: VColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: VColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        PhosphorIconsFill.heart,
                        color: VColors.onPrimary,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.sm),
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.arrowsClockwise, size: 16, color: VColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'Anlık VitaxBand Ölçümü • 0 sn gecikme',
                      style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                if (_isMeasuring) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VRadius.pill),
                    child: LinearProgressIndicator(
                      value: _measureProgress,
                      minHeight: 6,
                      backgroundColor: VColors.surfaceContainer,
                      valueColor: const AlwaysStoppedAnimation(VColors.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ölçülüyor... %${(_measureProgress * 100).toInt()}',
                    style: VText.microTag.copyWith(color: VColors.primary),
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  height: VSpace.touchMin,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: VColors.primary,
                      foregroundColor: VColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VRadius.button),
                      ),
                    ),
                    onPressed: _isMeasuring ? null : _startMeasurement,
                    icon: const Icon(PhosphorIconsFill.heartbeat, size: 20),
                    label: Text(_isMeasuring ? 'Ölçülüyor...' : 'Şimdi Ölç (30s PPG)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),

          // 2. 24-Saatlik Nabız Çizelgesi
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Günlük Seyir', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text('24-Saatlik Nabız Çizelgesi', style: VText.headlineMd),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VColors.secondaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                      child: Text(
                        '00:00 - Şu An',
                        style: VText.microTag.copyWith(color: VColors.secondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(VSpace.sm),
                        decoration: BoxDecoration(
                          color: VColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(VRadius.md),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: VColors.secondaryContainer.withOpacity(0.4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(PhosphorIconsFill.moon, size: 18, color: VColors.secondary),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EN DÜŞÜK', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                Row(
                                  children: [
                                    Text('54 ', style: VText.headlineMd),
                                    Text('BPM', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(VSpace.sm),
                        decoration: BoxDecoration(
                          color: VColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(VRadius.md),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: VColors.errorContainer,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(PhosphorIconsRegular.barbell, size: 18, color: VColors.error),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EN YÜKSEK', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                Row(
                                  children: [
                                    Text('148 ', style: VText.headlineMd),
                                    Text('BPM', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                // 24 Saatlik Çizim
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _Hr24hChartPainter(),
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
          const SizedBox(height: VSpace.md),

          // 3. 30 Günlük Dinlenik Nabız
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kardiyovasküler Uyum', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text('30 Günlük Dinlenik Nabız', style: VText.headlineMd),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VColors.tertiaryFixed,
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                      child: Text(
                        'Mükemmel Toparlanma',
                        style: VText.microTag.copyWith(color: VColors.onSurface, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                Container(
                  padding: const EdgeInsets.all(VSpace.sm),
                  decoration: BoxDecoration(
                    color: VColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: VColors.tertiary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(PhosphorIconsRegular.trendDown, size: 20, color: VColors.tertiary),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('-5 BPM ', style: VText.headlineMd.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
                              Text('düşüş', style: VText.bodyMd.copyWith(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Text('Aylık ortalama 63 BPM\'den 58 BPM\'e geriledi', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VSpace.md),
                // 30 günlük barlar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final h in [0.95, 0.92, 0.86, 0.82, 0.76, 0.72, 0.65, 0.62]) ...[
                      Expanded(
                        child: Container(
                          height: 50 * h,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: h < 0.7 ? VColors.tertiary : VColors.secondary.withOpacity(0.5),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('30 gün önce (63 BPM)', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                    Text('Son 7 gün (58 BPM)', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),

          // 4. Kalp Hızı Bölgeleri Dağılımı
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Yoğunluk Analizi', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                        const SizedBox(height: 2),
                        Text('Kalp Hızı Bölgeleri', style: VText.headlineMd),
                      ],
                    ),
                    const Icon(PhosphorIconsRegular.chartDonut, color: VColors.onSurfaceVariant, size: 20),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                // Yatay çubuk
                ClipRRect(
                  borderRadius: BorderRadius.circular(VRadius.pill),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: const [
                        Expanded(flex: 60, child: ColoredBox(color: VColors.secondary)),
                        Expanded(flex: 22, child: ColoredBox(color: VColors.tertiary)),
                        Expanded(flex: 12, child: ColoredBox(color: VColors.primaryFixed)),
                        Expanded(flex: 5, child: ColoredBox(color: VColors.primary)),
                        Expanded(flex: 1, child: ColoredBox(color: VColors.error)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: VSpace.md),
                _ZoneRow(color: VColors.secondary, title: 'Zon 1 (Isınma <115)', subtitle: 'Toparlanma & Hafif Etkinlik', time: '4 sa 20 dk', percent: '%60'),
                _ZoneRow(color: VColors.tertiary, title: 'Zon 2 (Yağ Yakımı 115-135)', subtitle: 'Temel Dayanıklılık', time: '1 sa 15 dk', percent: '%22'),
                _ZoneRow(color: VColors.primaryFixed, title: 'Zon 3 (Aerobik 135-152)', subtitle: 'Kardiyo Kapasite Gelişimi', time: '38 dk', percent: '%12'),
                _ZoneRow(color: VColors.primary, title: 'Zon 4 (Anaerobik 152-168)', subtitle: 'Laktat Eşiği Artışı', time: '18 dk', percent: '%5'),
                _ZoneRow(color: VColors.error, title: 'Zon 5 (Maksimum >168)', subtitle: 'Pik Hız & İnterval', time: '4 dk', percent: '%1'),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),

          // 5. HRV & Stres Seviyesi
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Otonom Sinir Sistemi', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                const SizedBox(height: 2),
                Text('HRV & Stres Seviyesi', style: VText.headlineMd),
                const SizedBox(height: VSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(VSpace.sm),
                        decoration: BoxDecoration(
                          color: VColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(VRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('HRV (RMSSD)', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                                const Icon(PhosphorIconsFill.heartbeat, size: 16, color: VColors.tertiary),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text('62', style: VText.headlineLg.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(width: 4),
                                Text('ms', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Sağlıklı Denge', style: VText.microTag.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(VSpace.sm),
                        decoration: BoxDecoration(
                          color: VColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(VRadius.md),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Stres Endeksi', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                                const Icon(PhosphorIconsRegular.personSimpleTaiChi, size: 16, color: VColors.secondary),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text('28', style: VText.headlineLg.copyWith(fontWeight: FontWeight.w800)),
                                const SizedBox(width: 4),
                                Text('/ 100', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Düşük / Dingin', style: VText.microTag.copyWith(color: VColors.secondary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: VColors.surfaceContainerHigh.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(VRadius.sm),
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIconsRegular.moon, size: 16, color: VColors.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'VitaxBand gece boyu otonom izleme verisi ile kalibre edilmiştir.',
                          style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),

          // 6. Tıbbi Feragatname
          Container(
            padding: const EdgeInsets.all(VSpace.sm),
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tıbbi cihaz değildir. VitaxBand verileri yalnızca genel zindelik ve spor takibi amaçlıdır; klinik tanı veya tedavi amacıyla kullanılamaz.',
                    style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  const _ZoneRow({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.percent,
  });

  final Color color;
  final String title;
  final String subtitle;
  final String time;
  final String percent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: VText.bodyMdMedium),
              Text(subtitle, style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(time, style: VText.labelMd),
            Text(percent, style: VText.microTag.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}

class _Hr24hChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = VColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          VColors.primary.withOpacity(0.25),
          VColors.primary.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.25, size.height * 0.75,
      size.width * 0.45, size.height * 0.45,
      size.width * 0.6, size.height * 0.2,
    );
    path.cubicTo(
      size.width * 0.75, size.height * 0.35,
      size.width * 0.85, size.height * 0.6,
      size.width, size.height * 0.5,
    );

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Live dot
    final dotPaint = Paint()..color = VColors.primary;
    canvas.drawCircle(Offset(size.width, size.height * 0.5), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
