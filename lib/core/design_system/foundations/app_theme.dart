import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';

/// Light ve dark `ThemeData` (DESIGN_SYSTEM.md §15).
///
/// Bold Text ve Increase Contrast bu katmanda uygulanmaz (tema `MediaQuery` olmadan kurulur);
/// ekranlar bunları `context.text` ve `context.colors` üzerinden alır.
abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light, AppColors.light);
  static final ThemeData dark = _build(Brightness.dark, AppColors.dark);

  static ThemeData _build(Brightness brightness, AppColors c) {
    final text = AppTypography.regular;
    // Fraunces hiçbir Material yuvasına bağlanmaz; yalnızca display ve h1'de kullanılır.
    final textTheme = TextTheme(
      bodyLarge: text.body,
      bodyMedium: text.body,
      bodySmall: text.bodySmall,
      labelLarge: text.label,
      titleMedium: text.title,
    ).apply(bodyColor: c.textPrimary, displayColor: c.textPrimary);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: c.brand,
        onPrimary: c.onBrand,
        // Tek vurgu rengi kuralı: secondary de brand.
        secondary: c.brand,
        onSecondary: c.onBrand,
        error: c.error,
        onError: c.onError,
        surface: c.surface,
        onSurface: c.textPrimary,
        outline: c.borderControl,
        outlineVariant: c.border,
        surfaceTint: Colors.transparent,
      ),
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      dividerColor: c.border,
      textTheme: textTheme,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const CupertinoPageTransitionsBuilder(),
        },
      ),
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: brightness,
        primaryColor: c.brand,
        primaryContrastingColor: c.onBrand,
        scaffoldBackgroundColor: c.canvas,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.brand,
        selectionColor: c.brand.withAlpha(0x4D),
        selectionHandleColor: c.brand,
      ),
      extensions: [c],
    );
  }
}
