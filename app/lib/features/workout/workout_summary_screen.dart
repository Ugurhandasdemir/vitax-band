import 'package:fl_chart/fl_chart.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../core/workout_calc.dart';
import '../../data/exercise_catalog.dart';
import '../../data/models.dart';
import 'workout_providers.dart';

/// Seansın bant nabız örnekleri (özet grafiği için).
final sessionHrProvider = FutureProvider.family<List<HrSample>, int>((
  ref,
  id,
) async {
  final s = await ref.watch(sessionProvider(id).future);
  if (s == null) return const [];
  final end =
      s.endedAt ??
      (s.sets.isEmpty ? s.startedAt : s.sets.last.endedAt).add(
        const Duration(minutes: 1),
      );
  return ref.watch(bandSampleRepositoryProvider).hrBetween(s.startedAt, end);
});

String _kg(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : formatDecimalTr(v);

/// Antrenman Özeti: istatistikler, rekorlar, hareket detayları, nabız akışı, not.
class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({super.key, required this.sessionId});
  final int sessionId;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  final _note = TextEditingController();
  bool _noteLoaded = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    await ref
        .read(workoutRepositoryProvider)
        .updateSessionNote(widget.sessionId, _note.text.trim());
    ref.read(workoutActionsProvider).sessionFinished(widget.sessionId);
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider(widget.sessionId)).value;
    final catalog = ref.watch(exerciseCatalogProvider).value;
    final profile = ref.watch(profileProvider).value ?? const Profile();
    final now = ref.watch(clockProvider)();
    final all =
        ref.watch(recentSessionsProvider).value ?? const <WorkoutSession>[];
    final hrSamples =
        ref.watch(sessionHrProvider(widget.sessionId)).value ??
        const <HrSample>[];

    if (s == null) {
      return const VDetailScaffold(
        title: 'Antrenman Özeti',
        body: Center(child: Text('Antrenman bulunamadı')),
      );
    }
    if (!_noteLoaded) {
      _note.text = s.note;
      _noteLoaded = true;
    }

    final dur =
        s.duration ??
        (s.sets.isEmpty
            ? Duration.zero
            : s.sets.last.endedAt.difference(s.startedAt));
    final hr = sessionHr(s.sets);
    final kcal = estimateWorkoutKcal(
      dur,
      profile.weightKg,
      avgHr: (hr == null || hr.avg == 0) ? null : hr.avg,
    );
    final volume = sessionVolume(s);

    // Egzersizleri ilk görülme sırasıyla grupla.
    final groups = <String, List<SetLog>>{};
    for (final x in s.sets) {
      groups.putIfAbsent(x.exerciseId, () => []).add(x);
    }

    // Kişisel rekor: bu seanstaki en yüksek ağırlık, önceki seansların en iyisini aşıyorsa.
    String? prText;
    for (final e in groups.entries) {
      final prevBest = all
          .where((o) => o.id != s.id && o.startedAt.isBefore(s.startedAt))
          .expand((o) => o.sets)
          .where((x) => x.exerciseId == e.key)
          .fold<double?>(
            null,
            (a, x) => a == null || x.weightKg > a ? x.weightKg : a,
          );
      final best = e.value.reduce((a, b) => b.weightKg > a.weightKg ? b : a);
      if (isPersonalRecord(best, previousBestKg: prevBest)) {
        final name = catalog?.byId(e.key)?.displayName ?? e.key;
        prText = '$name: ${_kg(best.weightKg)} kg × ${best.reps} tekrar';
        break;
      }
    }

    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
    final when = day == today
        ? 'Bugün, ${formatClockTime(s.startedAt)}'
        : '${formatDayMonth(s.startedAt)}, ${formatClockTime(s.startedAt)}';

    return VDetailScaffold(
      key: const ValueKey('screen-workout-summary'),
      title: 'Antrenman Özeti',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.md,
          VSpace.margin,
          VSpace.lg,
        ),
        children: [
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      PhosphorIconsFill.sealCheck,
                      size: 18,
                      color: VColors.tertiary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'TEBRİKLER! ANTRENMAN TAMAMLANDI',
                      style: VText.microTag.copyWith(color: VColors.tertiary),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(s.name, style: VText.headlineLg),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      PhosphorIconsBold.clock,
                      size: 14,
                      color: VColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      when,
                      style: VText.bodyMd.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (prText != null) ...[
            const SizedBox(height: VSpace.gutter),
            Container(
              padding: const EdgeInsets.all(VSpace.md),
              decoration: BoxDecoration(
                color: VColors.primary,
                borderRadius: BorderRadius.circular(VRadius.card),
              ),
              child: Row(
                children: [
                  const Icon(
                    PhosphorIconsRegular.trophy,
                    color: VColors.onPrimary,
                  ),
                  const SizedBox(width: VSpace.gutter),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YENİ KİŞİSEL REKOR (PR)',
                          style: VText.microTag.copyWith(
                            color: VColors.primaryFixed,
                          ),
                        ),
                        Text(
                          prText,
                          style: VText.bodyLgMedium.copyWith(
                            color: VColors.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: VSpace.gutter),
          Row(
            children: [
              Expanded(
                child: _Stat('TOPLAM SÜRE', '${dur.inMinutes}', 'dk', null),
              ),
              const SizedBox(width: VSpace.gutter),
              Expanded(
                child: _Stat('YAKILAN KALORİ', '$kcal', 'kcal', 'Tahmini'),
              ),
            ],
          ),
          const SizedBox(height: VSpace.gutter),
          Row(
            children: [
              Expanded(
                child: _Stat(
                  'ORTALAMA NABIZ',
                  hr == null || hr.avg == 0 ? '--' : '${hr.avg}',
                  'bpm',
                  hr == null || hr.peak == 0 ? null : 'Zirve: ${hr.peak} bpm',
                ),
              ),
              const SizedBox(width: VSpace.gutter),
              Expanded(
                child: _Stat(
                  'TOPLAM HACİM',
                  formatTr(volume.round()),
                  'kg',
                  '${s.sets.length} toplam set',
                ),
              ),
            ],
          ),
          if (hrSamples.length >= 2) ...[
            const SizedBox(height: VSpace.md),
            VCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nabız & Egzersiz Akışı', style: VText.headlineMd),
                  const SizedBox(height: 4),
                  Text(
                    '${dur.inMinutes} dakikalık nabız eğrisi',
                    style: VText.microTag.copyWith(
                      fontWeight: FontWeight.w500,
                      color: VColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: VSpace.md),
                  SizedBox(
                    height: 130,
                    child: _HrChart(
                      key: const ValueKey('summary-hr-chart'),
                      samples: hrSamples,
                      start: s.startedAt,
                      sets: s.sets,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              Expanded(
                child: Text('Hareket Detayları', style: VText.headlineMd),
              ),
              Text(
                '${groups.length} Egzersiz',
                style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: VSpace.sm),
          for (final e in groups.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: VSpace.gutter),
              child: _ExerciseCard(
                ex: catalog?.byId(e.key),
                id: e.key,
                sets: e.value,
              ),
            ),
          const SizedBox(height: VSpace.sm),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KİŞİSEL NOT',
                  style: VText.labelCaps.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  key: const ValueKey('summary-note'),
                  controller: _note,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Antrenman hissi, yorgunluk notları...',
                    filled: true,
                    fillColor: VColors.surfaceContainerLow,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(VRadius.md),
                      borderSide: BorderSide.none,
                    ),
                  ),
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
              onPressed: _saveAndClose,
              icon: const Icon(PhosphorIconsRegular.floppyDisk, color: VColors.onPrimary),
              label: Text(
                'Özeti Kaydet ve Kapat',
                style: VText.labelMd.copyWith(color: VColors.onPrimary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.unit, this.sub);
  final String label;
  final String value;
  final String unit;
  final String? sub;

  @override
  Widget build(BuildContext context) => VCard(
    padding: const EdgeInsets.all(VSpace.gutter),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: VText.displayLg.copyWith(fontSize: 28)),
            const SizedBox(width: 4),
            Text(
              unit,
              style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
            ),
          ],
        ),
        if (sub != null)
          Text(
            sub!,
            style: VText.microTag.copyWith(
              fontWeight: FontWeight.w500,
              color: VColors.tertiary,
            ),
          ),
      ],
    ),
  );
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.ex, required this.id, required this.sets});
  final Exercise? ex;
  final String id;
  final List<SetLog> sets;

  @override
  Widget build(BuildContext context) {
    final avgW = sets.fold(0.0, (a, x) => a + x.weightKg) / sets.length;
    final hr = sessionHr(sets);
    final rec = [
      for (final x in sets)
        if (x.recoveryBpm != null) x.recoveryBpm!,
    ];
    final avgRec = rec.isEmpty
        ? null
        : (rec.reduce((a, b) => a + b) / rec.length).round();
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  ex?.displayName ?? id,
                  style: VText.bodyLgMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: VColors.primaryFixed,
                  borderRadius: BorderRadius.circular(VRadius.sm),
                ),
                child: Text(
                  '${sets.length} Set',
                  style: VText.microTag.copyWith(color: VColors.primary),
                ),
              ),
            ],
          ),
          if (ex != null)
            Text(
              '${ex!.targetTr} • ${ex!.equipmentTr}',
              style: VText.microTag.copyWith(
                fontWeight: FontWeight.w500,
                color: VColors.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: VSpace.gutter),
          Container(
            padding: const EdgeInsets.symmetric(vertical: VSpace.gutter),
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Row(
              children: [
                _Col(
                  'Ağırlık',
                  avgW > 0 ? '${_kg(avgW.roundToDouble())} kg ort.' : 'Vücut',
                ),
                _Col(
                  'Ort. Nabız',
                  hr == null || hr.avg == 0 ? '--' : '${hr.avg} bpm',
                  sub: hr == null || hr.peak == 0 ? null : 'Zirve: ${hr.peak}',
                  color: VColors.error,
                ),
                _Col(
                  'Toparlanma',
                  avgRec == null ? '--' : '-$avgRec bpm',
                  color: VColors.tertiary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Col extends StatelessWidget {
  const _Col(
    this.label,
    this.value, {
    this.sub,
    this.color = VColors.onSurface,
  });
  final String label;
  final String value;
  final String? sub;
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: VText.labelMd.copyWith(color: color)),
        ),
        if (sub != null)
          Text(
            sub!,
            style: VText.microTag.copyWith(
              fontSize: 9,
              color: VColors.onSurfaceVariant,
            ),
          ),
      ],
    ),
  );
}

class _HrChart extends StatelessWidget {
  const _HrChart({
    super.key,
    required this.samples,
    required this.start,
    required this.sets,
  });
  final List<HrSample> samples;
  final DateTime start;
  final List<SetLog> sets;

  @override
  Widget build(BuildContext context) {
    double x(DateTime t) => t.difference(start).inSeconds / 60.0;
    final spots = [for (final p in samples) FlSpot(x(p.at), p.bpm.toDouble())];
    final maxX = spots.last.x;
    final ys = spots.map((s) => s.y);
    final lo = ys.reduce((a, b) => a < b ? a : b) - 10;
    final hi = ys.reduce((a, b) => a > b ? a : b) + 10;
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: maxX <= 0 ? 1 : maxX,
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
            for (var i = 0; i < sets.length; i++)
              VerticalRangeAnnotation(
                x1: x(sets[i].startedAt).clamp(0, maxX <= 0 ? 1 : maxX),
                x2: x(sets[i].endedAt).clamp(0, maxX <= 0 ? 1 : maxX),
                color: (i.isEven ? VColors.secondary : VColors.primary)
                    .withValues(alpha: 0.12),
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
