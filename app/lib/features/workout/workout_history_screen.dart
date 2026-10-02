import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/format.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/detail_scaffold.dart';
import '../../core/widgets/v_card.dart';
import '../../core/workout_calc.dart';
import '../../data/models.dart';
import 'workout_providers.dart';
import 'workout_summary_screen.dart';

const _shortDays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

/// Antrenman Geçmişi: seri, haftalık durum, haftalık hacim ve son seanslar.
class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(clockProvider)();
    final today = DateTime(now.year, now.month, now.day);
    final sessions =
        ref.watch(recentSessionsProvider).value ?? const <WorkoutSession>[];
    final catalog = ref.watch(exerciseCatalogProvider).value;
    final profile = ref.watch(profileProvider).value ?? const Profile();

    final monday = today.subtract(Duration(days: today.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final weekDays = [
      for (var i = 0; i < 7; i++) monday.add(Duration(days: i)),
    ];
    final perDay = <int, double>{};
    final doneDays = <int>{};
    for (final s in sessions) {
      final d = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      if (!d.isBefore(monday) && !d.isAfter(sunday)) {
        doneDays.add(d.day);
        perDay[d.day] = (perDay[d.day] ?? 0) + sessionVolume(s);
      }
    }
    final weekVolume = perDay.values.fold(0.0, (a, b) => a + b);
    final monthCount = sessions
        .where(
          (s) => s.startedAt.year == now.year && s.startedAt.month == now.month,
        )
        .length;
    final streak = workoutStreak(sessions, now);
    final maxDay = perDay.values.fold(0.0, (a, b) => a > b ? a : b);
    final list = sessions.take(10).toList();

    String rangeText() {
      if (monday.month == sunday.month) {
        return '${monday.day} - ${sunday.day} ${upperTr(_month(monday))}';
      }
      return '${monday.day} ${upperTr(_month(monday))} - ${sunday.day} ${upperTr(_month(sunday))}';
    }

    return VDetailScaffold(
      key: const ValueKey('screen-workout-history'),
      title: 'Antrenman Geçmişi',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          VSpace.margin,
          VSpace.md,
          VSpace.margin,
          VSpace.lg,
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: VColors.surfaceContainer,
                borderRadius: BorderRadius.circular(VRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    PhosphorIconsFill.flame,
                    size: 16,
                    color: VColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$streak Günlük Seri • Bu ay $monthCount Antrenman',
                    style: VText.labelMd.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: VSpace.md),
          VCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'BU HAFTA (${rangeText()})',
                        style: VText.labelCaps.copyWith(
                          color: VColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: VColors.tertiaryFixed,
                        borderRadius: BorderRadius.circular(VRadius.sm),
                      ),
                      child: Text(
                        '${doneDays.length} / 7 TAMAMLANDI',
                        style: VText.microTag.copyWith(color: VColors.tertiary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.gutter),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              _shortDays[i],
                              style: VText.microTag.copyWith(
                                color: VColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              key: ValueKey('week-day-${weekDays[i].day}'),
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: doneDays.contains(weekDays[i].day)
                                    ? VColors.primaryContainer
                                    : VColors.surfaceContainer,
                                shape: BoxShape.circle,
                                border: weekDays[i] == today
                                    ? Border.all(
                                        color: VColors.primary,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Text(
                                '${weekDays[i].day}',
                                style: VText.labelMd.copyWith(
                                  color: doneDays.contains(weekDays[i].day)
                                      ? VColors.onPrimary
                                      : VColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
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
                  'HAFTALIK ANTRENMAN HACMİ',
                  style: VText.labelCaps.copyWith(
                    color: VColors.onSurfaceVariant,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatDecimalTr(weekVolume / 1000),
                      style: VText.displayLg.copyWith(fontSize: 34),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Ton Hacim',
                      style: VText.bodyLg.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: VSpace.md),
                SizedBox(
                  height: 100,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                (perDay[weekDays[i].day] ?? 0) > 0
                                    ? '${formatDecimalTr(perDay[weekDays[i].day]! / 1000)}t'
                                    : '-',
                                style: VText.microTag.copyWith(
                                  fontSize: 9,
                                  color: VColors.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 30,
                                height: maxDay <= 0
                                    ? 4
                                    : 4 +
                                          56 *
                                              ((perDay[weekDays[i].day] ?? 0) /
                                                  maxDay),
                                decoration: BoxDecoration(
                                  color: (perDay[weekDays[i].day] ?? 0) > 0
                                      ? VColors.primaryContainer
                                      : VColors.surfaceContainer,
                                  borderRadius: BorderRadius.circular(
                                    VRadius.sm,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _shortDays[i],
                                style: VText.microTag.copyWith(
                                  color: weekDays[i] == today
                                      ? VColors.primary
                                      : VColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: VSpace.md),
          Row(
            children: [
              Expanded(child: Text('Son Seanslar', style: VText.headlineMd)),
              Text(
                '${list.length} Oturum Listelendi',
                style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: VSpace.sm),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(VSpace.lg),
              child: Text(
                'Henüz antrenman yok. İlk antrenmanını Egzersiz sekmesinden başlat.',
                textAlign: TextAlign.center,
                style: VText.bodyMd.copyWith(color: VColors.onSurfaceVariant),
              ),
            )
          else
            for (final s in list)
              Padding(
                padding: const EdgeInsets.only(bottom: VSpace.gutter),
                child: _SessionCard(
                  session: s,
                  now: now,
                  weightKg: profile.weightKg,
                  names: [
                    for (final id in {for (final x in s.sets) x.exerciseId})
                      catalog?.byId(id)?.displayName ?? id,
                  ],
                ),
              ),
        ],
      ),
    );
  }

  static String _month(DateTime d) => formatDayMonth(d).split(' ').last;
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.now,
    required this.weightKg,
    required this.names,
  });
  final WorkoutSession session;
  final DateTime now;
  final double weightKg;
  final List<String> names;

  String get _caption {
    final t = session.startedAt;
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(t.year, t.month, t.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'BUGÜN, ${formatClockTime(t)}';
    if (diff == 1) return 'DÜN, ${formatClockTime(t)}';
    return '${t.day} ${upperTr(formatDayMonth(t).split(' ').last)}, ${upperTr(weekdayName(t))}';
  }

  @override
  Widget build(BuildContext context) {
    final dur =
        session.duration ??
        (session.sets.isEmpty
            ? Duration.zero
            : session.sets.last.endedAt.difference(session.startedAt));
    final hr = sessionHr(session.sets);
    final kcal = estimateWorkoutKcal(
      dur,
      weightKg,
      avgHr: hr?.avg == 0 ? null : hr?.avg,
    );
    return VCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _caption,
                style: VText.labelCaps.copyWith(color: VColors.primary),
              ),
              const Spacer(),
              Text(
                '${session.sets.length} Set',
                style: VText.microTag.copyWith(color: VColors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(session.name, style: VText.headlineMd),
          const SizedBox(height: VSpace.gutter),
          Container(
            padding: const EdgeInsets.symmetric(vertical: VSpace.gutter),
            decoration: BoxDecoration(
              color: VColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(VRadius.md),
            ),
            child: Row(
              children: [
                _Cell('Süre', '${dur.inMinutes} dk'),
                _Cell('Yakım', '$kcal kcal'),
                _Cell(
                  'Hacim',
                  '${formatTr(sessionVolume(session).round())} kg',
                ),
                _Cell(
                  'Ort. Nabız',
                  hr == null || hr.avg == 0 ? '--' : '${hr.avg} bpm',
                  color: VColors.secondary,
                ),
              ],
            ),
          ),
          if (names.isNotEmpty) ...[
            const SizedBox(height: VSpace.gutter),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final n in names)
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
                      n,
                      style: VText.microTag.copyWith(
                        color: VColors.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              key: ValueKey('session-detail-${session.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => WorkoutSummaryScreen(sessionId: session.id!),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 8, left: 8, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Detayları İncele',
                      style: VText.labelMd.copyWith(color: VColors.primary),
                    ),
                    const Icon(
                      PhosphorIconsRegular.caretRight,
                      size: 18,
                      color: VColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.label, this.value, {this.color = VColors.onSurface});
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
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: VText.labelMd.copyWith(color: color)),
        ),
      ],
    ),
  );
}
