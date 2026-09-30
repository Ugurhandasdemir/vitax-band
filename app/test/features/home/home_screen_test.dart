import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/band_sample_repository.dart';
import 'package:vitax_app/data/repos/nutrition_repository.dart';
import 'package:vitax_app/data/repos/settings_repository.dart';
import 'package:vitax_app/features/add_food/add_food_screen.dart';
import 'package:vitax_app/features/diary/diary_screen.dart';
import 'package:vitax_app/features/balance/balance_screen.dart';
import 'package:vitax_app/features/home/home_screen.dart';
import 'package:vitax_app/features/hydration/hydration_screen.dart';
import 'package:vitax_app/core/theme/app_theme.dart';

import '../../support/seed.dart';

Future<ProviderContainer> pumpHome(
  WidgetTester tester, {
  bool seeded = true,
  CoachBriefing? briefing,
  List<HrSample> hr = const [],
  int steps = 0,
}) async {
  tester.view.physicalSize = const Size(375, 667);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final nutrition = InMemoryNutritionRepository();
  if (seeded) await seedDemoDay(nutrition);
  final band = InMemoryBandSampleRepository();
  if (hr.isNotEmpty) await band.insertHr(hr);
  if (steps > 0) {
    await band.insertSteps([
      StepSample(at: DateTime(2026, 10, 24, 9), total: steps),
    ]);
  }
  final settings = InMemorySettingsRepository();
  await settings.saveProfile(const Profile(weightKg: 70, kcalGoal: 2100));
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => DateTime(2026, 10, 24, 14, 30)),
      nutritionRepositoryProvider.overrideWithValue(nutrition),
      bandSampleRepositoryProvider.overrideWithValue(band),
      settingsRepositoryProvider.overrideWithValue(settings),
      coachBriefingProvider.overrideWith((ref) async => briefing),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: buildAppTheme(),
        home: const Scaffold(body: HomeScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> scrollTo(WidgetTester tester, Finder f) async {
  await tester.scrollUntilVisible(
    f,
    200,
    scrollable: find
        .descendant(
          of: find.byKey(const ValueKey('screen-home')),
          matching: find.byType(Scrollable),
        )
        .first,
  );
}

void main() {
  testWidgets('tarih başlığı "Bugün, 24 Ekim"', (tester) async {
    await pumpHome(tester);
    expect(find.text('GÜNLÜK TAKİP'), findsOneWidget);
    expect(find.text('Bugün, 24 Ekim'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enerji bütçesi: halka, yakılan ve kalan', (tester) async {
    await pumpHome(tester, steps: 11250);
    expect(find.text('ENERJİ BÜTÇESİ'), findsOneWidget);
    expect(find.text('1.420'), findsOneWidget);
    expect(find.text('/ 2.100 KCAL'), findsOneWidget);
    expect(find.text('450'), findsOneWidget); // yakılan
    expect(find.text('680'), findsOneWidget); // kalan
    expect(find.textContaining('VİTAXBAND'), findsWidgets);
  });

  testWidgets('makro kartları değer, hedef ve yüzdeyi gösterir', (
    tester,
  ) async {
    await pumpHome(tester);
    await scrollTo(tester, find.byKey(const ValueKey('macro-protein')));
    expect(find.text('PROTEİN'), findsOneWidget);
    expect(find.text('KARB'), findsOneWidget);
    expect(find.text('YAĞ'), findsOneWidget);
    expect(find.text('112'), findsOneWidget);
    expect(find.text('%75'), findsOneWidget);
    expect(find.text('%60'), findsOneWidget);
    expect(find.text('%46'), findsOneWidget); // 32/70
  });

  testWidgets('koç özeti boşken yönlendirici boş durum gösterir', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.byKey(const ValueKey('coach-empty')), findsOneWidget);
    expect(find.textContaining('veri'), findsWidgets);
  });

  testWidgets('koç özeti varken hazırlık skoru ve plan görünür', (
    tester,
  ) async {
    await pumpHome(
      tester,
      briefing: const CoachBriefing(
        readiness: 88,
        plan: '45 dk Kuvvet Antrenmanı • 2.100 kcal hedefi • 2.5 L su',
        insight: 'Dün gece 7s 12dk derin uyku toparlanmanı artırdı.',
      ),
    );
    expect(find.text('Hazırlık Skoru: %88'), findsOneWidget);
    expect(find.textContaining('Kuvvet Antrenmanı'), findsOneWidget);
    expect(find.textContaining('derin uyku'), findsOneWidget);
    expect(find.byKey(const ValueKey('coach-empty')), findsNothing);
  });

  testWidgets('bant canlı kartı nabız, adım, uykuyu gösterir; veri yoksa --', (
    tester,
  ) async {
    await pumpHome(
      tester,
      hr: [HrSample(at: DateTime(2026, 10, 24, 14, 29), bpm: 72)],
      steps: 8432,
    );
    await scrollTo(tester, find.byKey(const ValueKey('band-live-card')));
    expect(find.text('VİTAXBAND CANLI'), findsOneWidget);
    expect(find.text('72'), findsOneWidget);
    expect(find.text('8.432'), findsOneWidget);
    expect(find.text('--'), findsWidgets); // uyku verisi henüz yok
  });

  testWidgets('bant verisi hiç yokken çökmez, tireler gösterilir', (
    tester,
  ) async {
    await pumpHome(tester);
    await scrollTo(tester, find.byKey(const ValueKey('band-live-card')));
    expect(tester.takeException(), isNull);
    expect(find.text('--'), findsWidgets);
  });

  testWidgets('su: toplam gösterilir ve hızlı butonlar ekler', (tester) async {
    await pumpHome(tester);
    await scrollTo(tester, find.byKey(const ValueKey('water-card')));
    expect(find.text('1,2 L'), findsOneWidget);
    expect(find.textContaining('/ 2,5 L'), findsOneWidget);
    await tester.tap(find.text('+200 ml'));
    await tester.pumpAndSettle();
    expect(find.text('1,4 L'), findsOneWidget);
    await tester.tap(find.textContaining('+Şişe'));
    await tester.pumpAndSettle();
    expect(find.text('1,9 L'), findsOneWidget);
  });

  testWidgets('öğün listesi: kahvaltı, öğle, atıştırmalık kcal; akşam boş', (
    tester,
  ) async {
    await pumpHome(tester);
    await scrollTo(tester, find.byKey(const ValueKey('meals-card')));
    expect(find.text('Bugünün Öğünleri'), findsOneWidget);
    expect(find.text('Kahvaltı'), findsOneWidget);
    expect(find.text('420'), findsOneWidget);
    expect(find.text('Öğle'), findsOneWidget);
    expect(find.text('650'), findsOneWidget);
    expect(find.text('Akşam'), findsOneWidget);
    expect(find.text('Henüz kaydedilmedi'), findsOneWidget);
  });

  testWidgets('öğün satırında yiyecek adları özetlenir', (tester) async {
    await pumpHome(tester);
    await scrollTo(tester, find.byKey(const ValueKey('meals-card')));
    expect(find.textContaining('Yulaf ezmesi'), findsOneWidget);
  });

  testWidgets('iPhone SE 3 boyutunda taşma yok (veri dolu ve boş)', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiç veri yokken de çökmez', (tester) async {
    await pumpHome(tester, seeded: false);
    expect(tester.takeException(), isNull);
    expect(find.text('0'), findsWidgets);
  });

  testWidgets('+ düğmesi Yemek Ekle ekranını açar', (tester) async {
    await pumpHome(tester);
    await scrollTo(tester, find.byKey(const ValueKey('meals-add')));
    await tester.ensureVisible(find.byKey(const ValueKey('meals-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meals-add')));
    await tester.pumpAndSettle();
    expect(find.byType(AddFoodScreen), findsOneWidget);
  });

  testWidgets('öğün satırına dokununca Kalori Takibi açılır', (tester) async {
    await pumpHome(tester);
    await scrollTo(tester, find.text('Kahvaltı'));
    await tester.ensureVisible(find.text('Kahvaltı'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Kahvaltı'));
    await tester.pumpAndSettle();
    expect(find.byType(DiaryScreen), findsOneWidget);
  });

  testWidgets('Su Takibi başlığına dokununca su ekranı açılır', (tester) async {
    await pumpHome(tester);
    await scrollTo(tester, find.byKey(const ValueKey('water-card')));
    await tester.ensureVisible(find.text('Su Takibi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Su Takibi'));
    await tester.pumpAndSettle();
    expect(find.byType(HydrationScreen), findsOneWidget);
  });

  testWidgets('Enerji Bütçesi kartına dokununca Kalori Dengesi açılır', (
    tester,
  ) async {
    await pumpHome(tester);
    await tester.tap(find.text('ENERJİ BÜTÇESİ'));
    await tester.pumpAndSettle();
    expect(find.byType(BalanceScreen), findsOneWidget);
  });
}
