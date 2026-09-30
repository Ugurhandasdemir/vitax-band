import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/features/profile/profile_hub_screen.dart';
import 'package:vitax_app/features/profile/profile_screen.dart';
import 'package:vitax_app/features/weight/weight_screen.dart';

import '../../support/pump.dart';

void main() {
  testWidgets('profil merkezi girişleri listeler', (tester) async {
    await pumpScreen(tester, const ProfileHubScreen(), seeded: false);
    for (final t in [
      'Profil ve Hedefler',
      'Kilo Analizi',
      'Bilekliğim',
      'Veri Kasası ve Gizlilik',
      'Bildirimler ve Uyarılar',
    ]) {
      expect(find.text(t), findsOneWidget);
    }
  });

  testWidgets('Profil ve Hedefler ekranı açılır', (tester) async {
    await pumpScreen(tester, const ProfileHubScreen(), seeded: false);
    await tester.tap(find.text('Profil ve Hedefler'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('Kilo Analizi ekranı açılır', (tester) async {
    await pumpScreen(tester, const ProfileHubScreen(), seeded: false);
    await tester.tap(find.text('Kilo Analizi'));
    await tester.pumpAndSettle();
    expect(find.byType(WeightScreen), findsOneWidget);
  });
}
