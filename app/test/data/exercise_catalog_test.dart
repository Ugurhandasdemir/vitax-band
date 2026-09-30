import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/data/exercise_catalog.dart';

void main() {
  final small = ExerciseCatalog.fromJson(
    File('test/fixtures/exercises_small.json').readAsStringSync(),
  );

  group('ayrıştırma ve etiketler', () {
    test('8 kayıt yüklenir, id ile bulunur', () {
      expect(small.all, hasLength(8));
      expect(small.byId('0001')!.name, 'barbell bench press');
      expect(small.byId('9999'), isNull);
    });

    test('görünen ad her kelimenin baş harfi büyük', () {
      expect(small.byId('0001')!.displayName, 'Barbell Bench Press');
      expect(small.byId('0003')!.displayName, 'Pull Up');
    });

    test('Türkçe etiketler', () {
      final e = small.byId('0001')!;
      expect(e.bodyPartTr, 'Göğüs');
      expect(e.equipmentTr, 'Halter');
      expect(e.targetTr, 'Göğüs');
      expect(small.byId('0003')!.equipmentTr, 'Vücut Ağırlığı');
      expect(small.byId('0004')!.bodyPartTr, 'Üst Bacak');
      expect(e.secondaryTr, ['Triseps', 'Omuz']);
    });

    test('bilinmeyen değer İngilizce baş harfi büyük döner', () {
      expect(labelTr('weird thing', const {}), 'Weird Thing');
    });

    test('medya adresleri GitHub ham dosya adresidir', () {
      final e = small.byId('0001')!;
      expect(
        e.gifUrl,
        startsWith(
          'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/',
        ),
      );
      expect(e.gifUrl, endsWith('.gif'));
      expect(e.imageUrl, endsWith('.jpg'));
    });

    test('atıf metni', () {
      expect(mediaAttribution, '© Gym visual — https://gymvisual.com/');
    });
  });

  group('filtre ve arama', () {
    test('gruplar', () {
      expect(small.search(group: ExerciseGroup.all), hasLength(8));
      expect(small.search(group: ExerciseGroup.chest), hasLength(2));
      expect(
        small.search(group: ExerciseGroup.legs).single.name,
        'barbell squat',
      );
      expect(
        small.search(group: ExerciseGroup.arms).single.name,
        'dumbbell curl',
      );
      expect(small.search(group: ExerciseGroup.abs).single.name, 'crunch');
      expect(
        small.search(group: ExerciseGroup.shoulders).single.name,
        'shoulder press',
      );
      expect(small.search(group: ExerciseGroup.cardio).single.name, 'run');
      expect(small.search(group: ExerciseGroup.back).single.name, 'pull up');
    });

    test('ada göre arama', () {
      expect(small.search(query: 'bench').single.name, 'barbell bench press');
    });

    test('Türkçe etiketle arama: göğüs, büyük harf ve noktasız', () {
      expect(small.search(query: 'GÖĞÜS'), hasLength(2));
      expect(small.search(query: 'gogus'), hasLength(2));
    });

    test('hedef kası Türkçe aranır: biseps', () {
      expect(small.search(query: 'biseps').single.name, 'dumbbell curl');
    });

    test('ekipman filtresi', () {
      expect(small.search(equipment: 'dumbbell'), hasLength(3));
      expect(small.search(equipment: 'barbell'), hasLength(2));
    });

    test('grup, arama ve ekipman birlikte', () {
      final r = small.search(
        query: 'fly',
        group: ExerciseGroup.chest,
        equipment: 'dumbbell',
      );
      expect(r.single.name, 'dumbbell fly');
      expect(small.search(query: 'fly', group: ExerciseGroup.back), isEmpty);
    });

    test('sonuçlar ada göre sıralı', () {
      final names = small.search().map((e) => e.name).toList();
      expect(names, [...names]..sort());
    });

    test(
      'eşleşme yoksa boş',
      () => expect(small.search(query: 'xqzw'), isEmpty),
    );

    test('ekipman listesi benzersiz ve sıralı', () {
      expect(small.equipmentList, ['barbell', 'body weight', 'dumbbell']);
    });
  });

  group('gerçek varlık (assets/data/exercises.json)', () {
    final real = ExerciseCatalog.fromJson(
      File('assets/data/exercises.json').readAsStringSync(),
    );

    test('1324 egzersiz, id benzersiz', () {
      expect(real.all, hasLength(1324));
      expect(real.all.map((e) => e.id).toSet().length, 1324);
    });

    test('hepsinin Türkçe ve İngilizce adımı, medya yolu var', () {
      for (final e in real.all) {
        expect(e.stepsTr, isNotEmpty, reason: e.name);
        expect(e.stepsEn, isNotEmpty, reason: e.name);
        expect(e.gifUrl, isNotEmpty);
        expect(e.imageUrl, isNotEmpty);
      }
    });

    test('grup sayıları veri setiyle uyumlu', () {
      expect(real.search(group: ExerciseGroup.chest), hasLength(163));
      expect(real.search(group: ExerciseGroup.back), hasLength(203));
      expect(real.search(group: ExerciseGroup.abs), hasLength(169));
      expect(real.search(group: ExerciseGroup.shoulders), hasLength(143));
      expect(real.search(group: ExerciseGroup.legs), hasLength(227 + 59));
      expect(real.search(group: ExerciseGroup.arms), hasLength(292 + 37));
      expect(real.search(group: ExerciseGroup.cardio), hasLength(29));
    });

    test('Türkçe adımlarda görünmez karakter kalmadı', () {
      for (final e in real.all) {
        for (final s in e.stepsTr) {
          expect(s.contains('​'), isFalse, reason: e.name);
        }
      }
    });
  });
}
