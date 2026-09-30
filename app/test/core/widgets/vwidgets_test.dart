import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/core/theme/app_theme.dart';
import 'package:vitax_app/core/theme/tokens.dart';
import 'package:vitax_app/core/widgets/bottom_nav.dart';
import 'package:vitax_app/core/widgets/calorie_ring.dart';
import 'package:vitax_app/core/widgets/v_card.dart';
import 'package:vitax_app/core/widgets/v_progress_bar.dart';
import 'package:vitax_app/core/widgets/v_segmented.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  home: Scaffold(
    body: Center(child: SizedBox(width: 300, child: child)),
  ),
);

void main() {
  navLayoutTests();
  testWidgets('VProgressBar dolu kısım oranı değere eşit', (tester) async {
    await tester.pumpWidget(wrap(const VProgressBar(value: 0.75)));
    final track = tester.getSize(find.byKey(const ValueKey('vprogress-track')));
    final fill = tester.getSize(find.byKey(const ValueKey('vprogress-fill')));
    expect(fill.width / track.width, closeTo(0.75, 0.01));
    expect(track.height, 8);
  });

  testWidgets('VProgressBar değeri 0-1 aralığına sıkıştırır', (tester) async {
    await tester.pumpWidget(wrap(const VProgressBar(value: 1.8)));
    final track = tester.getSize(find.byKey(const ValueKey('vprogress-track')));
    final fill = tester.getSize(find.byKey(const ValueKey('vprogress-fill')));
    expect(fill.width, closeTo(track.width, 0.01));
  });

  testWidgets('VCard 16px yarıçap ve ince kenarlık kullanır', (tester) async {
    await tester.pumpWidget(wrap(const VCard(child: Text('x'))));
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(VCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final deco = box.decoration as BoxDecoration;
    expect(deco.borderRadius, BorderRadius.circular(VRadius.card));
    expect(deco.color, VColors.surfaceContainerLowest);
    expect((deco.border as Border).top.color, VColors.surfaceContainerHighest);
  });

  testWidgets('CalorieRing değeri ve hedefi Türkçe biçimde gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const CalorieRing(value: 1420, goal: 2100)));
    expect(find.text('1.420'), findsOneWidget);
    expect(find.text('/ 2.100 KCAL'), findsOneWidget);
  });

  testWidgets('CalorieRing oranı değer/hedef', (tester) async {
    await tester.pumpWidget(wrap(const CalorieRing(value: 1050, goal: 2100)));
    final ring = tester.widget<CalorieRing>(find.byType(CalorieRing));
    expect(ring.fraction, closeTo(0.5, 0.001));
  });

  testWidgets('CalorieRing hedef 0 ise çökmez', (tester) async {
    await tester.pumpWidget(wrap(const CalorieRing(value: 100, goal: 0)));
    expect(tester.takeException(), isNull);
    final ring = tester.widget<CalorieRing>(find.byType(CalorieRing));
    expect(ring.fraction, 0);
  });

  testWidgets('VSegmented seçimi bildirir', (tester) async {
    int? picked;
    await tester.pumpWidget(
      wrap(
        VSegmented(
          labels: const ['Bugün', 'Kalp', 'Uyku'],
          selected: 0,
          onChanged: (i) => picked = i,
        ),
      ),
    );
    await tester.tap(find.text('Uyku'));
    expect(picked, 2);
  });

  testWidgets('VBottomNav 5 sekme gösterir ve dokunmayı bildirir', (
    tester,
  ) async {
    int? tapped;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          bottomNavigationBar: VBottomNav(
            selected: 0,
            onTap: (i) => tapped = i,
          ),
        ),
      ),
    );
    for (final l in ['Genel', 'Aktivite', 'Tara', 'AI Koç', 'Egzersiz']) {
      expect(find.text(l), findsOneWidget);
    }
    await tester.tap(find.text('Tara'));
    expect(tapped, 2);
  });

  testWidgets('VBottomNav seçili sekme turuncu hap', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          bottomNavigationBar: VBottomNav(selected: 1, onTap: (_) {}),
        ),
      ),
    );
    final pill = tester.widget<Container>(
      find.byKey(const ValueKey('nav-pill-1')),
    );
    final deco = pill.decoration as BoxDecoration;
    expect(deco.color, VColors.primaryContainer);
  });
}

// Regresyon: alt sekme çubuğu ekranın altında, sabit yükseklikte olmalı.
void navLayoutTests() {
  testWidgets('VBottomNav altta ve 64px yüksekliğinde', (tester) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: VBottomNav(selected: 0, onTap: (_) {}),
        ),
      ),
    );
    final r = tester.getRect(find.byType(VBottomNav));
    expect(r.height, 64);
    expect(r.bottom, 667);
  });
}
