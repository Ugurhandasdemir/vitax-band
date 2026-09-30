import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models.dart';

/// Rutin oluşturucunun düzenlenen taslağı.
class RoutineDraftState {
  const RoutineDraftState({this.id, this.name = '', this.items = const []});
  final int? id;
  final String name;
  final List<RoutineItem> items;

  bool get isValid => name.trim().isNotEmpty && items.isNotEmpty;

  Routine toRoutine() => Routine(id: id, name: name.trim(), items: items);

  RoutineDraftState copyWith({String? name, List<RoutineItem>? items}) =>
      RoutineDraftState(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items,
      );
}

class RoutineDraftController extends Notifier<RoutineDraftState> {
  @override
  RoutineDraftState build() => const RoutineDraftState();

  /// Var olan rutini yükler; null verilirse boş taslak başlatır.
  void load(Routine? r) {
    state = r == null
        ? const RoutineDraftState()
        : RoutineDraftState(id: r.id, name: r.name, items: List.of(r.items));
  }

  void rename(String name) => state = state.copyWith(name: name);

  void addExercise(String exerciseId, {double weightKg = 0}) {
    if (state.items.any((i) => i.exerciseId == exerciseId)) return;
    state = state.copyWith(
      items: [
        ...state.items,
        RoutineItem.uniform(
          exerciseId: exerciseId,
          sets: 3,
          reps: 10,
          weightKg: weightKg,
        ),
      ],
    );
  }

  void removeExercise(int index) {
    final items = [...state.items]..removeAt(index);
    state = state.copyWith(items: items);
  }

  /// Flutter ReorderableListView kuralı: aşağı taşırken [newIndex] bir fazladır.
  void moveExercise(int oldIndex, int newIndex) {
    final items = [...state.items];
    if (newIndex > oldIndex) newIndex -= 1;
    final it = items.removeAt(oldIndex);
    items.insert(newIndex, it);
    state = state.copyWith(items: items);
  }

  void _update(int i, RoutineItem Function(RoutineItem) f) {
    final items = [...state.items];
    items[i] = f(items[i]);
    state = state.copyWith(items: items);
  }

  void addSet(int i) => _update(i, (it) {
    final last = it.sets.isEmpty
        ? const PlannedSet(reps: 10, weightKg: 0)
        : it.sets.last;
    return it.copyWith(sets: [...it.sets, last]);
  });

  /// En az bir set kalır.
  void removeSet(int i, int j) => _update(i, (it) {
    if (it.sets.length <= 1) return it;
    final sets = [...it.sets]..removeAt(j);
    return it.copyWith(sets: sets);
  });

  void setReps(int i, int j, int reps) => _update(i, (it) {
    final sets = [...it.sets];
    sets[j] = sets[j].copyWith(reps: reps < 0 ? 0 : reps);
    return it.copyWith(sets: sets);
  });

  void setWeight(int i, int j, double kg) => _update(i, (it) {
    final sets = [...it.sets];
    sets[j] = sets[j].copyWith(weightKg: kg < 0 ? 0 : kg);
    return it.copyWith(sets: sets);
  });

  void setRest(int i, int seconds) =>
      _update(i, (it) => it.copyWith(restSec: seconds.clamp(15, 300)));
}

final routineDraftProvider =
    NotifierProvider<RoutineDraftController, RoutineDraftState>(
      RoutineDraftController.new,
    );
