import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_fixed_colors.dart';

/// docs/design-system/tokens.json ile kodlanan renklerin birebir eşleştiğini doğrular.
final Map<String, Color Function(AppColors)> _themed = {
  'canvas': (c) => c.canvas,
  'surface': (c) => c.surface,
  'surface-raised': (c) => c.surfaceRaised,
  'surface-muted': (c) => c.surfaceMuted,
  'surface-pressed': (c) => c.surfacePressed,
  'surface-input-focus': (c) => c.surfaceInputFocus,
  'track-off': (c) => c.trackOff,
  'text-primary': (c) => c.textPrimary,
  'text-secondary': (c) => c.textSecondary,
  'text-tertiary': (c) => c.textTertiary,
  'text-disabled': (c) => c.textDisabled,
  'border': (c) => c.border,
  'border-control': (c) => c.borderControl,
  'brand': (c) => c.brand,
  'brand-pressed': (c) => c.brandPressed,
  'on-brand': (c) => c.onBrand,
  'brand-soft': (c) => c.brandSoft,
  'on-brand-soft': (c) => c.onBrandSoft,
  'brand-muted': (c) => c.brandMuted,
  'success': (c) => c.success,
  'success-soft': (c) => c.successSoft,
  'warning': (c) => c.warning,
  'warning-soft': (c) => c.warningSoft,
  'error': (c) => c.error,
  'error-soft': (c) => c.errorSoft,
  'on-error': (c) => c.onError,
  'scrim': (c) => c.scrim,
  'avatar-sand': (c) => c.avatarSand,
  'avatar-sage': (c) => c.avatarSage,
  'avatar-mist': (c) => c.avatarMist,
  'avatar-rose': (c) => c.avatarRose,
  'avatar-lavender': (c) => c.avatarLavender,
  'focus-ring': (c) => c.focusRing,
};

const Map<String, Color> _fixed = {
  'moment-bg': AppFixedColors.momentBg,
  'moment-ink': AppFixedColors.momentInk,
  'moment-track': AppFixedColors.momentTrack,
  'moment-ghost': AppFixedColors.momentGhost,
  'inverse-surface': AppFixedColors.inverseSurface,
  'inverse-text': AppFixedColors.inverseText,
  'inverse-action': AppFixedColors.inverseAction,
  'inverse-success': AppFixedColors.inverseSuccess,
  'inverse-error': AppFixedColors.inverseError,
};

Color _parse(String hex, Map<String, dynamic> byName, String theme) {
  final alias = RegExp(r'^\{(.+)\}$').firstMatch(hex);
  if (alias != null) {
    return _parse(
      (byName[alias.group(1)]['value'] as Map)[theme] as String,
      byName,
      theme,
    );
  }
  final h = hex.substring(1);
  final rgb = int.parse(h.substring(0, 6), radix: 16);
  final alpha = h.length == 8 ? int.parse(h.substring(6), radix: 16) : 0xFF;
  return Color((alpha << 24) | rgb);
}

void main() {
  final json = jsonDecode(
    File('docs/design-system/tokens.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final tokens = (json['color'] as Map<String, dynamic>)['tokens'] as List;
  final byName = {
    for (final t in tokens) t['name'] as String: t as Map<String, dynamic>,
  };

  test('tokens.json içindeki her renk kodda karşılanıyor ve tersi', () {
    expect({..._themed.keys, ..._fixed.keys}, byName.keys.toSet());
  });

  for (final entry in byName.entries) {
    final name = entry.key;
    final value = entry.value['value'] as Map<String, dynamic>;

    test('$name light/dark değerleri', () {
      final light = _parse(value['light'] as String, byName, 'light');
      final dark = _parse(value['dark'] as String, byName, 'dark');
      if (_fixed.containsKey(name)) {
        expect(_fixed[name], light);
        expect(_fixed[name], dark);
      } else {
        expect(_themed[name]!(AppColors.light), light);
        expect(_themed[name]!(AppColors.dark), dark);
      }
    });
  }

  test('tokens.json dışı iki sabit (DESIGN_SYSTEM §10 Media ikon butonu)', () {
    expect(AppFixedColors.mediaOverlay, const Color(0x59000000));
    expect(AppFixedColors.onMedia, const Color(0xFFFFFFFF));
    // %35 siyah: alfa 0x59 = 89/255 ≈ 0,349.
    expect(AppFixedColors.mediaOverlay.a, closeTo(0.35, 0.005));
  });

  test('avatarTints sırası Kum, Adaçayı, Sis, Gül, Lavanta', () {
    expect(AppColors.light.avatarTints, [
      AppColors.light.avatarSand,
      AppColors.light.avatarSage,
      AppColors.light.avatarMist,
      AppColors.light.avatarRose,
      AppColors.light.avatarLavender,
    ]);
  });

  test('high contrast yalnızca textSecondary değiştirir', () {
    expect(AppColors.lightHighContrast.textSecondary, const Color(0xFF4A433E));
    expect(AppColors.darkHighContrast.textSecondary, const Color(0xFFD0C8CF));
    expect(AppColors.lightHighContrast.brand, AppColors.light.brand);
  });

  test('lerp uçlarda ilgili temayı döndürür', () {
    expect(
      AppColors.light.lerp(AppColors.dark, 0).canvas,
      AppColors.light.canvas,
    );
    expect(
      AppColors.light.lerp(AppColors.dark, 1).canvas,
      AppColors.dark.canvas,
    );
  });
}
