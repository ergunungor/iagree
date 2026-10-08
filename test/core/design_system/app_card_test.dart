import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/content/app_card.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_elevation.dart';

import '../../support/pump_app.dart';

Finder get _card => find.byType(AppCard);

/// Kartın dış kabı: surface dolgulu, radius 20.
Finder get _surface => find
    .descendant(
      of: _card,
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
ShapeDecoration _deco(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_surface).decoration as ShapeDecoration;
BorderSide _side(WidgetTester tester) =>
    (_deco(tester).shape as OutlinedBorder).side;

/// 2px brand seçili kenarlığı.
Finder get _selectedBorder => find.descendant(
  of: _card,
  matching: find.byWidgetPredicate((w) {
    if (w is! DecoratedBox) return false;
    final d = w.decoration;
    return d is ShapeDecoration &&
        d.color == null &&
        d.shape is RoundedSuperellipseBorder &&
        (d.shape as RoundedSuperellipseBorder).side.width == 2;
  }),
);

Widget _content([String text = 'Cuma akşamı']) => Text(text);

void main() {
  group('standart', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final e1 = dark ? AppElevation.dark.e1 : AppElevation.light.e1;
      final name = dark ? 'dark' : 'light';

      testWidgets('surface, radius lg, E1 $name', (tester) async {
        await pumpApp(tester, AppCard(child: _content()), dark: dark);
        expect(_deco(tester).color, c.surface);
        expect(_deco(tester).shadows, e1.shadows);
        expect(_side(tester), e1.side);
      });
    }

    testWidgets('içerik padding 16', (tester) async {
      await pumpApp(tester, AppCard(child: _content()));
      final card = tester.getRect(_card);
      final text = tester.getRect(find.text('Cuma akşamı'));
      expect(text.left - card.left, 16);
      expect(text.top - card.top, 16);
      expect(card.bottom - text.bottom, 16);
    });

    testWidgets('dokunulamaz: gesture ve semantics düğümü yok', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, AppCard(child: _content()));
      expect(
        find.descendant(of: _card, matching: find.byType(GestureDetector)),
        findsNothing,
      );
      expect(
        tester.getSemantics(find.text('Cuma akşamı')).label,
        'Cuma akşamı',
      );
      handle.dispose();
    });

    testWidgets('Increase Contrast: borderControl kenarı', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: MaterialApp(
            theme: ThemeData(extensions: [AppColors.light]),
            home: Scaffold(body: AppCard(child: _content())),
          ),
        ),
      );
      expect(_side(tester).color, AppColors.lightHighContrast.borderControl);
      expect(_side(tester).width, 1);
    });
  });

  group('interaktif', () {
    testWidgets('semanticLabel zorunlu', (tester) async {
      expect(
        () => AppCard(onPressed: () {}, child: _content()),
        throwsAssertionError,
      );
    });

    testWidgets('dokununca çağrılır; tam genişlik', (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        AppCard(
          onPressed: () => taps++,
          semanticLabel: 'Kart',
          child: _content(),
        ),
      );
      await tester.tap(_card);
      expect(taps, 1);
      expect(tester.getSize(_card).width, 760);
    });

    testWidgets('basılı: 0.97 scale + textPrimary %4 örtü; bırakınca kalkar', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppCard(onPressed: () {}, semanticLabel: 'Kart', child: _content()),
      );
      Finder overlay() =>
          find.descendant(of: _card, matching: find.byType(AnimatedOpacity));
      expect(tester.widget<AnimatedOpacity>(overlay()).opacity, 0);
      final g = await tester.startGesture(tester.getCenter(_card));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.widget<AnimatedOpacity>(overlay()).opacity, 1);
      final color = tester
          .widget<ColoredBox>(
            find.descendant(of: overlay(), matching: find.byType(ColoredBox)),
          )
          .color;
      expect(color.a, closeTo(0.04, 0.005));
      expect(
        color.toARGB32() & 0xFFFFFF,
        AppColors.light.textPrimary.toARGB32() & 0xFFFFFF,
      );
      final t = tester.widget<Transform>(
        find.descendant(of: _card, matching: find.byType(Transform)).first,
      );
      expect(t.transform.entry(0, 0), closeTo(0.97, 1e-3));
      await g.up();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedOpacity>(overlay()).opacity, 0);
    });

    testWidgets('tek öğe olarak okunur', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        AppCard(
          onPressed: () {},
          semanticLabel: 'Trattoria Lume. İtalyan, orta fiyat, 1,2 kilometre.',
          child: _content('Trattoria Lume'),
        ),
      );
      final node = tester.getSemantics(_card);
      expect(node.label, 'Trattoria Lume. İtalyan, orta fiyat, 1,2 kilometre.');
      expect(node.flagsCollection.isButton, isTrue);
      expect(find.bySemanticsLabel('Trattoria Lume'), findsNothing);
      handle.dispose();
    });
  });

  group('seçili', () {
    testWidgets('2px brand kenar; boyut ve içerik konumu değişmez', (
      tester,
    ) async {
      Future<void> pump(bool selected) => pumpApp(
        tester,
        AppCard(
          selected: selected,
          onPressed: () {},
          semanticLabel: 'Kart',
          child: _content(),
        ),
      );
      await pump(false);
      expect(_selectedBorder, findsNothing);
      final size = tester.getSize(_card);
      final textPos = tester.getTopLeft(find.text('Cuma akşamı'));
      await pump(true);
      expect(_selectedBorder, findsOneWidget);
      final side =
          (tester.widget<DecoratedBox>(_selectedBorder).decoration
                      as ShapeDecoration)
                  .shape
              as OutlinedBorder;
      expect(side.side.color, AppColors.light.brand);
      expect(side.side.width, 2);
      expect(tester.getSize(_card), size);
      expect(tester.getTopLeft(find.text('Cuma akşamı')), textPos);
    });

    testWidgets('semantics: seçili', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        AppCard(
          selected: true,
          onPressed: () {},
          semanticLabel: 'Kart',
          child: _content(),
        ),
      );
      expect(
        tester.getSemantics(_card).flagsCollection.isSelected.toString(),
        contains('isTrue'),
      );
      handle.dispose();
    });
  });

  group('medya', () {
    testWidgets('üstte 4:3 görsel, kenardan kenara; metin alanı padding 16', (
      tester,
    ) async {
      const key = ValueKey('media');
      await pumpApp(
        tester,
        SizedBox(
          width: 320,
          child: AppCard(
            media: const ColoredBox(key: key, color: Colors.teal),
            child: _content(),
          ),
        ),
      );
      final card = tester.getRect(_card);
      final media = tester.getRect(find.byKey(key));
      expect(media.width, card.width);
      expect(media.left, card.left);
      expect(media.top, card.top);
      expect(media.width / media.height, closeTo(4 / 3, 0.001));
      final text = tester.getRect(find.text('Cuma akşamı'));
      expect(text.top - media.bottom, 16);
      expect(text.left - card.left, 16);
      expect(card.bottom - text.bottom, 16);
    });

    testWidgets('görsel kartın köşelerine göre kırpılır', (tester) async {
      await pumpApp(
        tester,
        SizedBox(
          width: 320,
          child: AppCard(
            media: const ColoredBox(color: Colors.teal),
            child: _content(),
          ),
        ),
      );
      final clip = tester.widget<ClipPath>(
        find.descendant(of: _card, matching: find.byType(ClipPath)).first,
      );
      final path = (clip.clipper! as ShapeBorderClipper).getClip(
        tester.getSize(_card),
      );
      expect(path.contains(const Offset(1, 1)), isFalse);
      expect(path.contains(Offset(tester.getSize(_card).width / 2, 1)), isTrue);
    });
  });

  testWidgets('yazı 2x: taşma yok', (tester) async {
    await pumpApp(
      tester,
      SizedBox(
        width: 320,
        child: AppCard(
          onPressed: () {},
          semanticLabel: 'Kart',
          media: const ColoredBox(color: Colors.teal),
          child: _content('Trattoria Lume · İtalyan · ₺₺'),
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('mediaAspectRatio: varsayılan 4:3, verilince o oran', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const SizedBox(
        width: 300,
        child: AppCard(
          media: ColoredBox(key: ValueKey('m'), color: Colors.red),
          child: Text('x'),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('m'))).height,
      closeTo(225, 0.01),
    );
    await pumpApp(
      tester,
      const SizedBox(
        width: 300,
        child: AppCard(
          mediaAspectRatio: 16 / 10,
          media: ColoredBox(key: ValueKey('m'), color: Colors.red),
          child: Text('x'),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('m'))).height,
      closeTo(187.5, 0.01),
    );
  });
}
