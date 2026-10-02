import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/nutrition_calc.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/calorie_ring.dart';
import '../../core/widgets/v_card.dart';
import '../../core/widgets/v_progress_bar.dart';
import '../../data/models.dart';
import '../add_food/add_food_screen.dart';
import '../balance/balance_screen.dart';
import '../band/band_status.dart';
import '../diary/diary_screen.dart';
import '../hydration/hydration_screen.dart';

const _gap = SizedBox(height: VSpace.md);

/// Genel Bakış: günün özeti, enerji bütçesi, makrolar, bant, su, öğünler.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(selectedDayProvider);
    return ListView(
      key: const ValueKey('screen-home'),
      padding: const EdgeInsets.fromLTRB(
        VSpace.margin,
        VSpace.md,
        VSpace.margin,
        VSpace.lg,
      ),
      children: [
        _DateHeader(day: day),
        _gap,
        const _CoachCard(),
        _gap,
        _EnergyCard(day: day),
        _gap,
        _MacroRow(day: day),
        _gap,
        const _BandLiveCard(),
        _gap,
        _WaterCard(day: day),
        _gap,
        _MealsCard(day: day),
      ],
    );
  }
}

class _DateHeader extends ConsumerWidget {
  const _DateHeader({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final isToday = DateUtils.isSameDay(day, now);
    final title = isToday
        ? 'Bugün, ${formatDayMonth(day)}'
        : formatDayMonth(day);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GÜNLÜK TAKİP',
                style: VText.labelCaps.copyWith(
                  color: VColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VText.displayLg.copyWith(fontSize: 28, height: 34 / 28),
              ),
            ],
          ),
        ),
        GestureDetector(
          key: const ValueKey('home-calendar'),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: day,
              firstDate: DateTime(2020),
              lastDate: now,
            );
            if (picked != null) {
              ref.read(selectedDayProvider.notifier).set(picked);
            }
          },
          child: Container(
            width: VSpace.touchMin,
            height: VSpace.touchMin,
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: VColors.surfaceContainerHighest),
            ),
            child: const Icon(
              PhosphorIconsRegular.calendarDots,
              size: 22,
              color: VColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _CoachCard extends ConsumerWidget {
  const _CoachCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefing = ref.watch(coachBriefingProvider).value;
    return VCard(
      key: const ValueKey('coach-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                PhosphorIconsRegular.brain,
                color: VColors.primary,
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Günün Koç Özeti',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VText.headlineMd,
                ),
              ),
              if (briefing?.readiness != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: VColors.tertiary,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: Text(
                    'Hazırlık Skoru: %${briefing!.readiness}',
                    style: VText.microTag.copyWith(color: VColors.onTertiary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          if (briefing == null)
            Container(
              key: const ValueKey('coach-empty'),
              width: double.infinity,
              padding: const EdgeInsets.all(VSpace.gutter),
              decoration: BoxDecoration(
                color: VColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(VRadius.md),
              ),
              child: Text(
                'Koçun günlük özeti için birkaç günlük bant verisi gerekiyor. '
                'Bileğine tak ve yemeklerini kaydet.',
                style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
              ),
            )
          else ...[
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Bugünün Planı: ', style: VText.bodyLgMedium),
                  TextSpan(text: briefing.plan, style: VText.bodyLg),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    PhosphorIconsRegular.sparkle,
                    size: 20,
                    color: VColors.tertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(briefing.insight, style: VText.bodyLg)),
                ],
              ),
            ),
            const SizedBox(height: VSpace.gutter),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                height: VSpace.touchMin,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: VColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Planı gör', style: VText.labelMd),
                    const SizedBox(width: 4),
                    const Icon(PhosphorIconsRegular.caretRight, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EnergyCard extends ConsumerWidget {
  const _EnergyCard({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e =
        ref.watch(energySummaryProvider(day)).value ??
        const EnergySummary(eaten: 0, goal: 0, burned: 0);
    final now = ref.watch(clockProvider)();
    final hr = ref.watch(latestHrProvider).value;
    final caption = hr == null
        ? 'VitaxBand • henüz veri yok'
        : 'VitaxBand • ${formatAgo(now.difference(hr.at))} güncellendi';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const BalanceScreen())),
      child: VCard(
        key: const ValueKey('energy-card'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'ENERJİ BÜTÇESİ',
                  style: VText.labelCaps.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    caption,
                    maxLines: 1,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: VText.microTag.copyWith(
                      fontWeight: FontWeight.w500,
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: VSpace.md),
            Row(
              children: [
                CalorieRing(value: e.eaten, goal: e.goal, size: 136),
                const SizedBox(width: VSpace.md),
                Expanded(
                  child: Column(
                    children: [
                      _StatBox(
                        label: 'YAKILAN (VİTAXBAND)',
                        value: formatTr(e.burned),
                        color: VColors.secondary,
                      ),
                      const SizedBox(height: VSpace.sm),
                      _StatBox(
                        label: 'KALAN HEDEF',
                        value: formatTr(e.remaining),
                        color: VColors.primary,
                      ),
                    ],
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

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: VColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(VRadius.md),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: VText.headlineLg.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'kcal',
              style: VText.labelMd.copyWith(color: VColors.onSurfaceVariant),
            ),
          ],
        ),
      ],
    ),
  );
}

class _MacroRow extends ConsumerWidget {
  const _MacroRow({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(dayTotalsProvider(day)).value ?? const DayTotals();
    final p = ref.watch(profileProvider).value ?? const Profile();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MacroCard(
            key: const ValueKey('macro-protein'),
            label: 'PROTEİN',
            value: t.protein.round(),
            goal: p.proteinGoal,
            color: VColors.secondary,
          ),
        ),
        const SizedBox(width: VSpace.gutter),
        Expanded(
          child: _MacroCard(
            key: const ValueKey('macro-carbs'),
            label: 'KARB',
            value: t.carbs.round(),
            goal: p.carbsGoal,
            color: VColors.tertiary,
          ),
        ),
        const SizedBox(width: VSpace.gutter),
        Expanded(
          child: _MacroCard(
            key: const ValueKey('macro-fat'),
            label: 'YAĞ',
            value: t.fat.round(),
            goal: p.fatGoal,
            color: VColors.primaryContainer,
          ),
        ),
      ],
    );
  }
}

class _MacroCard extends StatelessWidget {
  const _MacroCard({
    super.key,
    required this.label,
    required this.value,
    required this.goal,
    required this.color,
  });
  final String label;
  final int value;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) => VCard(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
              ),
            ),
            Text(
              '%${percent(value, goal)}',
              style: VText.microTag.copyWith(color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$value', style: VText.headlineMd),
            Text(
              '/${goal}g',
              style: VText.microTag.copyWith(
                fontWeight: FontWeight.w500,
                color: VColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        VProgressBar(
          value: goal <= 0 ? 0 : value / goal,
          color: color,
          height: 6,
        ),
      ],
    ),
  );
}

class _BandLiveCard extends ConsumerWidget {
  const _BandLiveCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final day = DateTime(now.year, now.month, now.day);
    final band = ref.watch(bandStatusProvider);
    final hr = ref.watch(latestHrProvider).value;
    final steps = ref.watch(stepsProvider(day)).value ?? 0;
    final sleep = ref.watch(lastNightSleepProvider).value;
    // Bir saat önceki nabız "canlı" sayılmaz.
    final hrFresh = hr != null && now.difference(hr.at).inMinutes <= 10;
    return VCard(
      key: const ValueKey('band-live-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: band.connected
                      ? VColors.secondary
                      : VColors.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'VİTAXBAND CANLI',
                style: VText.labelCaps.copyWith(color: VColors.onSurface),
              ),
              const Spacer(),
              Text(
                band.connected ? 'Bluetooth Bağlı' : 'Bağlı değil',
                style: VText.microTag.copyWith(
                  fontWeight: FontWeight.w500,
                  color: VColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          Row(
            children: [
              Expanded(
                child: _LiveTile(
                  icon: PhosphorIconsRegular.heart,
                  iconColor: VColors.error,
                  value: hrFresh ? '${hr.bpm}' : '--',
                  label: 'bpm Nabız',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LiveTile(
                  icon: PhosphorIconsRegular.personSimpleWalk,
                  iconColor: VColors.secondary,
                  value: steps > 0 ? formatTr(steps) : '--',
                  label: 'Adım',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _LiveTile(
                  icon: PhosphorIconsRegular.moon,
                  iconColor: VColors.tertiary,
                  value: sleep == null
                      ? '--'
                      : '${sleep.inHours}s ${sleep.inMinutes % 60}d',
                  label: 'Dün Gece',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LiveTile extends StatelessWidget {
  const _LiveTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
    decoration: BoxDecoration(
      color: VColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(VRadius.md),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VText.headlineMd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: VText.microTag.copyWith(
            fontWeight: FontWeight.w500,
            color: VColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _WaterCard extends ConsumerWidget {
  const _WaterCard({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ml = ref.watch(waterProvider(day)).value ?? 0;
    final goal =
        (ref.watch(profileProvider).value ?? const Profile()).waterGoalMl;
    final filled = goal <= 0 ? 0 : (ml / goal * 5).ceil().clamp(0, 5);
    final actions = ref.read(nutritionActionsProvider);
    return VCard(
      key: const ValueKey('water-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const HydrationScreen()),
            ),
            child: Row(
              children: [
                const Icon(PhosphorIconsRegular.drop, color: VColors.secondary),
                const SizedBox(width: 8),
                Text('Su Takibi', style: VText.headlineMd),
                const Spacer(),
                Text(
                  '${formatLiters(ml)} L',
                  style: VText.labelMd.copyWith(color: VColors.secondary),
                ),
                Text(
                  ' / ${formatLiters(goal)} L',
                  style: VText.labelMd.copyWith(
                    fontWeight: FontWeight.w500,
                    color: VColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              for (var i = 0; i < 5; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: i < filled
                          ? VColors.secondary
                          : VColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(VRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              Expanded(
                child: _WaterButton(
                  label: '+200 ml',
                  onTap: () => actions.addWater(day, 200, label: 'Bardak'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WaterButton(
                  label: '+300 ml',
                  onTap: () => actions.addWater(day, 300, label: 'Kupa'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _WaterButton(
                  label: '+Şişe (500 ml)',
                  filled: true,
                  onTap: () => actions.addWater(day, 500, label: 'Şişe'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaterButton extends StatelessWidget {
  const _WaterButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: VSpace.touchMin,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: filled ? VColors.secondary : VColors.surfaceContainer,
        borderRadius: BorderRadius.circular(VRadius.button),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: VText.labelMd.copyWith(
          fontSize: 12,
          color: filled ? VColors.onSecondary : VColors.onSurface,
        ),
      ),
    ),
  );
}

class _MealsCard extends ConsumerWidget {
  const _MealsCard({required this.day});
  final DateTime day;

  static const _icons = {
    MealType.breakfast: PhosphorIconsRegular.sun,
    MealType.lunch: PhosphorIconsRegular.bowlFood,
    MealType.dinner: PhosphorIconsRegular.moon,
    MealType.snack: PhosphorIconsRegular.leaf,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final foods = ref.watch(dayFoodProvider(day)).value ?? const <FoodEntry>[];
    final title = DateUtils.isSameDay(day, now)
        ? 'Bugünün Öğünleri'
        : 'Öğünler';
    // Ana üç öğün her zaman görünür; atıştırmalık sadece kayıt varsa.
    final meals = [
      MealType.breakfast,
      MealType.lunch,
      MealType.dinner,
      if (foods.any((f) => f.meal == MealType.snack)) MealType.snack,
    ];
    return Column(
      key: const ValueKey('meals-card'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: VText.headlineMd),
            const Spacer(),
            GestureDetector(
              key: const ValueKey('meals-add'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const AddFoodScreen()),
              ),
              child: Container(
                width: VSpace.touchMin,
                height: VSpace.touchMin,
                decoration: const BoxDecoration(
                  color: VColors.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(PhosphorIconsRegular.plus, color: VColors.onPrimaryContainer),
              ),
            ),
          ],
        ),
        const SizedBox(height: VSpace.gutter),
        VCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < meals.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    color: VColors.surfaceContainerHighest,
                  ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DiaryScreen(),
                    ),
                  ),
                  child: _MealRow(
                    meal: meals[i],
                    icon: _icons[meals[i]]!,
                    entries: foods.where((f) => f.meal == meals[i]).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.icon,
    required this.entries,
  });
  final MealType meal;
  final IconData icon;
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final kcal = entries.fold<int>(0, (a, e) => a + e.kcal);
    final empty = entries.isEmpty;
    return Padding(
      padding: const EdgeInsets.all(VSpace.md),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Icon(icon, size: 22, color: VColors.onSurfaceVariant),
          ),
          const SizedBox(width: VSpace.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meal.shortLabel, style: VText.bodyLgMedium),
                Text(
                  empty
                      ? 'Henüz kaydedilmedi'
                      : entries.map((e) => e.name).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: VSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(empty ? '--' : formatTr(kcal), style: VText.headlineMd),
              Text(
                'kcal',
                style: VText.microTag.copyWith(
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
}
