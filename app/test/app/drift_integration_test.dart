import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/data/db/app_database.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/band_sample_repository.dart';
import 'package:vitax_app/data/repos/nutrition_repository.dart';
import 'package:vitax_app/data/repos/settings_repository.dart';

import '../support/pump.dart';

/// Gerçek SQLite (bellekte) ile baştan sona: onboarding -> kayıt -> kalıcılık.
void main() {
  testWidgets('onboarding ve yemek kaydı SQLite üzerinden kalıcı olur', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final nutrition = DriftNutritionRepository(db);
    final settings = DriftSettingsRepository(db);
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 24, 14, 30)),
        nutritionRepositoryProvider.overrideWithValue(nutrition),
        bandSampleRepositoryProvider.overrideWithValue(
          DriftBandSampleRepository(db),
        ),
        settingsRepositoryProvider.overrideWithValue(settings),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const VitaxApp()),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-onboarding')), findsOneWidget);

    // onboarding doldur
    for (final (k, v) in [
      ('onb-height', '172'),
      ('onb-weight', '76,4'),
      ('onb-age', '28'),
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(ValueKey(k)),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.byKey(ValueKey(k)));
      await tester.enterText(find.byKey(ValueKey(k)), v);
    }
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('onb-continue')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapVisible(tester, find.byKey(const ValueKey('onb-continue')));
    expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);

    // yemek ekle (eylem katmanı) ve kalıcılığı doğrula
    final day = DateTime(2026, 10, 24);
    await container
        .read(nutritionActionsProvider)
        .addFood(
          FoodEntry(
            date: day,
            meal: MealType.lunch,
            name: 'Pilav',
            portion: '1 tabak',
            kcal: 300,
          ),
        );
    await container
        .read(nutritionActionsProvider)
        .addWater(day, 500, label: 'Şişe');
    await tester.pumpAndSettle();

    expect((await nutrition.foodForDay(day)).single.name, 'Pilav');
    expect(await nutrition.waterForDay(day), 500);
    final p = await settings.loadProfile();
    expect(p.onboarded, isTrue);
    expect(p.kcalGoal, greaterThan(1200));
    expect((await nutrition.latestWeight())!.kg, 76.4);
    expect(tester.takeException(), isNull);
  });
}
