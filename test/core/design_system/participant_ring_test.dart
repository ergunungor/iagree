import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/people/app_avatar.dart';
import 'package:iagree/core/design_system/components/people/participant_ring.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

Finder get _ring => find.byType(ParticipantRing);
Finder get _arc => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is ParticipantArcPainter,
);
Finder get _dashed => find.byWidgetPredicate(
  (w) => w is CustomPaint && w.painter is DashedCirclePainter,
);
ParticipantArcPainter _arcPainter(WidgetTester tester) =>
    tester.widget<CustomPaint>(_arc).painter! as ParticipantArcPainter;
Finder get _badge => find.byIcon(AppIcons.check);

Widget _host(
  ParticipantStatus status, {
  double progress = 0,
  AppAvatarSize size = AppAvatarSize.md,
  Key? key,
}) => ParticipantRing(
  key: key,
  userId: 'u-can',
  name: 'Can',
  status: status,
  progress: progress,
  size: size,
);

void main() {
  group('boyut ve yerleşim', () {
    testWidgets('kutu avatar + 8 (2pt boşluk + 2pt halka), her durumda aynı', (
      tester,
    ) async {
      for (final status in ParticipantStatus.values) {
        await pumpApp(tester, _host(status, progress: 0.5));
        expect(tester.getSize(_ring), const Size.square(48), reason: '$status');
      }
      await pumpApp(
        tester,
        _host(ParticipantStatus.joined, size: AppAvatarSize.lg),
      );
      expect(tester.getSize(_ring), const Size.square(64));
      expect(ParticipantRing.outerSize(AppAvatarSize.xl), 96);
    });

    test('progress 0–1 dışında kabul edilmez', () {
      expect(
        () => ParticipantRing(
          userId: 'u',
          name: 'x',
          status: ParticipantStatus.choosing,
          progress: 1.1,
        ),
        throwsAssertionError,
      );
      expect(
        () => ParticipantRing(
          userId: 'u',
          name: 'x',
          status: ParticipantStatus.choosing,
          progress: -0.1,
        ),
        throwsAssertionError,
      );
    });
  });

  group('invited', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      testWidgets(
        'kesik çizgi borderControl, avatar yok ${dark ? 'dark' : 'light'}',
        (tester) async {
          await pumpApp(tester, _host(ParticipantStatus.invited), dark: dark);
          final painter =
              tester.widget<CustomPaint>(_dashed).painter!
                  as DashedCirclePainter;
          expect(painter.color, c.borderControl);
          expect(painter.strokeWidth, 2);
          expect(painter.diameter, 40);
          expect(find.byType(AppAvatar), findsNothing);
          expect(_arc, findsNothing);
          expect(_badge, findsNothing);
        },
      );
    }

    test('çizgi sayısı çevreye göre eşit aralıklı', () {
      const p = DashedCirclePainter(
        color: Colors.black,
        diameter: 40,
        strokeWidth: 2,
      );
      expect(p.dashCount, (math.pi * 38 / 8).round());
      const big = DashedCirclePainter(
        color: Colors.black,
        diameter: 56,
        strokeWidth: 2,
      );
      expect(big.dashCount, greaterThan(p.dashCount));
    });
  });

  group('joined', () {
    testWidgets('halka yok, avatar var', (tester) async {
      await pumpApp(tester, _host(ParticipantStatus.joined));
      expect(find.byType(AppAvatar), findsOneWidget);
      expect(_arcPainter(tester).sweep, 0);
      expect(_dashed, findsNothing);
      expect(_badge, findsNothing);
    });
  });

  group('choosing', () {
    testWidgets('brand yay, ilerleme kadar dolar, 2pt', (tester) async {
      await pumpApp(tester, _host(ParticipantStatus.choosing, progress: 0.6));
      final p = _arcPainter(tester);
      expect(p.sweep, closeTo(0.6, 1e-9));
      expect(p.color, AppColors.light.brand);
      expect(p.strokeWidth, 2);
      expect(_badge, findsNothing);
    });

    testWidgets(
      'ilerleme canlı: emphasis ile yumuşakça dolar (ara değer görülür)',
      (tester) async {
        await pumpApp(
          tester,
          _host(
            ParticipantStatus.choosing,
            progress: 0.2,
            key: const ValueKey('r'),
          ),
        );
        await pumpApp(
          tester,
          _host(
            ParticipantStatus.choosing,
            progress: 0.8,
            key: const ValueKey('r'),
          ),
          settle: false,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        final mid = _arcPainter(tester).sweep;
        expect(mid, greaterThan(0.2));
        expect(mid, lessThan(0.8));
        await tester.pumpAndSettle();
        expect(_arcPainter(tester).sweep, closeTo(0.8, 1e-9));
      },
    );

    testWidgets('Reduce Motion: ilerleme anında', (tester) async {
      await pumpApp(
        tester,
        _host(
          ParticipantStatus.choosing,
          progress: 0.2,
          key: const ValueKey('r'),
        ),
        disableAnimations: true,
      );
      await pumpApp(
        tester,
        _host(
          ParticipantStatus.choosing,
          progress: 0.8,
          key: const ValueKey('r'),
        ),
        disableAnimations: true,
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(_arcPainter(tester).sweep, closeTo(0.8, 1e-9));
    });
  });

  group('ready', () {
    testWidgets('tam brand halka + sağ altta 18\'lik ✓ rozeti', (tester) async {
      await pumpApp(tester, _host(ParticipantStatus.ready));
      expect(_arcPainter(tester).sweep, 1);
      final badge = tester.getRect(
        find.ancestor(of: _badge, matching: find.byType(SizedBox)).first,
      );
      expect(badge.size, const Size.square(18));
      final ring = tester.getRect(_ring);
      expect(badge.center.dx, greaterThan(ring.center.dx));
      expect(badge.center.dy, greaterThan(ring.center.dy));
      final icon = tester.widget<Icon>(_badge);
      expect(icon.color, AppColors.light.onBrand);
    });

    testWidgets('rozet brand dolgulu, çevresinde 2px canvas halka', (
      tester,
    ) async {
      await pumpApp(tester, _host(ParticipantStatus.ready));
      // Halkanın içindeki, ShapeDecoration'lı daire kutuları: avatar tinti dışında rozet.
      final circles = find
          .descendant(
            of: _ring,
            matching: find.byWidgetPredicate(
              (w) =>
                  w is DecoratedBox &&
                  w.decoration is ShapeDecoration &&
                  (w.decoration as ShapeDecoration).shape is CircleBorder,
            ),
          )
          .evaluate()
          .map((e) => e.widget as DecoratedBox)
          .toList();
      final colors = circles
          .map((b) => (b.decoration as ShapeDecoration).color)
          .toList();
      expect(
        colors,
        containsAll([AppColors.light.brand, AppColors.light.canvas]),
      );
      final canvasCircle = find.byWidgetPredicate(
        (w) =>
            w is DecoratedBox &&
            w.decoration is ShapeDecoration &&
            (w.decoration as ShapeDecoration).color == AppColors.light.canvas,
      );
      expect(tester.getSize(canvasCircle.first), const Size.square(22));
    });

    testWidgets('dark temada renkler', (tester) async {
      await pumpApp(tester, _host(ParticipantStatus.ready), dark: true);
      expect(_arcPainter(tester).color, AppColors.dark.brand);
      expect(tester.widget<Icon>(_badge).color, AppColors.dark.onBrand);
    });

    testWidgets(
      'choosing → ready: rozet springBouncy ile belirir (0\'dan başlar, taşar, 1\'e oturur)',
      (tester) async {
        await pumpApp(
          tester,
          _host(
            ParticipantStatus.choosing,
            progress: 1,
            key: const ValueKey('r'),
          ),
        );
        expect(_badge, findsNothing);
        await pumpApp(
          tester,
          _host(ParticipantStatus.ready, key: const ValueKey('r')),
          settle: false,
        );
        double scale() => tester
            .widget<Transform>(
              find.ancestor(of: _badge, matching: find.byType(Transform)).first,
            )
            .transform
            .entry(0, 0);
        await tester.pump();
        expect(scale(), lessThan(0.2));
        var peak = 0.0;
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          peak = math.max(peak, scale());
        }
        expect(peak, greaterThan(1.0), reason: 'bouncy: hafif taşar');
        expect(peak, lessThan(1.5));
        await tester.pumpAndSettle();
        expect(scale(), closeTo(1, 0.01));
      },
    );

    testWidgets('Reduce Motion: rozet anında tam boyutta', (tester) async {
      await pumpApp(
        tester,
        _host(
          ParticipantStatus.choosing,
          progress: 1,
          key: const ValueKey('r'),
        ),
        disableAnimations: true,
      );
      await pumpApp(
        tester,
        _host(ParticipantStatus.ready, key: const ValueKey('r')),
        disableAnimations: true,
        settle: false,
      );
      await tester.pump();
      final t = tester.widget<Transform>(
        find.ancestor(of: _badge, matching: find.byType(Transform)).first,
      );
      expect(t.transform.entry(0, 0), 1);
    });

    testWidgets('ready\'den çıkınca rozet kalkar', (tester) async {
      await pumpApp(
        tester,
        _host(ParticipantStatus.ready, key: const ValueKey('r')),
      );
      await pumpApp(
        tester,
        _host(ParticipantStatus.joined, key: const ValueKey('r')),
      );
      expect(_badge, findsNothing);
    });
  });

  group('VoiceOver', () {
    Future<String> label(
      WidgetTester tester,
      ParticipantStatus s, {
      double progress = 0,
      Locale locale = const Locale('tr'),
    }) async {
      await pumpApp(tester, _host(s, progress: progress), locale: locale);
      return tester.getSemantics(_ring).label;
    }

    testWidgets('Türkçe: "Can, seçiyor, yüzde 60" ve diğer durumlar', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      expect(
        await label(tester, ParticipantStatus.choosing, progress: 0.6),
        'Can, seçiyor, yüzde 60',
      );
      expect(await label(tester, ParticipantStatus.ready), 'Can, hazır');
      expect(await label(tester, ParticipantStatus.joined), 'Can, katıldı');
      expect(await label(tester, ParticipantStatus.invited), 'Can, bekleniyor');
      handle.dispose();
    });

    testWidgets('İngilizce', (tester) async {
      final handle = tester.ensureSemantics();
      expect(
        await label(
          tester,
          ParticipantStatus.choosing,
          progress: 0.6,
          locale: const Locale('en'),
        ),
        'Can, choosing, 60 percent',
      );
      expect(
        await label(
          tester,
          ParticipantStatus.ready,
          locale: const Locale('en'),
        ),
        'Can, ready',
      );
      handle.dispose();
    });

    testWidgets('yüzde yuvarlanır', (tester) async {
      final handle = tester.ensureSemantics();
      expect(
        await label(tester, ParticipantStatus.choosing, progress: 0.333),
        'Can, seçiyor, yüzde 33',
      );
      handle.dispose();
    });
  });
}
