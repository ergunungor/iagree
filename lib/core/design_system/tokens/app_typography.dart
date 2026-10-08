import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Tipografi token'ları (DESIGN_SYSTEM.md §4). Renk içermez; renk component'te verilir.
///
/// UI stillerinde `fontFamily` boş: iOS'ta sistem fontu (SF Pro). Fraunces yalnızca
/// [display] ve [h1]'de.
@immutable
class AppTypography {
  const AppTypography({
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.title,
    required this.body,
    required this.bodySmall,
    required this.label,
    required this.button,
    required this.buttonSmall,
    required this.caption,
    required this.overline,
    required this.arcNumberSmall,
    required this.arcNumberLarge,
  });

  /// display ve h1 için Dynamic Type üst sınırı.
  static const double displayMaxScale = 1.3;

  /// AgreementArc içindeki sayı için Dynamic Type üst sınırı.
  static const double arcNumberMaxScale = 1.5;

  static const String _displayFamily = 'Fraunces';

  static final AppTypography regular = AppTypography(
    display: _display(size: 40, lineHeight: 44, letterSpacing: -0.6),
    h1: _display(size: 32, lineHeight: 38, letterSpacing: -0.3),
    h2: _ui(
      size: 24,
      lineHeight: 30,
      weight: FontWeight.w700,
      letterSpacing: 0.07,
    ),
    h3: _ui(
      size: 20,
      lineHeight: 25,
      weight: FontWeight.w600,
      letterSpacing: 0.38,
    ),
    title: _ui(
      size: 17,
      lineHeight: 22,
      weight: FontWeight.w600,
      letterSpacing: -0.41,
    ),
    body: _ui(
      size: 17,
      lineHeight: 24,
      weight: FontWeight.w400,
      letterSpacing: -0.41,
    ),
    bodySmall: _ui(
      size: 15,
      lineHeight: 20,
      weight: FontWeight.w400,
      letterSpacing: -0.24,
    ),
    label: _ui(
      size: 15,
      lineHeight: 20,
      weight: FontWeight.w500,
      letterSpacing: -0.24,
    ),
    button: _ui(
      size: 17,
      lineHeight: 22,
      weight: FontWeight.w600,
      letterSpacing: -0.41,
    ),
    buttonSmall: _ui(
      size: 15,
      lineHeight: 20,
      weight: FontWeight.w600,
      letterSpacing: -0.24,
    ),
    caption: _ui(
      size: 13,
      lineHeight: 18,
      weight: FontWeight.w400,
      letterSpacing: -0.08,
    ),
    overline: _ui(
      size: 12,
      lineHeight: 16,
      weight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
    arcNumberSmall: _ui(
      size: 13,
      lineHeight: 18,
      weight: FontWeight.w600,
      letterSpacing: -0.08,
    ),
    arcNumberLarge: _ui(
      size: 34,
      lineHeight: 40,
      weight: FontWeight.w700,
      letterSpacing: 0.37,
    ),
  );

  /// Bold Text açıkken kullanılan, bir kez üretilen varyant.
  static final AppTypography boldText = regular.bold();

  final TextStyle display;
  final TextStyle h1;
  final TextStyle h2;
  final TextStyle h3;
  final TextStyle title;
  final TextStyle body;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle button;
  final TextStyle buttonSmall;
  final TextStyle caption;
  final TextStyle overline;

  /// AgreementArc S'nin yan yüzdesi (`caption` 600). tokens.json'da ayrı stil değildir.
  final TextStyle arcNumberSmall;

  /// AgreementArc L'nin yay içi yüzdesi (34 bold). M `title` kullanır.
  final TextStyle arcNumberLarge;

  /// Bold Text erişilebilirlik ayarı: bütün ağırlıklar +100 (en fazla 900).
  AppTypography bold() {
    return AppTypography(
      display: _bolder(display),
      h1: _bolder(h1),
      h2: _bolder(h2),
      h3: _bolder(h3),
      title: _bolder(title),
      body: _bolder(body),
      bodySmall: _bolder(bodySmall),
      label: _bolder(label),
      button: _bolder(button),
      buttonSmall: _bolder(buttonSmall),
      caption: _bolder(caption),
      overline: _bolder(overline),
      arcNumberSmall: _bolder(arcNumberSmall),
      arcNumberLarge: _bolder(arcNumberLarge),
    );
  }

  static TextStyle _ui({
    required double size,
    required double lineHeight,
    required FontWeight weight,
    required double letterSpacing,
  }) {
    return TextStyle(
      fontSize: size,
      height: lineHeight / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  static TextStyle _display({
    required double size,
    required double lineHeight,
    required double letterSpacing,
  }) {
    return TextStyle(
      fontFamily: _displayFamily,
      fontSize: size,
      height: lineHeight / size,
      fontWeight: FontWeight.w500,
      letterSpacing: letterSpacing,
      leadingDistribution: TextLeadingDistribution.even,
      fontVariations: const [
        FontVariation('SOFT', 50),
        FontVariation('WONK', 0),
        FontVariation('wght', 500),
      ],
    );
  }

  static TextStyle _bolder(TextStyle style) {
    final bolder = math.min(style.fontWeight!.value + 100, 900);
    final weight = FontWeight.values[bolder ~/ 100 - 1];
    return style.copyWith(
      fontWeight: weight,
      fontVariations: style.fontVariations
          ?.map(
            (v) => v.axis == 'wght'
                ? FontVariation('wght', math.min(v.value + 100, 900))
                : v,
          )
          .toList(),
    );
  }
}

extension AppTextStyleX on TextStyle {
  /// Puan, fiyat, mesafe, yüzde: sabit genişlikli rakamlar.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}
