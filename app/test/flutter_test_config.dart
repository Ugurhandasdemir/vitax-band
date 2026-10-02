import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tüm testlerde gerçek Inter yazı tipini yükler (Ahem yerine).
/// Böylece metin ölçüleri cihazdakiyle aynı olur ve golden karşılaştırması anlamlı kalır.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  final loader = FontLoader('Inter');
  for (final w in ['Regular', 'SemiBold', 'Bold', 'ExtraBold']) {
    final Uint8List bytes = File('assets/fonts/Inter-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();

  // Material ikon yazı tipi: golden görüntülerde kare yerine gerçek ikon çıksın.
  final root =
      Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['HOME']}/development/flutter';
  final iconFile = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (iconFile.existsSync()) {
    final icons = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(iconFile.readAsBytesSync())));
    await icons.load();
  }

  // Phosphor ikon yazı tipleri: golden görüntülerde gerçek ikon çıksın.
  final pubCache =
      Platform.environment['PUB_CACHE'] ??
      '${Platform.environment['HOME']}/.pub-cache';
  final phosphorFonts = {
    'packages/phosphor_flutter/PhosphorRegular': 'Phosphor.ttf',
    'packages/phosphor_flutter/PhosphorFill': 'Phosphor-Fill.ttf',
    'packages/phosphor_flutter/PhosphorBold': 'Phosphor-Bold.ttf',
    'packages/phosphor_flutter/PhosphorLight': 'Phosphor-Light.ttf',
    'packages/phosphor_flutter/PhosphorThin': 'Phosphor-Thin.ttf',
    'packages/phosphor_flutter/PhosphorDuotone': 'Phosphor-Duotone.ttf',
  };
  final pubDevDir = Directory('$pubCache/hosted/pub.dev');
  if (pubDevDir.existsSync()) {
    final phosphorDirs = pubDevDir
        .listSync()
        .whereType<Directory>()
        .where((d) => d.path.split('/').last.startsWith('phosphor_flutter-'))
        .toList();
    if (phosphorDirs.isNotEmpty) {
      final pDir = phosphorDirs.first;
      for (final entry in phosphorFonts.entries) {
        final f = File('${pDir.path}/lib/fonts/${entry.value}');
        if (f.existsSync()) {
          final fl = FontLoader(entry.key)
            ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
          await fl.load();
        }
      }
    }
  }

  await testMain();
}
