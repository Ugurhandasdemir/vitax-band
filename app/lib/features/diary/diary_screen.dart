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
import '../add_food/add_food_screen.dart';
import '../hydration/hydration_screen.dart';
import 'quick_add_sheet.dart';

/// Kalori Takibi: günlük enerji dengesi, makrolar, öğün öğün yemek günlüğü.
class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  // Kaydırarak silinenler hemen listeden çıkar (Dismissible ağaçta kalmamalı).
  final Set<int> _dismissed = {};

  void _openAdd(MealType? meal) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => AddFoodScreen(initialMeal: meal)),
  );

  void _snack(String text, {SnackBarAction? action}) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(text),
            action: action,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );

  Future<void> _copyYesterday(DateTime day) async {
    final n = await ref
        .read(nutritionActionsProvider)
        .copyDay(day.subtract(const Duration(days: 1)), day);
    _snack(n == 0 ? 'Dün için kayıt yok' : '$n yemek kopyalandı');
  }

  Future<void> _delete(FoodEntry e) async {
    setState(() => _dismissed.add(e.id!));
    await ref.read(nutritionActionsProvider).deleteFood(e);
    _snack(
      'Silindi',
      action: SnackBarAction(
        label: 'Geri Al',
        onPressed: () => ref.read(nutritionActionsProvider).restoreFood(e),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(selectedDayProvider);
    final foods = (ref.watch(dayFoodProvider(day)).value ?? const <FoodEntry>[])
        .where((e) => !_dismissed.contains(e.id))
        .toList();
    return VDetailScaffold(
      key: const ValueKey('screen-diary'),
      title: 'Kalori Takibi',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.md,
          VSpace.margin,
          VSpace.lg,
        ),
        children: [
          _WeekStrip(day: day),
          const SizedBox(height: VSpace.md),
          _SummaryCard(day: day),
          const SizedBox(height: VSpace.gutter),
          Row(
            children: [
              Expanded(
                child: _ChipButton(
                  icon: Icons.copy_outlined,
                  label: 'Dünü Kopyala',
                  onTap: () => _copyYesterday(day),
                ),
              ),
              const SizedBox(width: VSpace.gutter),
              Expanded(
                child: _ChipButton(
                  icon: Icons.bolt,
                  label: 'Hızlı Ekle',
                  onTap: () => showQuickAddSheet(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.md),
          for (final m in MealType.values) ...[
            _MealSection(
              meal: m,
              entries: foods.where((f) => f.meal == m).toList(),
              onAdd: () => _openAdd(m),
              onDelete: _delete,
            ),
            const SizedBox(height: VSpace.gutter),
          ],
          _WaterRow(day: day),
          const SizedBox(height: VSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.swipe_left_alt,
                size: 16,
                color: VColors.outline,
              ),
              const SizedBox(width: 6),
              Text(
                'Silmek için sola kaydırabilirsiniz',
                style: VText.microTag.copyWith(
                  fontWeight: FontWeight.w500,
                  color: VColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: Container(
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.sm,
          VSpace.margin,
          VSpace.sm,
        ),
        decoration: const BoxDecoration(
          color: VColors.surface,
          border: Border(
            top: BorderSide(color: VColors.surfaceContainerHighest),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 48,
            child: FilledButton.icon(
              key: const ValueKey('diary-bottom-add'),
              style: FilledButton.styleFrom(
                backgroundColor: VColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VRadius.button),
                ),
              ),
              onPressed: () => _openAdd(null),
              icon: const Icon(Icons.add, color: VColors.onPrimary),
              label: Text(
                'Yemek Ekle',
                style: VText.labelMd.copyWith(color: VColors.onPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monday = day.subtract(Duration(days: day.weekday - 1));
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Builder(
              builder: (_) {
                final d = DateTime(monday.year, monday.month, monday.day + i);
                final selected = DateUtils.isSameDay(d, day);
                return GestureDetector(
                  key: ValueKey('day-chip-${d.day}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ref.read(selectedDayProvider.notifier).set(d),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: selected
                          ? VColors.primaryContainer
                          : VColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(VRadius.md),
                      border: selected
                          ? null
                          : Border.all(color: VColors.surfaceContainerHighest),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          shortWeekday(d),
                          style: VText.microTag.copyWith(
                            color: selected
                                ? VColors.onPrimaryContainer
                                : VColors.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.day}',
                          style: VText.headlineMd.copyWith(
                            color: selected
                                ? VColors.onPrimaryContainer
                                : VColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e =
        ref.watch(energySummaryProvider(day)).value ??
        const EnergySummary(eaten: 0, goal: 0, burned: 0);
    final t = ref.watch(dayTotalsProvider(day)).value ?? const DayTotals();
    final p = ref.watch(profileProvider).value ?? const Profile();
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_outlined,
                size: 18,
                color: VColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'GÜNLÜK ENERJİ DENGESİ',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: VText.labelCaps.copyWith(color: VColors.primary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: VColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(VRadius.sm),
                ),
                child: Text(
                  'Hedef: ${formatTr(e.goal)} kcal',
                  style: VText.microTag.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          Row(
            children: [
              Expanded(
                child: _Cell(label: 'Alınan', value: formatTr(e.eaten)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Cell(
                  label: 'Kalan',
                  value: formatTr(e.remaining),
                  valueColor: VColors.primary,
                  highlight: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Cell(
                  label: 'Net Kalori',
                  value: formatTr(e.net),
                  labelColor: VColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.sm),
          Row(
            children: [
              const Icon(
                Icons.watch_outlined,
                size: 14,
                color: VColors.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                e.burned > 0
                    ? 'VitaxBand ile ${formatTr(e.burned)} kcal yakıldı.'
                    : 'Bant verisi yok, yakılan kalori hesaplanamadı.',
                style: VText.microTag.copyWith(
                  fontWeight: FontWeight.w500,
                  color: VColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          _MacroLine(
            'Protein',
            t.protein.round(),
            p.proteinGoal,
            VColors.secondary,
          ),
          const SizedBox(height: 8),
          _MacroLine(
            'Karbonhidrat',
            t.carbs.round(),
            p.carbsGoal,
            VColors.tertiary,
          ),
          const SizedBox(height: 8),
          _MacroLine('Yağ', t.fat.round(), p.fatGoal, VColors.primaryContainer),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    this.valueColor = VColors.onSurface,
    this.labelColor = VColors.onSurfaceVariant,
    this.highlight = false,
  });
  final String label;
  final String value;
  final Color valueColor;
  final Color labelColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(
      color: highlight
          ? VColors.surfaceContainerLowest
          : VColors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(VRadius.md),
      border: highlight
          ? Border.all(color: VColors.surfaceContainerHighest)
          : null,
    ),
    child: Column(
      children: [
        Text(
          label,
          style: VText.microTag.copyWith(
            fontWeight: FontWeight.w600,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: VText.headlineLg.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        Text(
          'kcal',
          style: VText.microTag.copyWith(
            fontWeight: FontWeight.w500,
            color: VColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );
}

class _MacroLine extends StatelessWidget {
  const _MacroLine(this.label, this.value, this.goal, this.color);
  final String label;
  final int value;
  final int goal;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Text(label, style: VText.labelMd.copyWith(fontSize: 12)),
          const Spacer(),
          Text(
            '${value}g / ${goal}g',
            style: VText.microTag.copyWith(
              fontWeight: FontWeight.w500,
              color: VColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
      const SizedBox(height: 4),
      VProgressBar(
        value: goal <= 0 ? 0 : value / goal,
        color: color,
        height: 6,
      ),
    ],
  );
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: VSpace.touchMin,
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(VRadius.pill),
        border: Border.all(color: VColors.surfaceContainerHighest),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: VColors.primary),
          const SizedBox(width: 8),
          Text(label, style: VText.labelMd),
        ],
      ),
    ),
  );
}

String _g(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : formatDecimalTr(v);

class _MealSection extends ConsumerWidget {
  const _MealSection({
    required this.meal,
    required this.entries,
    required this.onAdd,
    required this.onDelete,
  });
  final MealType meal;
  final List<FoodEntry> entries;
  final VoidCallback onAdd;
  final void Function(FoodEntry) onDelete;

  static const _icons = {
    MealType.breakfast: Icons.wb_sunny_outlined,
    MealType.lunch: Icons.restaurant_menu,
    MealType.dinner: Icons.nightlight_outlined,
    MealType.snack: Icons.eco_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goal = (ref.watch(profileProvider).value ?? const Profile()).kcalGoal;
    final (lo, hi) = recommendedRange(meal, goal);
    final total = entries.fold<int>(0, (a, e) => a + e.kcal);
    return VCard(
      padding: const EdgeInsets.all(VSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: VColors.primaryFixed,
                  borderRadius: BorderRadius.circular(VRadius.md),
                ),
                child: Icon(_icons[meal], color: VColors.primary, size: 22),
              ),
              const SizedBox(width: VSpace.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.headlineMd,
                    ),
                    Text(
                      'Önerilen: $lo-$hi kcal',
                      style: VText.microTag.copyWith(
                        fontWeight: FontWeight.w500,
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${formatTr(total)} kcal',
                style: VText.labelMd.copyWith(color: VColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          if (entries.isEmpty)
            Container(
              key: ValueKey('empty-${meal.name}'),
              width: double.infinity,
              padding: const EdgeInsets.all(VSpace.md),
              decoration: BoxDecoration(
                color: VColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(VRadius.md),
              ),
              child: Column(
                children: [
                  Text(
                    '${meal.label} henüz girilmedi. Sağlıklı bir seçimle hedefini tamamla!',
                    textAlign: TextAlign.center,
                    style: VText.bodyMd.copyWith(
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: VSpace.gutter),
                  GestureDetector(
                    key: ValueKey('add-to-${meal.name}'),
                    onTap: onAdd,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: VColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(VRadius.pill),
                        border: Border.all(
                          color: VColors.surfaceContainerHighest,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            size: 18,
                            color: VColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text('${meal.label} Ekle', style: VText.labelMd),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Dismissible(
                  key: ValueKey('food-${e.id}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => onDelete(e),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: VColors.errorContainer,
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: VColors.error,
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: VSpace.gutter,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(VRadius.md),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: VText.bodyMdMedium,
                              ),
                              Text(
                                '${e.portion} • P: ${_g(e.protein)}g '
                                'K: ${_g(e.carbs)}g Y: ${_g(e.fat)}g',
                                style: VText.microTag.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: VColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: VSpace.sm),
                        Text('${e.kcal} kcal', style: VText.labelMd),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 2),
            GestureDetector(
              key: ValueKey('add-to-${meal.name}'),
              behavior: HitTestBehavior.opaque,
              onTap: onAdd,
              child: Container(
                height: VSpace.touchMin,
                decoration: BoxDecoration(
                  color: VColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(VRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add, size: 18, color: VColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Yemek Ekle',
                      style: VText.labelMd.copyWith(color: VColors.primary),
                    ),
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

class _WaterRow extends ConsumerWidget {
  const _WaterRow({required this.day});
  final DateTime day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ml = ref.watch(waterProvider(day)).value ?? 0;
    final goal =
        (ref.watch(profileProvider).value ?? const Profile()).waterGoalMl;
    final left = (goal - ml) < 0 ? 0 : goal - ml;
    return VCard(
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
              Icons.water_drop_outlined,
              color: VColors.secondary,
              size: 22,
            ),
          ),
          const SizedBox(width: VSpace.gutter),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const HydrationScreen(),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Günlük Su Tüketimi', style: VText.bodyLgMedium),
                  Text(
                    '${formatLiters(ml)} L / ${formatLiters(goal)} L '
                    '(Kalan: ${formatLiters(left)} L)',
                    style: VText.microTag.copyWith(
                      fontWeight: FontWeight.w500,
                      color: VColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            key: const ValueKey('diary-water-add'),
            onTap: () => ref
                .read(nutritionActionsProvider)
                .addWater(day, 200, label: 'Bardak'),
            child: Container(
              width: VSpace.touchMin,
              height: VSpace.touchMin,
              decoration: const BoxDecoration(
                color: VColors.secondaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: VColors.secondary),
            ),
          ),
        ],
      ),
    );
  }
}
