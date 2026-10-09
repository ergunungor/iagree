import 'package:flutter/widgets.dart';

/// İkon boyutları (DESIGN_SYSTEM.md §8).
abstract final class AppIconSize {
  /// Caption içinde.
  static const double s14 = 14;

  /// Small buton, chip ✓.
  static const double s16 = 16;

  /// Large/Medium buton, search, liste satırı.
  static const double s20 = 20;

  /// Navigation bar.
  static const double s24 = 24;

  /// Empty ve error state.
  static const double s32 = 32;
}

/// Semantik ikon adları (DESIGN_SYSTEM.md §8). Ekranlar bu sınıf dışında ikon tanımlamaz.
///
/// Phosphor ikonları `phosphor_flutter` paketinin **font dosyalarıyla** çizilir; paketin Dart
/// kodu import edilmez (paket Flutter'ın `final class IconData`'sını extend ettiği için bu
/// Flutter sürümünde derlenmiyor). Kod noktaları paketin kaynağından alınmıştır ve
/// test/core/design_system/app_icons_test.dart ile paketin kaynağına karşı doğrulanır.
///
/// Varsayılan Regular; Fill yalnızca seçili/aktif durum için ve ihtiyaç doğdukça eklenir.
/// Renk yanındaki metinden miras alınır (`IconTheme`).
abstract final class AppIcons {
  static const String _package = 'phosphor_flutter';
  static const String _regular = 'PhosphorRegular';
  static const String _fill = 'PhosphorFill';

  /// Phosphor `camera` (regular).
  static const IconData camera = IconData(
    0xe10e,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `envelopeSimple` (regular).
  static const IconData mail = IconData(
    0xe218,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `export` (regular).
  static const IconData share = IconData(
    0xeaf0,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `arrowUUpLeft` (regular).
  static const IconData undo = IconData(
    0xe08a,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `check` (regular).
  static const IconData check = IconData(
    0xe182,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `x` (regular).
  static const IconData close = IconData(
    0xe4f6,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `heart` (regular).
  static const IconData heart = IconData(
    0xe2a8,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `heart` (fill).
  static const IconData heartFill = IconData(
    0xe2a8,
    fontFamily: _fill,
    fontPackage: _package,
  );

  /// Phosphor `prohibit` (regular).
  static const IconData prohibit = IconData(
    0xe3de,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `magnifyingGlass` (regular).
  static const IconData search = IconData(
    0xe30c,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `plus` (regular).
  static const IconData plus = IconData(
    0xe3d4,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `minus` (regular).
  static const IconData minus = IconData(
    0xe32a,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `caretLeft` (regular).
  static const IconData back = IconData(
    0xe138,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `caretRight` (regular).
  static const IconData chevronRight = IconData(
    0xe13a,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `caretUpDown` (regular).
  static const IconData upDown = IconData(
    0xe140,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `link` (regular).
  static const IconData link = IconData(
    0xe2e2,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `copy` (regular).
  static const IconData copy = IconData(
    0xe1ca,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `warning` (regular).
  static const IconData warning = IconData(
    0xe4e0,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `info` (regular).
  static const IconData info = IconData(
    0xe2ce,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `star` (regular).
  static const IconData star = IconData(
    0xe46a,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `star` (fill).
  static const IconData starFill = IconData(
    0xe46a,
    fontFamily: _fill,
    fontPackage: _package,
  );

  /// Phosphor `mapPin` (regular).
  static const IconData map = IconData(
    0xe316,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `userPlus` (regular).
  static const IconData userPlus = IconData(
    0xe4d0,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `wifiSlash` (regular).
  static const IconData wifiOff = IconData(
    0xe4f2,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `forkKnife` (regular).
  static const IconData food = IconData(
    0xe262,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `coffee` (regular).
  static const IconData coffee = IconData(
    0xe1c2,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `filmSlate` (regular).
  static const IconData film = IconData(
    0xe8c2,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `soccerBall` (regular).
  static const IconData sport = IconData(
    0xe716,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `martini` (regular).
  static const IconData bar = IconData(
    0xe31c,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `musicNotes` (regular).
  static const IconData concert = IconData(
    0xe340,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `gameController` (regular).
  static const IconData game = IconData(
    0xe26e,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `tree` (regular).
  static const IconData outdoor = IconData(
    0xe6da,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `bank` (regular).
  static const IconData culture = IconData(
    0xe0b4,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `shuffle` (regular).
  static const IconData anything = IconData(
    0xe422,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `cloudRain` (regular).
  static const IconData rain = IconData(
    0xe1b4,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `television` (regular).
  static const IconData tv = IconData(
    0xe754,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `moon` (regular).
  static const IconData moon = IconData(
    0xe330,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `dotsThree` (regular).
  static const IconData more = IconData(
    0xe1fe,
    fontFamily: _regular,
    fontPackage: _package,
  );

  /// Phosphor `pencilSimple` (regular).
  static const IconData edit = IconData(
    0xe3b4,
    fontFamily: _regular,
    fontPackage: _package,
  );
}
