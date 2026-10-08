import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/buttons/app_button.dart';
import 'package:iagree/core/design_system/components/inputs/app_search_field.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget field, {
  bool dark = false,
  double textScale = 1,
  Locale locale = const Locale('tr'),
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(20), child: field),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _field => find.byType(AppSearchField);
// Vazgeç butonunun pill kapsülünden ayırmak için radius 14'e bakar.
Finder get _box => find.descendant(
  of: _field,
  matching: find.byWidgetPredicate((w) {
    if (w is! Container) return false;
    final d = w.decoration;
    return d is ShapeDecoration &&
        d.shape is RoundedSuperellipseBorder &&
        (d.shape as RoundedSuperellipseBorder).borderRadius ==
            BorderRadius.circular(14);
  }),
);
Finder get _input =>
    find.descendant(of: _field, matching: find.byType(TextField));
Finder get _cancel =>
    find.descendant(of: _field, matching: find.byType(AppButton));

ShapeDecoration _decoration(WidgetTester tester) =>
    tester.widget<Container>(_box).decoration! as ShapeDecoration;
TextField _tf(WidgetTester tester) => tester.widget<TextField>(_input);

void main() {
  group('görünüm', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets(
        'varsayılan $name: yükseklik 44, radius 14, surfaceMuted, kenarlık yok',
        (tester) async {
          await _pump(
            tester,
            const AppSearchField(hintText: 'Mekan ara'),
            dark: dark,
          );
          expect(tester.getSize(_box).height, 44);
          expect(_decoration(tester).color, c.surfaceMuted);
          final shape = _decoration(tester).shape as RoundedSuperellipseBorder;
          expect(shape.borderRadius, BorderRadius.circular(14));
          expect(shape.side, BorderSide.none);
        },
      );

      testWidgets('büyüteç 20, textTertiary; ipucu textTertiary $name', (
        tester,
      ) async {
        await _pump(
          tester,
          const AppSearchField(hintText: 'Mekan ara'),
          dark: dark,
        );
        final icon = tester.widget<Icon>(find.byIcon(AppIcons.search));
        expect(icon.size, 20);
        expect(icon.color, c.textTertiary);
        expect(
          tester.widget<Text>(find.text('Mekan ara')).style!.color,
          c.textTertiary,
        );
        // Büyüteç solda, metinden önce.
        expect(
          tester.getTopLeft(find.byIcon(AppIcons.search)).dx,
          lessThan(tester.getTopLeft(_input).dx),
        );
      });
    }

    testWidgets('yazılan metin textPrimary, imleç brand, arama aksiyonu', (
      tester,
    ) async {
      await _pump(
        tester,
        AppSearchField(
          hintText: 'Mekan ara',
          controller: TextEditingController(text: 'Lume'),
        ),
      );
      expect(_tf(tester).style!.color, AppColors.light.textPrimary);
      expect(_tf(tester).cursorColor, AppColors.light.brand);
      expect(_tf(tester).textInputAction, TextInputAction.search);
    });
  });

  group('Vazgeç', () {
    testWidgets(
      'odak yokken görünmez; odakta sağda Tertiary Small "Vazgeç" belirir',
      (tester) async {
        await _pump(tester, const AppSearchField(hintText: 'Mekan ara'));
        expect(_cancel, findsNothing);
        await tester.tap(_input);
        await tester.pumpAndSettle();
        expect(_cancel, findsOneWidget);
        final b = tester.widget<AppButton>(_cancel);
        expect(b.variant, AppButtonVariant.tertiary);
        expect(b.size, AppButtonSize.small);
        expect(b.label, 'Vazgeç');
        expect(
          tester.getTopLeft(_cancel).dx,
          greaterThan(tester.getTopRight(_box).dx - 1),
        );
      },
    );

    testWidgets('İngilizce: "Cancel"', (tester) async {
      await _pump(
        tester,
        const AppSearchField(hintText: 'Search'),
        locale: const Locale('en'),
      );
      await tester.tap(_input);
      await tester.pumpAndSettle();
      expect(tester.widget<AppButton>(_cancel).label, 'Cancel');
    });

    testWidgets('Vazgeç belirince alan yüksekliği değişmez', (tester) async {
      await _pump(tester, const AppSearchField(hintText: 'Mekan ara'));
      final idle = tester.getSize(_box).height;
      await tester.tap(_input);
      await tester.pumpAndSettle();
      expect(tester.getSize(_box).height, idle);
      expect(idle, 44);
    });

    testWidgets(
      'dokununca metni temizler, odağı bırakır, onChanged("") ve onCancel çağrılır',
      (tester) async {
        final controller = TextEditingController(text: 'Trattoria');
        final changes = <String>[];
        var cancels = 0;
        await _pump(
          tester,
          AppSearchField(
            hintText: 'Mekan ara',
            controller: controller,
            onChanged: changes.add,
            onCancel: () => cancels++,
          ),
        );
        await tester.tap(_input);
        await tester.pumpAndSettle();
        await tester.tap(_cancel);
        await tester.pumpAndSettle();
        expect(controller.text, '');
        expect(changes, ['']);
        expect(cancels, 1);
        expect(_tf(tester).focusNode!.hasFocus, isFalse);
        expect(_cancel, findsNothing);
      },
    );

    testWidgets('pasif alan odaklanmaz, Vazgeç çıkmaz', (tester) async {
      await _pump(
        tester,
        const AppSearchField(hintText: 'Pasif', enabled: false),
      );
      await tester.tap(_input, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_cancel, findsNothing);
      expect(_tf(tester).style!.color, AppColors.light.textDisabled);
    });
  });

  group('giriş davranışı', () {
    testWidgets(
      'yazı onChanged ve controller\'a, gönder onSubmitted\'e gider',
      (tester) async {
        final controller = TextEditingController();
        final changes = <String>[];
        final submits = <String>[];
        await _pump(
          tester,
          AppSearchField(
            hintText: 'x',
            controller: controller,
            onChanged: changes.add,
            onSubmitted: submits.add,
          ),
        );
        await tester.enterText(_input, 'pizza');
        await tester.testTextInput.receiveAction(TextInputAction.search);
        expect(controller.text, 'pizza');
        expect(changes, ['pizza']);
        expect(submits, ['pizza']);
      },
    );

    testWidgets('dışarıdan verilen controller dispose edilmez', (tester) async {
      final controller = TextEditingController(text: 'a');
      await _pump(
        tester,
        AppSearchField(hintText: 'x', controller: controller),
      );
      await tester.pumpWidget(const SizedBox());
      controller.text = 'b';
      expect(controller.text, 'b');
      controller.dispose();
    });
  });

  group('erişilebilirlik ve ölçek', () {
    testWidgets(
      'semantics: etiket metin alanının düğümünde, Vazgeç ayrı buton',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(tester, const AppSearchField(hintText: 'Mekan ara'));
        final node = tester.getSemantics(_input);
        expect(node.label, contains('Mekan ara'));
        expect(node.flagsCollection.isTextField, isTrue);
        await tester.tap(_input);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Vazgeç'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('yazı 2x: alan metinle büyür, taşma yok', (tester) async {
      await _pump(
        tester,
        const AppSearchField(hintText: 'Mekan ara'),
        textScale: 2,
      );
      await tester.tap(_input);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_box).height, greaterThan(44));
    });
  });

  group('Reduce Motion', () {
    testWidgets('Vazgeç animasyonsuz ve çökmeden belirir', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('tr'),
            theme: AppTheme.light,
            home: const Scaffold(body: AppSearchField(hintText: 'Mekan ara')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Vazgeç'), findsOneWidget);
    });
  });
}
