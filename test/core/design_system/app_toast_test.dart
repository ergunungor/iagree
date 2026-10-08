import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/feedback/app_toast.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_elevation.dart';
import 'package:iagree/core/design_system/tokens/app_fixed_colors.dart';

import '../../support/pump_app.dart';

/// 390×844, üstte 47 pt safe area.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47 * 3);
  addTearDown(tester.view.reset);
}

class _Host extends StatelessWidget {
  const _Host({
    this.kind = AppToastKind.neutral,
    this.message = 'Oda kaydedildi',
    this.action,
    this.onAction,
    this.onHandle,
  });
  final AppToastKind kind;
  final String message;
  final String? action;
  final VoidCallback? onAction;
  final ValueChanged<AppToastHandle>? onHandle;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: () {
      final handle = AppToast.show(
        context,
        message: message,
        kind: kind,
        actionLabel: action,
        onAction: onAction,
      );
      onHandle?.call(handle);
    },
    child: const Text('Göster'),
  );
}

Finder get _pill => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final d = w.decoration;
  return d is ShapeDecoration && d.color == AppFixedColors.inverseSurface;
});
ShapeDecoration _deco(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_pill).decoration as ShapeDecoration;

Future<void> _show(WidgetTester tester) async {
  await tester.tap(find.text('Göster'));
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  tearDown(() {
    // Test sonunda kalan toast bir sonraki teste sızmasın.
  });

  group('görünüm', () {
    for (final dark in [false, true]) {
      final name = dark ? 'dark' : 'light';
      testWidgets('inverseSurface pill, E2, iki temada aynı zemin $name', (
        tester,
      ) async {
        _phone(tester);
        await pumpApp(tester, const _Host(), dark: dark);
        await _show(tester);
        expect(_deco(tester).color, AppFixedColors.inverseSurface);
        expect(
          (_deco(tester).shape as RoundedSuperellipseBorder).borderRadius,
          BorderRadius.circular(999),
        );
        final e2 = dark ? AppElevation.dark.e2 : AppElevation.light.e2;
        expect(_deco(tester).shadows, e2.shadows);
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      });
    }

    testWidgets('ekranın üstünde: safe area + 8, yatayda ortalı', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, const _Host());
      await _show(tester);
      final r = tester.getRect(_pill);
      expect(r.top, closeTo(47 + 8, 0.5));
      expect(r.center.dx, closeTo(195, 0.5));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'min yükseklik 44, yatay padding 16, ikon 20 solda, metin bodySmall inverseText',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, const _Host());
        await _show(tester);
        final r = tester.getRect(_pill);
        expect(r.height, greaterThanOrEqualTo(44));
        final icon = tester.getRect(find.byIcon(AppIcons.info));
        expect(icon.left - r.left, 16);
        expect(icon.width, 20);
        final text = tester.widget<Text>(find.text('Oda kaydedildi'));
        expect(text.style!.fontSize, 15);
        expect(text.style!.color, AppFixedColors.inverseText);
        expect(
          r.right - tester.getRect(find.text('Oda kaydedildi')).right,
          greaterThanOrEqualTo(16 - 0.5),
        );
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'ikonlar: nötr info/inverseText, başarı ✓/inverseSuccess, hata ⚠/inverseError',
      (tester) async {
        _phone(tester);
        final cases = {
          AppToastKind.neutral: (AppIcons.info, AppFixedColors.inverseText),
          AppToastKind.success: (AppIcons.check, AppFixedColors.inverseSuccess),
          AppToastKind.error: (AppIcons.warning, AppFixedColors.inverseError),
        };
        for (final e in cases.entries) {
          await pumpApp(tester, _Host(kind: e.key));
          await _show(tester);
          final icon = tester.widget<Icon>(find.byIcon(e.value.$1));
          expect(icon.color, e.value.$2, reason: '${e.key}');
          await tester.pump(const Duration(seconds: 4));
          await tester.pumpAndSettle();
        }
      },
    );

    testWidgets('metin en fazla 2 satır, taşan "…" ile kesilir', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _Host(message: 'Bağlantı kurulamadı. ' * 12));
      await _show(tester);
      final text = tester.widget<Text>(find.byType(Text).last);
      expect(text.maxLines, 2);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  group('metin stili', () {
    testWidgets(
      'Overlay\'de Material atası var: metin altı çizgili uyarı stiliyle çizilmez',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, _Host(action: 'Geri al', onAction: () {}));
        await _show(tester);
        for (final label in ['Oda kaydedildi', 'Geri al']) {
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
          expect(
            find.ancestor(
              of: find.text(label),
              matching: find.byType(Material),
            ),
            findsWidgets,
          );
        }
        await tester.pump(const Duration(seconds: 6));
        await tester.pumpAndSettle();
      },
    );
  });

  group('süre ve tekillik', () {
    testWidgets('3 sn sonra kapanır (eylemsiz)', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Host());
      await _show(tester);
      expect(AppToast.isShowing, isTrue);
      await tester.pump(const Duration(milliseconds: 2900));
      expect(find.text('Oda kaydedildi'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Oda kaydedildi'), findsNothing);
      expect(AppToast.isShowing, isFalse);
    });

    testWidgets('eylemli: 5 sn', (tester) async {
      _phone(tester);
      await pumpApp(tester, _Host(action: 'Geri al', onAction: () {}));
      await _show(tester);
      await tester.pump(const Duration(milliseconds: 4900));
      expect(find.text('Oda kaydedildi'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Oda kaydedildi'), findsNothing);
    });

    testWidgets('VoiceOver açıkken eylemli: 10 sn', (tester) async {
      _phone(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpApp(tester, _Host(action: 'Geri al', onAction: () {}));
      await _show(tester);
      await tester.pump(const Duration(milliseconds: 9900));
      expect(find.text('Oda kaydedildi'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Oda kaydedildi'), findsNothing);
    });

    testWidgets('aynı anda tek toast: yenisi eskisinin yerini alır', (
      tester,
    ) async {
      _phone(tester);
      late BuildContext ctx;
      await pumpApp(
        tester,
        Builder(
          builder: (c) {
            ctx = c;
            return const SizedBox();
          },
        ),
      );
      AppToast.show(ctx, message: 'Birinci');
      await tester.pump();
      AppToast.show(ctx, message: 'İkinci');
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Birinci'), findsNothing);
      expect(find.text('İkinci'), findsOneWidget);
      expect(
        find
            .byType(Positioned)
            .evaluate()
            .where(
              (e) =>
                  e.widget is Positioned && (e.widget as Positioned).top == 55,
            )
            .length,
        1,
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('handle.dismiss kapatır; ikinci çağrı zararsız', (
      tester,
    ) async {
      _phone(tester);
      AppToastHandle? handle;
      await pumpApp(tester, _Host(onHandle: (h) => handle = h));
      await _show(tester);
      handle!.dismiss();
      await tester.pumpAndSettle();
      expect(find.text('Oda kaydedildi'), findsNothing);
      handle!.dismiss();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('eylem', () {
    testWidgets(
      'eylem inverseAction label stilinde; dokununca onAction ve kapanır',
      (tester) async {
        _phone(tester);
        var undone = 0;
        await pumpApp(
          tester,
          _Host(action: 'Geri al', onAction: () => undone++),
        );
        await _show(tester);
        final label = tester.widget<Text>(find.text('Geri al'));
        expect(label.style!.color, AppFixedColors.inverseAction);
        expect(label.style!.fontSize, 15);
        expect(
          tester
              .getSize(
                find
                    .ancestor(
                      of: find.text('Geri al'),
                      matching: find.byType(ConstrainedBox),
                    )
                    .first,
              )
              .height,
          greaterThanOrEqualTo(44),
        );
        await tester.tap(find.text('Geri al'));
        await tester.pumpAndSettle();
        expect(undone, 1);
        expect(find.text('Oda kaydedildi'), findsNothing);
      },
    );

    test('eylem ve geri çağrı birlikte verilmeli', () {
      expect(
        () =>
            AppToast.show(_FakeContext(), message: 'x', actionLabel: 'Geri al'),
        throwsAssertionError,
      );
    });
  });

  group('hareket', () {
    testWidgets('yukarı kaydırarak kapanır', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Host());
      await _show(tester);
      await tester.fling(_pill, const Offset(0, -80), 1200);
      await tester.pumpAndSettle();
      expect(find.text('Oda kaydedildi'), findsNothing);
    });

    testWidgets('kısa çekme geri döner, kapanmaz; aşağı çekilmez', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, const _Host());
      await _show(tester);
      final top = tester.getTopLeft(_pill).dy;
      final g = await tester.startGesture(tester.getCenter(_pill));
      await g.moveBy(const Offset(0, 40)); // aşağı
      await tester.pump();
      expect(tester.getTopLeft(_pill).dy, top);
      await g.moveBy(const Offset(0, -10));
      await tester.pump();
      await g.up();
      await tester.pumpAndSettle();
      expect(find.text('Oda kaydedildi'), findsOneWidget);
      expect(tester.getTopLeft(_pill).dy, closeTo(top, 0.5));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('üstten 16 pt kayarak spring ile girer', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Host());
      await tester.tap(find.text('Göster'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final early = tester.getTopLeft(_pill).dy;
      await tester.pumpAndSettle();
      final settled = tester.getTopLeft(_pill).dy;
      expect(early, lessThan(settled));
      expect(settled - early, lessThanOrEqualTo(16));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });

    testWidgets('Reduce Motion: anında görünür, çıkışta animasyonsuz kalkar', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, const _Host(), disableAnimations: true);
      await tester.tap(find.text('Göster'));
      await tester.pump();
      expect(tester.getTopLeft(_pill).dy, closeTo(55, 0.5));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();
      expect(find.text('Oda kaydedildi'), findsNothing);
    });
  });

  group('erişilebilirlik', () {
    testWidgets(
      'canlı bölge: duyurulur; yukarı kaydırma ve kapatma eylemi var',
      (tester) async {
        _phone(tester);
        final handle = tester.ensureSemantics();
        await pumpApp(tester, const _Host());
        await _show(tester);
        final node = tester.getSemantics(find.text('Oda kaydedildi'));
        expect(node.flagsCollection.isLiveRegion, isTrue);
        expect(node.label, contains('Oda kaydedildi'));
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        handle.dispose();
      },
    );
  });
}

class _FakeContext extends Fake implements BuildContext {}
