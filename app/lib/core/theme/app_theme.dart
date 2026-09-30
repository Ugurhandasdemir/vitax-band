import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: VColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        surface: VColors.surface,
        primary: VColors.primary,
        onPrimary: VColors.onPrimary,
        primaryContainer: VColors.primaryContainer,
        onPrimaryContainer: VColors.onPrimaryContainer,
        secondary: VColors.secondary,
        tertiary: VColors.tertiary,
        error: VColors.error,
        onSurface: VColors.onSurface,
        onSurfaceVariant: VColors.onSurfaceVariant,
        outlineVariant: VColors.outlineVariant,
      );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: VColors.background,
    fontFamily: 'Inter',
    textTheme: TextTheme(
      displayLarge: VText.displayLg,
      headlineLarge: VText.headlineLg,
      headlineMedium: VText.headlineMd,
      bodyLarge: VText.bodyLg,
      bodyMedium: VText.bodyMd,
      labelLarge: VText.labelMd,
      labelSmall: VText.labelCaps,
    ),
    splashFactory: NoSplash.splashFactory,
    dividerColor: VColors.surfaceContainerHighest,
  );
}
