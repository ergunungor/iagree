import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/buttons/app_button.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_fixed_colors.dart';
import 'package:iagree/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget button, {
  bool dark = false,
  double textScale = 1,
  bool disableAnimations = false,
  // Spinner sonsuz animasyon yaptığı için loading'de pumpAndSettle beklemez.
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(body: Center(child: button)),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

Finder get _btn => find.byType(AppButton);
Finder get _box =>
    find.descendant(of: _btn, matching: find.byType(AnimatedContainer));

Color? _fill(WidgetTester tester) =>
    (tester.widget<AnimatedContainer>(_box).decoration! as ShapeDecoration)
        .color;

Color? _content(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: _btn, matching: find.byType(Text)))
    .style!
    .color;

double _scale(WidgetTester tester) => tester
    .widget<Transform>(
      find.descendant(of: _btn, matching: find.byType(Transform)).first,
    )
    .transform
    .entry(0, 0);

void main() {
  void noop() {}

  group('renkler', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';
      final cases = <String, (Widget, Color?, Color)>{
        'primary': (
          AppButton.primary(label: 'x', onPressed: noop),
          c.brand,
          c.onBrand,
        ),
        'secondary': (
          AppButton.secondary(label: 'x', onPressed: noop),
          c.surfaceMuted,
          c.textPrimary,
        ),
        'tertiary': (
          AppButton.tertiary(label: 'x', onPressed: noop),
          null,
          c.brand,
        ),
        'destructive': (
          AppButton.destructive(label: 'x', onPressed: noop),
          c.errorSoft,
          c.error,
        ),
        'destructiveStrong': (
          AppButton.destructiveStrong(label: 'x', onPressed: noop),
          c.error,
          c.onError,
        ),
        'moment': (
          AppButton.moment(label: 'x', onPressed: noop),
          AppFixedColors.momentInk,
          AppFixedColors.momentBg,
        ),
        'momentGhost': (
          AppButton.momentGhost(label: 'x', onPressed: noop),
          AppFixedColors.momentGhost,
          AppFixedColors.momentInk,
        ),
        'momentText': (
          AppButton.momentText(label: 'x', onPressed: noop),
          null,
          AppFixedColors.momentInk,
        ),
      };
      for (final e in cases.entries) {
        testWidgets('${e.key} $name', (tester) async {
          await _pump(tester, e.value.$1, dark: dark);
          expect(_fill(tester), e.value.$2);
          expect(_content(tester), e.value.$3);
        });
      }
    }
  });

  group('boyut', () {
    testWidgets('görünen yükseklikler 52 / 44 / 32, dokunma alanı en az 44', (
      tester,
    ) async {
      final heights = {
        AppButtonSize.large: 52.0,
        AppButtonSize.medium: 44.0,
        AppButtonSize.small: 32.0,
      };
      for (final e in heights.entries) {
        await _pump(
          tester,
          AppButton.primary(label: 'Dürt', onPressed: noop, size: e.key),
        );
        expect(tester.getSize(_box).height, e.value, reason: '${e.key}');
        expect(
          tester.getSize(_btn).height,
          greaterThanOrEqualTo(44),
          reason: '${e.key}',
        );
        expect(
          tester.getSize(_btn).width,
          greaterThanOrEqualTo(44),
          reason: '${e.key}',
        );
      }
    });

    testWidgets('large varsayılan olarak tam genişlik, medium içeriğe sığar', (
      tester,
    ) async {
      await _pump(
        tester,
        AppButton.primary(label: 'Oda oluştur', onPressed: noop),
      );
      expect(tester.getSize(_btn).width, 800);
      expect(tester.getSize(_box).width, 800);
      await _pump(
        tester,
        AppButton.primary(
          label: 'Oda oluştur',
          onPressed: noop,
          size: AppButtonSize.medium,
        ),
      );
      expect(tester.getSize(_box).width, lessThan(400));
    });

    testWidgets('yazı 2x: buton metinle büyür, taşma yok', (tester) async {
      await _pump(
        tester,
        AppButton.primary(label: 'Tercihlerimi gönder', onPressed: noop),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_box).height, greaterThan(52));
    });
  });

  group('state', () {
    testWidgets('onPressed çağrılır', (tester) async {
      var taps = 0;
      await _pump(
        tester,
        AppButton.primary(label: 'x', onPressed: () => taps++),
      );
      await tester.tap(_btn);
      expect(taps, 1);
    });

    testWidgets(
      'disabled: surfaceMuted dolgu, textDisabled içerik, tıklanmaz',
      (tester) async {
        await _pump(
          tester,
          const AppButton.primary(label: 'x', onPressed: null),
        );
        expect(_fill(tester), AppColors.light.surfaceMuted);
        expect(_content(tester), AppColors.light.textDisabled);
      },
    );

    testWidgets('tertiary disabled: yalnızca içerik textDisabled', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppButton.tertiary(label: 'x', onPressed: null),
      );
      expect(_fill(tester), isNull);
      expect(_content(tester), AppColors.light.textDisabled);
    });

    testWidgets('primary basılı: brandPressed + 0.97 scale, bırakınca döner', (
      tester,
    ) async {
      await _pump(tester, AppButton.primary(label: 'x', onPressed: noop));
      final g = await tester.startGesture(tester.getCenter(_btn));
      // İlk kare animasyonu başlatır; süre ikinci karede işler.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_fill(tester), AppColors.light.brandPressed);
      expect(_scale(tester), closeTo(0.97, 1e-3));
      await g.up();
      await tester.pumpAndSettle();
      expect(_fill(tester), AppColors.light.brand);
      expect(_scale(tester), closeTo(1, 1e-3));
    });

    testWidgets('secondary basılı: surfacePressed', (tester) async {
      await _pump(tester, AppButton.secondary(label: 'x', onPressed: noop));
      final g = await tester.startGesture(tester.getCenter(_btn));
      // İlk kare animasyonu başlatır; süre ikinci karede işler.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_fill(tester), AppColors.light.surfacePressed);
      await g.up();
    });

    testWidgets('token\'ı olmayan variant basılınca bir ton koyulaşır', (
      tester,
    ) async {
      for (final b in [
        AppButton.destructive(label: 'x', onPressed: noop),
        AppButton.destructiveStrong(label: 'x', onPressed: noop),
        AppButton.moment(label: 'x', onPressed: noop),
      ]) {
        await _pump(tester, b);
        final before = HSLColor.fromColor(_fill(tester)!).lightness;
        final g = await tester.startGesture(tester.getCenter(_btn));
        // İlk kare animasyonu başlatır; süre ikinci karede işler.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final after = HSLColor.fromColor(_fill(tester)!).lightness;
        expect(after, lessThan(before), reason: '${b.variant}');
        await g.up();
        await tester.pumpAndSettle();
      }
    });

    testWidgets('tertiary basılı: içerik %50 opaklık, dolgu yok', (
      tester,
    ) async {
      await _pump(tester, AppButton.tertiary(label: 'x', onPressed: noop));
      final g = await tester.startGesture(tester.getCenter(_btn));
      // İlk kare animasyonu başlatır; süre ikinci karede işler.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final opacity = tester.widget<AnimatedOpacity>(
        find.descendant(of: _btn, matching: find.byType(AnimatedOpacity)),
      );
      expect(opacity.opacity, 0.5);
      expect(_fill(tester), isNull);
      await g.up();
    });

    testWidgets('Reduce Motion: scale yok, renk yine değişir', (tester) async {
      await _pump(
        tester,
        AppButton.primary(label: 'x', onPressed: noop),
        disableAnimations: true,
      );
      final g = await tester.startGesture(tester.getCenter(_btn));
      // İlk kare animasyonu başlatır; süre ikinci karede işler.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(_scale(tester), 1);
      expect(_fill(tester), AppColors.light.brandPressed);
      await g.up();
    });

    testWidgets('loading: genişlik sabit, spinner var, basış yok sayılır', (
      tester,
    ) async {
      var taps = 0;
      await _pump(
        tester,
        AppButton.primary(
          label: 'Linki paylaş',
          onPressed: () => taps++,
          size: AppButtonSize.medium,
        ),
      );
      final width = tester.getSize(_box).width;
      await _pump(
        tester,
        AppButton.primary(
          label: 'Linki paylaş',
          onPressed: () => taps++,
          size: AppButtonSize.medium,
          isLoading: true,
        ),
        settle: false,
      );
      expect(tester.getSize(_box).width, width);
      expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
      await tester.tap(_btn);
      expect(taps, 0);
    });
  });

  group('erişilebilirlik ve içerik', () {
    testWidgets('semantics: buton, etiket, enabled', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AppButton.primary(label: 'Oda oluştur', onPressed: noop),
      );
      expect(
        tester.getSemantics(_btn),
        matchesSemantics(
          label: 'Oda oluştur',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      await _pump(
        tester,
        const AppButton.primary(label: 'Oda oluştur', onPressed: null),
      );
      expect(
        tester.getSemantics(_btn),
        matchesSemantics(
          label: 'Oda oluştur',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('loading: VoiceOver değeri "Yükleniyor"', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        AppButton.primary(label: 'x', onPressed: noop, isLoading: true),
        settle: false,
      );
      expect(tester.getSemantics(_btn).value, 'Yükleniyor');
      handle.dispose();
    });

    testWidgets('etiket büyük harfe çevrilmez', (tester) async {
      await _pump(tester, AppButton.primary(label: 'iAgree', onPressed: noop));
      expect(find.text('iAgree'), findsOneWidget);
    });

    testWidgets('ikon solda, etiketten önce', (tester) async {
      await _pump(
        tester,
        AppButton.primary(
          label: 'Linki paylaş',
          onPressed: noop,
          icon: Icons.add,
        ),
      );
      expect(
        tester.getTopLeft(find.byIcon(Icons.add)).dx,
        lessThan(tester.getTopLeft(find.text('Linki paylaş')).dx),
      );
    });
  });
}
