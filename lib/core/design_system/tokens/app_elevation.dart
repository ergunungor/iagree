import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Tek bir elevation seviyesi: gölgeler ve (dark E1'de) hairline kenar.
@immutable
class AppElevationLevel {
  const AppElevationLevel({
    this.shadows = const [],
    this.side = BorderSide.none,
  });

  final List<BoxShadow> shadows;
  final BorderSide side;
}

/// Elevation seviyeleri (DESIGN_SYSTEM.md §7). Spread her zaman 0, gölge rengi #1C1917.
/// Tema brightness'ına göre [light] ya da [dark] seçilir.
@immutable
class AppElevation {
  const AppElevation({required this.e1, required this.e2, required this.e3});

  /// Kart.
  final AppElevationLevel e1;

  /// Toast, sürüklenen kart, scroll'daki CTA bölgesi.
  final AppElevationLevel e2;

  /// Sheet, modal (scrim ile birlikte).
  final AppElevationLevel e3;

  static const Color _warm = Color(0xFF1C1917);

  static final AppElevation light = AppElevation(
    e1: AppElevationLevel(
      shadows: [
        BoxShadow(
          color: _warm.withAlpha(0x0D),
          offset: const Offset(0, 1),
          blurRadius: 3,
        ),
        BoxShadow(
          color: _warm.withAlpha(0x0A),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ],
    ),
    e2: AppElevationLevel(
      shadows: [
        BoxShadow(
          color: _warm.withAlpha(0x14),
          offset: const Offset(0, 8),
          blurRadius: 24,
        ),
        BoxShadow(
          color: _warm.withAlpha(0x0A),
          offset: const Offset(0, 2),
          blurRadius: 6,
        ),
      ],
    ),
    e3: AppElevationLevel(
      shadows: [
        BoxShadow(
          color: _warm.withAlpha(0x1A),
          offset: const Offset(0, -4),
          blurRadius: 32,
        ),
      ],
    ),
  );

  static final AppElevation dark = AppElevation(
    e1: AppElevationLevel(side: BorderSide(color: AppColors.dark.border)),
    e2: const AppElevationLevel(
      shadows: [
        BoxShadow(
          color: Color(0x66000000),
          offset: Offset(0, 8),
          blurRadius: 24,
        ),
      ],
    ),
    e3: const AppElevationLevel(
      shadows: [
        BoxShadow(
          color: Color(0x73000000),
          offset: Offset(0, -4),
          blurRadius: 32,
        ),
      ],
    ),
  );
}
