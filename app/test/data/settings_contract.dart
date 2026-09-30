import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/settings_repository.dart';

void settingsContract(
  String name,
  Future<SettingsRepository> Function() create,
) {
  group('SettingsRepository[$name]', () {
    late SettingsRepository repo;
    setUp(() async => repo = await create());
    tearDown(() async => repo.close());

    test('kayıt yokken makul varsayılan profil döner', () async {
      final p = await repo.loadProfile();
      expect(p.kcalGoal, 2100);
      expect(p.proteinGoal, 150);
      expect(p.waterGoalMl, 2500);
      expect(p.stepGoal, 10000);
      expect(p.onboarded, isFalse);
    });

    test('kaydedilen profil aynen geri gelir', () async {
      const p = Profile(
        heightCm: 178,
        weightKg: 76.4,
        age: 27,
        sex: Sex.male,
        activity: ActivityLevel.active,
        goal: GoalType.lose,
        kcalGoal: 2250,
        proteinGoal: 153,
        carbsGoal: 240,
        fatGoal: 75,
        waterGoalMl: 3000,
        stepGoal: 12000,
        onboarded: true,
        name: 'Uğurhan',
        goalWeightKg: 72,
        startWeightKg: 81,
        units: Units.imperial,
      );
      await repo.saveProfile(p);
      final q = await repo.loadProfile();
      expect(q.heightCm, 178);
      expect(q.weightKg, 76.4);
      expect(q.sex, Sex.male);
      expect(q.activity, ActivityLevel.active);
      expect(q.goal, GoalType.lose);
      expect(q.kcalGoal, 2250);
      expect(q.waterGoalMl, 3000);
      expect(q.stepGoal, 12000);
      expect(q.onboarded, isTrue);
      expect(q.name, 'Uğurhan');
      expect(q.goalWeightKg, 72);
      expect(q.startWeightKg, 81);
      expect(q.units, Units.imperial);
    });

    test(
      'varsayılanlarda isim boş, hedef kilo belirsiz, metrik birim',
      () async {
        final p = await repo.loadProfile();
        expect(p.name, '');
        expect(p.goalWeightKg, 0);
        expect(p.startWeightKg, 0);
        expect(p.units, Units.metric);
      },
    );

    test(
      'string deposu: yoksa null, yazılan okunur, üzerine yazılır',
      () async {
        expect(await repo.getString('favorites'), isNull);
        await repo.setString('favorites', '["A","B"]');
        expect(await repo.getString('favorites'), '["A","B"]');
        await repo.setString('favorites', '["C"]');
        expect(await repo.getString('favorites'), '["C"]');
      },
    );

    test('ikinci kayıt öncekinin üzerine yazar', () async {
      const base = Profile(
        heightCm: 170,
        weightKg: 70,
        age: 30,
        sex: Sex.female,
        activity: ActivityLevel.light,
        goal: GoalType.maintain,
        kcalGoal: 1900,
        proteinGoal: 140,
        carbsGoal: 200,
        fatGoal: 60,
        waterGoalMl: 2500,
        stepGoal: 10000,
        onboarded: true,
      );
      await repo.saveProfile(base);
      await repo.saveProfile(base.copyWith(kcalGoal: 1800));
      expect((await repo.loadProfile()).kcalGoal, 1800);
    });
  });
}
