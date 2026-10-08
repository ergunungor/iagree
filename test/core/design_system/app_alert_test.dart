import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/buttons/app_button.dart';
import 'package:iagree/core/design_system/components/feedback/app_alert.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_elevation.dart';

import '../../support/pump_app.dart';

void _phone(WidgetTester tester, {Size size = const Size(1170, 2532)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

class _Opener extends StatefulWidget {
  const _Opener({
    this.destructive = true,
    this.message = 'Bu işlem geri alınamaz. Oda herkes için silinir.',
    this.cancelLabel,
  });
  final bool destructive;
  final String? message;
  final String? cancelLabel;

  @override
  State<_Opener> createState() => _OpenerState();
}

class _OpenerState extends State<_Opener> {
  Object? result = 'beklemede';

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        onPressed: () async {
          final r = await AppAlert.show(
            context,
            title: 'Oda silinsin mi?',
            message: widget.message,
            actionLabel: 'Odayı sil',
            cancelLabel: widget.cancelLabel,
            destructive: widget.destructive,
          );
          setState(() => result = r);
        },
        child: const Text('Aç'),
      ),
      Text('sonuç: $result'),
    ],
  );
}

Finder get _alertCard => find
    .descendant(
      of: find.byType(Center),
      matching: find.byWidgetPredicate((w) {
        if (w is! DecoratedBox) return false;
        final d = w.decoration;
        return d is ShapeDecoration &&
            d.color != null &&
            d.shape is RoundedSuperellipseBorder &&
            (d.shape as RoundedSuperellipseBorder).borderRadius ==
                BorderRadius.circular(20);
      }),
    )
    .first;

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Aç'));
  await tester.pumpAndSettle();
}

AppButton _button(WidgetTester tester, AppButtonVariant v) => tester
    .widgetList<AppButton>(find.byType(AppButton))
    .firstWhere((b) => b.variant == v);

void main() {
  group('görünüm', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets('surfaceRaised, radius lg, E3, scrim $name', (tester) async {
        _phone(tester);
        await pumpApp(tester, const _Opener(), dark: dark);
        await _open(tester);
        final deco =
            tester.widget<DecoratedBox>(_alertCard).decoration
                as ShapeDecoration;
        expect(deco.color, c.surfaceRaised);
        final e3 = dark ? AppElevation.dark.e3 : AppElevation.light.e3;
        expect(deco.shadows, e3.shadows);
        expect(
          tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
          c.scrim,
        );
      });
    }

    testWidgets('genişlik ekran − 48, en fazla 340; ortada', (tester) async {
      _phone(tester); // 390 → 342 → 340
      await pumpApp(tester, const _Opener());
      await _open(tester);
      expect(tester.getSize(_alertCard).width, 340);
      expect(tester.getCenter(_alertCard).dx, closeTo(195, 0.5));
      expect(tester.getCenter(_alertCard).dy, closeTo(422, 40));
    });

    testWidgets('dar ekranda ekran − 48', (tester) async {
      _phone(tester, size: const Size(900, 1800)); // 300 geniş
      await pumpApp(tester, const _Opener());
      await _open(tester);
      expect(tester.getSize(_alertCard).width, 252);
    });

    testWidgets(
      'padding 24; başlık h3 ortalı; metin bodySmall textSecondary ortalı',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, const _Opener());
        await _open(tester);
        final card = tester.getRect(_alertCard);
        expect(
          tester.getTopLeft(find.text('Oda silinsin mi?')).dy - card.top,
          24,
        );
        final title = tester.widget<Text>(find.text('Oda silinsin mi?'));
        expect(title.style!.fontSize, 20);
        expect(title.textAlign, TextAlign.center);
        final msg = tester.widget<Text>(find.textContaining('geri alınamaz'));
        expect(msg.style!.fontSize, 15);
        expect(msg.style!.color, AppColors.light.textSecondary);
        expect(msg.textAlign, TextAlign.center);
        expect(
          card.bottom - tester.getBottomLeft(find.byType(AppButton).last).dy,
          greaterThanOrEqualTo(24 - 1),
        );
      },
    );

    testWidgets('mesajsız alert de çalışır', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener(message: null));
      await _open(tester);
      expect(find.text('Oda silinsin mi?'), findsOneWidget);
      expect(find.textContaining('geri alınamaz'), findsNothing);
    });
  });

  group('metin stili', () {
    testWidgets(
      'dialog\'da Material atası var: metin altı çizgili uyarı stiliyle çizilmez',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, const _Opener());
        await _open(tester);
        for (final label in ['Oda silinsin mi?']) {
          final rich = tester.widget<RichText>(
            find
                .descendant(
                  of: find.text(label),
                  matching: find.byType(RichText),
                )
                .first,
          );
          final decoration = rich.text.style?.decoration;
          expect(
            decoration == null || decoration == TextDecoration.none,
            isTrue,
            reason: label,
          );
        }
      },
    );
  });

  group('butonlar', () {
    testWidgets(
      'dikey: eylem üstte (destructiveStrong), Tertiary "Vazgeç" altta, tam genişlik',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, const _Opener());
        await _open(tester);
        final action = find.widgetWithText(AppButton, 'Odayı sil');
        final cancel = find.widgetWithText(AppButton, 'Vazgeç');
        expect(
          tester.widget<AppButton>(action).variant,
          AppButtonVariant.destructiveStrong,
        );
        expect(
          tester.widget<AppButton>(cancel).variant,
          AppButtonVariant.tertiary,
        );
        expect(
          tester.getCenter(action).dy,
          lessThan(tester.getCenter(cancel).dy),
        );
        expect(tester.getCenter(action).dx, tester.getCenter(cancel).dx);
        expect(tester.getSize(action).width, tester.getSize(cancel).width);
        expect(tester.getSize(action).width, 340 - 48);
        expect(
          tester.getTopLeft(cancel).dy - tester.getBottomLeft(action).dy,
          closeTo(8, 1),
        );
      },
    );

    testWidgets('destructive: false → Primary', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener(destructive: false));
      await _open(tester);
      expect(_button(tester, AppButtonVariant.primary).label, 'Odayı sil');
      expect(
        tester
            .widgetList<AppButton>(find.byType(AppButton))
            .where((b) => b.variant == AppButtonVariant.destructiveStrong),
        isEmpty,
      );
    });

    testWidgets('eylem true, Vazgeç false döner', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await _open(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Odayı sil'));
      await tester.pumpAndSettle();
      expect(find.text('sonuç: true'), findsOneWidget);
      await _open(tester);
      await tester.tap(find.widgetWithText(AppButton, 'Vazgeç'));
      await tester.pumpAndSettle();
      expect(find.text('sonuç: false'), findsOneWidget);
    });

    testWidgets(
      'Vazgeç metni özelleştirilebilir; İngilizce varsayılan "Cancel"',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, const _Opener(cancelLabel: 'Kalsın'));
        await _open(tester);
        expect(find.widgetWithText(AppButton, 'Kalsın'), findsOneWidget);
        await tester.tap(find.widgetWithText(AppButton, 'Kalsın'));
        await tester.pumpAndSettle();
        await pumpApp(tester, const _Opener(), locale: const Locale('en'));
        await _open(tester);
        expect(find.widgetWithText(AppButton, 'Cancel'), findsOneWidget);
      },
    );

    testWidgets('scrim\'e dokunmak kapatmaz', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await _open(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text('Oda silinsin mi?'), findsOneWidget);
    });
  });

  group('hareket', () {
    testWidgets('1,05 → 1 ölçek ve fade ile girer', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await tester.tap(find.text('Aç'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      final scale = tester
          .widget<ScaleTransition>(
            find
                .descendant(
                  of: find.byType(Navigator),
                  matching: find.byType(ScaleTransition),
                )
                .last,
          )
          .scale
          .value;
      final fade = tester
          .widget<FadeTransition>(
            find
                .descendant(
                  of: find.byType(Navigator),
                  matching: find.byType(FadeTransition),
                )
                .last,
          )
          .opacity
          .value;
      expect(scale, inInclusiveRange(1.0, 1.05));
      expect(fade, inInclusiveRange(0.0, 1.0));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ScaleTransition>(
              find
                  .descendant(
                    of: find.byType(Navigator),
                    matching: find.byType(ScaleTransition),
                  )
                  .last,
            )
            .scale
            .value,
        1.0,
      );
    });

    testWidgets('Reduce Motion: anında, hata yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener(), disableAnimations: true);
      await tester.tap(find.text('Aç'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(find.text('Oda silinsin mi?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('erişilebilirlik ve ölçek', () {
    testWidgets('rota adı başlık; başlık header; iki buton erişilebilir', (
      tester,
    ) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const _Opener());
      await _open(tester);
      expect(
        tester
            .getSemantics(find.text('Oda silinsin mi?'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      expect(find.bySemanticsLabel('Odayı sil'), findsOneWidget);
      expect(find.bySemanticsLabel('Vazgeç'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('yazı 2x: içerik ekran içinde kayar, taşma yok', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, const _Opener(), textScale: 2);
      await _open(tester);
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(_alertCard).height,
        lessThanOrEqualTo(844 * 0.8 + 0.5),
      );
    });
  });
}
