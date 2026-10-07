import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/inputs/app_text_field.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/l10n/app_localizations.dart';

Future<void> _pump(
  WidgetTester tester,
  Widget field, {
  bool dark = false,
  double textScale = 1,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('tr'),
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: Padding(padding: const EdgeInsets.all(20), child: field),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _field => find.byType(AppTextField);
Finder get _box =>
    find.descendant(of: _field, matching: find.byType(AnimatedContainer));
Finder get _input =>
    find.descendant(of: _field, matching: find.byType(TextField));

ShapeDecoration _decoration(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(_box).decoration! as ShapeDecoration;
Color? _fill(WidgetTester tester) => _decoration(tester).color;
BorderSide _side(WidgetTester tester) =>
    (_decoration(tester).shape as OutlinedBorder).side;
TextField _tf(WidgetTester tester) => tester.widget<TextField>(_input);

void main() {
  group('görünüm', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets(
        'varsayılan $name: surfaceMuted, kenarlık yok, radius 14, min 52',
        (tester) async {
          await _pump(
            tester,
            const AppTextField(label: 'Oda adı', hintText: 'Örn. Cuma'),
            dark: dark,
          );
          expect(_fill(tester), c.surfaceMuted);
          expect(_side(tester).color, Colors.transparent);
          expect(
            (_decoration(tester).shape as RoundedSuperellipseBorder)
                .borderRadius,
            BorderRadius.circular(14),
          );
          expect(tester.getSize(_box).height, greaterThanOrEqualTo(52));
          expect(tester.getSize(_box).height, lessThan(60));
        },
      );

      testWidgets(
        'etiket üstte, label stili textSecondary, floating değil $name',
        (tester) async {
          await _pump(
            tester,
            const AppTextField(label: 'Oda adı', hintText: 'x'),
            dark: dark,
          );
          final label = tester.widget<Text>(find.text('Oda adı'));
          expect(label.style!.color, c.textSecondary);
          expect(label.style!.fontSize, 15);
          expect(
            tester.getBottomLeft(find.text('Oda adı')).dy,
            lessThan(tester.getTopLeft(_box).dy),
          );
          expect(
            tester.getTopLeft(_box).dy -
                tester.getBottomLeft(find.text('Oda adı')).dy,
            closeTo(8, 3),
          );
          // Odakta da etiket yerinde kalır (floating label yok).
          final before = tester.getTopLeft(find.text('Oda adı'));
          await tester.tap(_input);
          await tester.pumpAndSettle();
          expect(tester.getTopLeft(find.text('Oda adı')), before);
        },
      );

      testWidgets('placeholder textTertiary, metin textPrimary $name', (
        tester,
      ) async {
        final controller = TextEditingController();
        await _pump(
          tester,
          AppTextField(label: 'x', hintText: 'İpucu', controller: controller),
          dark: dark,
        );
        expect(
          tester.widget<Text>(find.text('İpucu')).style!.color,
          c.textTertiary,
        );
        expect(_tf(tester).style!.color, c.textPrimary);
        expect(_tf(tester).cursorColor, c.brand);
      });
    }
  });

  group('odak', () {
    testWidgets('odakta surfaceInputFocus + 1,5px brand; yerleşim kaymaz', (
      tester,
    ) async {
      await _pump(tester, const AppTextField(label: 'x', hintText: 'y'));
      final size = tester.getSize(_field);
      final textPos = tester.getTopLeft(_input);
      await tester.tap(_input);
      await tester.pumpAndSettle();
      expect(_fill(tester), AppColors.light.surfaceInputFocus);
      expect(_side(tester).color, AppColors.light.brand);
      expect(_side(tester).width, 1.5);
      expect(tester.getSize(_field), size);
      expect(tester.getTopLeft(_input), textPos);
    });

    testWidgets('dolu alanda temizle ikonu belirince yükseklik değişmez', (
      tester,
    ) async {
      await _pump(
        tester,
        AppTextField(
          label: 'x',
          controller: TextEditingController(text: 'Cuma'),
        ),
      );
      final idle = tester.getSize(_box).height;
      await tester.tap(_input);
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.close), findsOneWidget);
      expect(tester.getSize(_box).height, idle);
      expect(idle, 52);
    });

    testWidgets(
      'dark: odak dolgusu surfaceInputFocus (= surfaceMuted ile aynı değer)',
      (tester) async {
        await _pump(tester, const AppTextField(label: 'x'), dark: true);
        await tester.tap(_input);
        await tester.pumpAndSettle();
        expect(_fill(tester), AppColors.dark.surfaceInputFocus);
        expect(_side(tester).color, AppColors.dark.brand);
      },
    );

    testWidgets('etikete dokununca alan odaklanır', (tester) async {
      await _pump(tester, const AppTextField(label: 'Oda adı'));
      await tester.tap(find.text('Oda adı'));
      await tester.pumpAndSettle();
      expect(_tf(tester).focusNode!.hasFocus, isTrue);
    });
  });

  group('temizle ikonu', () {
    testWidgets(
      'yalnızca odakta ve doluyken görünür; dokununca temizler, odak kalır',
      (tester) async {
        final controller = TextEditingController(text: 'Cuma');
        final changes = <String>[];
        await _pump(
          tester,
          AppTextField(
            label: 'x',
            controller: controller,
            onChanged: changes.add,
          ),
        );
        expect(find.byIcon(AppIcons.close), findsNothing);

        await tester.tap(_input);
        await tester.pumpAndSettle();
        expect(find.byIcon(AppIcons.close), findsOneWidget);
        expect(tester.widget<Icon>(find.byIcon(AppIcons.close)).size, 20);

        await tester.tap(find.byIcon(AppIcons.close));
        await tester.pumpAndSettle();
        expect(controller.text, '');
        expect(changes, ['']);
        expect(find.byIcon(AppIcons.close), findsNothing);
        expect(_tf(tester).focusNode!.hasFocus, isTrue);
      },
    );

    testWidgets('boşken odakta görünmez', (tester) async {
      await _pump(tester, const AppTextField(label: 'x'));
      await tester.tap(_input);
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.close), findsNothing);
    });

    testWidgets(
      'temizle ikonunun VoiceOver etiketi "Temizle", dokunma alanı 44',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(
          tester,
          AppTextField(
            label: 'x',
            controller: TextEditingController(text: 'a'),
          ),
        );
        await tester.tap(_input);
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Temizle'), findsOneWidget);
        final clear = find
            .ancestor(
              of: find.byIcon(AppIcons.close),
              matching: find.byType(SizedBox),
            )
            .first;
        expect(tester.getSize(clear), const Size(44, 44));
        handle.dispose();
      },
    );
  });

  group('hata ve pasif', () {
    testWidgets(
      'hata: 1,5px error kenarlık, altta ⚠ ve error metin (caption)',
      (tester) async {
        await _pump(
          tester,
          const AppTextField(
            label: 'E-posta',
            errorText: 'Geçerli bir e-posta adresi yaz.',
          ),
        );
        expect(_side(tester).color, AppColors.light.error);
        expect(_side(tester).width, 1.5);
        final msg = tester.widget<Text>(
          find.text('Geçerli bir e-posta adresi yaz.'),
        );
        expect(msg.style!.color, AppColors.light.error);
        expect(msg.style!.fontSize, 13);
        final icon = tester.widget<Icon>(find.byIcon(AppIcons.warning));
        expect(icon.size, 14);
        expect(icon.color, AppColors.light.error);
        expect(
          tester.getTopLeft(find.text('Geçerli bir e-posta adresi yaz.')).dy,
          greaterThan(tester.getBottomLeft(_box).dy),
        );
      },
    );

    testWidgets('hata odaktan önceliklidir', (tester) async {
      await _pump(tester, const AppTextField(label: 'x', errorText: 'Hata'));
      await tester.tap(_input);
      await tester.pumpAndSettle();
      expect(_side(tester).color, AppColors.light.error);
    });

    testWidgets('hata mesajı canlı bölge olarak duyurulur', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AppTextField(label: 'x', errorText: 'Hata mesajı'),
      );
      expect(
        tester.getSemantics(find.text('Hata mesajı')),
        matchesSemantics(label: 'Hata mesajı', isLiveRegion: true),
      );
      handle.dispose();
    });

    testWidgets('hata yokken satır yok', (tester) async {
      await _pump(tester, const AppTextField(label: 'x'));
      expect(find.byIcon(AppIcons.warning), findsNothing);
    });

    testWidgets('pasif: textDisabled, odaklanmaz, temizle yok, kenarlık yok', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Sabit');
      await _pump(
        tester,
        AppTextField(label: 'x', controller: controller, enabled: false),
      );
      expect(_tf(tester).style!.color, AppColors.light.textDisabled);
      expect(_fill(tester), AppColors.light.surfaceMuted);
      await tester.tap(_input, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(_tf(tester).focusNode!.hasFocus, isFalse);
      expect(find.byIcon(AppIcons.close), findsNothing);
      expect(_side(tester).color, Colors.transparent);
    });
  });

  group('giriş davranışı', () {
    testWidgets('yazılan metin controller ve onChanged\'e gider', (
      tester,
    ) async {
      final controller = TextEditingController();
      final changes = <String>[];
      await _pump(
        tester,
        AppTextField(
          label: 'x',
          controller: controller,
          onChanged: changes.add,
        ),
      );
      await tester.enterText(_input, 'Can');
      expect(controller.text, 'Can');
      expect(changes, ['Can']);
    });

    testWidgets('klavye ayarları aktarılır (e-posta, autofill, aksiyon)', (
      tester,
    ) async {
      await _pump(
        tester,
        const AppTextField(
          label: 'E-posta',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: [AutofillHints.email],
          autocorrect: false,
          textCapitalization: TextCapitalization.none,
        ),
      );
      final tf = _tf(tester);
      expect(tf.keyboardType, TextInputType.emailAddress);
      expect(tf.textInputAction, TextInputAction.done);
      expect(tf.autofillHints, [AutofillHints.email]);
      expect(tf.autocorrect, isFalse);
    });

    testWidgets('kendi controller ve focusNode\'unu yönetir ve temizler', (
      tester,
    ) async {
      await _pump(tester, const AppTextField(label: 'x'));
      await tester.enterText(_input, 'a');
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });

    testWidgets('dışarıdan verilen controller dispose edilmez', (tester) async {
      final controller = TextEditingController(text: 'a');
      await _pump(tester, AppTextField(label: 'x', controller: controller));
      await tester.pumpWidget(const SizedBox());
      controller.text = 'b';
      expect(controller.text, 'b');
      controller.dispose();
    });
  });

  group('erişilebilirlik ve ölçek', () {
    testWidgets('semantics: etiket metin alanının kendi düğümünde', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const AppTextField(label: 'Oda adı', hintText: 'Örn. Cuma'),
      );
      final node = tester.getSemantics(_input);
      // Etiket önce, ipucu ondan sonra okunur.
      expect(node.label, startsWith('Oda adı'));
      expect(node.label, contains('Örn. Cuma'));
      expect(node.flagsCollection.isTextField, isTrue);
      handle.dispose();
    });

    testWidgets('yazı 2x: alan metinle büyür, taşma yok', (tester) async {
      await _pump(
        tester,
        const AppTextField(
          label: 'Oda adı',
          hintText: 'Örn. Cuma akşamı',
          errorText: 'Bir ad yaz.',
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_box).height, greaterThan(60));
    });
  });
}
