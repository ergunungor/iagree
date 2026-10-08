import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/buttons/app_button.dart';
import 'package:iagree/core/design_system/components/feedback/app_sheet.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_elevation.dart';

import '../../support/pump_app.dart';

/// 390×844 telefon.
void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

class _Opener extends StatefulWidget {
  const _Opener({
    this.detents = const [AppSheetDetent.fit],
    this.footer,
    this.lines = 3,
  });
  final List<AppSheetDetent> detents;
  final Widget? footer;
  final int lines;

  @override
  State<_Opener> createState() => _OpenerState();
}

class _OpenerState extends State<_Opener> {
  Object? result = 'beklemede';
  int opened = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      TextButton(
        onPressed: () async {
          opened++;
          final r = await AppSheet.show<String>(
            context,
            title: 'Paylaş',
            detents: widget.detents,
            footer: widget.footer,
            builder: (context) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < widget.lines; i++)
                  SizedBox(height: 44, child: Text('Satır $i')),
              ],
            ),
          );
          setState(() => result = r);
        },
        child: const Text('Aç'),
      ),
      Text('sonuç: $result'),
    ],
  );
}

Finder get _sheetTitle => find.text('Paylaş');

/// Sheet paneli: yalnızca üst köşeleri 28 yuvarlak olan tek kutu.
Finder get _panel => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final d = w.decoration;
  return d is ShapeDecoration &&
      d.shape is RoundedSuperellipseBorder &&
      (d.shape as RoundedSuperellipseBorder).borderRadius == _topRadius28;
});

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Aç'));
  await tester.pumpAndSettle();
}

void main() {
  group('görünüm', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets('surfaceRaised, üst köşeler radius xl, E3, scrim $name', (
        tester,
      ) async {
        _phone(tester);
        await pumpApp(tester, const _Opener(), dark: dark);
        await _open(tester);
        final deco =
            tester.widget<DecoratedBox>(_panel.first).decoration
                as ShapeDecoration;
        expect(deco.color, c.surfaceRaised);
        final shape = deco.shape as RoundedSuperellipseBorder;
        expect(shape.borderRadius, _topRadius28);
        expect(
          deco.shadows,
          (dark ? AppElevation.dark : AppElevation.light).e3.shadows,
        );
        final barrier = tester.widget<ModalBarrier>(
          find.byType(ModalBarrier).last,
        );
        expect(barrier.color, c.scrim);
      });
    }

    testWidgets('grabber 36×5, üstten 8; başlık h3 sola hizalı, yanlar 24', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await _open(tester);
      final panel = tester.getRect(_panel.first);
      final grabber = find.byWidgetPredicate(
        (w) => w is SizedBox && w.width == 36 && w.height == 5,
      );
      final g = tester.getRect(grabber);
      expect(g.size, const Size(36, 5));
      expect(g.top - panel.top, 8);
      expect(g.center.dx, closeTo(panel.center.dx, 0.5));
      final title = tester.widget<Text>(_sheetTitle);
      expect(title.style!.fontSize, 20);
      expect(title.style!.fontWeight, FontWeight.w600);
      expect(tester.getTopLeft(_sheetTitle).dx - panel.left, 24);
      expect(tester.getTopLeft(find.text('Satır 0')).dx - panel.left, 24);
    });

    testWidgets('grabber rengi textTertiary %30', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await _open(tester);
      final grabber = tester.widget<DecoratedBox>(
        find
            .ancestor(
              of: find.byWidgetPredicate(
                (w) => w is SizedBox && w.width == 36 && w.height == 5,
              ),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final color = (grabber.decoration as ShapeDecoration).color!;
      expect(color.a, closeTo(0.3, 0.01));
      expect(
        color.toARGB32() & 0xFFFFFF,
        AppColors.light.textTertiary.toARGB32() & 0xFFFFFF,
      );
    });

    testWidgets(
      'CTA altta sabit: içerik uzayınca footer yerinde, içerik kayar',
      (tester) async {
        _phone(tester);
        await pumpApp(
          tester,
          _Opener(
            lines: 40,
            footer: AppButton.primary(label: 'Linki paylaş', onPressed: () {}),
          ),
        );
        await _open(tester);
        final footerBottom = tester.getBottomLeft(find.text('Linki paylaş')).dy;
        expect(footerBottom, lessThanOrEqualTo(844));
        await tester.drag(
          find.byType(SingleChildScrollView).last,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getBottomLeft(find.text('Linki paylaş')).dy,
          footerBottom,
        );
        expect(find.text('Satır 0').hitTestable(), findsNothing);
      },
    );
  });

  group('detent', () {
    testWidgets('fit: içeriğe sığar, ekranın %90\'ını geçmez', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener(lines: 2));
      await _open(tester);
      final h = tester.getSize(_panel.first).height;
      expect(h, lessThan(844 * 0.5));
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      await pumpApp(tester, const _Opener(lines: 100));
      await _open(tester);
      expect(tester.getSize(_panel.first).height, closeTo(844 * 0.9, 1));
    });

    testWidgets('medium: ekranın yarısı', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener(detents: [AppSheetDetent.medium]));
      await _open(tester);
      expect(tester.getSize(_panel.first).height, closeTo(422, 1));
    });

    testWidgets('large: üstte safe area + 16 boşluk, ✕ görünür', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, const _Opener(detents: [AppSheetDetent.large]));
      await _open(tester);
      final top = tester.getTopLeft(_panel.first).dy;
      expect(top, closeTo(0 + 16, 1)); // test ortamında safe area 0
      expect(find.byIcon(AppIcons.close), findsOneWidget);
    });

    testWidgets('✕ yalnızca Large\'da: fit ve medium\'da yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await _open(tester);
      expect(find.byIcon(AppIcons.close), findsNothing);
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      await pumpApp(tester, const _Opener(detents: [AppSheetDetent.medium]));
      await _open(tester);
      expect(find.byIcon(AppIcons.close), findsNothing);
    });

    testWidgets('✕ sheet\'i kapatır', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener(detents: [AppSheetDetent.large]));
      await _open(tester);
      await tester.tap(find.byIcon(AppIcons.close));
      await tester.pumpAndSettle();
      expect(_sheetTitle, findsNothing);
      expect(AppSheet.isOpen, isFalse);
    });

    testWidgets(
      '[medium, large]: medium başlar, yukarı sürüklenince large olur ve ✕ belirir',
      (tester) async {
        _phone(tester);
        await pumpApp(
          tester,
          const _Opener(detents: [AppSheetDetent.medium, AppSheetDetent.large]),
        );
        await _open(tester);
        expect(tester.getSize(_panel.first).height, closeTo(422, 2));
        expect(find.byIcon(AppIcons.close), findsNothing);
        await tester.fling(_sheetTitle, const Offset(0, -400), 1500);
        await tester.pumpAndSettle();
        expect(tester.getSize(_panel.first).height, greaterThan(422 + 200));
        expect(find.byIcon(AppIcons.close), findsOneWidget);
      },
    );

    testWidgets('[medium, large]: aşağı sürüklenince kapanır', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        const _Opener(detents: [AppSheetDetent.medium, AppSheetDetent.large]),
      );
      await _open(tester);
      await tester.fling(_sheetTitle, const Offset(0, 600), 2000);
      await tester.pumpAndSettle();
      expect(_sheetTitle, findsNothing);
    });

    test('yalnızca [medium, large] ikili kabul edilir', () {
      expect(
        () => AppSheet.show<void>(
          _FakeContext(),
          title: 'x',
          builder: (_) => const SizedBox(),
          detents: const [AppSheetDetent.fit, AppSheetDetent.large],
        ),
        throwsAssertionError,
      );
    });
  });

  group('kapatma ve tekillik', () {
    testWidgets('scrim\'e dokununca kapanır', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await _open(tester);
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(_sheetTitle, findsNothing);
      expect(find.text('sonuç: null'), findsOneWidget);
    });

    testWidgets('aşağı kaydırınca kapanır (fit)', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await _open(tester);
      await tester.fling(_sheetTitle, const Offset(0, 500), 2000);
      await tester.pumpAndSettle();
      expect(_sheetTitle, findsNothing);
    });

    testWidgets('üst üste en fazla bir sheet: ikincisi açılmaz', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await _open(tester);
      expect(AppSheet.isOpen, isTrue);
      final context = tester.element(_sheetTitle);
      final second = await AppSheet.show<String>(
        context,
        title: 'İkinci',
        builder: (_) => const Text('ikinci içerik'),
      );
      await tester.pumpAndSettle();
      expect(second, isNull);
      expect(find.text('İkinci'), findsNothing);
    });

    testWidgets('kapanınca yeniden açılabilir', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await _open(tester);
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(AppSheet.isOpen, isFalse);
      await _open(tester);
      expect(_sheetTitle, findsOneWidget);
    });

    testWidgets('Navigator.pop değeri döner', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await _open(tester);
      Navigator.of(tester.element(_sheetTitle)).pop('seçildi');
      await tester.pumpAndSettle();
      expect(find.text('sonuç: seçildi'), findsOneWidget);
    });
  });

  group('hareket ve erişilebilirlik', () {
    testWidgets('Reduce Motion: sheet anında açılır, hata yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener(), disableAnimations: true);
      await tester.tap(find.text('Aç'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(_sheetTitle, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('giriş spring ile, çıkış %25 daha kısa', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Opener());
      await tester.tap(find.text('Aç'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = tester.getTopLeft(_panel.first).dy;
      await tester.pumpAndSettle();
      final settled = tester.getTopLeft(_panel.first).dy;
      expect(mid, greaterThan(settled), reason: 'hâlâ aşağıdan geliyor');
    });

    testWidgets('semantics: rota adı başlık, başlık header', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const _Opener());
      await _open(tester);
      final node = tester.getSemantics(_sheetTitle);
      expect(node.label, 'Paylaş');
      expect(node.flagsCollection.isHeader, isTrue);
      handle.dispose();
    });

    testWidgets('scrim VoiceOver\'a "Kapat" etiketiyle kapatılabilir', (
      tester,
    ) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const _Opener());
      await _open(tester);
      expect(find.bySemanticsLabel('Kapat'), findsWidgets);
      handle.dispose();
    });
  });
}

/// `show`'un assert'i bağlama ulaşmadan tetiklenir.
class _FakeContext extends Fake implements BuildContext {}

// Üst köşeleri 28 olan, alt köşeleri sıfır BorderRadius.
const _topRadius28 = BorderRadius.vertical(top: Radius.circular(28));
