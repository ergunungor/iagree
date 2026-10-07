import 'dart:math' as math;

import 'package:flutter/painting.dart';

import 'app_elevation.dart';

/// Köşe yarıçapları (DESIGN_SYSTEM.md §6). Köşeler iOS continuous corner
/// ([RoundedSuperellipseBorder]) ile çizilir; ekran kodunda `BorderRadius.circular` yazılmaz.
abstract final class AppRadius {
  static const double xs = 6;
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static BorderRadius all(double radius) =>
      BorderRadius.all(Radius.circular(radius));

  /// Yalnızca üst köşeler (bottom sheet).
  static BorderRadius top(double radius) =>
      BorderRadius.vertical(top: Radius.circular(radius));

  static RoundedSuperellipseBorder border(
    double radius, {
    BorderSide side = BorderSide.none,
  }) {
    return RoundedSuperellipseBorder(borderRadius: all(radius), side: side);
  }

  static RoundedSuperellipseBorder topBorder(
    double radius, {
    BorderSide side = BorderSide.none,
  }) {
    return RoundedSuperellipseBorder(borderRadius: top(radius), side: side);
  }

  /// İç içe radius: iç radius = dış radius − padding (0'ın altına inmez).
  static double inner(double outer, double padding) =>
      math.max(0, outer - padding);

  /// Köşe + dolgu + elevation. [side] verilirse elevation'ın hairline'ını ezer.
  static ShapeDecoration decoration({
    required double radius,
    Color? color,
    BorderSide? side,
    AppElevationLevel? elevation,
  }) {
    return ShapeDecoration(
      color: color,
      shape: border(radius, side: side ?? elevation?.side ?? BorderSide.none),
      shadows: elevation?.shadows,
    );
  }
}
