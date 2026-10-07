import 'package:flutter/material.dart';

/// Temaya göre değişen renk token'ları. Değerler docs/design-system/tokens.json'dan birebir.
/// İki temada aynı olan renkler için bkz. [AppFixedColors].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceMuted,
    required this.surfacePressed,
    required this.surfaceInputFocus,
    required this.trackOff,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textDisabled,
    required this.border,
    required this.borderControl,
    required this.brand,
    required this.brandPressed,
    required this.onBrand,
    required this.brandSoft,
    required this.onBrandSoft,
    required this.brandMuted,
    required this.success,
    required this.successSoft,
    required this.warning,
    required this.warningSoft,
    required this.error,
    required this.errorSoft,
    required this.onError,
    required this.scrim,
    required this.avatarSand,
    required this.avatarSage,
    required this.avatarMist,
    required this.avatarRose,
    required this.avatarLavender,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceRaised;
  final Color surfaceMuted;
  final Color surfacePressed;
  final Color surfaceInputFocus;
  final Color trackOff;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textDisabled;
  final Color border;
  final Color borderControl;
  final Color brand;
  final Color brandPressed;
  final Color onBrand;
  final Color brandSoft;
  final Color onBrandSoft;
  final Color brandMuted;
  final Color success;
  final Color successSoft;
  final Color warning;
  final Color warningSoft;
  final Color error;
  final Color errorSoft;
  final Color onError;
  final Color scrim;
  final Color avatarSand;
  final Color avatarSage;
  final Color avatarMist;
  final Color avatarRose;
  final Color avatarLavender;

  /// Klavye/Switch Control odağı: 2px canvas boşluk + 2px brand halka.
  Color get focusRing => brand;

  /// Fotoğrafsız avatar zeminleri; sıra: Kum, Adaçayı, Sis, Gül, Lavanta.
  List<Color> get avatarTints => [
    avatarSand,
    avatarSage,
    avatarMist,
    avatarRose,
    avatarLavender,
  ];

  static const AppColors light = AppColors(
    canvas: Color(0xFFFAF7F2),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFF3EEE7),
    surfacePressed: Color(0xFFEAE3DA),
    surfaceInputFocus: Color(0xFFFFFFFF),
    trackOff: Color(0xFFEAE3DA),
    textPrimary: Color(0xFF1C1917),
    textSecondary: Color(0xFF5E5650),
    textTertiary: Color(0xFF6F665F),
    textDisabled: Color(0xFFB3AAA0),
    border: Color(0xFFE5DDD3),
    borderControl: Color(0xFF8F857A),
    brand: Color(0xFF6B2E63),
    brandPressed: Color(0xFF58254F),
    onBrand: Color(0xFFFFFFFF),
    brandSoft: Color(0xFFF4E8F1),
    onBrandSoft: Color(0xFF4E1F48),
    brandMuted: Color(0xFFB07AA8),
    success: Color(0xFF1F7A4D),
    successSoft: Color(0xFFE4F2EA),
    warning: Color(0xFF8A5300),
    warningSoft: Color(0xFFFBF0DA),
    error: Color(0xFFB42A23),
    errorSoft: Color(0xFFFBE8E6),
    onError: Color(0xFFFFFFFF),
    scrim: Color(0x661C1917),
    avatarSand: Color(0xFFEADFD3),
    avatarSage: Color(0xFFDCE3D5),
    avatarMist: Color(0xFFD9E0E8),
    avatarRose: Color(0xFFEBDCE0),
    avatarLavender: Color(0xFFE3DCEA),
  );

  static const AppColors dark = AppColors(
    canvas: Color(0xFF16131A),
    surface: Color(0xFF1F1B24),
    surfaceRaised: Color(0xFF29242E),
    surfaceMuted: Color(0xFF2B2630),
    surfacePressed: Color(0xFF37313C),
    surfaceInputFocus: Color(0xFF2B2630),
    trackOff: Color(0xFF3A3440),
    textPrimary: Color(0xFFF4EFF2),
    textSecondary: Color(0xFFB5ACB4),
    textTertiary: Color(0xFF9D949E),
    textDisabled: Color(0xFF5F5864),
    border: Color(0xFF38323E),
    borderControl: Color(0xFF7D7483),
    brand: Color(0xFFD59AD0),
    brandPressed: Color(0xFFC487BE),
    onBrand: Color(0xFF16131A),
    brandSoft: Color(0xFF3B2338),
    onBrandSoft: Color(0xFFF2D6EE),
    brandMuted: Color(0xFF8A5A85),
    success: Color(0xFF52C48D),
    successSoft: Color(0xFF17301F),
    warning: Color(0xFFEDB24E),
    warningSoft: Color(0xFF33280F),
    error: Color(0xFFFF7F76),
    errorSoft: Color(0xFF3B1B1B),
    onError: Color(0xFF16131A),
    scrim: Color(0x8C000000),
    avatarSand: Color(0xFF3A332C),
    avatarSage: Color(0xFF2F362D),
    avatarMist: Color(0xFF2D333B),
    avatarRose: Color(0xFF3A2E32),
    avatarLavender: Color(0xFF342E3D),
  );

  /// Increase Contrast: yalnızca textSecondary koyulaşır (DESIGN_SYSTEM.md §14).
  static final AppColors lightHighContrast = light.copyWith(
    textSecondary: const Color(0xFF4A433E),
  );
  static final AppColors darkHighContrast = dark.copyWith(
    textSecondary: const Color(0xFFD0C8CF),
  );

  @override
  AppColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceMuted,
    Color? surfacePressed,
    Color? surfaceInputFocus,
    Color? trackOff,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textDisabled,
    Color? border,
    Color? borderControl,
    Color? brand,
    Color? brandPressed,
    Color? onBrand,
    Color? brandSoft,
    Color? onBrandSoft,
    Color? brandMuted,
    Color? success,
    Color? successSoft,
    Color? warning,
    Color? warningSoft,
    Color? error,
    Color? errorSoft,
    Color? onError,
    Color? scrim,
    Color? avatarSand,
    Color? avatarSage,
    Color? avatarMist,
    Color? avatarRose,
    Color? avatarLavender,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfacePressed: surfacePressed ?? this.surfacePressed,
      surfaceInputFocus: surfaceInputFocus ?? this.surfaceInputFocus,
      trackOff: trackOff ?? this.trackOff,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textDisabled: textDisabled ?? this.textDisabled,
      border: border ?? this.border,
      borderControl: borderControl ?? this.borderControl,
      brand: brand ?? this.brand,
      brandPressed: brandPressed ?? this.brandPressed,
      onBrand: onBrand ?? this.onBrand,
      brandSoft: brandSoft ?? this.brandSoft,
      onBrandSoft: onBrandSoft ?? this.onBrandSoft,
      brandMuted: brandMuted ?? this.brandMuted,
      success: success ?? this.success,
      successSoft: successSoft ?? this.successSoft,
      warning: warning ?? this.warning,
      warningSoft: warningSoft ?? this.warningSoft,
      error: error ?? this.error,
      errorSoft: errorSoft ?? this.errorSoft,
      onError: onError ?? this.onError,
      scrim: scrim ?? this.scrim,
      avatarSand: avatarSand ?? this.avatarSand,
      avatarSage: avatarSage ?? this.avatarSage,
      avatarMist: avatarMist ?? this.avatarMist,
      avatarRose: avatarRose ?? this.avatarRose,
      avatarLavender: avatarLavender ?? this.avatarLavender,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfacePressed: Color.lerp(surfacePressed, other.surfacePressed, t)!,
      surfaceInputFocus: Color.lerp(
        surfaceInputFocus,
        other.surfaceInputFocus,
        t,
      )!,
      trackOff: Color.lerp(trackOff, other.trackOff, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textDisabled: Color.lerp(textDisabled, other.textDisabled, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderControl: Color.lerp(borderControl, other.borderControl, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      brandPressed: Color.lerp(brandPressed, other.brandPressed, t)!,
      onBrand: Color.lerp(onBrand, other.onBrand, t)!,
      brandSoft: Color.lerp(brandSoft, other.brandSoft, t)!,
      onBrandSoft: Color.lerp(onBrandSoft, other.onBrandSoft, t)!,
      brandMuted: Color.lerp(brandMuted, other.brandMuted, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSoft: Color.lerp(successSoft, other.successSoft, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSoft: Color.lerp(warningSoft, other.warningSoft, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      onError: Color.lerp(onError, other.onError, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      avatarSand: Color.lerp(avatarSand, other.avatarSand, t)!,
      avatarSage: Color.lerp(avatarSage, other.avatarSage, t)!,
      avatarMist: Color.lerp(avatarMist, other.avatarMist, t)!,
      avatarRose: Color.lerp(avatarRose, other.avatarRose, t)!,
      avatarLavender: Color.lerp(avatarLavender, other.avatarLavender, t)!,
    );
  }
}
