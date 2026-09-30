import 'dart:convert';

import '../core/text_search.dart';

const mediaAttribution = '© Gym visual — https://gymvisual.com/';

const _mediaBase =
    'https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/';

const _bodyPartTr = {
  'chest': 'Göğüs',
  'back': 'Sırt',
  'shoulders': 'Omuz',
  'upper arms': 'Üst Kol',
  'lower arms': 'Ön Kol',
  'upper legs': 'Üst Bacak',
  'lower legs': 'Alt Bacak',
  'waist': 'Karın',
  'cardio': 'Kardiyo',
  'neck': 'Boyun',
};

const _equipmentTr = {
  'body weight': 'Vücut Ağırlığı',
  'dumbbell': 'Dumbbell',
  'cable': 'Kablo',
  'barbell': 'Halter',
  'leverage machine': 'Makine',
  'band': 'Direnç Bandı',
  'smith machine': 'Smith Makinesi',
  'kettlebell': 'Kettlebell',
  'weighted': 'Ağırlıklı',
  'stability ball': 'Denge Topu',
  'ez barbell': 'EZ Bar',
  'assisted': 'Destekli',
  'sled machine': 'Kızak Makinesi',
  'medicine ball': 'Sağlık Topu',
  'roller': 'Masaj Silindiri',
  'rope': 'Halat',
  'olympic barbell': 'Olimpik Halter',
  'bosu ball': 'Bosu Topu',
  'resistance band': 'Direnç Bandı',
  'trap bar': 'Trap Bar',
  'wheel roller': 'Karın Tekeri',
  'hammer': 'Çekiç',
  'tire': 'Lastik',
  'skierg machine': 'SkiErg',
  'stepmill machine': 'Merdiven Makinesi',
  'elliptical machine': 'Eliptik',
  'stationary bike': 'Sabit Bisiklet',
  'upper body ergometer': 'Üst Vücut Ergometresi',
};

const _muscleTr = {
  'abs': 'Karın',
  'pectorals': 'Göğüs',
  'chest': 'Göğüs',
  'biceps': 'Biseps',
  'triceps': 'Triseps',
  'glutes': 'Kalça',
  'delts': 'Omuz',
  'shoulders': 'Omuz',
  'upper back': 'Üst Sırt',
  'lats': 'Latissimus',
  'calves': 'Baldır',
  'quads': 'Ön Bacak',
  'quadriceps': 'Ön Bacak',
  'hamstrings': 'Arka Bacak',
  'forearms': 'Ön Kol',
  'cardiovascular system': 'Kardiyovasküler',
  'obliques': 'Yan Karın',
  'hip flexors': 'Kalça Fleksörleri',
  'trapezius': 'Trapez',
  'traps': 'Trapez',
  'spine': 'Omurga',
  'adductors': 'İç Bacak',
  'abductors': 'Dış Bacak',
  'levator scapulae': 'Kürek Kaldırıcı',
  'serratus anterior': 'Serratus',
  'lower back': 'Bel',
  'rhomboids': 'Romboid',
  'rotator cuff': 'Rotator Manşet',
  'core': 'Merkez Bölge',
  'groin': 'Kasık',
  'brachialis': 'Brakialis',
  'wrist flexors': 'Bilek Fleksörleri',
  'wrist extensors': 'Bilek Ekstansörleri',
  'deltoids': 'Omuz',
  'latissimus dorsi': 'Latissimus',
  'hamstring': 'Arka Bacak',
  'quadriceps femoris': 'Ön Bacak',
  'ankle stabilizers': 'Ayak Bileği',
  'ankles': 'Ayak Bileği',
  'feet': 'Ayak',
  'hands': 'El',
  'inner thighs': 'İç Bacak',
  'shins': 'Kaval',
  'neck': 'Boyun',
  'upper chest': 'Üst Göğüs',
  'lower abs': 'Alt Karın',
  'sternocleidomastoid': 'Boyun Yan',
};

String _title(String s) => s
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// Sözlükte varsa Türkçe etiket, yoksa İngilizce baş harfleri büyük hâli.
String labelTr(String key, Map<String, String> dict) =>
    dict[key] ?? _title(key);

/// Ekipman anahtarı için Türkçe etiket.
String equipmentLabelTr(String key) => labelTr(key, _equipmentTr);

/// Kütüphane filtre grupları (tasarımdaki çipler).
enum ExerciseGroup {
  all('Tümü'),
  chest('Göğüs'),
  back('Sırt'),
  legs('Bacak'),
  arms('Kol'),
  shoulders('Omuz'),
  abs('Karın'),
  cardio('Kardiyo');

  const ExerciseGroup(this.label);
  final String label;

  bool matches(String bodyPart) => switch (this) {
    ExerciseGroup.all => true,
    ExerciseGroup.chest => bodyPart == 'chest',
    ExerciseGroup.back => bodyPart == 'back',
    ExerciseGroup.legs => bodyPart == 'upper legs' || bodyPart == 'lower legs',
    ExerciseGroup.arms => bodyPart == 'upper arms' || bodyPart == 'lower arms',
    ExerciseGroup.shoulders => bodyPart == 'shoulders',
    ExerciseGroup.abs => bodyPart == 'waist',
    ExerciseGroup.cardio => bodyPart == 'cardio',
  };
}

class Exercise {
  Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.equipment,
    required this.target,
    required this.muscle,
    required this.secondary,
    required this.stepsTr,
    required this.stepsEn,
    required this.imagePath,
    required this.gifPath,
  }) : _haystack = normalizeTr(
         [
           name,
           labelTr(bodyPart, _bodyPartTr),
           bodyPart,
           labelTr(equipment, _equipmentTr),
           equipment,
           labelTr(target, _muscleTr),
           target,
           labelTr(muscle, _muscleTr),
           muscle,
         ].join(' '),
       );

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
    id: j['id'] as String,
    name: j['name'] as String,
    bodyPart: j['bodyPart'] as String,
    equipment: j['equipment'] as String,
    target: j['target'] as String,
    muscle: (j['muscle'] as String?) ?? '',
    secondary: List<String>.from(j['secondary'] as List? ?? const []),
    stepsTr: List<String>.from(j['stepsTr'] as List? ?? const []),
    stepsEn: List<String>.from(j['stepsEn'] as List? ?? const []),
    imagePath: j['image'] as String,
    gifPath: j['gif'] as String,
  );

  final String id;
  final String name;
  final String bodyPart;
  final String equipment;
  final String target;
  final String muscle;
  final List<String> secondary;
  final List<String> stepsTr;
  final List<String> stepsEn;
  final String imagePath;
  final String gifPath;
  final String _haystack;

  String get displayName => _title(name);
  String get bodyPartTr => labelTr(bodyPart, _bodyPartTr);
  String get equipmentTr => labelTr(equipment, _equipmentTr);
  String get targetTr => labelTr(target, _muscleTr);
  String get muscleTr => labelTr(muscle, _muscleTr);
  List<String> get secondaryTr => [
    for (final s in secondary) labelTr(s, _muscleTr),
  ];
  String get gifUrl => '$_mediaBase$gifPath';
  String get imageUrl => '$_mediaBase$imagePath';
}

class ExerciseCatalog {
  ExerciseCatalog(this.all) : _byId = {for (final e in all) e.id: e};

  factory ExerciseCatalog.fromJson(String source) => ExerciseCatalog([
    for (final j in (jsonDecode(source) as List))
      Exercise.fromJson(j as Map<String, dynamic>),
  ]);

  final List<Exercise> all;
  final Map<String, Exercise> _byId;

  Exercise? byId(String id) => _byId[id];

  /// Ekipman adları (İngilizce anahtar), benzersiz ve sıralı.
  List<String> get equipmentList =>
      (all.map((e) => e.equipment).toSet().toList()..sort());

  List<Exercise> search({
    String query = '',
    ExerciseGroup group = ExerciseGroup.all,
    String? equipment,
  }) {
    final q = normalizeTr(query);
    final r = all.where((e) {
      if (!group.matches(e.bodyPart)) return false;
      if (equipment != null && e.equipment != equipment) return false;
      return q.isEmpty || e._haystack.contains(q);
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    return r;
  }
}
