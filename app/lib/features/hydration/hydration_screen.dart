import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/nutrition_calc.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../core/widgets/v_progress_bar.dart';
import '../../data/models.dart';

const _days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// Su Takibi: günlük hidrasyon, hızlı ekleme, kayıtlar ve haftalık denge.
class HydrationScreen extends ConsumerStatefulWidget {
  const HydrationScreen({super.key});

  @override
  ConsumerState<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends ConsumerState<HydrationScreen> {
  int _custom = 250;

  Future<void> _editGoal(int current) async {
    final c = TextEditingController(text: '$current');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VColors.surface,
        title: Text('Günlük Su Hedefi', style: VText.headlineMd),
        content: TextField(
          key: const ValueKey('goal-ml'),
          controller: c,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'ml'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    final v = int.tryParse(c.text.trim());
    if (ok == true && v != null && v >= 500 && v <= 10000) {
      final p = await ref.read(profileProvider.future);
      await ref.read(profileActionsProvider).save(p.copyWith(waterGoalMl: v));
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(selectedDayProvider);
    final ml = ref.watch(waterProvider(day)).value ?? 0;
    final goal =
        (ref.watch(profileProvider).value ?? const Profile()).waterGoalMl;
    final entries =
        ref.watch(waterEntriesProvider(day)).value ?? const <WaterEntry>[];
    final monday = day.subtract(Duration(days: day.weekday - 1));
    final week =
        ref
            .watch(
              waterWeekProvider(
                DateTime(monday.year, monday.month, monday.day),
              ),
            )
            .value ??
        List<int>.filled(7, 0);
    final pct = percent(ml, goal);
    final status = hydrationStatus(pct);
    final actions = ref.read(nutritionActionsProvider);

    return VDetailScaffold(
      key: const ValueKey('screen-hydration'),
      title: 'Su Takibi',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.md,
          VSpace.margin,
          VSpace.lg,
        ),
        children: [
          _StatusCard(status: status),
          const SizedBox(height: VSpace.md),
          VCard(
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'GÜNLÜK HİDRASYON',
                      style: VText.labelCaps.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _editGoal(goal),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            PhosphorIconsBold.pencilSimple,
                            size: 14,
                            color: VColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hedefi Düzenle (${formatLiters(goal)} L)',
                            style: VText.labelMd.copyWith(
                              fontSize: 12,
                              color: VColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                _Glass(
                  fraction: goal <= 0 ? 0 : (ml / goal).clamp(0.0, 1.0),
                  percent: pct,
                ),
                const SizedBox(height: VSpace.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatLiters(ml),
                      style: VText.displayLg.copyWith(
                        fontSize: 40,
                        height: 1,
                        color: VColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'L',
                      style: VText.headlineMd.copyWith(
                        color: VColors.secondary,
                      ),
                    ),
                    Text(
                      ' / ${formatLiters(goal)} L Hedef',
                      style: VText.bodyLg.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (ml >= goal)
                  Text(
                    'Bugünkü hedefi tamamladın!',
                    style: VText.bodyMd.copyWith(color: VColors.tertiary),
                  )
                else
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: 'Hedefe ', style: VText.bodyMd),
                        TextSpan(
                          text: '${formatLiters(goal - ml)} L kaldı',
                          style: VText.bodyMd.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        TextSpan(
                          text: ' (%$pct tamamlandı)',
                          style: VText.bodyMd,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: VSpace.gutter),
                VProgressBar(value: goal <= 0 ? 0 : ml / goal, height: 6),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              Text(
                'HIZLI EKLE',
                style: VText.labelCaps.copyWith(
                  color: VColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'TEK DOKUNUŞ',
                style: VText.labelCaps.copyWith(
                  color: VColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.sm),
          Row(
            children: [
              Expanded(
                child: _QuickButton(
                  key: const ValueKey('quick-200'),
                  icon: PhosphorIconsRegular.pintGlass,
                  amount: '+200',
                  label: 'Bardak',
                  onTap: () => actions.addWater(day, 200, label: 'Bardak'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickButton(
                  key: const ValueKey('quick-300'),
                  icon: PhosphorIconsRegular.coffee,
                  amount: '+300',
                  label: 'Kupa',
                  onTap: () => actions.addWater(day, 300, label: 'Kupa'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickButton(
                  key: const ValueKey('quick-500'),
                  icon: PhosphorIconsRegular.drop,
                  amount: '+500',
                  label: 'Şişe',
                  filled: true,
                  onTap: () => actions.addWater(day, 500, label: 'Şişe'),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.md),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ÖZEL MİKTAR GİRİŞİ',
                  style: VText.labelCaps.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: VSpace.gutter),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: VColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(VRadius.button),
                        ),
                        child: Row(
                          children: [
                            _StepBtn(
                              key: const ValueKey('custom-minus'),
                              icon: PhosphorIconsRegular.minus,
                              onTap: () => setState(
                                () => _custom = (_custom - 50).clamp(50, 2000),
                              ),
                            ),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text('$_custom', style: VText.headlineMd),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ml',
                                    style: VText.bodyMd.copyWith(
                                      color: VColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _StepBtn(
                              key: const ValueKey('custom-plus'),
                              icon: PhosphorIconsRegular.plus,
                              onTap: () => setState(
                                () => _custom = (_custom + 50).clamp(50, 2000),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: VSpace.gutter),
                    GestureDetector(
                      key: const ValueKey('custom-add'),
                      onTap: () => actions.addWater(day, _custom),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: VColors.primaryContainer,
                          borderRadius: BorderRadius.circular(VRadius.button),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              PhosphorIconsRegular.plusCircle,
                              size: 18,
                              color: VColors.onPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ekle',
                              style: VText.labelMd.copyWith(
                                color: VColors.onPrimary,
                              ),
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
          _EntriesCard(entries: entries, onUndo: actions.deleteWater),
          const SizedBox(height: VSpace.md),
          _WeekCard(week: week, goal: goal, todayIndex: day.weekday - 1),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.status});
  final HydrationStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status.label) {
      'Düşük' => (VColors.errorContainer, VColors.onErrorContainer),
      'Hedefte' => (VColors.tertiary, VColors.onTertiary),
      _ => (VColors.tertiaryFixed, VColors.onTertiaryFixed),
    };
    return VCard(
      padding: const EdgeInsets.symmetric(horizontal: VSpace.md, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: VColors.secondaryFixed,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              PhosphorIconsRegular.drop,
              color: VColors.secondary,
            ),
          ),
          const SizedBox(width: VSpace.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HÜCRESEL CANLILIK',
                  style: VText.microTag.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
                Text(status.message, style: VText.bodyMdMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(VRadius.pill),
            ),
            child: Text(
              status.label,
              style: VText.microTag.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// Su seviyesini gösteren bardak (seviye değişince akıcı animasyon).
class _Glass extends StatelessWidget {
  const _Glass({required this.fraction, required this.percent});
  final double fraction;
  final int percent;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 130,
    height: 170,
    child: TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: fraction),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(size: const Size(130, 170), painter: _GlassPainter(v)),
          Positioned(
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: VColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
              child: Text(
                '%$percent',
                style: VText.microTag.copyWith(color: VColors.secondary),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _GlassPainter extends CustomPainter {
  _GlassPainter(this.fraction);
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glass = Path()
      ..moveTo(w * 0.05, 0)
      ..lineTo(w * 0.95, 0)
      ..lineTo(w * 0.78, h - 14)
      ..quadraticBezierTo(w * 0.76, h, w * 0.6, h)
      ..lineTo(w * 0.4, h)
      ..quadraticBezierTo(w * 0.24, h, w * 0.22, h - 14)
      ..close();
    canvas.drawPath(glass, Paint()..color = VColors.surfaceContainerLow);
    canvas.save();
    canvas.clipPath(glass);
    final top = h * (1 - fraction);
    canvas.drawRect(
      Rect.fromLTRB(0, top, w, h),
      Paint()..color = VColors.secondary,
    );
    // su yüzeyi parlaması
    canvas.drawRect(
      Rect.fromLTRB(0, top, w, top + 2),
      Paint()..color = VColors.secondaryContainer,
    );
    canvas.restore();
    canvas.drawPath(
      glass,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = VColors.surfaceContainerHighest,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.fraction != fraction;
}

class _QuickButton extends StatelessWidget {
  const _QuickButton({
    super.key,
    required this.icon,
    required this.amount,
    required this.label,
    required this.onTap,
    this.filled = false,
  });
  final IconData icon;
  final String amount;
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? VColors.onSecondary : VColors.onSurface;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: filled ? VColors.secondary : VColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(VRadius.md),
          border: filled
              ? null
              : Border.all(color: VColors.surfaceContainerHighest),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: filled ? VColors.onSecondary : VColors.secondary,
            ),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: VText.headlineMd.copyWith(color: fg, fontSize: 16),
                ),
                Text(
                  label,
                  style: VText.microTag.copyWith(
                    fontWeight: FontWeight.w600,
                    color: fg.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({super.key, required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: SizedBox(
      width: VSpace.touchMin,
      height: 48,
      child: Icon(icon, size: 20, color: VColors.onSurface),
    ),
  );
}

String _period(int hour) => hour < 10
    ? 'Sabah'
    : hour < 14
    ? 'Öğle'
    : hour < 18
    ? 'İkindi'
    : 'Akşam';

String _hm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

class _EntriesCard extends StatelessWidget {
  const _EntriesCard({required this.entries, required this.onUndo});
  final List<WaterEntry> entries;
  final void Function(WaterEntry) onUndo;

  @override
  Widget build(BuildContext context) => VCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(PhosphorIconsRegular.clockCounterClockwise, size: 20, color: VColors.secondary),
            const SizedBox(width: 8),
            Text('Bugünün Kayıtları', style: VText.headlineMd),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: VColors.surfaceContainer,
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
              child: Text(
                '${entries.length} Giriş',
                style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpace.gutter),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: VSpace.md),
            child: Center(
              child: Text(
                'Henüz su kaydı yok. Hızlı ekle ile ilk bardağını kaydet.',
                textAlign: TextAlign.center,
                style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
              ),
            ),
          )
        else
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: VColors.secondaryFixed,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      switch (e.label) {
                        'Kupa' => PhosphorIconsRegular.coffee,
                        'Şişe' => PhosphorIconsRegular.drop,
                        _ => PhosphorIconsRegular.pintGlass,
                      },
                      size: 18,
                      color: VColors.secondary,
                    ),
                  ),
                  const SizedBox(width: VSpace.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.label == null
                              ? '${e.ml} ml'
                              : '${e.ml} ml (${e.label})',
                          style: VText.bodyMdMedium,
                        ),
                        Text(
                          '${_hm(e.at)} • ${_period(e.at.hour)}',
                          style: VText.microTag.copyWith(
                            fontWeight: FontWeight.w500,
                            color: VColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    key: ValueKey('undo-water-${e.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onUndo(e),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 10,
                      ),
                      child: Text(
                        'Geri Al',
                        style: VText.labelMd.copyWith(color: VColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      ],
    ),
  );
}

class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.week,
    required this.goal,
    required this.todayIndex,
  });
  final List<int> week;
  final int goal;
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    final summary = weekWaterSummary(week, goal);
    final maxV = [
      goal * 1.15,
      ...week.map((v) => v.toDouble()),
    ].reduce((a, b) => a > b ? a : b);
    const barArea = 110.0;
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'HİDRASYON DÖNGÜSÜ',
                style: VText.labelCaps.copyWith(
                  color: VColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: VColors.tertiary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Hedefe Ulaşıldı',
                style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Haftalık Su Dengesi', style: VText.headlineMd),
          const SizedBox(height: VSpace.md),
          SizedBox(
            height: barArea + 54,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 18 + barArea * (1 - goal / maxV),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: VColors.outlineVariant,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${formatLiters(goal)}L Hedef',
                        style: VText.microTag.copyWith(color: VColors.primary),
                      ),
                    ],
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: _Bar(
                          value: week[i],
                          goal: goal,
                          maxV: maxV,
                          area: barArea,
                          label: _days[i],
                          isToday: i == todayIndex,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.gutter),
          Container(
            padding: const EdgeInsets.all(VSpace.gutter),
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Row(
              children: [
                const Icon(
                  PhosphorIconsRegular.sealCheck,
                  size: 20,
                  color: VColors.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Haftalık Başarı: ${summary.daysReached}/7 Gün',
                    style: VText.bodyMdMedium,
                  ),
                ),
                Text(
                  'ORT. ${formatLiters(summary.averageMl)} L',
                  style: VText.labelCaps.copyWith(color: VColors.secondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.goal,
    required this.maxV,
    required this.area,
    required this.label,
    required this.isToday,
  });
  final int value;
  final int goal;
  final double maxV;
  final double area;
  final String label;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final reached = goal > 0 && value >= goal;
    final h = maxV <= 0 ? 0.0 : area * value / maxV;
    final color = isToday
        ? VColors.secondary
        : reached
        ? VColors.tertiaryFixed
        : VColors.surfaceContainerHigh;
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        SizedBox(
          height: 18,
          child: value > 0
              ? Text(
                  formatLiters(value),
                  style: VText.microTag.copyWith(
                    color: isToday
                        ? VColors.secondary
                        : VColors.onSurfaceVariant,
                  ),
                )
              : null,
        ),
        Container(
          width: 26,
          height: h < 6 && value > 0 ? 6 : h,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(VRadius.base),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 16,
          child: reached
              ? const Icon(
                  PhosphorIconsBold.checkCircle,
                  size: 14,
                  color: VColors.tertiary,
                )
              : null,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isToday ? VColors.secondaryFixed : Colors.transparent,
            borderRadius: BorderRadius.circular(VRadius.sm),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              isToday ? 'Bugün' : label,
              maxLines: 1,
              style: VText.microTag.copyWith(
                color: isToday ? VColors.secondary : VColors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
