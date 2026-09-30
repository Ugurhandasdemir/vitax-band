import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/hr_detect.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../core/widgets/v_progress_bar.dart';
import '../../core/widgets/v_segmented.dart';
import '../../core/workout_calc.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models.dart';
import '../band/band_status.dart';
import '../exercises/exercise_picker_screen.dart';
import 'active_workout.dart';
import 'workout_providers.dart';
import 'workout_summary_screen.dart';

String _kg(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : formatDecimalTr(v);

/// Canlı Antrenman: set set kayıt, canlı nabız, dinlenme sayacı, öneri modu.
class LiveWorkoutScreen extends ConsumerStatefulWidget {
  const LiveWorkoutScreen({super.key});

  @override
  ConsumerState<LiveWorkoutScreen> createState() => _LiveWorkoutScreenState();
}

class _LiveWorkoutScreenState extends ConsumerState<LiveWorkoutScreen> {
  Timer? _ticker;
  int _restExtra = 0;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  ActiveWorkoutController get _ctl => ref.read(activeWorkoutProvider.notifier);

  Future<void> _confirmFinish() async {
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VColors.surface,
        title: Text(
          'Antrenmanı bitirmek istiyor musun?',
          style: VText.headlineMd,
        ),
        content: const Text('Bitirirsen kayıtların özet ekranında görünür.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('keep'),
            child: const Text('Devam Et'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cancel'),
            child: Text(
              'Vazgeç ve Sil',
              style: TextStyle(color: VColors.error),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop('finish'),
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (r == 'finish') {
      final id = await _ctl.finish();
      if (id != null && mounted) {
        ref.read(workoutActionsProvider).sessionFinished(id);
        await Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => WorkoutSummaryScreen(sessionId: id),
          ),
        );
      }
    } else if (r == 'cancel') {
      await _ctl.cancel();
      ref.read(workoutActionsProvider).sessionFinished(-1);
      if (mounted) Navigator.of(context).maybePop();
    }
  }

  Future<void> _addExercise() async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (id != null) _ctl.addExercise(id);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<HrReading>>(liveHrProvider, (prev, next) {
      next.whenData((r) => _ctl.recordHr(r.bpm));
    });
    ref.listen<ActiveWorkoutState?>(activeWorkoutProvider, (prev, next) {
      if (next?.phase == WorkoutPhase.resting &&
          prev?.phase != WorkoutPhase.resting) {
        _restExtra = 0;
      }
    });

    final s = ref.watch(activeWorkoutProvider);
    if (s == null) {
      return VDetailScaffold(
        title: 'Canlı Antrenman',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Aktif antrenman yok', style: VText.headlineMd),
              const SizedBox(height: VSpace.md),
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      );
    }

    final now = ref.watch(clockProvider)();
    final band = ref.watch(bandStatusProvider);
    final profile = ref.watch(profileProvider).value ?? const Profile();
    final catalog = ref.watch(exerciseCatalogProvider).value;
    final ex = s.currentExerciseId == null
        ? null
        : catalog?.byId(s.currentExerciseId!);
    final item = s.currentItem;

    return VDetailScaffold(
      key: const ValueKey('screen-live-workout'),
      title: 'Canlı Antrenman',
      actions: [
        IconButton(
          key: const ValueKey('finish-workout'),
          icon: const Icon(Icons.check_circle_outline, color: VColors.primary),
          onPressed: _confirmFinish,
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: VColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CANLI SEANS',
                          style: VText.labelCaps.copyWith(color: VColors.error),
                        ),
                      ],
                    ),
                    Text(
                      s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VText.headlineLg,
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 120,
                child: VSegmented(
                  labels: const ['Elle', 'Öneri'],
                  selected: s.mode == WorkoutMode.manual ? 0 : 1,
                  onChanged: (i) => _ctl.setMode(
                    i == 0 ? WorkoutMode.manual : WorkoutMode.auto,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          VCard(
            padding: const EdgeInsets.symmetric(
              horizontal: VSpace.md,
              vertical: 10,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: VColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(formatClock(s.elapsed(now)), style: VText.headlineMd),
                const SizedBox(width: 6),
                Text(
                  'TOPLAM',
                  style: VText.microTag.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: VColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(VRadius.pill),
                  ),
                  child: Text(
                    'VitaxBand • canlı',
                    style: VText.microTag.copyWith(
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.gutter),
          _HrCard(
            s: s,
            now: now,
            profile: profile,
            bandConnected: band.connected,
          ),
          if (s.suggestion != null) ...[
            const SizedBox(height: VSpace.gutter),
            _SuggestionBanner(
              s: s,
              onAccept: _ctl.acceptSuggestion,
              onDismiss: _ctl.dismissSuggestion,
            ),
          ],
          const SizedBox(height: VSpace.gutter),
          if (item == null)
            VCard(
              child: Column(
                children: [
                  Text(
                    'Bu antrenmanda henüz hareket yok',
                    style: VText.bodyLgMedium,
                  ),
                  const SizedBox(height: VSpace.gutter),
                  FilledButton.icon(
                    onPressed: _addExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Hareket Ekle'),
                  ),
                ],
              ),
            )
          else
            _MovementCard(s: s, ex: ex, item: item, onFinish: _confirmFinish),
          if (s.phase == WorkoutPhase.resting) ...[
            const SizedBox(height: VSpace.gutter),
            _RestCard(
              s: s,
              now: now,
              extra: _restExtra,
              onAdjust: (d) => setState(() {
                final total = (item?.restSec ?? 90) + _restExtra + d;
                if (total >= 15) _restExtra += d;
              }),
            ),
          ],
          if (item != null) ...[
            const SizedBox(height: VSpace.gutter),
            _SetHistory(s: s, item: item),
          ],
          const SizedBox(height: VSpace.gutter),
          _HrChartCard(s: s),
        ],
      ),
    );
  }
}

class _HrCard extends StatelessWidget {
  const _HrCard({
    required this.s,
    required this.now,
    required this.profile,
    this.bandConnected = false,
  });
  final ActiveWorkoutState s;
  final DateTime now;
  final Profile profile;
  final bool bandConnected;

  @override
  Widget build(BuildContext context) {
    final last = s.hr.isEmpty ? null : s.hr.last;
    final fresh =
        last != null && now.difference(last.at) <= const Duration(seconds: 10);
    final maxHr = maxHrForAge(profile.age);
    final zone = fresh ? hrZone(last.bpm, maxHr: maxHr) : 0;
    final avg = s.hr.isEmpty
        ? null
        : (s.hr.fold<int>(0, (a, p) => a + p.bpm) / s.hr.length).round();
    final kcal = estimateWorkoutKcal(
      s.elapsed(now),
      profile.weightKg,
      avgHr: avg,
    );
    const zoneColors = [
      VColors.secondaryContainer,
      VColors.tertiaryFixed,
      VColors.secondary,
      VColors.primaryContainer,
      VColors.outlineVariant,
    ];
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: VColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CANLI NABIZ',
                          style: VText.microTag.copyWith(
                            color: VColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          fresh ? '${last.bpm}' : '--',
                          style: VText.displayLg.copyWith(fontSize: 38),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'BPM',
                          style: VText.labelMd.copyWith(color: VColors.error),
                        ),
                      ],
                    ),
                    if (bandConnected && !fresh)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Nabız hazırlanıyor...',
                          style: VText.microTag.copyWith(
                            color: VColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'AKTİF HARCAMA',
                    style: VText.microTag.copyWith(
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('$kcal', style: VText.headlineLg),
                      const SizedBox(width: 3),
                      Text(
                        'kcal',
                        style: VText.bodyMd.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'tahmini',
                    style: VText.microTag.copyWith(
                      fontWeight: FontWeight.w500,
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (s.hr.isEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Nabız hazırlanıyor... İlk değer ~1 dk sürebilir, bilekliğin sıkı olsun.',
              style: VText.microTag.copyWith(
                fontWeight: FontWeight.w500,
                color: VColors.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: VSpace.gutter),
          Row(
            children: [
              for (var i = 1; i <= 5; i++) ...[
                if (i > 1) const SizedBox(width: 3),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == zone
                              ? zoneColors[i - 1]
                              : zoneColors[i - 1].withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(VRadius.pill),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Zon $i',
                        style: VText.microTag.copyWith(
                          fontSize: 9,
                          color: i == zone
                              ? VColors.onSurface
                              : VColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionBanner extends StatelessWidget {
  const _SuggestionBanner({
    required this.s,
    required this.onAccept,
    required this.onDismiss,
  });
  final ActiveWorkoutState s;
  final VoidCallback onAccept;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final bpm = s.hr.isEmpty ? 0 : s.hr.last.bpm;
    final text = s.suggestion == HrSuggestion.setStarted
        ? 'Nabız yükseliyor ($bpm bpm), ${s.setIndex + 1}. set başlamış olabilir.'
        : 'Nabız düşüyor ($bpm bpm), dinlenme başlamış olabilir.';
    return Container(
      padding: const EdgeInsets.all(VSpace.md),
      decoration: BoxDecoration(
        color: VColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(VRadius.card),
        border: const Border(
          left: BorderSide(color: VColors.primaryContainer, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors, size: 16, color: VColors.primary),
              const SizedBox(width: 6),
              Text(
                'VİTAX AKILLI ALGILAMA',
                style: VText.microTag.copyWith(color: VColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(text, style: VText.bodyMd),
          const SizedBox(height: VSpace.gutter),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: VColors.tertiary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VRadius.button),
                      ),
                    ),
                    onPressed: onAccept,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Onayla'),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: VColors.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(VRadius.button),
                      ),
                    ),
                    onPressed: onDismiss,
                    child: Text('Yoksay', style: VText.labelMd),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MovementCard extends ConsumerWidget {
  const _MovementCard({
    required this.s,
    required this.ex,
    required this.item,
    required this.onFinish,
  });
  final ActiveWorkoutState s;
  final Exercise? ex;
  final RoutineItem item;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.read(activeWorkoutProvider.notifier);
    final media = ref.watch(exerciseMediaBuilderProvider);
    final planned = item.sets.length;
    final working = s.phase == WorkoutPhase.working;
    final setNo = s.setIndex + 1;

    Widget primary;
    if (working) {
      primary = _Primary(
        icon: Icons.stop_circle_outlined,
        label: 'Seti Bitir (Set $setNo)',
        color: VColors.primary,
        onTap: () => ctl.endSet(),
      );
    } else if (s.exerciseDone) {
      primary = s.isLastExercise
          ? _Primary(
              icon: Icons.flag_outlined,
              label: 'Antrenmanı Bitir',
              color: VColors.tertiary,
              onTap: onFinish,
            )
          : _Primary(
              icon: Icons.skip_next,
              label: 'Sonraki Hareket',
              color: VColors.primaryContainer,
              onTap: ctl.nextExercise,
            );
    } else {
      primary = _Primary(
        icon: Icons.play_circle_outline,
        label: 'Seti Başlat (Set $setNo)',
        color: VColors.primaryContainer,
        onTap: ctl.startSet,
      );
    }

    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'ŞU ANKİ HAREKET',
                  style: VText.labelCaps.copyWith(color: VColors.error),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: VColors.primaryFixed,
                  borderRadius: BorderRadius.circular(VRadius.pill),
                ),
                child: Text(
                  s.exerciseDone
                      ? 'TAMAMLANDI'
                      : 'SET ${math.min(setNo, planned)} / $planned',
                  style: VText.microTag.copyWith(color: VColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(ex?.displayName ?? item.exerciseId, style: VText.headlineLg),
          if (ex != null)
            Text(
              '${ex!.bodyPartTr} • ${ex!.targetTr} • ${ex!.equipmentTr}',
              style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
            ),
          const SizedBox(height: VSpace.gutter),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(VRadius.md),
                    child: ex == null
                        ? const SizedBox(width: 120, height: 120)
                        : media(ex!.gifUrl, size: 120),
                  ),
                  Container(
                    margin: const EdgeInsets.all(6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: VColors.inverseSurface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(VRadius.sm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.loop,
                          size: 10,
                          color: VColors.inverseOnSurface,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Döngü',
                          style: VText.microTag.copyWith(
                            fontSize: 9,
                            color: VColors.inverseOnSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: VSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HEDEF AĞIRLIK',
                      style: VText.microTag.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                    _Stepper(
                      minusKey: 'w-minus',
                      plusKey: 'w-plus',
                      label: '${_kg(s.draftWeightKg)} kg',
                      onMinus: () =>
                          ctl.setDraft(weightKg: s.draftWeightKg - 2.5),
                      onPlus: () =>
                          ctl.setDraft(weightKg: s.draftWeightKg + 2.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'HEDEF TEKRAR',
                      style: VText.microTag.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                    _Stepper(
                      minusKey: 'r-minus',
                      plusKey: 'r-plus',
                      label: '${s.draftReps} tekrar',
                      onMinus: () => ctl.setDraft(reps: s.draftReps - 1),
                      onPlus: () => ctl.setDraft(reps: s.draftReps + 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              Expanded(child: primary),
              if (!s.isLastExercise) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  key: const ValueKey('next-exercise'),
                  onTap: ctl.nextExercise,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: VColors.surfaceContainer,
                      borderRadius: BorderRadius.circular(VRadius.button),
                    ),
                    child: const Icon(Icons.skip_next),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _Primary extends StatelessWidget {
  const _Primary({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(VRadius.button),
        ),
      ),
      onPressed: onTap,
      icon: Icon(icon, color: VColors.onPrimary),
      label: Text(
        label,
        style: VText.labelMd.copyWith(color: VColors.onPrimary),
      ),
    ),
  );
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.minusKey,
    required this.plusKey,
    required this.label,
    required this.onMinus,
    required this.onPlus,
  });
  final String minusKey;
  final String plusKey;
  final String label;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  Widget _b(String k, IconData i, VoidCallback f) => GestureDetector(
    key: ValueKey(k),
    behavior: HitTestBehavior.opaque,
    onTap: f,
    child: Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: VColors.surfaceContainer,
        borderRadius: BorderRadius.circular(VRadius.base),
      ),
      child: Icon(i, size: 16),
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _b(minusKey, Icons.remove, onMinus),
      Expanded(
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: VText.headlineMd.copyWith(fontSize: 16),
        ),
      ),
      _b(plusKey, Icons.add, onPlus),
    ],
  );
}

class _RestCard extends StatelessWidget {
  const _RestCard({
    required this.s,
    required this.now,
    required this.extra,
    required this.onAdjust,
  });
  final ActiveWorkoutState s;
  final DateTime now;
  final int extra;
  final void Function(int) onAdjust;

  @override
  Widget build(BuildContext context, [WidgetRef? _]) => Consumer(
    builder: (context, ref, _) {
      final total = Duration(seconds: (s.currentItem?.restSec ?? 90) + extra);
      final elapsed = s.restElapsed(now);
      final frac = total.inSeconds == 0
          ? 1.0
          : (elapsed.inSeconds / total.inSeconds).clamp(0.0, 1.0);
      final lastRec = s.loggedSets.isEmpty
          ? null
          : s.loggedSets.last.recoveryBpm;
      final ctl = ref.read(activeWorkoutProvider.notifier);
      return VCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.hourglass_bottom,
                  color: VColors.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DİNLENME SÜRESİ',
                        style: VText.microTag.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${formatClock(elapsed)} / ${formatClock(total)}',
                        style: VText.headlineMd,
                      ),
                    ],
                  ),
                ),
                _Pill('-15s', 'rest-minus', () => onAdjust(-15)),
                const SizedBox(width: 6),
                _Pill('+15s', 'rest-plus', () => onAdjust(15)),
                const SizedBox(width: 6),
                _Pill('Atla', 'rest-skip', ctl.skipRest),
              ],
            ),
            const SizedBox(height: VSpace.gutter),
            VProgressBar(value: frac, color: VColors.secondary),
            if (lastRec != null) ...[
              const SizedBox(height: VSpace.gutter),
              Container(
                padding: const EdgeInsets.all(VSpace.gutter),
                decoration: BoxDecoration(
                  color: VColors.tertiaryFixed.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(VRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.monitor_heart_outlined,
                      color: VColors.tertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NABIZ TOPARLANMASI',
                            style: VText.microTag.copyWith(
                              color: VColors.tertiary,
                            ),
                          ),
                          Text(
                            '-$lastRec bpm (60 sn içinde düştü)',
                            style: VText.bodyMdMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.label, this.keyName, this.onTap);
  final String label;
  final String keyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    key: ValueKey(keyName),
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: VColors.surfaceContainer,
        borderRadius: BorderRadius.circular(VRadius.md),
      ),
      child: Text(label, style: VText.labelMd.copyWith(fontSize: 12)),
    ),
  );
}

class _SetHistory extends StatelessWidget {
  const _SetHistory({required this.s, required this.item});
  final ActiveWorkoutState s;
  final RoutineItem item;

  @override
  Widget build(BuildContext context) {
    final id = item.exerciseId;
    final done = s.loggedSets.where((x) => x.exerciseId == id).toList();
    final planned = item.sets.length;
    final total = math.max(planned, done.length + (s.exerciseDone ? 0 : 1));
    final rows = <Widget>[];
    for (var i = 0; i < total; i++) {
      if (i < done.length) {
        final d = done[i];
        rows.add(
          _row(
            n: i + 1,
            text: '${d.reps} tekrar × ${_kg(d.weightKg)} kg',
            trailing: d.avgHr == null ? '—' : '${d.avgHr} bpm',
            state: _RowState.done,
          ),
        );
      } else if (i == done.length && !s.exerciseDone) {
        rows.add(
          _row(
            n: i + 1,
            text: '${s.draftReps} tekrar × ${_kg(s.draftWeightKg)} kg',
            sub: s.phase == WorkoutPhase.working
                ? 'Sensör devrede (Aktif Set)'
                : null,
            trailing: 'ŞU AN',
            state: _RowState.active,
          ),
        );
      } else {
        final p = item.sets[math.min(i, planned - 1)];
        rows.add(
          _row(
            n: i + 1,
            text: '${p.reps} tekrar × ${_kg(p.weightKg)} kg',
            trailing: 'Sırada',
            state: _RowState.upcoming,
          ),
        );
      }
    }
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text('Set Geçmişi', style: VText.headlineMd)),
              Text(
                'HEDEF: $planned SET',
                style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          ...rows,
        ],
      ),
    );
  }

  Widget _row({
    required int n,
    required String text,
    required String trailing,
    required _RowState state,
    String? sub,
  }) {
    final (bg, fg) = switch (state) {
      _RowState.done => (VColors.surfaceContainerLow, VColors.tertiary),
      _RowState.active => (VColors.primaryFixed, VColors.primary),
      _RowState.upcoming => (VColors.surfaceContainerLow, VColors.outline),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(VSpace.gutter),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(VRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: state == _RowState.upcoming
                  ? VColors.surfaceContainer
                  : fg,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$n',
              style: VText.microTag.copyWith(
                color: state == _RowState.upcoming
                    ? VColors.onSurfaceVariant
                    : VColors.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: VSpace.gutter),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: VText.bodyMdMedium.copyWith(
                    color: state == _RowState.upcoming
                        ? VColors.onSurfaceVariant
                        : VColors.onSurface,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub,
                    style: VText.microTag.copyWith(color: VColors.primary),
                  ),
              ],
            ),
          ),
          Text(trailing, style: VText.microTag.copyWith(color: fg)),
          if (state == _RowState.done) ...[
            const SizedBox(width: 6),
            const Icon(Icons.check_circle, size: 18, color: VColors.tertiary),
          ],
        ],
      ),
    );
  }
}

enum _RowState { done, active, upcoming }

class _HrChartCard extends StatelessWidget {
  const _HrChartCard({required this.s});
  final ActiveWorkoutState s;

  @override
  Widget build(BuildContext context) {
    final hr = s.hr;
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nabız & Efor Eğrisi', style: VText.headlineMd),
          const SizedBox(height: VSpace.md),
          if (hr.length < 2)
            SizedBox(
              height: 80,
              child: Center(
                child: Text(
                  'Nabız verisi bekleniyor',
                  style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
                ),
              ),
            )
          else
            SizedBox(
              height: 130,
              child: _Chart(key: const ValueKey('hr-chart'), s: s),
            ),
        ],
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({super.key, required this.s});
  final ActiveWorkoutState s;

  @override
  Widget build(BuildContext context) {
    final t0 = s.hr.first.at;
    double x(DateTime t) => t.difference(t0).inSeconds / 60.0;
    final spots = [for (final p in s.hr) FlSpot(x(p.at), p.bpm.toDouble())];
    final maxX = math.max(spots.last.x, 0.1);
    final lo = spots.map((e) => e.y).reduce(math.min) - 10;
    final hi = spots.map((e) => e.y).reduce(math.max) + 10;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX,
        minY: lo,
        maxY: hi,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(),
          rightTitles: AxisTitles(),
          leftTitles: AxisTitles(),
          bottomTitles: AxisTitles(),
        ),
        rangeAnnotations: RangeAnnotations(
          verticalRangeAnnotations: [
            for (var i = 0; i < s.loggedSets.length; i++)
              VerticalRangeAnnotation(
                x1: x(s.loggedSets[i].startedAt).clamp(0, maxX),
                x2: x(s.loggedSets[i].endedAt).clamp(0, maxX),
                color: VColors.secondary.withValues(alpha: 0.14),
              ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: VColors.primaryContainer,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
