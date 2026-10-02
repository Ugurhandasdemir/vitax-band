import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../core/workout_calc.dart';
import '../../data/models.dart';
import '../exercises/exercise_picker_screen.dart';
import 'active_workout.dart';
import 'live_workout_screen.dart';
import 'routine_draft.dart';
import 'workout_providers.dart';

String _kg(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : formatDecimalTr(v);

/// Antrenman Oluşturucu: rutin adı, hareket sırası, set başına hedefler, mola.
class RoutineBuilderScreen extends ConsumerStatefulWidget {
  const RoutineBuilderScreen({
    super.key,
    this.routine,
    this.initialExerciseIds = const [],
  });
  final Routine? routine;
  final List<String> initialExerciseIds;

  @override
  ConsumerState<RoutineBuilderScreen> createState() =>
      _RoutineBuilderScreenState();
}

class _RoutineBuilderScreenState extends ConsumerState<RoutineBuilderScreen> {
  late final TextEditingController _name;
  final Set<int> _collapsed = {};

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.routine?.name ?? '');
    Future(() async {
      final c = ref.read(routineDraftProvider.notifier);
      c.load(widget.routine);
      for (final id in widget.initialExerciseIds) {
        final last = await ref.read(lastPerformanceProvider(id).future);
        c.addExercise(id, weightKg: last?.best.weightKg ?? 0);
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _snack(String t) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(t), behavior: SnackBarBehavior.floating),
    );

  Future<Routine?> _save() async {
    final d = ref.read(routineDraftProvider);
    if (!d.isValid) {
      _snack('Rutine ad ver ve en az bir egzersiz ekle');
      return null;
    }
    final id = await ref
        .read(workoutActionsProvider)
        .saveRoutine(d.toRoutine());
    return Routine(id: id, name: d.name.trim(), items: d.items);
  }

  Future<void> _addExercise() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (id == null || !mounted) return;
    final last = await ref.read(lastPerformanceProvider(id).future);
    ref
        .read(routineDraftProvider.notifier)
        .addExercise(id, weightKg: last?.best.weightKg ?? 0);
  }

  Future<void> _start() async {
    if (ref.read(activeWorkoutProvider) != null) {
      _snack('Önce devam eden antrenmanı bitir');
      return;
    }
    final r = await _save();
    if (r == null) return;
    await ref.read(activeWorkoutProvider.notifier).start(routine: r);
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const LiveWorkoutScreen()),
      );
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VColors.surface,
        title: Text('Rutini sil?', style: VText.headlineMd),
        content: const Text(
          'Bu rutin kalıcı olarak silinir. Geçmiş antrenmanların korunur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final id = ref.read(routineDraftProvider).id;
    if (id != null) await ref.read(workoutActionsProvider).deleteRoutine(id);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final d = ref.watch(routineDraftProvider);
    final ctl = ref.read(routineDraftProvider.notifier);
    final catalog = ref.watch(exerciseCatalogProvider).value;
    final media = ref.watch(exerciseMediaBuilderProvider);
    final routine = d.toRoutine();
    final minutes = routineEstimatedMinutes(routine);

    return VDetailScaffold(
      key: const ValueKey('screen-routine-builder'),
      title: 'Antrenman Oluşturucu',
      actions: [
        TextButton(
          onPressed: () async {
            final r = await _save();
            if (!context.mounted) return;
            if (r != null) Navigator.of(context).maybePop();
          },
          child: Text(
            'Kaydet',
            style: VText.labelMd.copyWith(color: VColors.primary),
          ),
        ),
      ],
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.md,
          VSpace.margin,
          VSpace.lg,
        ),
        children: [
          Text(
            'ANTRENMAN PLANI',
            style: VText.labelCaps.copyWith(color: VColors.primary),
          ),
          const SizedBox(height: VSpace.sm),
          VCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rutin Adı',
                        style: VText.microTag.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                      TextField(
                        key: const ValueKey('routine-name'),
                        controller: _name,
                        onChanged: ctl.rename,
                        style: VText.headlineMd,
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: 'Örn. Göğüs & Triceps',
                          hintStyle: VText.headlineMd.copyWith(
                            color: VColors.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  PhosphorIconsRegular.pencilSimple,
                  color: VColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.gutter),
          VCard(
            padding: const EdgeInsets.symmetric(vertical: VSpace.gutter),
            child: Row(
              children: [
                _Stat('SÜRE', '$minutes dk'),
                _Divider(),
                _Stat('HACİM', '${routineSetCount(routine)} Set'),
                _Divider(),
                _Stat('HEDEF', routineGoal(routine), color: VColors.secondary),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  'EGZERSİZ SIRALAMASI (${d.items.length})',
                  style: VText.labelCaps.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
              ),
              Text(
                'Sıralamak için basılı tut',
                style: VText.microTag.copyWith(
                  fontWeight: FontWeight.w500,
                  color: VColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.sm),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: d.items.length,
            // ignore: deprecated_member_use
            onReorder: ctl.moveExercise,
            itemBuilder: (context, i) {
              final item = d.items[i];
              final ex = catalog?.byId(item.exerciseId);
              final expanded = !_collapsed.contains(i);
              return Padding(
                key: ValueKey('routine-item-${item.exerciseId}'),
                padding: const EdgeInsets.only(bottom: VSpace.sm),
                child: VCard(
                  padding: const EdgeInsets.all(VSpace.sm),
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => setState(
                          () => expanded
                              ? _collapsed.add(i)
                              : _collapsed.remove(i),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ReorderableDragStartListener(
                              index: i,
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 26,
                                ),
                                child: Icon(
                                  PhosphorIconsRegular.dotsSixVertical,
                                  color: VColors.outline,
                                ),
                              ),
                            ),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(VRadius.md),
                              child: ex == null
                                  ? const SizedBox(width: 72, height: 72)
                                  : media(ex.gifUrl, size: 72),
                            ),
                            const SizedBox(width: VSpace.gutter),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ex?.displayName ?? item.exerciseId,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: VText.bodyLgMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    expanded || item.sets.isEmpty
                                        ? 'Hedef: ${ex?.targetTr ?? ''}'
                                        : '${item.sets.length} Set × ${item.sets.first.reps} Tekrar '
                                              '(${_kg(item.sets.first.weightKg)} kg)',
                                    style: VText.microTag.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: VColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _editRest(i, item.restSec),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: VColors.surfaceContainer,
                                        borderRadius: BorderRadius.circular(
                                          VRadius.pill,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            PhosphorIconsBold.timer,
                                            size: 12,
                                            color: VColors.secondary,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${item.restSec} sn mola',
                                            style: VText.microTag.copyWith(
                                              color: VColors.onSurface,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              key: ValueKey('remove-exercise-$i'),
                              onTap: () => ctl.removeExercise(i),
                              child: const Padding(
                                padding: EdgeInsets.all(8),
                                child: Icon(
                                  PhosphorIconsRegular.trashSimple,
                                  color: VColors.outline,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (expanded) ...[
                        const SizedBox(height: VSpace.sm),
                        for (var j = 0; j < item.sets.length; j++)
                          _SetRow(
                            index: i,
                            setIndex: j,
                            set: item.sets[j],
                            canRemove: item.sets.length > 1,
                          ),
                        GestureDetector(
                          key: ValueKey('add-set-$i'),
                          onTap: () => ctl.addSet(i),
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.only(top: 4),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: VColors.surfaceContainer,
                              borderRadius: BorderRadius.circular(VRadius.md),
                            ),
                            child: Text(
                              '+ Set ekle',
                              style: VText.labelMd.copyWith(
                                color: VColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          GestureDetector(
            onTap: _addExercise,
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: VColors.surfaceContainer,
                borderRadius: BorderRadius.circular(VRadius.card),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(PhosphorIconsRegular.plusCircle, color: VColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Egzersiz Ekle',
                    style: VText.labelMd.copyWith(color: VColors.primary),
                  ),
                ],
              ),
            ),
          ),
          if (d.id != null) ...[
            const SizedBox(height: VSpace.md),
            Center(
              child: TextButton(
                onPressed: _delete,
                child: Text(
                  'Rutini Sil',
                  style: VText.labelMd.copyWith(color: VColors.error),
                ),
              ),
            ),
          ],
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
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: VColors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VRadius.button),
                ),
              ),
              onPressed: _start,
              icon: const Icon(PhosphorIconsRegular.play, color: VColors.onPrimary),
              label: Text(
                'Antrenmanı Başlat ($minutes dk)',
                style: VText.labelMd.copyWith(color: VColors.onPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editRest(int i, int current) async {
    final v = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: VColors.surface,
      builder: (ctx) {
        var value = current;
        return StatefulBuilder(
          builder: (ctx, setSt) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(VSpace.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Set arası mola', style: VText.headlineMd),
                  const SizedBox(height: VSpace.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () =>
                            setSt(() => value = (value - 15).clamp(15, 300)),
                        icon: const Icon(PhosphorIconsRegular.minusCircle),
                      ),
                      Text('$value sn', style: VText.headlineLg),
                      IconButton(
                        onPressed: () =>
                            setSt(() => value = (value + 15).clamp(15, 300)),
                        icon: const Icon(PhosphorIconsRegular.plusCircle),
                      ),
                    ],
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(value),
                    child: const Text('Tamam'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (v != null) ref.read(routineDraftProvider.notifier).setRest(i, v);
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.color = VColors.onSurface});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(value, style: VText.headlineMd.copyWith(color: color)),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: VColors.surfaceContainerHighest);
}

class _SetRow extends ConsumerWidget {
  const _SetRow({
    required this.index,
    required this.setIndex,
    required this.set,
    required this.canRemove,
  });
  final int index;
  final int setIndex;
  final PlannedSet set;
  final bool canRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(routineDraftProvider.notifier);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: VColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Text('${setIndex + 1}', style: VText.microTag),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${set.reps} tekrar • ${_kg(set.weightKg)} kg',
              style: VText.bodyMdMedium,
            ),
          ),
          _Mini(
            key: ValueKey('r-minus-$index-$setIndex'),
            icon: PhosphorIconsRegular.minus,
            onTap: () => ctl.setReps(index, setIndex, set.reps - 1),
          ),
          _Mini(
            key: ValueKey('r-plus-$index-$setIndex'),
            icon: PhosphorIconsRegular.plus,
            onTap: () => ctl.setReps(index, setIndex, set.reps + 1),
          ),
          const SizedBox(width: 6),
          _Mini(
            key: ValueKey('w-minus-$index-$setIndex'),
            icon: PhosphorIconsRegular.barbell,
            small: true,
            onTap: () => ctl.setWeight(index, setIndex, set.weightKg - 2.5),
            badge: '-',
          ),
          _Mini(
            key: ValueKey('w-plus-$index-$setIndex'),
            icon: PhosphorIconsRegular.barbell,
            small: true,
            onTap: () => ctl.setWeight(index, setIndex, set.weightKg + 2.5),
            badge: '+',
          ),
          if (canRemove)
            GestureDetector(
              key: ValueKey('remove-set-$index-$setIndex'),
              onTap: () => ctl.removeSet(index, setIndex),
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(PhosphorIconsRegular.x, size: 18, color: VColors.outline),
              ),
            ),
        ],
      ),
    );
  }
}

class _Mini extends StatelessWidget {
  const _Mini({
    super.key,
    required this.icon,
    required this.onTap,
    this.small = false,
    this.badge,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool small;
  final String? badge;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(left: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: VColors.surfaceContainer,
        borderRadius: BorderRadius.circular(VRadius.base),
      ),
      child: badge == null
          ? Icon(icon, size: 16)
          : Text(
              badge == '+' ? '+kg' : '-kg',
              style: VText.microTag.copyWith(fontSize: 9),
            ),
    ),
  );
}
