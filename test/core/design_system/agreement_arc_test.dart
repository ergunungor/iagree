import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/agreement/agreement_arc.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_fixed_colors.dart';

import '../../support/pump_app.dart';

final _light = AppColors.light;

Finder get _arc => find.byType(AgreementArc);
Finder get _paint =>
    find.descendant(of: _arc, matching: find.byType(CustomPaint)).first;

Widget _arcOf({
  int love = 2,
  int ok = 2,
  int total = 5,
  AgreementArcSize size = AgreementArcSize.large,
  bool onMoment = false,
  bool animate = false,
}) => AgreementArc(
  loveCount: love,
  okCount: ok,
  total: total,
  size: size,
  onMoment: onMoment,
  animate: animate,
);

Text _number(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text));

void main() {
  group('boyutlar ve çizim', () {
    final specs = {
      AgreementArcSize.small: (32.0, 4.0),
      AgreementArcSize.medium: (64.0, 6.0),
      AgreementArcSize.large: (160.0, 14.0),
    };
    for (final e in specs.entries) {
      testWidgets(
        '${e.key.name}: genişlik ${e.value.$1}, çizgi ${e.value.$2}',
        (tester) async {
          await pumpApp(tester, _arcOf(size: e.key));
          final (width, stroke) = e.value;
          expect(tester.getSize(_paint).width, width);
          expect(tester.getSize(_paint).height, width / 2 + stroke / 2);
          expect(
            _paint,
            paints
              ..arc(color: _light.surfacePressed, strokeWidth: stroke)
              ..arc(color: _light.brand, strokeWidth: stroke)
              ..arc(color: _light.brandMuted, strokeWidth: stroke),
          );
        },
      );
    }

    testWidgets(
      'iz, soldan Çok isterim sonra Olur; yalnız biri varsa tek dilim',
      (tester) async {
        await pumpApp(tester, _arcOf(love: 0, ok: 3, total: 4));
        expect(
          _paint,
          paints
            ..arc(color: _light.surfacePressed)
            ..arc(color: _light.brandMuted),
        );
        await pumpApp(tester, _arcOf(love: 3, ok: 0, total: 4));
        expect(
          _paint,
          paints
            ..arc(color: _light.surfacePressed)
            ..arc(color: _light.brand),
        );
      },
    );

    testWidgets('dark temada dark renkler', (tester) async {
      await pumpApp(tester, _arcOf(), dark: true);
      expect(
        _paint,
        paints
          ..arc(color: AppColors.dark.surfacePressed)
          ..arc(color: AppColors.dark.brand)
          ..arc(color: AppColors.dark.brandMuted),
      );
    });

    testWidgets('onMoment: momentTrack iz, momentInk tek ton dolgu', (
      tester,
    ) async {
      await pumpApp(tester, _arcOf(onMoment: true));
      expect(
        _paint,
        paints
          ..arc(color: AppFixedColors.momentTrack)
          ..arc(color: AppFixedColors.momentInk),
      );
      expect(_number(tester, '%80').style!.color, AppFixedColors.momentInk);
      expect(
        _number(tester, '4/5 kişi').style!.color,
        AppFixedColors.momentInk,
      );
    });

    testWidgets('kimse olumlu değilse yalnızca iz çizilir', (tester) async {
      await pumpApp(tester, _arcOf(love: 0, ok: 0, total: 5));
      expect(_paint, paints..arc(color: _light.surfacePressed));
      expect(find.text('%0'), findsOneWidget);
    });
  });

  group('metin', () {
    testWidgets('S: yüzde yayın sağında, caption 600; kişi sayısı yok', (
      tester,
    ) async {
      await pumpApp(tester, _arcOf(size: AgreementArcSize.small));
      final t = _number(tester, '%80');
      expect(t.style!.fontSize, 13);
      expect(t.style!.fontWeight, FontWeight.w600);
      expect(
        tester.getTopLeft(find.text('%80')).dx,
        greaterThan(tester.getTopRight(_paint).dx - 1),
      );
      expect(find.textContaining('kişi'), findsNothing);
    });

    testWidgets('M: yüzde yay içinde, title; altında "4/5 kişi"', (
      tester,
    ) async {
      await pumpApp(tester, _arcOf(size: AgreementArcSize.medium));
      final t = _number(tester, '%80');
      expect(t.style!.fontSize, 17);
      expect(t.style!.fontWeight, FontWeight.w600);
      final arcRect = tester.getRect(_paint);
      expect(arcRect.contains(tester.getCenter(find.text('%80'))), isTrue);
      expect(
        tester.getTopLeft(find.text('4/5 kişi')).dy,
        greaterThanOrEqualTo(arcRect.bottom),
      );
    });

    testWidgets('L: yüzde 34 bold, tabular; kişi sayısı altında', (
      tester,
    ) async {
      await pumpApp(tester, _arcOf());
      final t = _number(tester, '%80');
      expect(t.style!.fontSize, 34);
      expect(t.style!.fontWeight, FontWeight.w700);
      expect(
        t.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(find.text('4/5 kişi'), findsOneWidget);
      expect(t.style!.fontFamily, isNot('Fraunces'));
    });

    for (final size in [AgreementArcSize.medium, AgreementArcSize.large]) {
      testWidgets(
        '${size.name}: %100 yayın çizgilerine değmeden iç alana sığar',
        (tester) async {
          await pumpApp(tester, _arcOf(love: 0, ok: 5, size: size));
          final text = tester.getRect(find.text('%100'));
          final arc = tester.getRect(_paint);
          final inset = size.stroke + 8;
          expect(text.left, greaterThanOrEqualTo(arc.left + inset - 0.01));
          expect(text.right, lessThanOrEqualTo(arc.right - inset + 0.01));
        },
      );
    }

    testWidgets('yüzde aşağı yuvarlanır: 2/3 → %66', (tester) async {
      await pumpApp(tester, _arcOf(love: 0, ok: 2, total: 3));
      expect(find.text('%66'), findsOneWidget);
      expect(find.text('2/3 kişi'), findsOneWidget);
    });

    testWidgets('en: 80% ve people', (tester) async {
      await pumpApp(tester, _arcOf(), locale: const Locale('en'));
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('4/5 people'), findsOneWidget);
    });

    for (final size in AgreementArcSize.values) {
      testWidgets('yazı 2x: sayı en fazla 1.5x, taşma yok (${size.name})', (
        tester,
      ) async {
        await pumpApp(tester, _arcOf(size: size), textScale: 2);
        final ctx = tester.element(find.text('%80'));
        expect(MediaQuery.textScalerOf(ctx).scale(10), 15);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('animasyon', () {
    Future<void> start(WidgetTester tester, {bool reduce = false}) async {
      await pumpApp(
        tester,
        _arcOf(animate: true),
        disableAnimations: reduce,
        settle: false,
      );
      await tester.pump();
    }

    int shown(WidgetTester tester) {
      final text = tester
          .widgetList<Text>(
            find.descendant(of: _arc, matching: find.byType(Text)),
          )
          .map((t) => t.data!)
          .firstWhere((s) => s.startsWith('%'));
      return int.parse(text.substring(1));
    }

    testWidgets('100 ms gecikme: bu sürede yay ve sayı 0', (tester) async {
      await start(tester);
      await tester.pump(const Duration(milliseconds: 90));
      expect(shown(tester), 0);
      expect(_paint, paints..arc(color: _light.surfacePressed));
    });

    testWidgets('sayı yayla eşzamanlı sayar, artarak son değere varır', (
      tester,
    ) async {
      await start(tester);
      var last = -1;
      var sawMid = false;
      for (var i = 0; i < 50; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final v = shown(tester);
        expect(v, greaterThanOrEqualTo(last));
        if (v > 0 && v < 80) sawMid = true;
        last = v;
      }
      expect(sawMid, isTrue);
      await tester.pump(const Duration(milliseconds: 400));
      expect(shown(tester), 80);
      expect(
        _paint,
        paints
          ..arc(color: _light.surfacePressed)
          ..arc(color: _light.brand)
          ..arc(color: _light.brandMuted),
      );
    });

    testWidgets('toplam süre 100 ms + 600 ms; sonra kare planlanmaz', (
      tester,
    ) async {
      await start(tester);
      await tester.pump(const Duration(milliseconds: 650));
      expect(shown(tester), lessThan(100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(shown(tester), 80);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('Reduce Motion: doğrudan son değer, animasyon yok', (
      tester,
    ) async {
      await start(tester, reduce: true);
      expect(shown(tester), 80);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('animate: false: doğrudan son değer', (tester) async {
      await pumpApp(tester, _arcOf(), settle: false);
      await tester.pump();
      expect(shown(tester), 80);
    });

    testWidgets(
      'sayılar sonradan değişirse anında yeni değer, yeniden dolma yok',
      (tester) async {
        await pumpApp(tester, _arcOf(animate: true));
        expect(shown(tester), 80);
        await pumpApp(
          tester,
          _arcOf(love: 1, ok: 1, total: 5, animate: true),
          settle: false,
        );
        await tester.pump();
        expect(shown(tester), 40);
      },
    );
  });

  group('semantics', () {
    testWidgets('tr: tek düğüm, sayıya ek yok', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _arcOf());
      expect(
        tester.getSemantics(_arc).label,
        'Uyum yüzde 80. Toplam 5 kişi, olumlu 4, çok isteyen 2.',
      );
      expect(find.bySemanticsLabel('%80'), findsNothing);
      handle.dispose();
    });

    testWidgets('çok isteyen yoksa o kısım yok', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _arcOf(love: 0, ok: 3, total: 4));
      expect(
        tester.getSemantics(_arc).label,
        'Uyum yüzde 75. Toplam 4 kişi, olumlu 3.',
      );
      handle.dispose();
    });

    testWidgets('en cümlesi', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _arcOf(), locale: const Locale('en'));
      expect(
        tester.getSemantics(_arc).label,
        'Agreement 80 percent. 4 of 5 people are in favor, 2 of them really want it.',
      );
      handle.dispose();
    });
  });

  test('geçersiz sayılar assert verir', () {
    expect(
      () => AgreementArc(loveCount: 3, okCount: 3, total: 5),
      throwsAssertionError,
    );
    expect(
      () => AgreementArc(loveCount: -1, okCount: 0, total: 5),
      throwsAssertionError,
    );
  });
}
