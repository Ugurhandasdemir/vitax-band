import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/features/add_food/add_food_screen.dart';
import 'package:vitax_app/features/diary/diary_screen.dart';
import 'package:vitax_app/features/hydration/hydration_screen.dart';

import '../support/pump.dart';

/// Görsel regresyon: tam uzunlukta ekran görüntüleri. Tasarım PNG'leriyle gözle karşılaştırılır.
void main() {
  testWidgets('Kalori Günlüğü (golden)', (tester) async {
    await pumpScreen(
      tester,
      const DiaryScreen(),
      steps: 11250,
      size: const Size(375, 2000),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/diary.png'),
    );
  });

  testWidgets('Yemek Ekle (golden)', (tester) async {
    await pumpScreen(
      tester,
      const AddFoodScreen(),
      size: const Size(375, 1500),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/add_food.png'),
    );
  });

  testWidgets('Su Takibi (golden)', (tester) async {
    await pumpScreen(
      tester,
      const HydrationScreen(),
      size: const Size(375, 1700),
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/hydration.png'),
    );
  });
}
