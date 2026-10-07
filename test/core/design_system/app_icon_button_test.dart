import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/buttons/app_icon_button.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_fixed_colors.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget button, {
  bool dark = false,
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(body: Center(child: button)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _btn => find.byType(AppIconButton);
Finder get _circle =>
    find.descendant(of: _btn, matching: find.byType(AnimatedContainer));
Finder get _icon => find.descendant(of: _btn, matching: find.byType(Icon));

Color? _fill(WidgetTester tester) =>
    (tester.widget<AnimatedContainer>(_circle).decoration! as ShapeDecoration)
        .color;
Color? _iconColor(WidgetTester tester) => tester.widget<Icon>(_icon).color;
double _iconSize(WidgetTester tester) => tester.widget<Icon>(_icon).size!;
double _opacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find.descendant(of: _btn, matching: find.byType(AnimatedOpacity)),
    )
    .opacity;
Finder get _transform =>
    find.descendant(of: _btn, matching: find.byType(Transform));

Future<TestGesture> _hold(WidgetTester tester) async {
  final g = await tester.startGesture(tester.getCenter(_btn));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  return g;
}

void main() {
  void noop() {}

  group('stiller ve renkler', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets('plain $name: dolgusuz, ikon textPrimary, 24', (
        tester,
      ) async {
        await _pump(
          tester,
          AppIconButton.plain(
            icon: AppIcons.back,
            semanticLabel: 'Geri',
            onPressed: noop,
          ),
          dark: dark,
        );
        expect(_circle, findsNothing);
        expect(_iconColor(tester), c.textPrimary);
        expect(_iconSize(tester), 24);
      });

      testWidgets('soft $name: surfaceMuted daire, ikon textPrimary, 20', (
        tester,
      ) async {
        await _pump(
          tester,
          AppIconButton.soft(
            icon: AppIcons.undo,
            semanticLabel: 'Geri al',
            onPressed: noop,
          ),
          dark: dark,
        );
        expect(_fill(tester), c.surfaceMuted);
        expect(_iconColor(tester), c.textPrimary);
        expect(_iconSize(tester), 20);
      });

      testWidgets('media $name: siyah %35 daire, beyaz ikon, iki temada aynı', (
        tester,
      ) async {
        await _pump(
          tester,
          AppIconButton.media(
            icon: AppIcons.heart,
            semanticLabel: 'Beğen',
            onPressed: noop,
          ),
          dark: dark,
        );
        expect(_fill(tester), AppFixedColors.mediaOverlay);
        expect(_iconColor(tester), AppFixedColors.onMedia);
        expect(_iconSize(tester), 20);
      });
    }
  });

  group('boyut ve dokunma alanı', () {
    testWidgets('üç stilde de dokunma alanı 44x44', (tester) async {
      for (final b in [
        AppIconButton.plain(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: noop,
        ),
        AppIconButton.soft(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: noop,
        ),
        AppIconButton.media(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: noop,
        ),
      ]) {
        await _pump(tester, b);
        expect(tester.getSize(_btn), const Size(44, 44), reason: '${b.style}');
      }
    });

    testWidgets('soft ve media: görünen daire 36, tam daire şekli', (
      tester,
    ) async {
      for (final b in [
        AppIconButton.soft(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: noop,
        ),
        AppIconButton.media(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: noop,
        ),
      ]) {
        await _pump(tester, b);
        expect(
          tester.getSize(_circle),
          const Size(36, 36),
          reason: '${b.style}',
        );
        final d =
            tester.widget<AnimatedContainer>(_circle).decoration!
                as ShapeDecoration;
        expect(d.shape, isA<CircleBorder>());
      }
    });

    testWidgets('dairenin dışındaki ama 44 alan içindeki dokunuş da çalışır', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        AppIconButton.soft(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: () => taps++,
        ),
      );
      final topLeft = tester.getTopLeft(_btn);
      await tester.tapAt(topLeft + const Offset(2, 2));
      expect(taps, 1);
    });

    testWidgets('yazı 2x: boyut değişmez', (tester) async {
      await _pump(
        tester,
        AppIconButton.soft(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: noop,
        ),
        textScale: 2,
      );
      expect(tester.getSize(_btn), const Size(44, 44));
      expect(tester.takeException(), isNull);
    });
  });

  group('state', () {
    testWidgets('onPressed çağrılır', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppIconButton.plain(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: () => taps++,
        ),
      );
      await tester.tap(_btn);
      expect(taps, 1);
    });

    testWidgets('plain basılı: ikon %50, scale yok', (tester) async {
      await _pump(
        tester,
        AppIconButton.plain(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: noop,
        ),
      );
      final g = await _hold(tester);
      expect(_opacity(tester), 0.5);
      expect(_transform, findsNothing);
      await g.up();
    });

    testWidgets('soft basılı: surfacePressed + 0.97, ikon opak', (
      tester,
    ) async {
      await _pump(
        tester,
        AppIconButton.soft(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: noop,
        ),
      );
      final g = await _hold(tester);
      expect(_fill(tester), AppColors.light.surfacePressed);
      expect(
        tester.widget<Transform>(_transform.first).transform.entry(0, 0),
        closeTo(0.97, 1e-3),
      );
      expect(_opacity(tester), 1);
      await g.up();
      await tester.pumpAndSettle();
      expect(_fill(tester), AppColors.light.surfaceMuted);
    });

    testWidgets('media basılı: 0.97 + ikon %50, dolgu aynı', (tester) async {
      await _pump(
        tester,
        AppIconButton.media(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: noop,
        ),
      );
      final g = await _hold(tester);
      expect(_fill(tester), AppFixedColors.mediaOverlay);
      expect(_opacity(tester), 0.5);
      expect(
        tester.widget<Transform>(_transform.first).transform.entry(0, 0),
        closeTo(0.97, 1e-3),
      );
      await g.up();
    });

    testWidgets(
      'disabled: ikon textDisabled, soft dolgusu surfaceMuted, tıklanmaz',
      (tester) async {
        await _pump(
          tester,
          const AppIconButton.plain(
            icon: AppIcons.back,
            semanticLabel: 'a',
            onPressed: null,
          ),
        );
        expect(_iconColor(tester), AppColors.light.textDisabled);
        await _pump(
          tester,
          const AppIconButton.soft(
            icon: AppIcons.back,
            semanticLabel: 'a',
            onPressed: null,
          ),
        );
        expect(_iconColor(tester), AppColors.light.textDisabled);
        expect(_fill(tester), AppColors.light.surfaceMuted);
        final g = await _hold(tester);
        expect(_fill(tester), AppColors.light.surfaceMuted);
        await g.up();
      },
    );

    testWidgets('Reduce Motion: scale yok, soft rengi yine değişir', (
      tester,
    ) async {
      await _pump(
        tester,
        AppIconButton.soft(
          icon: AppIcons.back,
          semanticLabel: 'a',
          onPressed: noop,
        ),
        disableAnimations: true,
      );
      final g = await _hold(tester);
      expect(
        tester.widget<Transform>(_transform.first).transform.entry(0, 0),
        1,
      );
      expect(_fill(tester), AppColors.light.surfacePressed);
      await g.up();
    });
  });

  group('erişilebilirlik', () {
    testWidgets('semantics: etiket, buton, enabled / disabled', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AppIconButton.soft(
          icon: AppIcons.undo,
          semanticLabel: 'Geri al',
          onPressed: noop,
        ),
      );
      expect(
        tester.getSemantics(_btn),
        matchesSemantics(
          label: 'Geri al',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );
      await _pump(
        tester,
        const AppIconButton.soft(
          icon: AppIcons.undo,
          semanticLabel: 'Geri al',
          onPressed: null,
        ),
      );
      expect(
        tester.getSemantics(_btn),
        matchesSemantics(
          label: 'Geri al',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    test('boş semanticLabel kabul edilmez', () {
      expect(
        () => AppIconButton.plain(
          icon: AppIcons.back,
          semanticLabel: '',
          onPressed: () {},
        ),
        throwsAssertionError,
      );
    });
  });
}
