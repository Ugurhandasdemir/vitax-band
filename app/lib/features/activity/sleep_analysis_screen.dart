import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';

class SleepAnalysisScreen extends ConsumerWidget {
  const SleepAnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return VDetailScaffold(
      title: 'Uyku Analizi',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: VSpace.margin, vertical: VSpace.md),
        children: [
          // 1. Last Night Summary Hero Card
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Geçen Geceki Uyku', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
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
                          Text('2 dk önce senkronize', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('7', style: VText.displayLg.copyWith(fontSize: 42, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    Text('sa', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                    const SizedBox(width: 8),
                    Text('12', style: VText.displayLg.copyWith(fontSize: 42, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 4),
                    Text('dk', style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: VSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: VColors.tertiary,
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, size: 18, color: VColors.onTertiary),
                      const SizedBox(width: 6),
                      Text(
                        'Uyku Skoru: 89 / 100 • Dinlendirici',
                        style: VText.labelMd.copyWith(color: VColors.onTertiary),
                      ),
                    ],
                  ),
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
                              decoration: const BoxDecoration(
                                color: VColors.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.bedtime, size: 18, color: VColors.secondary),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('YATIŞ', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                Text('23:45', style: VText.headlineMd),
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
                                color: VColors.surfaceContainerHighest,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.alarm, size: 18, color: VColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('UYANIŞ', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                                Text('06:57', style: VText.headlineMd),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),

          // 2. Uyku Evreleri
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.waves, size: 20, color: VColors.secondary),
                        const SizedBox(width: 6),
                        Text('Uyku Evreleri', style: VText.headlineMd),
                      ],
                    ),
                    Text('Vitax Optik PPG', style: VText.labelCaps.copyWith(color: VColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                // Çubuk
                ClipRRect(
                  borderRadius: BorderRadius.circular(VRadius.pill),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: const [
                        Expanded(flex: 24, child: ColoredBox(color: VColors.secondary)),
                        Expanded(flex: 63, child: ColoredBox(color: VColors.secondaryContainer)),
                        Expanded(flex: 10, child: ColoredBox(color: VColors.surfaceDim)),
                        Expanded(flex: 3, child: ColoredBox(color: VColors.primaryContainer)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: VSpace.md),
                // Hipnogram Görseli
                SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: _HypnogramPainter(),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('23:45', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                    Text('01:30', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                    Text('03:15', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                    Text('05:00', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                    Text('06:57', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                // Evre Metrikleri
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 2.2,
                  children: [
                    _StageTile(color: VColors.secondary, title: 'Derin Uyku', time: '1 sa 45 dk', percent: '%24'),
                    _StageTile(color: VColors.secondaryContainer, title: 'Hafif Uyku', time: '4 sa 32 dk', percent: '%63'),
                    _StageTile(color: VColors.surfaceDim, title: 'REM / Rüya', time: '42 dk', percent: '%10'),
                    _StageTile(color: VColors.primaryContainer, title: 'Uyanık', time: '13 dk', percent: '%3'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),

          // 3. 7 Gecelik Eğilim
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
                        Text('7 Gecelik Eğilim', style: VText.headlineMd),
                        Text('Ortalama: 7 sa 05 dk', style: VText.microTag.copyWith(color: VColors.onSurfaceVariant)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VColors.secondaryFixed,
                        borderRadius: BorderRadius.circular(VRadius.sm),
                      ),
                      child: Text(
                        'Hedef: 7.5 sa',
                        style: VText.microTag.copyWith(color: VColors.onSecondaryFixed, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                SizedBox(
                  height: 120,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _DaySleepBar(day: 'Pzt', hours: 6.6, heightPct: 0.65),
                      _DaySleepBar(day: 'Sal', hours: 7.1, heightPct: 0.72),
                      _DaySleepBar(day: 'Çar', hours: 7.7, heightPct: 0.82),
                      _DaySleepBar(day: 'Per', hours: 7.2, heightPct: 0.74, isHighlight: true),
                      _DaySleepBar(day: 'Cum', hours: 6.8, heightPct: 0.68),
                      _DaySleepBar(day: 'Cmt', hours: 8.0, heightPct: 0.88),
                      _DaySleepBar(day: 'Paz', hours: 7.3, heightPct: 0.75),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),

          // 4. Uyku Düzeni & Tutarlılık Kartı
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: VColors.tertiaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_graph, size: 20, color: VColors.onTertiaryFixed),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('%94 Uyku Tutarlılığı', style: VText.headlineMd),
                        Text('YÜKSEK DÜZEY', style: VText.microTag.copyWith(color: VColors.tertiary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.sm),
                Text(
                  'Son 7 gün içinde ortalama yatış saatiniz sadece ±18 dakika saptı. Sirkadiyen ritminiz toparlanmanızı hızlandırıyor.',
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                ),
                const SizedBox(height: VSpace.md),
                Container(
                  padding: const EdgeInsets.all(VSpace.sm),
                  decoration: BoxDecoration(
                    color: VColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(VRadius.md),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.psychology, size: 20, color: VColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('VitaxBand AI Koç Notu', style: VText.labelCaps.copyWith(color: VColors.primary)),
                            const SizedBox(height: 2),
                            Text(
                              'Bu akşam 23:30\'da ekran süresini sonlandırmak derin uyku oranını %5 daha artırabilir.',
                              style: VText.bodyMd,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),

          // Bilgilendirme Notu
          Container(
            padding: const EdgeInsets.all(VSpace.sm),
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: VColors.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'VitaxBand donanımının ham uyku paketleri doğrulanana kadar uyku verileri tahmini ve referans amaçlıdır.',
                    style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _StageTile extends StatelessWidget {
  const _StageTile({
    required this.color,
    required this.title,
    required this.time,
    required this.percent,
  });

  final Color color;
  final String title;
  final String time;
  final String percent;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: VColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(VRadius.sm),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(title, style: VText.labelMd),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(time, style: VText.bodyMdMedium),
            Text(percent, style: VText.microTag.copyWith(color: VColors.onSurfaceVariant, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    ),
  );
}

class _DaySleepBar extends StatelessWidget {
  const _DaySleepBar({
    required this.day,
    required this.hours,
    required this.heightPct,
    this.isHighlight = false,
  });

  final String day;
  final double hours;
  final double heightPct;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.end,
    children: [
      Container(
        width: 18,
        height: 70 * heightPct,
        decoration: BoxDecoration(
          color: isHighlight ? VColors.primaryContainer : VColors.secondaryContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        day,
        style: VText.microTag.copyWith(
          color: isHighlight ? VColors.primary : VColors.onSurfaceVariant,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    ],
  );
}

class _HypnogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = VColors.secondary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final points = [
      Offset(0, size.height * 0.2),
      Offset(size.width * 0.1, size.height * 0.6),
      Offset(size.width * 0.2, size.height * 0.85),
      Offset(size.width * 0.35, size.height * 0.85),
      Offset(size.width * 0.45, size.height * 0.6),
      Offset(size.width * 0.55, size.height * 0.35),
      Offset(size.width * 0.65, size.height * 0.6),
      Offset(size.width * 0.75, size.height * 0.85),
      Offset(size.width * 0.85, size.height * 0.6),
      Offset(size.width * 0.95, size.height * 0.15),
      Offset(size.width, size.height * 0.2),
    ];

    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
