import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/features/workout/routine_draft.dart';

ProviderContainer make([Routine? r]) {
  final c = ProviderContainer();
  addTearDown(c.dispose);
  c.read(routineDraftProvider.notifier).load(r);
  return c;
}

RoutineDraftController ctl(ProviderContainer c) =>
    c.read(routineDraftProvider.notifier);
RoutineDraftState st(ProviderContainer c) => c.read(routineDraftProvider);

final _r = Routine(
  id: 7,
  name: 'Push',
  items: [
    RoutineItem.uniform(exerciseId: 'a', sets: 3, reps: 10, weightKg: 50),
    RoutineItem.uniform(exerciseId: 'b', sets: 2, reps: 12, weightKg: 20),
  ],
);

void main() {
  test('yeni taslak boş; var olan rutin yüklenir', () {
    final c = make();
    expect(st(c).name, '');
    expect(st(c).items, isEmpty);
    expect(st(c).id, isNull);
    ctl(c).load(_r);
    expect(st(c).id, 7);
    expect(st(c).name, 'Push');
    expect(st(c).items, hasLength(2));
  });

  test('ad değişir', () {
    final c = make();
    ctl(c).rename('Bacak Günü');
    expect(st(c).name, 'Bacak Günü');
  });

  test('egzersiz eklenir: varsayılan 3 set x 10 tekrar, verilen ağırlık', () {
    final c = make();
    ctl(c).addExercise('x', weightKg: 40);
    final it = st(c).items.single;
    expect(it.exerciseId, 'x');
    expect(it.sets, hasLength(3));
    expect(it.sets.first.reps, 10);
    expect(it.sets.first.weightKg, 40);
    expect(it.restSec, 90);
  });

  test('aynı egzersiz iki kez eklenmez', () {
    final c = make();
    ctl(c).addExercise('x');
    ctl(c).addExercise('x');
    expect(st(c).items, hasLength(1));
  });

  test('egzersiz silinir', () {
    final c = make(_r);
    ctl(c).removeExercise(0);
    expect(st(c).items.map((i) => i.exerciseId), ['b']);
  });

  test(
    'sıralama: sürükle-bırak mantığı (Flutter kuralı, aşağı taşırken -1)',
    () {
      final c = make(
        Routine(
          name: 'x',
          items: [
            RoutineItem.uniform(exerciseId: 'a', sets: 1, reps: 1, weightKg: 0),
            RoutineItem.uniform(exerciseId: 'b', sets: 1, reps: 1, weightKg: 0),
            RoutineItem.uniform(exerciseId: 'c', sets: 1, reps: 1, weightKg: 0),
          ],
        ),
      );
      ctl(c).moveExercise(0, 3); // a en sona
      expect(st(c).items.map((i) => i.exerciseId), ['b', 'c', 'a']);
      ctl(c).moveExercise(2, 0); // a başa
      expect(st(c).items.map((i) => i.exerciseId), ['a', 'b', 'c']);
    },
  );

  test('set ekle: son setin kopyası; set sil (en az 1 set kalır)', () {
    final c = make(_r);
    ctl(c).addSet(1);
    expect(st(c).items[1].sets, hasLength(3));
    expect(st(c).items[1].sets.last.weightKg, 20);
    ctl(c).removeSet(1, 0);
    ctl(c).removeSet(1, 0);
    ctl(c).removeSet(1, 0); // son set silinmez
    expect(st(c).items[1].sets, hasLength(1));
  });

  test('tekrar ve ağırlık düzenlenir, negatif olmaz', () {
    final c = make(_r);
    ctl(c).setReps(0, 1, 8);
    ctl(c).setWeight(0, 1, 62.5);
    expect(st(c).items[0].sets[1].reps, 8);
    expect(st(c).items[0].sets[1].weightKg, 62.5);
    ctl(c).setReps(0, 1, -3);
    ctl(c).setWeight(0, 1, -10);
    expect(st(c).items[0].sets[1].reps, 0);
    expect(st(c).items[0].sets[1].weightKg, 0);
  });

  test('mola süresi 15-300 sn arasında sınırlanır', () {
    final c = make(_r);
    ctl(c).setRest(0, 120);
    expect(st(c).items[0].restSec, 120);
    ctl(c).setRest(0, 5);
    expect(st(c).items[0].restSec, 15);
    ctl(c).setRest(0, 999);
    expect(st(c).items[0].restSec, 300);
  });

  test('geçerlilik: ad ve en az bir egzersiz gerekir', () {
    final c = make();
    expect(st(c).isValid, isFalse);
    ctl(c).rename('A');
    expect(st(c).isValid, isFalse);
    ctl(c).addExercise('x');
    expect(st(c).isValid, isTrue);
    ctl(c).rename('   ');
    expect(st(c).isValid, isFalse);
  });

  test('toRoutine adı kırpar ve id korur', () {
    final c = make(_r);
    ctl(c).rename('  Push 2  ');
    final r = st(c).toRoutine();
    expect(r.id, 7);
    expect(r.name, 'Push 2');
    expect(r.items, hasLength(2));
  });
}
