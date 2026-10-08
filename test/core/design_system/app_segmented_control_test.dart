import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/selection/app_segmented_control.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_elevation.dart';

import '../../support/pump_app.dart';

const _three = [
  AppSegment(value: 'a', label: 'Sabah'),
  AppSegment(value: 'b', label: 'Öğle'),
  AppSegment(value: 'c', label: 'Akşam'),
];

class _Host extends StatefulWidget {
  const _Host({
    super.key,
    this.segments = _three,
    this.enabled = true,
    this.onValue,
  });
  final List<AppSegment<String>> segments;
  final bool enabled;
  final ValueChanged<String>? onValue;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String value = 'a';

  @override
  Widget build(BuildContext context) => AppSegmentedControl<String>(
    segments: widget.segments,
    value: value,
    onChanged: widget.enabled
        ? (v) {
            setState(() => value = v);
            widget.onValue?.call(v);
          }
        : null,
  );
}

Finder get _control => find.byType(AppSegmentedControl<String>);
// Kap: surfaceMuted, radius md (14).
Finder get _container => find.descendant(
  of: _control,
  matching: find.byWidgetPredicate((w) {
    if (w is! DecoratedBox) return false;
    final d = w.decoration;
    return d is ShapeDecoration &&
        d.shape is RoundedSuperellipseBorder &&
        (d.shape as RoundedSuperellipseBorder).borderRadius ==
            BorderRadius.circular(14);
  }),
);
// Seçili göstergesi: radius sm (10).
Finder get _indicator => find.descendant(
  of: _control,
  matching: find.byWidgetPredicate((w) {
    if (w is! DecoratedBox) return false;
    final d = w.decoration;
    return d is ShapeDecoration &&
        d.shape is RoundedSuperellipseBorder &&
        (d.shape as RoundedSuperellipseBorder).borderRadius ==
            BorderRadius.circular(10);
  }),
);
ShapeDecoration _deco(WidgetTester tester, Finder f) =>
    tester.widget<DecoratedBox>(f).decoration as ShapeDecoration;
TextStyle _style(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style!;

void main() {
  group('görünüm', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets(
        'kap surfaceMuted radius md; seçili segment surfaceRaised radius sm + E1 $name',
        (tester) async {
          await pumpApp(tester, const _Host(), dark: dark);
          expect(_deco(tester, _container).color, c.surfaceMuted);
          expect(_deco(tester, _indicator).color, c.surfaceRaised);
          final e1 = dark ? AppElevation.dark.e1 : AppElevation.light.e1;
          expect(_deco(tester, _indicator).shadows, e1.shadows);
          expect(
            (_deco(tester, _indicator).shape as OutlinedBorder).side,
            e1.side,
          );
        },
      );

      testWidgets('seçili 600 textPrimary; diğerleri 500 textSecondary $name', (
        tester,
      ) async {
        await pumpApp(tester, const _Host(), dark: dark);
        expect(_style(tester, 'Sabah').fontWeight, FontWeight.w600);
        expect(_style(tester, 'Sabah').color, c.textPrimary);
        expect(_style(tester, 'Öğle').fontWeight, FontWeight.w500);
        expect(_style(tester, 'Öğle').color, c.textSecondary);
      });
    }

    testWidgets('yükseklik 44, iç boşluk 4, segmentler eşit genişlikte', (
      tester,
    ) async {
      await pumpApp(tester, const _Host());
      expect(tester.getSize(_container).height, 44);
      final box = tester.getRect(_container);
      final ind = tester.getRect(_indicator);
      expect(ind.left - box.left, closeTo(4, 0.5));
      expect(ind.top - box.top, closeTo(4, 0.5));
      expect(ind.height, closeTo(36, 0.5));
      final w = box.width / 3;
      expect(ind.width, closeTo(w - 8 / 3 * 1, w * 0.1));
    });

    testWidgets('gösterge her segmentte etiketiyle aynı merkezde', (
      tester,
    ) async {
      for (final v in ['a', 'b', 'c']) {
        await pumpApp(tester, _Host(key: ValueKey(v), onValue: (_) {}));
        final label = {'a': 'Sabah', 'b': 'Öğle', 'c': 'Akşam'}[v]!;
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
        expect(
          tester.getCenter(_indicator).dx,
          closeTo(tester.getCenter(find.text(label)).dx, 0.5),
          reason: label,
        );
      }
    });

    testWidgets('iki ve dört segmentle çalışır', (tester) async {
      await pumpApp(
        tester,
        const _Host(
          segments: [
            AppSegment(value: 'a', label: 'Açık'),
            AppSegment(value: 'b', label: 'Koyu'),
          ],
        ),
      );
      expect(find.text('Açık'), findsOneWidget);
      await pumpApp(
        tester,
        const _Host(
          segments: [
            AppSegment(value: 'a', label: 'Bir'),
            AppSegment(value: 'b', label: 'İki'),
            AppSegment(value: 'c', label: 'Üç'),
            AppSegment(value: 'd', label: 'Dört'),
          ],
        ),
      );
      expect(find.text('Dört'), findsOneWidget);
    });

    test('1 ya da 5 segment kabul edilmez', () {
      expect(
        () => AppSegmentedControl<String>(
          segments: const [AppSegment(value: 'a', label: 'a')],
          value: 'a',
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );
      expect(
        () => AppSegmentedControl<String>(
          segments: [
            for (final v in 'abcde'.split('')) AppSegment(value: v, label: v),
          ],
          value: 'a',
          onChanged: (_) {},
        ),
        throwsAssertionError,
      );
    });
  });

  group('seçim ve animasyon', () {
    testWidgets('dokunulan segment seçilir, gösterge oraya kayar', (
      tester,
    ) async {
      final seen = <String>[];
      await pumpApp(tester, _Host(onValue: seen.add));
      final x0 = tester.getCenter(_indicator).dx;
      await tester.tap(find.text('Akşam'));
      await tester.pump(); // animasyonu başlatan kare
      await tester.pump(const Duration(milliseconds: 80));
      final mid = tester.getCenter(_indicator).dx;
      expect(mid, greaterThan(x0));
      await tester.pumpAndSettle();
      expect(seen, ['c']);
      expect(
        tester.getCenter(_indicator).dx,
        closeTo(tester.getCenter(find.text('Akşam')).dx, 1),
      );
      expect(_style(tester, 'Akşam').fontWeight, FontWeight.w600);
      expect(_style(tester, 'Sabah').fontWeight, FontWeight.w500);
    });

    testWidgets('seçili segmente tekrar dokunmak tetiklemez', (tester) async {
      final seen = <String>[];
      await pumpApp(tester, _Host(onValue: seen.add));
      await tester.tap(find.text('Sabah'));
      await tester.pumpAndSettle();
      expect(seen, isEmpty);
    });

    testWidgets('segment hücresine (metin dışına) dokunmak da seçer, 44 alan', (
      tester,
    ) async {
      final seen = <String>[];
      await pumpApp(tester, _Host(onValue: seen.add));
      final cell = tester.getRect(find.byType(Expanded).first);
      expect(cell.height, 44);
      final secondCell = tester.getRect(find.byType(Expanded).at(1));
      await tester.tapAt(Offset(secondCell.left + 3, secondCell.top + 3));
      await tester.pumpAndSettle();
      expect(seen, ['b']);
    });

    testWidgets('Reduce Motion: gösterge anında oturur', (tester) async {
      await pumpApp(tester, const _Host(), disableAnimations: true);
      await tester.tap(find.text('Akşam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        tester.getCenter(_indicator).dx,
        closeTo(tester.getCenter(find.text('Akşam')).dx, 1),
      );
    });

    testWidgets('her değişimde selection haptic', (tester) async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              calls.add(call.arguments as String);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await pumpApp(tester, const _Host());
      await tester.tap(find.text('Öğle'));
      await tester.pumpAndSettle();
      expect(calls, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('pasif: seçilemez, metin textDisabled', (tester) async {
      final seen = <String>[];
      await pumpApp(tester, _Host(enabled: false, onValue: seen.add));
      await tester.tap(find.text('Akşam'));
      await tester.pumpAndSettle();
      expect(seen, isEmpty);
      expect(_style(tester, 'Akşam').color, AppColors.light.textDisabled);
    });
  });

  group('erişilebilirlik ve ölçek', () {
    testWidgets('her segment seçili durumuyla buton', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const _Host());
      expect(
        tester.getSemantics(find.bySemanticsLabel('Sabah')),
        matchesSemantics(
          label: 'Sabah',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Öğle')),
        matchesSemantics(
          label: 'Öğle',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      handle.dispose();
    });

    testWidgets('yazı 2x: segmentler metinle büyür, taşma yok', (tester) async {
      await pumpApp(tester, const _Host(), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_container).height, greaterThan(44));
    });
  });
}
