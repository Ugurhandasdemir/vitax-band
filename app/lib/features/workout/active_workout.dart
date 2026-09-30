import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/hr_detect.dart';
import '../../data/models.dart';

enum WorkoutPhase { idle, working, resting }

enum WorkoutMode { manual, auto }

class ActiveWorkoutState {
  const ActiveWorkoutState({
    required this.sessionId,
    required this.name,
    required this.startedAt,
    required this.items,
    this.routineId,
    this.exerciseIndex = 0,
    this.setIndex = 0,
    this.phase = WorkoutPhase.idle,
    this.draftReps = 10,
    this.draftWeightKg = 0,
    this.setStartedAt,
    this.restStartedAt,
    this.loggedSets = const [],
    this.mode = WorkoutMode.manual,
    this.hr = const [],
    this.suggestion,
    this.suggestionCooldownUntil,
    this.pendingRecovery,
  });

  final int sessionId;
  final String name;
  final int? routineId;
  final DateTime startedAt;
  final List<RoutineItem> items;
  final int exerciseIndex;
  final int setIndex;
  final WorkoutPhase phase;
  final int draftReps;
  final double draftWeightKg;
  final DateTime? setStartedAt;
  final DateTime? restStartedAt;
  final List<SetLog> loggedSets;
  final WorkoutMode mode;
  final List<HrPoint> hr;
  final HrSuggestion? suggestion;
  final DateTime? suggestionCooldownUntil;

  /// Toparlanması hesaplanacak son set: (set id, tepe nabız, bitiş zamanı).
  final (int, int, DateTime)? pendingRecovery;

  RoutineItem? get currentItem =>
      exerciseIndex < items.length ? items[exerciseIndex] : null;
  String? get currentExerciseId => currentItem?.exerciseId;
  bool get exerciseDone =>
      currentItem != null && setIndex >= currentItem!.sets.length;
  bool get isLastExercise => exerciseIndex >= items.length - 1;
  double get totalVolume =>
      loggedSets.fold(0.0, (a, s) => a + s.reps * s.weightKg);

  Duration elapsed(DateTime now) => now.difference(startedAt);
  Duration restElapsed(DateTime now) =>
      restStartedAt == null ? Duration.zero : now.difference(restStartedAt!);
  Duration restRemaining(DateTime now) {
    final total = Duration(seconds: currentItem?.restSec ?? 90);
    final left = total - restElapsed(now);
    return left.isNegative ? Duration.zero : left;
  }

  ActiveWorkoutState copyWith({
    List<RoutineItem>? items,
    int? exerciseIndex,
    int? setIndex,
    WorkoutPhase? phase,
    int? draftReps,
    double? draftWeightKg,
    DateTime? setStartedAt,
    bool clearSetStartedAt = false,
    DateTime? restStartedAt,
    bool clearRestStartedAt = false,
    List<SetLog>? loggedSets,
    WorkoutMode? mode,
    List<HrPoint>? hr,
    HrSuggestion? suggestion,
    bool clearSuggestion = false,
    DateTime? suggestionCooldownUntil,
    (int, int, DateTime)? pendingRecovery,
    bool clearPendingRecovery = false,
  }) => ActiveWorkoutState(
    sessionId: sessionId,
    name: name,
    routineId: routineId,
    startedAt: startedAt,
    items: items ?? this.items,
    exerciseIndex: exerciseIndex ?? this.exerciseIndex,
    setIndex: setIndex ?? this.setIndex,
    phase: phase ?? this.phase,
    draftReps: draftReps ?? this.draftReps,
    draftWeightKg: draftWeightKg ?? this.draftWeightKg,
    setStartedAt: clearSetStartedAt
        ? null
        : (setStartedAt ?? this.setStartedAt),
    restStartedAt: clearRestStartedAt
        ? null
        : (restStartedAt ?? this.restStartedAt),
    loggedSets: loggedSets ?? this.loggedSets,
    mode: mode ?? this.mode,
    hr: hr ?? this.hr,
    suggestion: clearSuggestion ? null : (suggestion ?? this.suggestion),
    suggestionCooldownUntil:
        suggestionCooldownUntil ?? this.suggestionCooldownUntil,
    pendingRecovery: clearPendingRecovery
        ? null
        : (pendingRecovery ?? this.pendingRecovery),
  );
}

/// Canlı antrenman durum makinesi: elle set işaretleme, nabızdan öneri (onaylı),
/// set başına nabız özeti ve toparlanma hesabı.
class ActiveWorkoutController extends Notifier<ActiveWorkoutState?> {
  @override
  ActiveWorkoutState? build() => null;

  DateTime get _now => ref.read(clockProvider)();

  PlannedSet _planFor(RoutineItem? item, int setIndex) {
    if (item == null || item.sets.isEmpty) {
      return const PlannedSet(reps: 10, weightKg: 0);
    }
    return setIndex < item.sets.length ? item.sets[setIndex] : item.sets.last;
  }

  Future<void> start({Routine? routine, String? name}) async {
    final startedAt = _now;
    final title = routine?.name ?? name ?? 'Serbest Antrenman';
    final id = await ref
        .read(workoutRepositoryProvider)
        .startSession(
          name: title,
          startedAt: startedAt,
          routineId: routine?.id,
        );
    final items = List<RoutineItem>.of(routine?.items ?? const []);
    final first = _planFor(items.isEmpty ? null : items.first, 0);
    state = ActiveWorkoutState(
      sessionId: id,
      name: title,
      routineId: routine?.id,
      startedAt: startedAt,
      items: items,
      draftReps: first.reps,
      draftWeightKg: first.weightKg,
    );
  }

  void setDraft({int? reps, double? weightKg}) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(
      draftReps: reps == null ? null : (reps < 0 ? 0 : reps),
      draftWeightKg: weightKg == null ? null : (weightKg < 0 ? 0 : weightKg),
    );
  }

  void setMode(WorkoutMode mode) {
    final s = state;
    if (s == null) return;
    state = s.copyWith(mode: mode, clearSuggestion: mode == WorkoutMode.manual);
  }

  void startSet() {
    final s = state;
    if (s == null || s.phase == WorkoutPhase.working) return;
    state = s.copyWith(
      phase: WorkoutPhase.working,
      setStartedAt: _now,
      clearRestStartedAt: true,
      clearSuggestion: true,
    );
  }

  Future<void> endSet({int? reps, double? weightKg}) async {
    final s = state;
    if (s == null ||
        s.phase != WorkoutPhase.working ||
        s.setStartedAt == null) {
      return;
    }
    final exerciseId = s.currentExerciseId;
    if (exerciseId == null) return;
    final ended = _now;
    final started = s.setStartedAt!;
    final hr = summarizeHr(s.hr, started, ended);
    final setNo =
        s.loggedSets.where((x) => x.exerciseId == exerciseId).length + 1;
    final log = SetLog(
      exerciseId: exerciseId,
      setNo: setNo,
      reps: reps ?? s.draftReps,
      weightKg: weightKg ?? s.draftWeightKg,
      startedAt: started,
      endedAt: ended,
      avgHr: hr?.avg,
      peakHr: hr?.peak,
    );
    final id = await ref
        .read(workoutRepositoryProvider)
        .addSet(s.sessionId, log);
    final saved = SetLog(
      id: id,
      exerciseId: log.exerciseId,
      setNo: log.setNo,
      reps: log.reps,
      weightKg: log.weightKg,
      startedAt: log.startedAt,
      endedAt: log.endedAt,
      avgHr: log.avgHr,
      peakHr: log.peakHr,
    );
    final cur = state ?? s;
    final nextIndex = cur.setIndex + 1;
    final next = _planFor(cur.currentItem, nextIndex);
    state = cur.copyWith(
      phase: WorkoutPhase.resting,
      restStartedAt: ended,
      clearSetStartedAt: true,
      loggedSets: [...cur.loggedSets, saved],
      setIndex: nextIndex,
      draftReps: next.reps,
      draftWeightKg: next.weightKg,
      clearSuggestion: true,
      pendingRecovery: hr == null ? null : (id, hr.peak, ended),
      clearPendingRecovery: hr == null,
    );
  }

  void skipRest() {
    final s = state;
    if (s == null || s.phase != WorkoutPhase.resting) return;
    state = s.copyWith(phase: WorkoutPhase.idle, clearRestStartedAt: true);
  }

  void nextExercise() {
    final s = state;
    if (s == null || s.exerciseIndex >= s.items.length - 1) return;
    final idx = s.exerciseIndex + 1;
    final first = _planFor(s.items[idx], 0);
    state = s.copyWith(
      exerciseIndex: idx,
      setIndex: 0,
      phase: WorkoutPhase.idle,
      clearRestStartedAt: true,
      clearSetStartedAt: true,
      draftReps: first.reps,
      draftWeightKg: first.weightKg,
    );
  }

  /// Serbest antrenmanda (ya da ortada) egzersiz ekler. Liste boşsa ona geçer.
  void addExercise(String exerciseId) {
    final s = state;
    if (s == null) return;
    final item = RoutineItem.uniform(
      exerciseId: exerciseId,
      sets: 3,
      reps: 10,
      weightKg: 0,
    );
    final items = [...s.items, item];
    if (s.items.isEmpty) {
      state = s.copyWith(
        items: items,
        exerciseIndex: 0,
        setIndex: 0,
        draftReps: 10,
        draftWeightKg: 0,
      );
    } else {
      state = s.copyWith(items: items);
    }
  }

  /// Bant ~1 Hz nabız gönderir. Geçersiz değerler (bant takılı değil vb.) yok sayılır.
  void recordHr(int bpm) {
    var s = state;
    if (s == null || bpm < 30 || bpm > 210) return;
    final now = _now;
    final cutoff = now.subtract(const Duration(minutes: 10));
    final hr = [...s.hr.where((p) => p.at.isAfter(cutoff)), HrPoint(now, bpm)];
    s = s.copyWith(hr: hr);

    // Toparlanma: set bitiminden 60 sn sonrası.
    final pending = s.pendingRecovery;
    if (pending != null) {
      final (setId, peak, endedAt) = pending;
      if (now.difference(endedAt) >= const Duration(seconds: 60)) {
        final drop = recoveryDrop(hr, peak: peak, endedAt: endedAt);
        if (drop != null) {
          final updated = [
            for (final x in s.loggedSets)
              if (x.id == setId)
                SetLog(
                  id: x.id,
                  exerciseId: x.exerciseId,
                  setNo: x.setNo,
                  reps: x.reps,
                  weightKg: x.weightKg,
                  startedAt: x.startedAt,
                  endedAt: x.endedAt,
                  avgHr: x.avgHr,
                  peakHr: x.peakHr,
                  recoveryBpm: drop,
                )
              else
                x,
          ];
          s = s.copyWith(loggedSets: updated, clearPendingRecovery: true);
          unawaited(
            ref
                .read(workoutRepositoryProvider)
                .updateSetHr(setId, recoveryBpm: drop),
          );
        } else if (now.difference(endedAt) > const Duration(seconds: 75)) {
          s = s.copyWith(clearPendingRecovery: true);
        }
      }
    }

    // Öneri modu: nabızdan set başlangıcı/bitişi önerisi (onay bekler).
    if (s.mode == WorkoutMode.auto &&
        (s.suggestionCooldownUntil == null ||
            !now.isBefore(s.suggestionCooldownUntil!))) {
      final sug = detectHrTrend(
        hr,
        now,
        setRunning: s.phase == WorkoutPhase.working,
      );
      if (sug != null && sug != s.suggestion) {
        s = s.copyWith(suggestion: sug);
      } else if (sug == null && s.suggestion != null) {
        s = s.copyWith(clearSuggestion: true);
      }
    }
    state = s;
  }

  Future<void> acceptSuggestion() async {
    final s = state;
    if (s == null || s.suggestion == null) return;
    final sug = s.suggestion!;
    state = s.copyWith(clearSuggestion: true);
    if (sug == HrSuggestion.setStarted) {
      startSet();
    } else {
      await endSet();
    }
  }

  void dismissSuggestion() {
    final s = state;
    if (s == null) return;
    state = s.copyWith(
      clearSuggestion: true,
      suggestionCooldownUntil: _now.add(const Duration(seconds: 60)),
    );
  }

  /// Antrenmanı bitirir ve seans numarasını döndürür.
  Future<int?> finish({String note = ''}) async {
    final s = state;
    if (s == null) return null;
    await ref
        .read(workoutRepositoryProvider)
        .finishSession(s.sessionId, _now, note: note);
    state = null;
    return s.sessionId;
  }

  /// Vazgeç: seansı ve setlerini siler.
  Future<void> cancel() async {
    final s = state;
    if (s == null) return;
    await ref.read(workoutRepositoryProvider).deleteSession(s.sessionId);
    state = null;
  }
}

final activeWorkoutProvider =
    NotifierProvider<ActiveWorkoutController, ActiveWorkoutState?>(
      ActiveWorkoutController.new,
    );
