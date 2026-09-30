import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/v_card.dart';
import '../../core/widgets/v_segmented.dart';
import '../../core/workout_calc.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models.dart';
import '../workout/active_workout.dart';
import '../workout/live_workout_screen.dart';
import '../workout/routine_builder_screen.dart';
import '../workout/workout_history_screen.dart';
import '../workout/workout_providers.dart';
import 'exercise_detail_screen.dart';
import 'exercise_widgets.dart';

/// Egzersiz sekmesi: kütüphane ve kayıtlı rutinler.
class ExercisesScreen extends ConsumerStatefulWidget {
  const ExercisesScreen({super.key});

  @override
  ConsumerState<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends ConsumerState<ExercisesScreen> {
  int _tab = 0;
  String _query = '';
  ExerciseGroup _group = ExerciseGroup.all;
  String? _equipment;

  void _push(Widget w) =>
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

  Future<void> _filterEquipment(ExerciseCatalog c) async {
    final r = await pickEquipment(context, c, _equipment);
    if (r == null) return;
    setState(() => _equipment = r == '__all__' ? null : r);
  }

  Future<void> _startRoutine(Routine r) async {
    if (ref.read(activeWorkoutProvider) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce devam eden antrenmanı bitir')),
      );
      return;
    }
    await ref.read(activeWorkoutProvider.notifier).start(routine: r);
    if (mounted) _push(const LiveWorkoutScreen());
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(exerciseCatalogProvider).value;
    final active = ref.watch(activeWorkoutProvider);
    final results =
        catalog?.search(query: _query, group: _group, equipment: _equipment) ??
        const <Exercise>[];

    return CustomScrollView(
      key: const ValueKey('screen-exercises'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            VSpace.margin,
            VSpace.md,
            VSpace.margin,
            VSpace.sm,
          ),
          sliver: SliverList.list(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Egzersizler',
                          style: VText.displayLg.copyWith(
                            fontSize: 28,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Hedef kas grubunu seç ve tekniği incele',
                          style: VText.bodyMd.copyWith(
                            color: VColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoundIcon(
                    key: const ValueKey('open-history'),
                    icon: Icons.history,
                    onTap: () => _push(const WorkoutHistoryScreen()),
                  ),
                  const SizedBox(width: 8),
                  _RoundIcon(
                    key: const ValueKey('equipment-filter'),
                    icon: Icons.tune,
                    highlighted: _equipment != null,
                    onTap: catalog == null
                        ? () {}
                        : () => _filterEquipment(catalog),
                  ),
                ],
              ),
              const SizedBox(height: VSpace.md),
              if (active != null) ...[
                VCard(
                  color: VColors.primaryFixed,
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: VColors.primary),
                      const SizedBox(width: VSpace.gutter),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Devam eden antrenman', style: VText.labelMd),
                            Text(
                              active.name,
                              style: VText.bodyMd.copyWith(
                                color: VColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: VColors.primaryContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(VRadius.button),
                          ),
                        ),
                        onPressed: () => _push(const LiveWorkoutScreen()),
                        child: const Text('Devam Et'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: VSpace.md),
              ],
              ExerciseSearchField(onChanged: (v) => setState(() => _query = v)),
              const SizedBox(height: VSpace.md),
              VSegmented(
                labels: const ['Egzersizler', 'Rutinler'],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(height: VSpace.md),
              if (_tab == 0) ...[
                GroupChips(
                  selected: _group,
                  onChanged: (g) => setState(() => _group = g),
                ),
                const SizedBox(height: VSpace.md),
                Row(
                  children: [
                    Text(
                      'KÜTÜPHANE (${results.length} HAREKET)',
                      style: VText.labelCaps.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: VColors.tertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ANİMASYONLU ANLATIM',
                      style: VText.microTag.copyWith(color: VColors.tertiary),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.sm),
              ],
            ],
          ),
        ),
        if (_tab == 0)
          if (results.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(VSpace.lg),
                child: Center(
                  child: Text(
                    'Sonuç bulunamadı',
                    style: VText.bodyMd.copyWith(
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                VSpace.margin,
                0,
                VSpace.margin,
                VSpace.lg,
              ),
              sliver: SliverList.separated(
                itemCount: results.length,
                separatorBuilder: (_, _) => const SizedBox(height: VSpace.sm),
                itemBuilder: (_, i) => ExerciseRow(
                  exercise: results[i],
                  onTap: () =>
                      _push(ExerciseDetailScreen(exerciseId: results[i].id)),
                ),
              ),
            )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              VSpace.margin,
              0,
              VSpace.margin,
              VSpace.lg,
            ),
            sliver: SliverToBoxAdapter(
              child: _RoutinesTab(
                onStart: _startRoutine,
                onEdit: (r) => _push(RoutineBuilderScreen(routine: r)),
                onNew: () => _push(const RoutineBuilderScreen()),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({
    super.key,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: VSpace.touchMin,
      height: VSpace.touchMin,
      decoration: BoxDecoration(
        color: highlighted ? VColors.primaryFixed : VColors.surfaceContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: 22,
        color: highlighted ? VColors.primary : VColors.onSurface,
      ),
    ),
  );
}

class _RoutinesTab extends ConsumerWidget {
  const _RoutinesTab({
    required this.onStart,
    required this.onEdit,
    required this.onNew,
  });
  final void Function(Routine) onStart;
  final void Function(Routine) onEdit;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routines = ref.watch(routinesProvider).value ?? const <Routine>[];
    final sessions =
        ref.watch(recentSessionsProvider).value ?? const <WorkoutSession>[];
    final now = ref.watch(clockProvider)();
    String lastDone(Routine r) {
      final done = sessions.where((s) => s.routineId == r.id).toList();
      if (done.isEmpty) return 'Henüz yapılmadı';
      done.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return formatDaysAgo(now, done.first.startedAt);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: VSpace.touchMin,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: VColors.surfaceContainerHighest),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(VRadius.button),
              ),
            ),
            onPressed: onNew,
            icon: const Icon(Icons.add, color: VColors.primary),
            label: Text(
              'Yeni Rutin',
              style: VText.labelMd.copyWith(color: VColors.primary),
            ),
          ),
        ),
        const SizedBox(height: VSpace.md),
        if (routines.isEmpty)
          Padding(
            padding: const EdgeInsets.all(VSpace.lg),
            child: Center(
              child: Text(
                'Henüz rutin yok. "Yeni Rutin" ile ilk planını oluştur ya da bir egzersizi rutine ekle.',
                textAlign: TextAlign.center,
                style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
              ),
            ),
          )
        else
          for (final r in routines)
            Padding(
              padding: const EdgeInsets.only(bottom: VSpace.gutter),
              child: VCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: VColors.primaryFixed,
                            borderRadius: BorderRadius.circular(VRadius.md),
                          ),
                          child: const Icon(Icons.bolt, color: VColors.primary),
                        ),
                        const SizedBox(width: VSpace.gutter),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KAYITLI RUTİN',
                                style: VText.labelCaps.copyWith(
                                  color: VColors.onSurfaceVariant,
                                ),
                              ),
                              Text(r.name, style: VText.headlineMd),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: VSpace.gutter),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _Meta(
                          Icons.fitness_center,
                          '${r.items.length} Egzersiz',
                        ),
                        _Meta(
                          Icons.timer_outlined,
                          '${routineEstimatedMinutes(r)} dk',
                        ),
                        _Meta(Icons.history, lastDone(r)),
                      ],
                    ),
                    const SizedBox(height: VSpace.gutter),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: VColors.primaryContainer,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    VRadius.button,
                                  ),
                                ),
                              ),
                              onPressed: () => onStart(r),
                              icon: const Icon(
                                Icons.play_arrow,
                                color: VColors.onPrimary,
                              ),
                              label: Text(
                                'Başlat',
                                style: VText.labelMd.copyWith(
                                  color: VColors.onPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          key: ValueKey('edit-routine-${r.id}'),
                          onTap: () => onEdit(r),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: VColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(
                                VRadius.button,
                              ),
                            ),
                            child: const Icon(Icons.edit_note),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: VColors.onSurfaceVariant),
      const SizedBox(width: 4),
      Text(text, style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant)),
    ],
  );
}
