import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/foundations/context_extensions.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_elevation.dart';
import 'package:iagree/core/design_system/tokens/app_motion.dart';
import 'package:iagree/core/design_system/tokens/app_typography.dart';

Future<BuildContext> _pump(
  WidgetTester tester, {
  required ThemeData theme,
  MediaQueryData media = const MediaQueryData(),
}) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MediaQuery(
      data: media,
      child: MaterialApp(
        theme: theme,
        home: Builder(
          builder: (c) {
            captured = c;
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  // Tema değişimi AnimatedTheme ile geçiş yapar; bitmesini bekle.
  await tester.pumpAndSettle();
  return captured;
}

void main() {
  testWidgets('colors: temaya göre', (tester) async {
    expect(
      (await _pump(tester, theme: AppTheme.light)).colors,
      same(AppColors.light),
    );
    expect(
      (await _pump(tester, theme: AppTheme.dark)).colors,
      same(AppColors.dark),
    );
  });

  testWidgets('colors: Increase Contrast yüksek kontrastlı varyantı seçer', (
    tester,
  ) async {
    const hc = MediaQueryData(highContrast: true);
    expect(
      (await _pump(tester, theme: AppTheme.light, media: hc)).colors,
      same(AppColors.lightHighContrast),
    );
    expect(
      (await _pump(tester, theme: AppTheme.dark, media: hc)).colors,
      same(AppColors.darkHighContrast),
    );
  });

  testWidgets('text: Bold Text ağırlıkları artırır', (tester) async {
    final normal = await _pump(tester, theme: AppTheme.light);
    expect(normal.text, same(AppTypography.regular));
    final bold = await _pump(
      tester,
      theme: AppTheme.light,
      media: const MediaQueryData(boldText: true),
    );
    expect(bold.text, same(AppTypography.boldText));
    expect(bold.text.body.fontWeight, FontWeight.w500);
  });

  testWidgets('motion: Reduce Motion', (tester) async {
    expect(
      (await _pump(tester, theme: AppTheme.light)).motion,
      same(AppMotion.regular),
    );
    final reduced = await _pump(
      tester,
      theme: AppTheme.light,
      media: const MediaQueryData(disableAnimations: true),
    );
    expect(reduced.motion, same(AppMotion.reduced));
  });

  testWidgets('elevation: dark\'ta E1 hairline', (tester) async {
    expect(
      (await _pump(tester, theme: AppTheme.light)).elevation,
      same(AppElevation.light),
    );
    expect(
      (await _pump(tester, theme: AppTheme.dark)).elevation,
      same(AppElevation.dark),
    );
  });
}
