import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/foundations/app_pressable.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/gallery/design_system_gallery.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester, {
  bool? dark,
  double scale = 1,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQueryData.fromView(View.of(context))
            .copyWith(disableAnimations: reduceMotion),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: DesignSystemGallery(initialDark: dark, initialTextScale: scale),
        ),
      ),
    ),
  );
}

void main() {
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'galeri taşma olmadan açılır: ${dark ? 'dark' : 'light'}, textScale $scale',
        (tester) async {
          await _pump(tester, dark: dark, scale: scale);
          expect(tester.takeException(), isNull);
          expect(find.text('Tipografi'), findsOneWidget);
        },
      );
    }
  }

  for (final dark in [false, true]) {
    testWidgets(
      'Reduce Motion açıkken galeri çökmeden açılır (${dark ? 'dark' : 'light'})',
      (tester) async {
        await _pump(tester, dark: dark, reduceMotion: true);
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('galerideki bütün AppPressable\'lar en az 44×44', (tester) async {
    await _pump(tester, dark: false);
    final small = <String>[];
    for (final e in find.byType(AppPressable, skipOffstage: false).evaluate()) {
      final size = (e.renderObject! as RenderBox).size;
      if (size.width < 44 || size.height < 44) {
        small.add('${(e.widget as AppPressable).semanticLabel}: $size');
      }
    }
    expect(small, isEmpty);
  });

  testWidgets('tokens.json\'daki her renk için bir swatch var', (tester) async {
    await _pump(tester, dark: false);
    final json = jsonDecode(
      File('docs/design-system/tokens.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final names = [
      for (final t in (json['color'] as Map)['tokens'] as List)
        t['name'] as String,
    ];
    String camel(String n) {
      final p = n.split('-');
      return p.first +
          p.skip(1).map((x) => x[0].toUpperCase() + x.substring(1)).join();
    }

    for (final n in names) {
      expect(
        find.byKey(ValueKey('swatch-${camel(n)}'), skipOffstage: false),
        findsOneWidget,
        reason: n,
      );
    }
  });

  testWidgets('tema anahtarı galerinin renklerini değiştirir', (tester) async {
    await _pump(tester, dark: false);
    Color canvas() =>
        Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor;
    expect(canvas(), AppColors.light.canvas);
    await tester.tap(find.byType(CupertinoSwitch).first);
    await tester.pump();
    expect(canvas(), AppColors.dark.canvas);
  });
}
