import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

void main() {
  final cases = {
    'light': (AppTheme.light, AppColors.light, Brightness.light),
    'dark': (AppTheme.dark, AppColors.dark, Brightness.dark),
  };

  for (final e in cases.entries) {
    final (theme, colors, brightness) = e.value;

    group(e.key, () {
      test('zemin, brightness ve AppColors extension', () {
        expect(theme.brightness, brightness);
        expect(theme.scaffoldBackgroundColor, colors.canvas);
        expect(theme.extension<AppColors>(), same(colors));
      });

      test('ripple yok, highlight saydam', () {
        expect(theme.splashFactory, same(NoSplash.splashFactory));
        expect(theme.highlightColor, Colors.transparent);
      });

      test('bütün platformlarda Cupertino geçişi', () {
        for (final p in TargetPlatform.values) {
          expect(
            theme.pageTransitionsTheme.builders[p],
            isA<CupertinoPageTransitionsBuilder>(),
            reason: '$p',
          );
        }
      });

      test('Cupertino primaryColor ve imleç brand', () {
        expect(theme.cupertinoOverrideTheme!.primaryColor, colors.brand);
        expect(theme.textSelectionTheme.cursorColor, colors.brand);
        expect(theme.textSelectionTheme.selectionHandleColor, colors.brand);
      });

      test('ColorScheme token\'lardan: brand/onBrand, tek vurgu rengi', () {
        final s = theme.colorScheme;
        expect(s.primary, colors.brand);
        expect(s.onPrimary, colors.onBrand);
        expect(s.secondary, colors.brand);
        expect(s.surface, colors.surface);
        expect(s.onSurface, colors.textPrimary);
        expect(s.error, colors.error);
        expect(s.onError, colors.onError);
      });

      test('Material TextTheme: body, renk textPrimary, serif yok', () {
        final t = theme.textTheme;
        expect(t.bodyMedium!.fontSize, 17);
        expect(t.bodyMedium!.color, colors.textPrimary);
        for (final s in [
          t.bodyLarge,
          t.bodyMedium,
          t.bodySmall,
          t.labelLarge,
          t.titleMedium,
        ]) {
          expect(s!.fontFamily, isNot('Fraunces'));
        }
      });
    });
  }
}
