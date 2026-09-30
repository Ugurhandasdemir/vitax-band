import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/core/nutrition_calc.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/nutrition_repository.dart';
import 'package:vitax_app/data/repos/settings_repository.dart';
import 'package:vitax_app/features/onboarding/onboarding_screen.dart';

import '../../support/pump.dart';

class _Env {
  _Env(this.settings, this.nutrition);
  final InMemorySettingsRepository settings;
  final InMemoryNutritionRepository nutrition;
}

Future<_Env> pumpGate(WidgetTester tester, {required bool onboarded}) async {
  tester.view.physicalSize = const Size(375, 667);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final settings = InMemorySettingsRepository();
  await settings.saveProfile(Profile(onboarded: onboarded));
  final nutrition = InMemoryNutritionRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 24, 14, 30)),
        settingsRepositoryProvider.overrideWithValue(settings),
        nutritionRepositoryProvider.overrideWithValue(nutrition),
      ],
      child: const VitaxApp(),
    ),
  );
  await tester.pumpAndSettle();
  return _Env(settings, nutrition);
}

Future<void> fillBody(
  WidgetTester tester, {
  String h = '172',
  String w = '76,4',
  String a = '28',
}) async {
  for (final (k, v) in [('onb-height', h), ('onb-weight', w), ('onb-age', a)]) {
    await scrollTo(tester, find.byKey(ValueKey(k)));
    await tester.ensureVisible(find.byKey(ValueKey(k)));
    await tester.enterText(find.byKey(ValueKey(k)), v);
  }
}

Future<void> scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('ilk açılışta karşılama, tamamlanmışsa ana kabuk', (
    tester,
  ) async {
    await pumpGate(tester, onboarded: false);
    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('Vital Precision\'a Hoş Geldin'), findsOneWidget);
  });

  testWidgets('onboarded ise doğrudan kabuk açılır', (tester) async {
    await pumpGate(tester, onboarded: true);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
  });

  testWidgets('hedef kartları tek seçimli', (tester) async {
    await pumpGate(tester, onboarded: false);
    Color? c(String k) =>
        ((tester
                    .widget<Container>(
                      find.byKey(ValueKey('onb-goal-$k'), skipOffstage: false),
                    )
                    .decoration)
                as BoxDecoration)
            .color;
    expect(c('lose'), isNot(const Color(0xFFFFFFFF)));
    await tester.tap(find.text('Kas Kütlesi ve Kuvvet Kazanmak'));
    await tester.pumpAndSettle();
    expect(c('gain'), isNot(const Color(0xFFFFFFFF)));
    expect(c('lose'), const Color(0xFFFFFFFF));
  });

  testWidgets(
    'geçerli bilgilerle devam: plan hesaplanır, profil ve ilk kilo kaydedilir',
    (tester) async {
      final env = await pumpGate(tester, onboarded: false);
      await fillBody(tester);
      await tapVisible(tester, find.byKey(const ValueKey('onb-sex-female')));
      await scrollTo(tester, find.byKey(const ValueKey('onb-continue')));
      await tapVisible(tester, find.byKey(const ValueKey('onb-continue')));
      final p = await env.settings.loadProfile();
      expect(p.onboarded, isTrue);
      expect(p.goal, GoalType.lose);
      expect(p.heightCm, 172);
      expect(p.weightKg, 76.4);
      expect(p.age, 28);
      expect(p.sex, Sex.female);
      expect(p.startWeightKg, 76.4);
      final expected = applyAutoPlan(
        const Profile(
          heightCm: 172,
          weightKg: 76.4,
          age: 28,
          sex: Sex.female,
          activity: ActivityLevel.moderate,
          goal: GoalType.lose,
        ),
      );
      expect(p.kcalGoal, expected.kcalGoal);
      expect(p.proteinGoal, expected.proteinGoal);
      expect((await env.nutrition.latestWeight())!.kg, 76.4);
      // kapı artık ana kabuğu gösterir
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
    },
  );

  testWidgets('geçersiz bilgi: devam etmez, uyarı gösterir', (tester) async {
    final env = await pumpGate(tester, onboarded: false);
    await fillBody(tester, h: '50', w: '76', a: '28');
    await scrollTo(tester, find.byKey(const ValueKey('onb-continue')));
    await tapVisible(tester, find.byKey(const ValueKey('onb-continue')));
    expect((await env.settings.loadProfile()).onboarded, isFalse);
    expect(find.textContaining('geçerli'), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('boş alanlarla devam edilemez', (tester) async {
    final env = await pumpGate(tester, onboarded: false);
    await scrollTo(tester, find.byKey(const ValueKey('onb-continue')));
    await tapVisible(tester, find.byKey(const ValueKey('onb-continue')));
    expect((await env.settings.loadProfile()).onboarded, isFalse);
  });

  testWidgets('Atla: varsayılanlarla tamamlar ve kabuğa geçer', (tester) async {
    final env = await pumpGate(tester, onboarded: false);
    await tester.tap(find.byKey(const ValueKey('onb-skip')));
    await tester.pumpAndSettle();
    expect((await env.settings.loadProfile()).onboarded, isTrue);
    expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
  });

  testWidgets('Daha Sonra bant adımını geçer, gizlilik notu doğru', (
    tester,
  ) async {
    await pumpGate(tester, onboarded: false);
    await scrollTo(tester, find.text('Daha Sonra'));
    expect(find.text('Bilekliği Şimdi Tara'), findsOneWidget);
    await scrollTo(tester, find.textContaining('Apple Health kullanılmaz'));
    expect(find.textContaining('yalnızca bu cihazda'), findsOneWidget);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpGate(tester, onboarded: false);
    expect(tester.takeException(), isNull);
  });
}
