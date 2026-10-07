import 'package:flutter/widgets.dart';

/// Hareket token'ları (DESIGN_SYSTEM.md §12). Reduce Motion'a duyarlıdır:
/// erişim için [AppMotion.of] kullanılır.
@immutable
class AppMotion {
  const AppMotion._({
    required this.reduceMotion,
    required this.fast,
    required this.standard,
    required this.emphasis,
    required this.expressive,
    required this.springSnappy,
    required this.springStandard,
    required this.springBouncy,
  });

  /// Reduce Motion kapalı.
  static final AppMotion regular = AppMotion._(
    reduceMotion: false,
    fast: const Duration(milliseconds: 120),
    standard: const Duration(milliseconds: 200),
    emphasis: const Duration(milliseconds: 300),
    expressive: const Duration(milliseconds: 600),
    springSnappy: _spring(stiffness: 439, ratio: 0.9),
    springStandard: _spring(stiffness: 195, ratio: 0.85),
    springBouncy: _spring(stiffness: 158, ratio: 0.7),
  );

  /// Reduce Motion açık: süreler 0, spring'ler aynı stiffness ile overshoot'suz (kritik sönüm).
  static final AppMotion reduced = AppMotion._(
    reduceMotion: true,
    fast: Duration.zero,
    standard: Duration.zero,
    emphasis: Duration.zero,
    expressive: Duration.zero,
    springSnappy: _spring(stiffness: 439, ratio: 1),
    springStandard: _spring(stiffness: 195, ratio: 1),
    springBouncy: _spring(stiffness: 158, ratio: 1),
  );

  /// `MediaQuery.disableAnimationsOf` açıksa [reduced], değilse [regular].
  static AppMotion of(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context) ? reduced : regular;

  /// Component'lerin "uçmak yerine solsun" gibi dallanmaları için.
  final bool reduceMotion;

  /// Basma, renk değişimi, chip seçimi.
  final Duration fast;

  /// Fade, scrim, küçük layout değişimi.
  final Duration standard;

  /// Kart girişi, çıkışlar, ring ilerlemesi.
  final Duration emphasis;

  /// Yalnızca Agreement Arc dolumu ve karar anı adımları.
  final Duration expressive;

  /// Basma dönüşü, chip genişliği.
  final SpringDescription springSnappy;

  /// Sheet, kart dönüşü, toast.
  final SpringDescription springStandard;

  /// Yalnızca tamamlanma anları: ring ✓, karar anı.
  final SpringDescription springBouncy;

  /// Ekrana giren her şey.
  static const Cubic enter = Cubic(0.16, 1, 0.3, 1);

  /// Ekrandan çıkan her şey.
  static const Cubic exit = Cubic(0.4, 0, 1, 1);

  /// Ekranda yer değiştiren şeyler.
  static const Cubic move = Cubic(0.65, 0, 0.35, 1);

  static SpringDescription _spring({
    required double stiffness,
    required double ratio,
  }) {
    return SpringDescription.withDampingRatio(
      mass: 1,
      stiffness: stiffness,
      ratio: ratio,
    );
  }
}
