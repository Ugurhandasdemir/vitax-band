import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../core/widgets/v_progress_bar.dart';
import '../../core/workout_calc.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models.dart';
import '../workout/active_workout.dart';
import '../workout/routine_builder_screen.dart';
import '../workout/workout_providers.dart';

/// Egzersiz Detayı: animasyonlu anlatım, kas dağılımı, adımlar, geçmiş.
class ExerciseDetailScreen extends ConsumerStatefulWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});
  final String exerciseId;

  @override
  ConsumerState<ExerciseDetailScreen> createState() =>
      _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends ConsumerState<ExerciseDetailScreen> {
  bool _playing = true;
  double _speed = 1.0;

  void _snack(String t) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(t), behavior: SnackBarBehavior.floating),
    );

  Future<void> _addToWorkout(Exercise ex) async {
    final routines = await ref.read(routinesProvider.future);
    if (!mounted) return;
    final active = ref.read(activeWorkoutProvider);
    final choice = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: VColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(VRadius.cardLg),
        ),
      ),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const SizedBox(height: VSpace.md),
            Center(child: Text('Antrenmana Ekle', style: VText.headlineMd)),
            if (active != null)
              ListTile(
                leading: const Icon(
                  PhosphorIconsRegular.timer,
                  color: VColors.primary,
                ),
                title: const Text('Aktif antrenmana ekle'),
                onTap: () => Navigator.of(ctx).pop('active'),
              ),
            ListTile(
              leading: const Icon(PhosphorIconsRegular.plus, color: VColors.primary),
              title: const Text('Yeni Rutin'),
              onTap: () => Navigator.of(ctx).pop('new'),
            ),
            for (final r in routines)
              ListTile(
                leading: const Icon(
                  PhosphorIconsRegular.lightning,
                  color: VColors.onSurfaceVariant,
                ),
                title: Text(r.name),
                onTap: () => Navigator.of(ctx).pop(r),
              ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;
    if (choice == 'active') {
      ref.read(activeWorkoutProvider.notifier).addExercise(ex.id);
      _snack('Antrenmana eklendi');
    } else if (choice == 'new') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RoutineBuilderScreen(initialExerciseIds: [ex.id]),
        ),
      );
    } else if (choice is Routine) {
      if (choice.items.any((i) => i.exerciseId == ex.id)) {
        _snack('Bu hareket zaten rutinde');
        return;
      }
      final last = await ref.read(lastPerformanceProvider(ex.id).future);
      final kg = last?.best.weightKg ?? 0;
      await ref
          .read(workoutActionsProvider)
          .saveRoutine(
            Routine(
              id: choice.id,
              name: choice.name,
              items: [
                ...choice.items,
                RoutineItem.uniform(
                  exerciseId: ex.id,
                  sets: 3,
                  reps: 10,
                  weightKg: kg,
                ),
              ],
            ),
          );
      if (mounted) _snack('Rutine eklendi');
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(exerciseCatalogProvider).value;
    final ex = catalog?.byId(widget.exerciseId);
    if (ex == null) {
      return VDetailScaffold(
        title: 'Egzersiz Detayı',
        body: Center(
          child: Text(
            catalog == null ? 'Yükleniyor...' : 'Egzersiz bulunamadı',
            style: VText.bodyLg,
          ),
        ),
      );
    }
    final media = ref.watch(exerciseMediaBuilderProvider);

    return VDetailScaffold(
      key: const ValueKey('screen-exercise-detail'),
      title: 'Egzersiz Detayı',
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
              _Pill(
                ex.bodyPartTr.toUpperCase(),
                VColors.secondaryFixed,
                VColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          VCard(
            padding: const EdgeInsets.all(VSpace.md),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: VColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            PhosphorIconsBold.repeat,
                            size: 14,
                            color: VColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Döngü',
                            style: VText.microTag.copyWith(
                              color: VColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: VColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(VRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final (label, v) in [
                            ('0.5x', 0.5),
                            ('1.0x', 1.0),
                          ])
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _speed = v),
                              child: Container(
                                key: ValueKey('speed-$label'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _speed == v
                                      ? VColors.surfaceContainerLowest
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(
                                    VRadius.pill,
                                  ),
                                ),
                                child: Text(
                                  label,
                                  style: VText.microTag.copyWith(
                                    color: _speed == v
                                        ? VColors.primary
                                        : VColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.gutter),
                Stack(
                  alignment: Alignment.bottomLeft,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(VRadius.card),
                      child: media(
                        ex.gifUrl,
                        size: 220,
                        fit: BoxFit.contain,
                        controllable: true,
                        speed: _speed,
                        playing: _playing,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: GestureDetector(
                        key: const ValueKey('media-toggle'),
                        onTap: () => setState(() => _playing = !_playing),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: VColors.inverseSurface,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _playing ? PhosphorIconsRegular.pause : PhosphorIconsRegular.play,
                            size: 20,
                            color: VColors.inverseOnSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    mediaAttribution,
                    style: VText.microTag.copyWith(
                      fontWeight: FontWeight.w500,
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          Text(ex.displayName, style: VText.headlineLg.copyWith(fontSize: 24)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Pill(
                ex.equipmentTr,
                VColors.surfaceContainer,
                VColors.onSurface,
              ),
              _Pill(ex.targetTr, VColors.secondaryFixed, VColors.secondary),
            ],
          ),
          const SizedBox(height: VSpace.md),
          VCard(
            child: Row(
              children: [
                const Icon(
                  PhosphorIconsRegular.barbell,
                  color: VColors.secondary,
                  size: 22,
                ),
                const SizedBox(width: VSpace.gutter),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EKİPMAN',
                        style: VText.labelCaps.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                      Text(ex.equipmentTr, style: VText.bodyLgMedium),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          _MuscleCard(ex: ex),
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              Expanded(
                child: Text('Uygulama Adımları', style: VText.headlineMd),
              ),
              Text(
                '${ex.stepsTr.length} Aşama',
                style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: VSpace.sm),
          for (var i = 0; i < ex.stepsTr.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: VSpace.sm),
              child: VCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: VColors.primaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${i + 1}',
                        style: VText.labelMd.copyWith(color: VColors.primary),
                      ),
                    ),
                    const SizedBox(width: VSpace.gutter),
                    Expanded(child: Text(ex.stepsTr[i], style: VText.bodyMd)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: VSpace.sm),
          _HistoryCard(exerciseId: ex.id),
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
              style: FilledButton.styleFrom(
                backgroundColor: VColors.primaryContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(VRadius.button),
                ),
              ),
              onPressed: () => _addToWorkout(ex),
              icon: const Icon(PhosphorIconsRegular.plus, color: VColors.onPrimary),
              label: Text(
                'Antrenmana Ekle',
                style: VText.labelMd.copyWith(color: VColors.onPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(VRadius.pill),
    ),
    child: Text(text, style: VText.labelMd.copyWith(fontSize: 12, color: fg)),
  );
}

class _MuscleCard extends StatelessWidget {
  const _MuscleCard({required this.ex});
  final Exercise ex;

  @override
  Widget build(BuildContext context) {
    final primary = ex.targetTr;
    final secondary = {
      for (final s in [ex.muscleTr, ...ex.secondaryTr])
        if (s.isNotEmpty && s != primary) s,
    }.toList();
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                PhosphorIconsRegular.personArmsSpread,
                size: 20,
                color: VColors.primary,
              ),
              const SizedBox(width: 8),
              Text('Kas Dağılımı', style: VText.headlineMd),
            ],
          ),
          const SizedBox(height: VSpace.md),
          _MuscleRow(primary, 'BİRİNCİL', 1.0, VColors.primary),
          for (final s in secondary) ...[
            const SizedBox(height: VSpace.gutter),
            _MuscleRow(s, 'İKİNCİL', 0.55, VColors.secondary),
          ],
        ],
      ),
    );
  }
}

class _MuscleRow extends StatelessWidget {
  const _MuscleRow(this.name, this.tag, this.value, this.color);
  final String name;
  final String tag;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(child: Text(name, style: VText.bodyMdMedium)),
          Text(tag, style: VText.microTag.copyWith(color: color)),
        ],
      ),
      const SizedBox(height: 4),
      VProgressBar(value: value, color: color, height: 6),
    ],
  );
}

class _HistoryCard extends ConsumerWidget {
  const _HistoryCard({required this.exerciseId});
  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final last = ref.watch(lastPerformanceProvider(exerciseId)).value;
    final sessions =
        ref.watch(recentSessionsProvider).value ?? const <WorkoutSession>[];
    // Kişisel rekor: son 120 gündeki en yüksek tahmini 1RM.
    SetLog? prSet;
    DateTime? prDate;
    var prRm = 0.0;
    for (final s in sessions) {
      for (final set in s.sets.where((x) => x.exerciseId == exerciseId)) {
        final rm = estimateOneRm(set);
        if (rm > prRm) {
          prRm = rm;
          prSet = set;
          prDate = s.startedAt;
        }
      }
    }
    return VCard(
      key: const ValueKey('history-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(PhosphorIconsRegular.clockCounterClockwise, size: 20, color: VColors.primary),
              const SizedBox(width: 8),
              Text('Geçmişim', style: VText.headlineMd),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          if (last == null)
            Text(
              'Henüz kayıt yok. İlk antrenmanın burada görünecek.',
              style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
            )
          else ...[
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Son Antrenman: ',
                    style: VText.bodyMd.copyWith(
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                  TextSpan(
                    text:
                        '${formatDaysAgo(now, last.sessionDate)} • ${last.sets.length} set',
                    style: VText.bodyMdMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'En iyi set: ${last.best.reps} × ${_kg(last.best.weightKg)} kg',
              style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
            ),
            if (prSet != null && prRm > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Kişisel Rekor (PR): 1RM: ${formatDecimalTr(prRm)} kg (${formatDayShortMonth(prDate!)})',
                style: VText.bodyMdMedium.copyWith(color: VColors.primary),
              ),
            ],
            if (_avgHr(last.sets) != null) ...[
              const SizedBox(height: VSpace.gutter),
              Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.heart,
                    size: 16,
                    color: VColors.error,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ORTALAMA NABIZ',
                    style: VText.labelCaps.copyWith(
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text('${_avgHr(last.sets)} bpm', style: VText.headlineMd),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _kg(double v) =>
      v == v.roundToDouble() ? '${v.round()}' : formatDecimalTr(v);

  int? _avgHr(List<SetLog> sets) {
    final v = [
      for (final s in sets)
        if (s.avgHr != null) s.avgHr!,
    ];
    if (v.isEmpty) return null;
    return (v.reduce((a, b) => a + b) / v.length).round();
  }
}
