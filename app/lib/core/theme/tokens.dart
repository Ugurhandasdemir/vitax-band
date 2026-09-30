import 'package:flutter/painting.dart';

/// Renkler: tasarım/v2/.../vital_balance/DESIGN.md ile birebir (tokens_test doğrular).
class VColors {
  VColors._();
  static const surface = Color(0xFFFBF8FF);
  static const background = Color(0xFFFBF8FF);
  static const surfaceDim = Color(0xFFDAD9E3);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF4F2FD);
  static const surfaceContainer = Color(0xFFEEEDF7);
  static const surfaceContainerHigh = Color(0xFFE8E7F1);
  static const surfaceContainerHighest = Color(0xFFE3E1EB);
  static const onSurface = Color(0xFF1A1B22);
  static const onSurfaceVariant = Color(0xFF5B4139);
  static const inverseSurface = Color(0xFF2F3037);
  static const inverseOnSurface = Color(0xFFF1EFFA);
  static const outline = Color(0xFF8F7067);
  static const outlineVariant = Color(0xFFE3BEB4);
  static const primary = Color(0xFFA83100);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFFD34000);
  static const onPrimaryContainer = Color(0xFFFFFBFF);
  static const primaryFixed = Color(0xFFFFDBD0);
  static const onPrimaryFixed = Color(0xFF3A0B00);
  static const secondary = Color(0xFF0060AB);
  static const onSecondary = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF6EAEFF);
  static const secondaryFixed = Color(0xFFD3E3FF);
  static const onSecondaryFixed = Color(0xFF001C39);
  static const tertiary = Color(0xFF016A34);
  static const onTertiary = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF2B844B);
  static const tertiaryFixed = Color(0xFF9DF6B1);
  static const onTertiaryFixed = Color(0xFF00210C);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
}

TextStyle _t(double size, FontWeight w, double lh, double lsEm) => TextStyle(
  fontFamily: 'Inter',
  fontSize: size,
  fontWeight: w,
  height: lh / size,
  letterSpacing: size * lsEm,
  color: VColors.onSurface,
);

class VText {
  VText._();
  static final displayLg = _t(32, FontWeight.w800, 38, -0.03);
  static final headlineLg = _t(22, FontWeight.w700, 28, -0.02);
  static final headlineMd = _t(18, FontWeight.w700, 24, -0.015);
  static final bodyLg = _t(16, FontWeight.w400, 24, -0.01);
  static final bodyLgMedium = _t(16, FontWeight.w500, 24, -0.01);
  static final bodyMd = _t(14, FontWeight.w400, 20, 0);
  static final bodyMdMedium = _t(14, FontWeight.w500, 20, 0);
  static final labelMd = _t(14, FontWeight.w600, 18, 0.01);
  static final labelCaps = _t(11, FontWeight.w700, 14, 0.08);
  static final microTag = _t(10, FontWeight.w700, 12, 0.04);
}

class VRadius {
  VRadius._();
  static const double sm = 4;
  static const double base = 8;
  static const double button = 10;
  static const double md = 12;
  static const double card = 16;
  static const double cardLg = 24;
  static const double pill = 9999;
}

class VSpace {
  VSpace._();
  static const double xs = 4;
  static const double sm = 8;
  static const double gutter = 12;
  static const double md = 16;
  static const double margin = 16;
  static const double lg = 20;
  static const double touchMin = 44;
}
