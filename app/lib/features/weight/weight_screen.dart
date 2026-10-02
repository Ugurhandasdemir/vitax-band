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
import '../../core/widgets/v_progress_bar.dart';
import '../../data/models.dart';

export '../../app/providers.dart' show WeightRange;

String _signed(double kg, Units u) {
  final v = u == Units.metric ? kg : kgToLb(kg);
  final s = v.abs().toStringAsFixed(1).replaceAll('.', ',');
  final sign = v > 0.04 ? '+' : (v < -0.04 ? '-' : '');
  return '$sign$s ${weightUnit(u)}';
}

/// Kilo Analizi: mevcut kilo, hedef ilerlemesi, grafik, VKİ ve kayıtlar.
class WeightScreen extends ConsumerStatefulWidget {
  const WeightScreen({super.key});

  @override
  ConsumerState<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends ConsumerState<WeightScreen> {
  WeightRange _range = WeightRange.d30;
  bool _showAll = false;

  Future<void> _editGoal(Profile profile, double current) async {
    final units = profile.units;
    final c = TextEditingController(
      text: profile.goalWeightKg > 0
          ? weightValue(profile.goalWeightKg, units).replaceAll(',', '.')
          : '',
    );
    String? error;
    final kg = await showDialog<double>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: VColors.surface,
          title: Text('Hedef Kilo', style: VText.headlineMd),
          content: TextField(
            key: const ValueKey('goal-kg'),
            controller: c,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              suffixText: weightUnit(units),
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                final raw = double.tryParse(c.text.trim().replaceAll(',', '.'));
                final v = raw == null
                    ? null
                    : (units == Units.metric ? raw : lbToKg(raw));
                if (v == null || v < 30 || v > 300) {
                  setSt(() => error = '30 ile 300 kg arasında bir değer gir');
                  return;
                }
                Navigator.of(ctx).pop(v);
              },
              child: const Text('Tamam'),
            ),
          ],
        ),
      ),
    );
    if (kg != null) {
      await ref
          .read(profileActionsProvider)
          .save(
            profile.copyWith(
              goalWeightKg: kg,
              startWeightKg: profile.startWeightKg > 0
                  ? profile.startWeightKg
                  : current,
            ),
          );
    }
  }

  Future<void> _openLogSheet(Units units) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: VColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(VRadius.cardLg)),
    ),
    builder: (_) => _LogSheet(units: units),
  );

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(clockProvider)();
    final profile = ref.watch(profileProvider).value ?? const Profile();
    final units = profile.units;
    final latest = ref.watch(latestWeightProvider).value;
    final current = latest?.kg ?? profile.weightKg;
    final rangeSeries =
        ref.watch(weightSeriesProvider(_range)).value ?? const <WeightPoint>[];
    final all =
        ref.watch(weightSeriesProvider(WeightRange.y1)).value ??
        const <WeightPoint>[];
    final d30 =
        ref.watch(weightSeriesProvider(WeightRange.d30)).value ??
        const <WeightPoint>[];
    final change7 = weightChange(all, const Duration(days: 7), now);
    final change30 = weightChange(d30, const Duration(days: 30), now);
    final hasGoal = profile.goalWeightKg > 0 && profile.startWeightKg > 0;
    final progress = hasGoal
        ? weightProgress(
            start: profile.startWeightKg,
            current: current,
            goal: profile.goalWeightKg,
          )
        : null;

    return VDetailScaffold(
      key: const ValueKey('screen-weight'),
      title: 'Kilo Analizi',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.md,
          VSpace.margin,
          VSpace.lg,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HASSAS ANALİZ',
                      style: VText.labelCaps.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text('Kilo & Vücut Kompozisyonu', style: VText.headlineLg),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                key: const ValueKey('weight-change-chip'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: change7 <= 0
                      ? VColors.tertiaryFixed
                      : VColors.primaryFixed,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      change7 <= 0 ? PhosphorIconsRegular.trendDown : PhosphorIconsRegular.trendUp,
                      size: 16,
                      color: change7 <= 0 ? VColors.tertiary : VColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _signed(change7, units),
                      style: VText.labelMd.copyWith(
                        color: change7 <= 0
                            ? VColors.tertiary
                            : VColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.md),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MEVCUT KİLO',
                            style: VText.labelCaps.copyWith(
                              color: VColors.onSurfaceVariant,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                weightValue(current, units),
                                style: VText.displayLg.copyWith(fontSize: 40),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                weightUnit(units),
                                style: VText.headlineMd.copyWith(
                                  color: VColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      key: const ValueKey('weight-goal'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _editGoal(profile, current),
                      child: profile.goalWeightKg > 0
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'HEDEF',
                                  style: VText.labelCaps.copyWith(
                                    color: VColors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  formatWeight(profile.goalWeightKg, units),
                                  style: VText.headlineLg.copyWith(
                                    color: VColors.secondary,
                                  ),
                                ),
                              ],
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: VColors.secondaryFixed,
                                borderRadius: BorderRadius.circular(
                                  VRadius.pill,
                                ),
                              ),
                              child: Text(
                                'Hedef belirle',
                                style: VText.labelMd.copyWith(
                                  fontSize: 12,
                                  color: VColors.secondary,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
                if (progress != null) ...[
                  const SizedBox(height: VSpace.gutter),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Başlangıç: ${formatWeight(profile.startWeightKg, units)}',
                        style: VText.microTag.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        'Hedef: ${formatWeight(profile.goalWeightKg, units)}',
                        style: VText.microTag.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  VProgressBar(
                    value: progress.percent / 100,
                    color: VColors.tertiary,
                    height: 8,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kalan: ${formatWeight(progress.remainingKg, units)} '
                    '(%${progress.percent} tamamlandı)',
                    style: VText.microTag.copyWith(color: VColors.tertiary),
                  ),
                ],
                if (d30.length >= 2) ...[
                  const SizedBox(height: VSpace.gutter),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: VColors.tertiaryFixed,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.check,
                          size: 18,
                          color: VColors.tertiary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _monthSummary(change30, units),
                          style: VText.bodyMd,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          VCard(
            child: Column(
              children: [
                _RangeChips(
                  selected: _range,
                  onChanged: (r) => setState(() => _range = r),
                ),
                const SizedBox(height: VSpace.md),
                if (rangeSeries.length >= 2)
                  SizedBox(
                    height: 190,
                    child: _WeightChart(
                      key: const ValueKey('weight-chart'),
                      points: rangeSeries,
                      goal: profile.goalWeightKg,
                      units: units,
                      now: now,
                      days: _range.days,
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: Center(
                      child: Text(
                        all.isEmpty
                            ? 'Henüz kilo kaydı yok. "Kilo Kaydet" ile ilk ölçümünü ekle.'
                            : 'Bu aralıkta grafik için en az 2 kayıt gerekir.',
                        textAlign: TextAlign.center,
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
          SizedBox(
            height: 48,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: VColors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VRadius.button),
                ),
              ),
              onPressed: () => _openLogSheet(units),
              icon: const Icon(
                PhosphorIconsRegular.scales,
                color: VColors.onPrimary,
              ),
              label: Text(
                'Kilo Kaydet',
                style: VText.labelMd.copyWith(color: VColors.onPrimary),
              ),
            ),
          ),
          const SizedBox(height: VSpace.md),
          _BmiCard(kg: current, heightCm: profile.heightCm),
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              Text('Son Kayıtlar', style: VText.headlineMd),
              const Spacer(),
              if (all.length > 4)
                GestureDetector(
                  onTap: () => setState(() => _showAll = !_showAll),
                  child: Text(
                    _showAll ? 'Daha Az' : 'Tüm Geçmiş',
                    style: VText.labelMd.copyWith(color: VColors.secondary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          _RecentList(points: all, showAll: _showAll, units: units, now: now),
        ],
      ),
    );
  }

  String _monthSummary(double change, Units u) {
    if (change < -0.04) {
      return 'Son 30 günde istikrarlı şekilde ${formatWeight(-change, u)} verdin. Harika ritim!';
    }
    if (change > 0.04) {
      return 'Son 30 günde ${formatWeight(change, u)} aldın.';
    }
    return 'Son 30 günde kilon sabit kaldı.';
  }
}

class _RangeChips extends StatelessWidget {
  const _RangeChips({required this.selected, required this.onChanged});
  final WeightRange selected;
  final ValueChanged<WeightRange> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: VColors.surfaceContainer,
      borderRadius: BorderRadius.circular(VRadius.md),
    ),
    child: Row(
      children: [
        for (final r in WeightRange.values)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(r),
              child: Container(
                key: ValueKey('range-${r.label}'),
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: r == selected
                      ? VColors.primaryContainer
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(VRadius.base),
                ),
                child: Text(
                  r.label,
                  style: VText.labelMd.copyWith(
                    color: r == selected
                        ? VColors.onPrimary
                        : VColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _WeightChart extends StatelessWidget {
  const _WeightChart({
    super.key,
    required this.points,
    required this.goal,
    required this.units,
    required this.now,
    required this.days,
  });
  final List<WeightPoint> points;
  final double goal;
  final Units units;
  final DateTime now;
  final int days;

  @override
  Widget build(BuildContext context) {
    final start = now.subtract(Duration(days: days));
    double x(DateTime t) => t.difference(start).inMinutes / 1440.0;
    double y(double kg) => units == Units.metric ? kg : kgToLb(kg);
    final spots = [for (final p in points) FlSpot(x(p.when), y(p.kg))];
    final ys = [...spots.map((s) => s.y), if (goal > 0) y(goal)];
    final lo = ys.reduce((a, b) => a < b ? a : b) - 1;
    final hi = ys.reduce((a, b) => a > b ? a : b) + 1;
    final xInterval = days / 4;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: days.toDouble(),
        minY: lo,
        maxY: hi,
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: ((hi - lo) / 3).clamp(0.5, 100),
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
              interval: xInterval,
              reservedSize: 26,
              getTitlesWidget: (v, meta) {
                final d = start.add(Duration(days: v.round()));
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    formatDayShortMonth(d),
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
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            if (goal > 0)
              HorizontalLine(
                y: y(goal),
                color: VColors.outline,
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topLeft,
                  style: VText.microTag.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                  labelResolver: (_) =>
                      'HEDEF: ${weightValue(goal, units)} ${weightUnit(units)}',
                ),
              ),
          ],
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => VColors.inverseSurface,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  _tooltip(s.spotIndex),
                  VText.microTag.copyWith(color: VColors.inverseOnSurface),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: VColors.secondary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: VColors.secondary.withValues(alpha: 0.10),
            ),
          ),
        ],
      ),
    );
  }

  String _tooltip(int i) {
    final p = points[i];
    final delta = i == 0 ? null : p.kg - points[i - 1].kg;
    final d = delta == null
        ? ''
        : ' (${_signed(delta, units).replaceAll(' ${weightUnit(units)}', '')})';
    return '${formatDayShortMonth(p.when)}: ${weightValue(p.kg, units)} ${weightUnit(units)}$d';
  }
}

class _BmiCard extends StatelessWidget {
  const _BmiCard({required this.kg, required this.heightCm});
  final double kg;
  final double heightCm;

  @override
  Widget build(BuildContext context) {
    final v = bmi(kg, heightCm);
    final cat = bmiCategory(v);
    final pos = ((v - 15) / 20).clamp(0.0, 1.0);
    const segColors = [
      VColors.secondaryFixed,
      VColors.tertiaryFixed,
      VColors.primaryFixed,
      VColors.errorContainer,
    ];
    return VCard(
      key: const ValueKey('bmi-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                PhosphorIconsRegular.identificationBadge,
                size: 20,
                color: VColors.secondary,
              ),
              const SizedBox(width: 8),
              Text('Vücut Kitle İndeksi', style: VText.headlineMd),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cat == BmiCategory.normal
                      ? VColors.tertiaryFixed
                      : VColors.primaryFixed,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
                child: Text(
                  cat.label,
                  style: VText.microTag.copyWith(
                    color: cat == BmiCategory.normal
                        ? VColors.tertiary
                        : VColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatDecimalTr(v),
                style: VText.displayLg.copyWith(fontSize: 34),
              ),
              const SizedBox(width: 8),
              Text(
                'VKİ (18,5 - 24,9 referans)',
                style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          LayoutBuilder(
            builder: (context, c) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 4; i++) ...[
                        if (i > 0) const SizedBox(width: 4),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: segColors[i],
                              borderRadius: BorderRadius.circular(VRadius.pill),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Positioned(
                    left: (c.maxWidth - 14) * pos,
                    top: -3,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: VColors.onSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: VColors.surfaceContainerLowest,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final c in BmiCategory.values)
                Text(
                  c.label,
                  style: VText.microTag.copyWith(
                    color: c == cat
                        ? VColors.onSurface
                        : VColors.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecentList extends StatelessWidget {
  const _RecentList({
    required this.points,
    required this.showAll,
    required this.units,
    required this.now,
  });
  final List<WeightPoint> points;
  final bool showAll;
  final Units units;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: VSpace.md),
        child: Text(
          'Henüz kilo kaydı yok.',
          textAlign: TextAlign.center,
          style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
        ),
      );
    }
    final chrono = [...points]..sort((a, b) => a.when.compareTo(b.when));
    final desc = chrono.reversed.toList();
    final shown = showAll ? desc : desc.take(4).toList();
    return Column(
      children: [
        for (var i = 0; i < shown.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RecentRow(
              point: shown[i],
              previous: () {
                final idx = chrono.indexOf(shown[i]);
                return idx > 0 ? chrono[idx - 1] : null;
              }(),
              units: units,
              isToday: DateUtils.isSameDay(shown[i].when, now),
            ),
          ),
      ],
    );
  }
}

class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.point,
    required this.previous,
    required this.units,
    required this.isToday,
  });
  final WeightPoint point;
  final WeightPoint? previous;
  final Units units;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final delta = previous == null ? null : point.kg - previous!.kg;
    final (text, color) = delta == null
        ? ('İlk kayıt', VColors.onSurfaceVariant)
        : delta.abs() < 0.05
        ? ('Sabit', VColors.onSurfaceVariant)
        : (
            _signed(delta, units),
            delta < 0 ? VColors.tertiary : VColors.primary,
          );
    final title = isToday
        ? 'Bugün, ${formatDayShortMonth(point.when)}'
        : '${weekdayName(point.when)}, ${formatDayShortMonth(point.when)}';
    return VCard(
      padding: const EdgeInsets.all(VSpace.gutter),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Icon(
              isToday ? PhosphorIconsRegular.calendarBlank : PhosphorIconsRegular.calendar,
              size: 20,
              color: isToday ? VColors.primary : VColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: VSpace.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: VText.bodyMdMedium,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: VColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(VRadius.sm),
                      ),
                      child: Text(
                        formatClockTime(point.when),
                        style: VText.microTag.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  point.when.hour < 10 ? 'Sabah aç karna' : 'Gün içi',
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatWeight(point.kg, units), style: VText.headlineMd),
              Text(text, style: VText.microTag.copyWith(color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LogSheet extends ConsumerStatefulWidget {
  const _LogSheet({required this.units});
  final Units units;

  @override
  ConsumerState<_LogSheet> createState() => _LogSheetState();
}

class _LogSheetState extends ConsumerState<_LogSheet> {
  final _c = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = double.tryParse(_c.text.trim().replaceAll(',', '.'));
    final kg = raw == null
        ? null
        : (widget.units == Units.metric ? raw : lbToKg(raw));
    if (kg == null || !await ref.read(weightActionsProvider).logWeight(kg)) {
      setState(() => _error = 'Geçerli bir kilo gir (30-300)');
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      VSpace.margin,
      VSpace.md,
      VSpace.margin,
      MediaQuery.of(context).viewInsets.bottom + VSpace.md,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kilo Kaydet', style: VText.headlineMd),
        const SizedBox(height: VSpace.md),
        TextField(
          key: const ValueKey('weight-input'),
          controller: _c,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: 'Kilo (${weightUnit(widget.units)})',
            filled: true,
            fillColor: VColors.surfaceContainerLow,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(VRadius.button),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: VText.bodyMd.copyWith(color: VColors.error)),
        ],
        const SizedBox(height: VSpace.md),
        SizedBox(
          width: double.infinity,
          height: VSpace.touchMin,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: VColors.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VRadius.button),
              ),
            ),
            onPressed: _save,
            child: Text(
              'Kaydet',
              style: VText.labelMd.copyWith(color: VColors.onPrimary),
            ),
          ),
        ),
      ],
    ),
  );
}
