import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:vitax_app/data/exercise_catalog.dart';
import 'package:vitax_app/features/exercises/exercise_detail_screen.dart';
import 'package:vitax_app/features/workout/active_workout.dart';
import 'package:vitax_app/features/workout/routine_builder_screen.dart';

import '../../support/pump.dart';
import '../../support/seed.dart';

Future<TestEnv> pumpDetail(
  WidgetTester tester, {
  String id = '0001',
  bool history = true,
}) => pumpScreen(
  tester,
  ExerciseDetailScreen(exerciseId: id),
  seeded: false,
  seedWorkouts: history ? seedWorkouts : null,
);

Future<void> scrollTo(WidgetTester tester, Finder f) => tester
    .scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);

void main() {
  testWidgets('başlık, etiketler ve animasyon çerçevesi (GIF) + atıf', (
    tester,
  ) async {
    await pumpDetail(tester);
    final ex = fixtureCatalog().byId('0001')!;
    expect(find.text('Barbell Bench Press'), findsOneWidget);
    expect(find.byKey(ValueKey('media:${ex.gifUrl}')), findsOneWidget);
    expect(find.text('Döngü'), findsOneWidget);
    expect(find.text('0.5x'), findsOneWidget);
    expect(find.text('1.0x'), findsOneWidget);
    expect(find.text(mediaAttribution), findsOneWidget);
    expect(find.text('Halter'), findsWidgets);
  });

  testWidgets('hız ve duraklat düğmeleri durum değiştirir', (tester) async {
    await pumpDetail(tester);
    expect(find.byIcon(PhosphorIconsRegular.pause), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('media-toggle')));
    await tester.pumpAndSettle();
    expect(find.byIcon(PhosphorIconsRegular.play), findsOneWidget);
    Color? c(String k) =>
        ((tester.widget<Container>(find.byKey(ValueKey('speed-$k'))).decoration)
                as BoxDecoration)
            .color;
    expect(c('1.0x'), isNot(Colors.transparent));
    await tester.tap(find.text('0.5x'));
    await tester.pumpAndSettle();
    expect(c('0.5x'), isNot(Colors.transparent));
    expect(c('1.0x'), Colors.transparent);
  });

  testWidgets('ekipman ve kas dağılımı: birincil ve ikincil', (tester) async {
    await pumpDetail(tester);
    await scrollTo(tester, find.text('Kas Dağılımı'));
    expect(find.text('EKİPMAN'), findsWidgets);
    expect(find.text('BİRİNCİL'), findsOneWidget);
    expect(find.text('İKİNCİL'), findsWidgets);
    expect(find.text('Triseps'), findsWidgets);
  });

  testWidgets('uygulama adımları Türkçe ve numaralı', (tester) async {
    await pumpDetail(tester);
    await scrollTo(tester, find.text('Uygulama Adımları'));
    final ex = fixtureCatalog().byId('0001')!;
    expect(find.text('${ex.stepsTr.length} Aşama'), findsOneWidget);
    expect(find.text(ex.stepsTr.first), findsOneWidget);
    expect(find.text('1'), findsWidgets);
  });

  testWidgets('Geçmişim: son antrenman, en iyi set, 1RM ve ortalama nabız', (
    tester,
  ) async {
    await pumpDetail(tester);
    await scrollTo(tester, find.text('Geçmişim'));
    expect(find.textContaining('3 gün önce'), findsOneWidget);
    expect(find.textContaining('4 set'), findsOneWidget);
    expect(find.textContaining('6 × 85 kg'), findsOneWidget);
    expect(find.textContaining('1RM: 102,0 kg'), findsOneWidget);
    expect(find.text('137 bpm'), findsOneWidget);
  });

  testWidgets('kayıt yoksa Geçmişim boş durum', (tester) async {
    await pumpDetail(tester, history: false);
    await scrollTo(tester, find.text('Geçmişim'));
    expect(find.textContaining('Henüz kayıt yok'), findsOneWidget);
  });

  testWidgets('Antrenmana Ekle: mevcut rutine eklenir', (tester) async {
    final env = await pumpDetail(tester, id: '0003'); // pull up rutinde yok
    await scrollTo(tester, find.text('Antrenmana Ekle'));
    await tapVisible(tester, find.text('Antrenmana Ekle'));
    await tester.tap(find.text('Push Day (İtiş A)'));
    await tester.pumpAndSettle();
    final r = (await env.workouts.routine(1))!;
    expect(r.items.map((i) => i.exerciseId), ['0001', '0002', '0003']);
    expect(find.text('Rutine eklendi'), findsOneWidget);
  });

  testWidgets('Antrenmana Ekle: zaten rutindeyse eklenmez, bilgi verir', (
    tester,
  ) async {
    final env = await pumpDetail(tester);
    await scrollTo(tester, find.text('Antrenmana Ekle'));
    await tapVisible(tester, find.text('Antrenmana Ekle'));
    await tester.tap(find.text('Push Day (İtiş A)'));
    await tester.pumpAndSettle();
    expect((await env.workouts.routine(1))!.items, hasLength(2));
    expect(find.text('Bu hareket zaten rutinde'), findsOneWidget);
  });

  testWidgets('Antrenmana Ekle: Yeni Rutin oluşturucuyu hareketle açar', (
    tester,
  ) async {
    await pumpDetail(tester, id: '0003');
    await scrollTo(tester, find.text('Antrenmana Ekle'));
    await tapVisible(tester, find.text('Antrenmana Ekle'));
    await tester.tap(find.text('Yeni Rutin'));
    await tester.pumpAndSettle();
    expect(find.byType(RoutineBuilderScreen), findsOneWidget);
    expect(find.text('Pull Up'), findsOneWidget);
  });

  testWidgets('aktif antrenman varken Aktif antrenmana ekle seçeneği çıkar', (
    tester,
  ) async {
    final env = await pumpDetail(tester, id: '0003');
    await env.container
        .read(activeWorkoutProvider.notifier)
        .start(name: 'Serbest');
    await scrollTo(tester, find.text('Antrenmana Ekle'));
    await tapVisible(tester, find.text('Antrenmana Ekle'));
    await tester.tap(find.text('Aktif antrenmana ekle'));
    await tester.pumpAndSettle();
    expect(
      env.container.read(activeWorkoutProvider)!.currentExerciseId,
      '0003',
    );
  });

  testWidgets('olmayan id çökmez', (tester) async {
    await pumpDetail(tester, id: '9999');
    expect(find.text('Egzersiz bulunamadı'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('taşma yok', (tester) async {
    await pumpDetail(tester);
    expect(tester.takeException(), isNull);
  });
}
