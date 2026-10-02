import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/nutrition_calc.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../core/widgets/v_segmented.dart';
import '../../data/models.dart';
import '../add_food/add_food_screen.dart';

String _signedKcal(int v) =>
    '${v > 0 ? '+' : (v < 0 ? '-' : '')}${formatTr(v.abs())}';

/// Kalori Dengesi: alınan ve (bazal + adım) harcanan enerji.
class BalanceScreen extends ConsumerStatefulWidget {
  const BalanceScreen({super.key});

  @override
  ConsumerState<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends ConsumerState<BalanceScreen> {
  int _period = 0; // 0 bu hafta, 1 geçen hafta, 2 aylık

  (DateTime, int) _range(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    return switch (_period) {
      0 => (monday, 7),
      1 => (monday.subtract(const Duration(days: 7)), 7),
      _ => (today.subtract(const Duration(days: 29)), 30),
    };
  }

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final profile = ref.watch(profileProvider).value ?? const Profile();
    final range = _range(now);
    final days =
        ref.watch(energyRangeProvider(range)).value ?? const <DayEnergy>[];
    final s = summarizeEnergy(days);
    final steps = ref.watch(stepsProvider(today)).value ?? 0;
    final intakeToday = ref.watch(dayTotalsProvider(today)).value?.kcal ?? 0;
    final bmrToday = bmr(
      sex: profile.sex,
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      age: profile.age,
    ).round();
    final activeToday = estimateStepKcal(
      steps: steps,
      weightKg: profile.weightKg,
    );
    final totalToday = bmrToday + activeToday;
    final hasData = s.loggedDays > 0;
    final deficit = s.net <= 0;

    return VDetailScaffold(
      key: const ValueKey('screen-balance'),
      title: 'Kalori Dengesi',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.md,
          VSpace.margin,
          VSpace.lg,
        ),
        children: [
          VSegmented(
            labels: const ['Bu Hafta', 'Geçen Hafta', 'Aylık'],
            selected: _period,
            onChanged: (i) => setState(() => _period = i),
          ),
          const SizedBox(height: VSpace.md),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      PhosphorIconsRegular.chartLine,
                      size: 18,
                      color: VColors.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _period == 2
                            ? 'AYLIK ENERJİ DENGESİ'
                            : 'HAFTALIK ENERJİ DENGESİ',
                        style: VText.labelCaps.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (hasData)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: deficit
                              ? VColors.tertiary
                              : VColors.primaryContainer,
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                        child: Text(
                          '${_signedKcal(s.net)} kcal',
                          style: VText.microTag.copyWith(
                            color: VColors.onPrimary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: VSpace.sm),
                Text(energyHeadline(s), style: VText.headlineLg),
                const SizedBox(height: 6),
                Text(
                  energyAdvice(s, profile.goal),
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                ),
                const SizedBox(height: VSpace.gutter),
                Row(
                  children: [
                    Expanded(
                      child: _StatCell(
                        label: 'Alınan',
                        dot: VColors.primaryContainer,
                        value: formatTr(s.totalIn),
                        sub: 'Ort. ${formatTr(s.avgIn)}/gün',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCell(
                        label: 'Yakılan',
                        dot: VColors.secondary,
                        value: formatTr(s.totalOut),
                        sub: 'Ort. ${formatTr(s.avgOut)}/gün',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCell(
                        label: 'Net Fark',
                        dot: VColors.tertiary,
                        value: _signedKcal(s.net),
                        sub: deficit ? 'Kcal Defisit' : 'Kcal Fazlası',
                        tint: deficit
                            ? VColors.tertiaryFixed
                            : VColors.primaryFixed,
                        valueColor: deficit
                            ? VColors.tertiary
                            : VColors.primary,
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
                Text(
                  'KARŞILAŞTIRMALI ANALİZ',
                  style: VText.labelCaps.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text('Alınan vs Yakılan', style: VText.headlineMd),
                const SizedBox(height: VSpace.sm),
                Row(
                  children: [
                    _Legend('Alınan Kalori', VColors.primaryContainer),
                    const SizedBox(width: 12),
                    _Legend('Yakılan (Bazal + Adım)', VColors.secondary),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                if (hasData)
                  SizedBox(
                    height: 180,
                    child: _BalanceChart(
                      key: const ValueKey('balance-chart'),
                      days: days,
                    ),
                  )
                else
                  SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Bu dönemde yemek kaydı yok.',
                        style: VText.bodyMd.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BİLEŞEN AYRIMI',
                  style: VText.labelCaps.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Günlük Enerji Dağılımı',
                        style: VText.headlineMd,
                      ),
                    ),
                    Text(
                      'Bugün',
                      style: VText.microTag.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.gutter),
                _Row(
                  icon: PhosphorIconsRegular.bed,
                  iconBg: VColors.secondaryFixed,
                  iconColor: VColors.secondary,
                  title: 'Bazal Metabolizma (BMR)',
                  subtitle: 'Dinlenme anı hücresel sarfiyat',
                  value: '${formatTr(bmrToday)} kcal',
                  note: '%${percent(bmrToday, totalToday)} pay',
                ),
                const SizedBox(height: 8),
                _Row(
                  icon: PhosphorIconsRegular.personSimpleWalk,
                  iconBg: VColors.secondaryFixed,
                  iconColor: VColors.secondary,
                  title: 'Aktif Efor & Adım',
                  subtitle: 'VitaxBand adımlarından tahmin',
                  value: '${formatTr(activeToday)} kcal',
                  note: '%${percent(activeToday, totalToday)} pay',
                ),
                const SizedBox(height: 8),
                _Row(
                  icon: PhosphorIconsRegular.flame,
                  iconBg: VColors.surfaceContainerHigh,
                  iconColor: VColors.onSurface,
                  title: 'Toplam Harcama',
                  value: '${formatTr(totalToday)} kcal',
                  big: true,
                ),
                const SizedBox(height: 8),
                _Row(
                  icon: PhosphorIconsRegular.forkKnife,
                  iconBg: VColors.primaryFixed,
                  iconColor: VColors.primary,
                  title: 'Alınan Gıda',
                  subtitle: 'Günlük giriş günlüğü',
                  value: '${formatTr(intakeToday)} kcal',
                  note: 'Net ${_signedKcal(intakeToday - totalToday)} kcal',
                  big: true,
                  valueColor: VColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: VColors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VRadius.button),
                ),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddFoodScreen()),
              ),
              icon: const Icon(
                PhosphorIconsRegular.plusCircle,
                color: VColors.onPrimary,
              ),
              label: Text(
                'Öğün veya Efor Ekle',
                style: VText.labelMd.copyWith(color: VColors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.dot,
    required this.value,
    required this.sub,
    this.tint,
    this.valueColor = VColors.onSurface,
  });
  final String label;
  final Color dot;
  final String value;
  final String sub;
  final Color? tint;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: tint ?? VColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(VRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: VText.headlineMd.copyWith(color: valueColor, fontSize: 17),
          ),
        ),
        Text(
          sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: VText.microTag.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            color: VColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _Legend extends StatelessWidget {
  const _Legend(this.label, this.color);
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 4),
      Text(
        label,
        style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
      ),
    ],
  );
}

class _BalanceChart extends StatelessWidget {
  const _BalanceChart({super.key, required this.days});
  final List<DayEnergy> days;

  @override
  Widget build(BuildContext context) {
    final maxV = days
        .map((d) => d.intake > d.burn ? d.intake : d.burn)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final long = days.length > 7;
    return BarChart(
      BarChartData(
        maxY: maxV * 1.15,
        alignment: BarChartAlignment.spaceAround,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: (maxV / 3).clamp(100, 100000),
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: VColors.surfaceContainer, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= days.length) return const SizedBox();
                if (long && i % 5 != 0) return const SizedBox();
                final d = days[i].day;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    long ? '${d.day}' : shortWeekday(d),
                    style: VText.microTag.copyWith(
                      fontWeight: FontWeight.w500,
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => VColors.inverseSurface,
            getTooltipItem: (g, gi, rod, ri) {
              final d = days[g.x];
              return BarTooltipItem(
                '${formatDayShortMonth(d.day)}\nAlınan ${formatTr(d.intake)} • '
                'Yakılan ${formatTr(d.burn)}',
                VText.microTag.copyWith(color: VColors.inverseOnSurface),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barsSpace: long ? 1 : 3,
              barRods: [
                BarChartRodData(
                  toY: days[i].intake.toDouble(),
                  color: VColors.primaryContainer,
                  width: long ? 3 : 8,
                  borderRadius: BorderRadius.circular(2),
                ),
                BarChartRodData(
                  toY: days[i].burn.toDouble(),
                  color: VColors.secondary,
                  width: long ? 3 : 8,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.value,
    this.subtitle,
    this.note,
    this.big = false,
    this.valueColor = VColors.secondary,
  });
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final String value;
  final String? note;
  final bool big;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(VSpace.gutter),
    decoration: BoxDecoration(
      color: VColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(VRadius.md),
    ),
    child: Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: VSpace.gutter),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: VText.bodyMdMedium),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: VText.microTag.copyWith(
                    fontWeight: FontWeight.w500,
                    color: VColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: (big ? VText.headlineMd : VText.labelMd).copyWith(
                color: big ? valueColor : VColors.secondary,
              ),
            ),
            if (note != null)
              Text(
                note!,
                style: VText.microTag.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: VColors.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
