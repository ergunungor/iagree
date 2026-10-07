import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/brand/app_logo.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_fixed_colors.dart';

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

List<double> _nums(String d) =>
    RegExp(r'-?\d+(\.\d+)?')
        .allMatches(d)
        .map((m) => double.parse(m[0]!))
        .toList();

List<double> _flat(List<Offset> points) => [
  for (final p in points) ...[p.dx, p.dy],
];

/// `<path d="..." stroke="#...">` girdilerini {stroke rengi|d} olarak toplar.
Map<String, String> _paths(String svg) => {
  for (final m in RegExp(
    r'<path d="([^"]+)"[^>]*stroke="(#[0-9a-f]{6})"',
  ).allMatches(svg))
    '${m[2]}|${m[1]}': m[1]!,
};

Future<void> _pump(
  WidgetTester tester,
  Widget logo, {
  bool dark = false,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(body: Center(child: logo)),
      ),
    ),
  );
}

AppLogoMarkPainter _painter(WidgetTester tester) =>
    tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byType(AppLogo),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter!
        as AppLogoMarkPainter;

void main() {
  group('geometri assets/logo SVG\'leriyle aynı', () {
    final twoTone = File('assets/logo/iagree-mark-two-tone.svg')
        .readAsStringSync();
    final ink = File('assets/logo/iagree-mark-ink.svg').readAsStringSync();

    test('twoTone: nokta, ✓, bacak, çizgi, kalınlık ve renkler', () {
      final dot = RegExp(
        r'<circle cx="([\d.]+)" cy="([\d.]+)" r="([\d.]+)" fill="(#[0-9a-f]{6})"',
      ).firstMatch(twoTone)!;
      expect(
        Offset(double.parse(dot[1]!), double.parse(dot[2]!)),
        AppLogoMarkPainter.dotCenter,
      );
      expect(double.parse(dot[3]!), AppLogoMarkPainter.dotRadius);
      expect(dot[4], _hex(AppColors.light.brand));

      expect(
        RegExp(r'viewBox="0 0 (\d+) (\d+)"').firstMatch(twoTone)![1],
        '${AppLogoMarkPainter.viewBox.toInt()}',
      );
      expect(
        RegExp(r'stroke-width="(\d+)"')
            .allMatches(twoTone)
            .map((m) => double.parse(m[1]!))
            .toSet(),
        {AppLogoMarkPainter.strokeWidth},
      );

      final byKey = _paths(twoTone);
      final check = byKey.entries.firstWhere(
        (e) => e.key.startsWith('#6b2e63'),
      );
      final others = byKey.entries
          .where((e) => e.key.startsWith('#1c1917'))
          .map((e) => _nums(e.value))
          .toList();
      expect(_nums(check.value), _flat(AppLogoMarkPainter.check));
      expect(
        others,
        containsAll([
          _flat(AppLogoMarkPainter.leg),
          _flat(AppLogoMarkPainter.bar),
        ]),
      );
      expect(check.key.startsWith(_hex(AppColors.light.brand)), isTrue);
      expect(
        byKey.keys.any((k) => k.startsWith(_hex(AppColors.light.textPrimary))),
        isTrue,
      );
    });

    test('ink: ✓ ile sağ bacak tek yol, tek renk textPrimary', () {
      final entries = _paths(ink).entries.toList();
      final joined = entries.firstWhere((e) => _nums(e.value).length == 8);
      expect(_nums(joined.value), [
        ..._flat(AppLogoMarkPainter.check),
        ...AppLogoMarkPainter.leg.last.dx.let(
          (_) => _flat([AppLogoMarkPainter.leg.last]),
        ),
      ]);
      expect(entries.map((e) => e.key.split('|').first).toSet(), {
        _hex(AppColors.light.textPrimary),
      });
    });

    test('cream ve plumLight renkleri SVG hex\'leri', () {
      final cream = File('assets/logo/iagree-mark-cream.svg')
          .readAsStringSync();
      final plum = File('assets/logo/iagree-mark-plum-light.svg')
          .readAsStringSync();
      expect(
        RegExp(r'fill="(#[0-9a-f]{6})"').firstMatch(cream)![1],
        _hex(AppFixedColors.momentInk),
      );
      expect(
        RegExp(r'fill="(#[0-9a-f]{6})"').firstMatch(plum)![1],
        _hex(AppColors.dark.brand),
      );
    });
  });

  group('renkler', () {
    testWidgets('twoTone: i ve ✓ brand, kalanı textPrimary', (tester) async {
      await _pump(tester, const AppLogo(variant: AppLogoVariant.twoTone));
      expect(_painter(tester).accent, AppColors.light.brand);
      expect(_painter(tester).base, AppColors.light.textPrimary);
    });

    testWidgets('ink / cream / plumLight tek renk', (tester) async {
      await _pump(tester, const AppLogo(variant: AppLogoVariant.ink));
      expect([
        _painter(tester).accent,
        _painter(tester).base,
      ], everyElement(AppColors.light.textPrimary));
      await _pump(tester, const AppLogo(variant: AppLogoVariant.cream));
      expect([
        _painter(tester).accent,
        _painter(tester).base,
      ], everyElement(AppFixedColors.momentInk));
      await _pump(tester, const AppLogo(variant: AppLogoVariant.plumLight));
      expect([
        _painter(tester).accent,
        _painter(tester).base,
      ], everyElement(AppColors.dark.brand));
    });

    testWidgets('auto: light → twoTone, dark → plumLight', (tester) async {
      await _pump(tester, const AppLogo.auto());
      expect(_painter(tester).accent, AppColors.light.brand);
      expect(_painter(tester).base, AppColors.light.textPrimary);
      await _pump(tester, const AppLogo.auto(), dark: true);
      await tester.pumpAndSettle();
      expect(_painter(tester).accent, AppColors.dark.brand);
      expect(_painter(tester).base, AppColors.dark.brand);
    });
  });

  group('boyut, wordmark, semantics', () {
    testWidgets('size işaretin kenarı; wordmark metin boyutu size/1,3', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppLogo(variant: AppLogoVariant.twoTone, size: 48),
      );
      expect(tester.getSize(find.byType(CustomPaint).last), const Size(48, 48));
      await _pump(
        tester,
        const AppLogo(
          variant: AppLogoVariant.twoTone,
          size: 52,
          wordmark: true,
        ),
      );
      final style = tester.widget<Text>(find.text('iAgree')).style!;
      expect(style.fontSize, closeTo(52 / 1.3, 1e-9));
    });

    testWidgets('wordmark: "iAgree", Fraunces 500, büyük harfe çevrilmez', (
      tester,
    ) async {
      await _pump(tester, const AppLogo.auto(wordmark: true));
      final style = tester.widget<Text>(find.text('iAgree')).style!;
      expect(style.fontFamily, 'Fraunces');
      expect(style.fontWeight, FontWeight.w500);
      expect(find.text('iAgree'), findsOneWidget);
    });

    testWidgets(
      'wordmark Dynamic Type\'a bağlı değil, Bold Text\'ten etkilenmez',
      (tester) async {
        await _pump(tester, const AppLogo.auto(wordmark: true));
        final h = tester.getSize(find.byType(AppLogo));
        await _pump(tester, const AppLogo.auto(wordmark: true), textScale: 2);
        expect(tester.getSize(find.byType(AppLogo)), h);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('semantics: tek öğe, etiket iAgree', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const AppLogo.auto(wordmark: true));
      expect(tester.getSemantics(find.byType(AppLogo)).label, 'iAgree');
      handle.dispose();
    });

    test('shouldRepaint yalnızca renk değişince', () {
      const a = AppLogoMarkPainter(accent: Colors.red, base: Colors.blue);
      expect(
        a.shouldRepaint(
          const AppLogoMarkPainter(accent: Colors.red, base: Colors.blue),
        ),
        isFalse,
      );
      expect(
        a.shouldRepaint(
          const AppLogoMarkPainter(accent: Colors.green, base: Colors.blue),
        ),
        isTrue,
      );
    });
  });
}

extension on double {
  T let<T>(T Function(double) f) => f(this);
}
