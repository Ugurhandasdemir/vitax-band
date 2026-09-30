import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/app.dart';
import 'package:vitax_app/app/providers.dart';
import 'package:vitax_app/data/models.dart';
import 'package:vitax_app/data/repos/settings_repository.dart';

Future<void> pumpApp(WidgetTester tester) async {
  // iPhone SE 3: 375x667
  tester.view.physicalSize = const Size(375, 667);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final settings = InMemorySettingsRepository();
  await settings.saveProfile(const Profile(onboarded: true));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [settingsRepositoryProvider.overrideWithValue(settings)],
      child: const VitaxApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('kabuk iPhone SE 3 boyutunda taşma olmadan açılır', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('screen-home')), findsOneWidget);
  });

  testWidgets('5 sekme var ve her biri kendi ekranını açar', (tester) async {
    await pumpApp(tester);
    final tabs = {
      'Aktivite': 'screen-activity',
      'Tara': 'screen-scan',
      'AI Koç': 'screen-coach',
      'Egzersiz': 'screen-exercises',
      'Genel': 'screen-home',
    };
    for (final e in tabs.entries) {
      await tester.tap(find.text(e.key));
      await tester.pumpAndSettle();
      expect(
        find.byKey(ValueKey(e.value)),
        findsOneWidget,
        reason: '${e.key} sekmesi ${e.value} açmalı',
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('üst barda başlık, avatar ve bant durum çipi var', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('Vital Precision'), findsOneWidget);
    expect(find.byKey(const ValueKey('top-avatar')), findsOneWidget);
    expect(find.byKey(const ValueKey('band-status-chip')), findsOneWidget);
  });

  testWidgets('avatara dokununca profil merkezi açılır', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byKey(const ValueKey('top-avatar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('screen-profile-hub')), findsOneWidget);
  });
}
