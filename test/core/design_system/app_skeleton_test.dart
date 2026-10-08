import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/feedback/app_skeleton.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

Finder get _fade => find.descendant(
  of: find.byType(AppSkeleton),
  matching: find.byType(FadeTransition),
);
double _opacity(WidgetTester tester) =>
    tester.widget<FadeTransition>(_fade).opacity.value;
Finder get _blocks => find.descendant(
  of: find.byType(AppSkeleton),
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is ShapeDecoration &&
        (w.decoration as ShapeDecoration).color == AppColors.light.surfaceMuted,
  ),
);

void main() {
  group('görünüm', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      testWidgets(
        'tek blok surfaceMuted, radius xs ${dark ? 'dark' : 'light'}',
        (tester) async {
          await pumpApp(
            tester,
            const AppSkeleton(width: 120),
            dark: dark,
            settle: false,
          );
          final deco =
              tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: find.byType(AppSkeleton),
                              matching: find.byType(DecoratedBox),
                            )
                            .first,
                      )
                      .decoration
                  as ShapeDecoration;
          expect(deco.color, c.surfaceMuted);
          expect(
            (deco.shape as RoundedSuperellipseBorder).borderRadius,
            BorderRadius.circular(6),
          );
          expect(tester.getSize(find.byType(AppSkeleton)), const Size(120, 16));
        },
      );
    }

    testWidgets('lines: 3 satır, aralarında 8, son satır daha kısa', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const SizedBox(width: 300, child: AppSkeleton.lines()),
        settle: false,
      );
      expect(_blocks, findsNWidgets(3));
      final rects = [for (var i = 0; i < 3; i++) tester.getRect(_blocks.at(i))];
      expect(rects[1].top - rects[0].bottom, 8);
      expect(rects[2].top - rects[1].bottom, 8);
      expect(rects[0].width, 300);
      expect(rects[1].width, 300);
      expect(rects[2].width, closeTo(180, 0.5));
    });

    testWidgets('1 ve 2 satır; tek satırda kısaltma yok', (tester) async {
      await pumpApp(
        tester,
        const SizedBox(width: 300, child: AppSkeleton.lines(lines: 1)),
        settle: false,
      );
      expect(tester.getSize(_blocks.first).width, 300);
      await pumpApp(
        tester,
        const SizedBox(width: 300, child: AppSkeleton.lines(lines: 2)),
        settle: false,
      );
      expect(_blocks, findsNWidgets(2));
    });

    test('en fazla 3 satır', () {
      expect(() => AppSkeleton.lines(lines: 4), throwsAssertionError);
      expect(() => AppSkeleton.lines(lines: 0), throwsAssertionError);
    });
  });

  group('nabız', () {
    testWidgets('opaklık 1 → 0,6 → 1; shimmer yok', (tester) async {
      await pumpApp(tester, const AppSkeleton(width: 100), settle: false);
      await tester.pump();
      expect(_opacity(tester), closeTo(1, 0.01));
      var low = 1.0;
      var high = 0.0;
      for (var i = 0; i < 80; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        low = low < _opacity(tester) ? low : _opacity(tester);
        high = high > _opacity(tester) ? high : _opacity(tester);
      }
      expect(low, closeTo(0.6, 0.02));
      expect(high, closeTo(1, 0.02));
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('her yön expressive (600 ms): ~600 ms\'de dip', (tester) async {
      await pumpApp(tester, const AppSkeleton(width: 100), settle: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(_opacity(tester), closeTo(0.6, 0.03));
      await tester.pump(const Duration(milliseconds: 600));
      expect(_opacity(tester), closeTo(1, 0.03));
    });

    testWidgets('Reduce Motion: nabız yok, opaklık 1, kare planlanmaz', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppSkeleton(width: 100),
        disableAnimations: true,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(_opacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
      await tester.pumpAndSettle();
    });

    testWidgets('Reduce Motion sonradan açılırsa nabız durur', (tester) async {
      await pumpApp(tester, const AppSkeleton(width: 100), settle: false);
      await tester.pump(const Duration(milliseconds: 300));
      await pumpApp(
        tester,
        const AppSkeleton(width: 100),
        disableAnimations: true,
        settle: false,
      );
      await tester.pump(const Duration(milliseconds: 50));
      expect(_opacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('semantics', () {
    testWidgets('grup bir kez "Yükleniyor"; tek blok süs', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const Column(children: [AppSkeleton(width: 50), AppSkeleton.lines()]),
        settle: false,
      );
      await tester.pump();
      expect(find.bySemanticsLabel('Yükleniyor'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('İngilizce: "Loading"', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const AppSkeleton.lines(),
        locale: const Locale('en'),
        settle: false,
      );
      await tester.pump();
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });
  });
}
