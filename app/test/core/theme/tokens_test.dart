import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:vitax_app/core/theme/tokens.dart';

/// Tasarımın DESIGN.md dosyasındaki `colors:` bloğunu okur.
Map<String, String> designColors() {
  final f = File(
    '../tasarim/v2/stitch_vital_precision_health_tracker/vital_balance/DESIGN.md',
  );
  final m = <String, String>{};
  var inColors = false;
  for (final l in f.readAsLinesSync()) {
    if (l.startsWith('colors:')) {
      inColors = true;
      continue;
    }
    if (inColors && !l.startsWith('  ')) break;
    final r = RegExp(r"^\s{2}([a-z-]+):\s*'(#[0-9a-fA-F]{6})'").firstMatch(l);
    if (r != null) m[r.group(1)!] = r.group(2)!.toLowerCase();
  }
  return m;
}

String hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

void main() {
  final design = designColors();

  test('DESIGN.md okunabiliyor ve anahtar renkleri içeriyor', () {
    expect(design['primary'], isNotNull);
    expect(design.length, greaterThan(20));
  });

  test('VColors tasarımdaki renklerle birebir aynı', () {
    final expected = <String, Color>{
      'surface': VColors.surface,
      'background': VColors.background,
      'surface-container-lowest': VColors.surfaceContainerLowest,
      'surface-container-low': VColors.surfaceContainerLow,
      'surface-container': VColors.surfaceContainer,
      'surface-container-high': VColors.surfaceContainerHigh,
      'surface-container-highest': VColors.surfaceContainerHighest,
      'on-surface': VColors.onSurface,
      'on-surface-variant': VColors.onSurfaceVariant,
      'primary': VColors.primary,
      'primary-container': VColors.primaryContainer,
      'on-primary': VColors.onPrimary,
      'primary-fixed': VColors.primaryFixed,
      'secondary': VColors.secondary,
      'secondary-fixed': VColors.secondaryFixed,
      'tertiary': VColors.tertiary,
      'tertiary-fixed': VColors.tertiaryFixed,
      'error': VColors.error,
      'error-container': VColors.errorContainer,
      'outline-variant': VColors.outlineVariant,
    };
    expected.forEach((key, color) {
      expect(hex(color), design[key], reason: 'renk uyuşmuyor: $key');
    });
  });

  test('yazı ölçeği tasarımla uyumlu (Inter, boyut, kalınlık)', () {
    expect(VText.displayLg.fontFamily, 'Inter');
    expect(VText.displayLg.fontSize, 32);
    expect(VText.displayLg.fontWeight, FontWeight.w800);
    expect(VText.headlineLg.fontSize, 22);
    expect(VText.headlineMd.fontSize, 18);
    expect(VText.headlineMd.fontWeight, FontWeight.w700);
    expect(VText.bodyMd.fontSize, 14);
    expect(VText.labelMd.fontWeight, FontWeight.w600);
    expect(VText.labelCaps.fontSize, 11);
    expect(VText.microTag.fontSize, 10);
  });

  test('yarıçap ve boşluk değerleri tasarımla uyumlu', () {
    expect(VRadius.button, 10);
    expect(VRadius.card, 16);
    expect(VRadius.cardLg, 24);
    expect(VSpace.md, 16);
    expect(VSpace.lg, 20);
    expect(VSpace.gutter, 12);
    expect(VSpace.sm, 8);
    expect(VSpace.touchMin, 44);
  });
}
