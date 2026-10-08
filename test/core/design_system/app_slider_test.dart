import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/inputs/app_slider.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_elevation.dart';

const _km = [1.0, 3.0, 5.0, 10.0];

class _Host extends StatefulWidget {
  const _Host({
    this.initial = 3,
    this.enabled = true,
    this.values = _km,
    this.onValue,
  });
  final double initial;
  final bool enabled;
  final List<double> values;
  final ValueChanged<double>? onValue;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late double value = widget.initial;

  @override
  Widget build(BuildContext context) => AppSlider(
    values: widget.values,
    value: value,
    semanticLabel: 'Mesafe',
    valueFormatter: (v) => '${v.round()} km',
    onChanged: widget.enabled
        ? (v) {
            setState(() => value = v);
            widget.onValue?.call(v);
          }
        : null,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          // Her pump'ta yeni state: `_Host.initial` yalnızca ilk kurulumda geçerli.
          body: KeyedSubtree(
            key: UniqueKey(),
            child: Padding(padding: const EdgeInsets.all(20), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _slider => find.byType(AppSlider);
// Thumb: 28'lik daire.
Finder get _thumb => find.descendant(
  of: _slider,
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is ShapeDecoration &&
        (w.decoration as ShapeDecoration).shape is CircleBorder,
  ),
);
// Dolu kısım ve iz: pill, 4 yüksek.
Finder _bar(Color color) => find.descendant(
  of: _slider,
  matching: find.byWidgetPredicate(
    (w) =>
        w is DecoratedBox &&
        w.decoration is ShapeDecoration &&
        (w.decoration as ShapeDecoration).color == color &&
        (w.decoration as ShapeDecoration).shape is RoundedSuperellipseBorder,
  ),
);
ShapeDecoration _thumbDecoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_thumb).decoration as ShapeDecoration;

/// Track alanının yerel x konumuna karşılık gelen global nokta.
Offset _at(WidgetTester tester, double fractionOfInner) {
  final box = tester.getRect(
    find.descendant(of: _slider, matching: find.byType(GestureDetector)).first,
  );
  const thumb = 28.0;
  final inner = box.width - thumb;
  return Offset(box.left + thumb / 2 + fractionOfInner * inner, box.center.dy);
}

void main() {
  group('görünüm', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets(
        'iz 4px surfaceMuted, dolu kısım brand, thumb 28 surface $name',
        (tester) async {
          await _pump(tester, const _Host(initial: 5), dark: dark);
          final track = tester.getSize(_bar(c.surfaceMuted).first);
          expect(track.height, 4);
          expect(tester.getSize(_bar(c.brand).first).height, 4);
          expect(tester.getSize(_thumb), const Size(28, 28));
          expect(_thumbDecoration(tester).color, c.surface);
        },
      );
    }

    testWidgets('değer üstte, title + tabular, sağa hizalı', (tester) async {
      await _pump(tester, const _Host(initial: 3));
      final text = tester.widget<Text>(find.text('3 km'));
      expect(text.style!.fontSize, 17);
      expect(text.style!.fontWeight, FontWeight.w600);
      expect(
        text.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(
        tester.getBottomLeft(find.text('3 km')).dy,
        lessThan(tester.getTopLeft(_thumb).dy),
      );
      expect(
        tester.getTopRight(find.text('3 km')).dx,
        closeTo(tester.getTopRight(_slider).dx, 1),
      );
    });

    testWidgets('konumlar eşit aralıklı: 1,3,5,10 → 0, 1/3, 2/3, 1', (
      tester,
    ) async {
      final lefts = <double>[];
      for (final v in _km) {
        await _pump(tester, _Host(initial: v));
        lefts.add(tester.getCenter(_thumb).dx);
      }
      final span = lefts.last - lefts.first;
      expect((lefts[1] - lefts.first) / span, closeTo(1 / 3, 0.01));
      expect((lefts[2] - lefts.first) / span, closeTo(2 / 3, 0.01));
    });

    testWidgets('dolu kısım thumb merkezine kadar uzanır', (tester) async {
      await _pump(tester, const _Host(initial: 5));
      final filled = tester.getRect(_bar(AppColors.light.brand).first);
      final thumbCenter = tester.getCenter(_thumb).dx;
      expect(filled.right, closeTo(thumbCenter, 1));
      expect(filled.left, closeTo(tester.getTopLeft(_slider).dx + 14, 1));
    });

    testWidgets('thumb uçlarda dışarı taşmaz', (tester) async {
      await _pump(tester, const _Host(initial: 1));
      expect(
        tester.getTopLeft(_thumb).dx,
        greaterThanOrEqualTo(tester.getTopLeft(_slider).dx - 0.01),
      );
      await _pump(tester, const _Host(initial: 10));
      expect(
        tester.getTopRight(_thumb).dx,
        lessThanOrEqualTo(tester.getTopRight(_slider).dx + 0.01),
      );
    });

    testWidgets('thumb gölgesi: dururken E1', (tester) async {
      await _pump(tester, const _Host(initial: 3));
      expect(_thumbDecoration(tester).shadows, AppElevation.light.e1.shadows);
      await _pump(tester, const _Host(initial: 3), dark: true);
      expect(_thumbDecoration(tester).shape, isA<CircleBorder>());
      expect(
        (_thumbDecoration(tester).shape as CircleBorder).side,
        AppElevation.dark.e1.side,
      );
    });

    testWidgets('dokunma alanı yüksekliği 44', (tester) async {
      await _pump(tester, const _Host());
      final area = find
          .descendant(of: _slider, matching: find.byType(GestureDetector))
          .first;
      expect(tester.getSize(area).height, 44);
    });
  });

  group('etkileşim', () {
    testWidgets('dokunulan konumdaki en yakın değere atlar', (tester) async {
      final seen = <double>[];
      await _pump(tester, _Host(initial: 3, onValue: seen.add));
      await tester.tapAt(_at(tester, 1.0));
      await tester.pumpAndSettle();
      expect(seen, [10.0]);
      await tester.tapAt(_at(tester, 0.0));
      await tester.pumpAndSettle();
      expect(seen, [10.0, 1.0]);
      expect(find.text('1 km'), findsOneWidget);
    });

    testWidgets(
      'serbest değer yok: iki değer arasına bırakınca en yakına oturur',
      (tester) async {
        final seen = <double>[];
        await _pump(tester, _Host(initial: 1, onValue: seen.add));
        await tester.tapAt(_at(tester, 0.40)); // 1/3 ile 2/3 arası, 1/3'e yakın
        await tester.pumpAndSettle();
        expect(seen, [3.0]);
        await tester.tapAt(_at(tester, 0.60)); // 2/3'e yakın
        await tester.pumpAndSettle();
        expect(seen, [3.0, 5.0]);
        expect(seen.every(_km.contains), isTrue);
      },
    );

    testWidgets(
      'sürüklerken geçilen her yeni değerde onChanged, aynı değerde tekrar yok',
      (tester) async {
        final seen = <double>[];
        await _pump(tester, _Host(initial: 1, onValue: seen.add));
        final g = await tester.startGesture(_at(tester, 0.0));
        for (var f = 0.0; f <= 1.0; f += 0.05) {
          await g.moveTo(_at(tester, f));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await tester.pumpAndSettle();
        expect(seen, [3.0, 5.0, 10.0]);
      },
    );

    testWidgets('sürüklerken thumb E2, bırakınca E1', (tester) async {
      await _pump(tester, const _Host(initial: 3));
      final g = await tester.startGesture(_at(tester, 1 / 3));
      await tester.pump();
      await g.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(_thumbDecoration(tester).shadows, AppElevation.light.e2.shadows);
      await g.up();
      await tester.pumpAndSettle();
      expect(_thumbDecoration(tester).shadows, AppElevation.light.e1.shadows);
    });

    testWidgets('yeni değere geçişte selection haptic, aynı değerde yok', (
      tester,
    ) async {
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
      await _pump(tester, const _Host(initial: 3));
      await tester.tapAt(_at(tester, 1 / 3)); // zaten 3 km
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
      await tester.tapAt(_at(tester, 1.0));
      await tester.pumpAndSettle();
      expect(calls, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('pasif: dokunulamaz, filled textDisabled, değer textDisabled', (
      tester,
    ) async {
      final seen = <double>[];
      await _pump(tester, _Host(initial: 5, enabled: false, onValue: seen.add));
      await tester.tapAt(_at(tester, 1.0));
      await tester.pumpAndSettle();
      expect(seen, isEmpty);
      expect(find.text('5 km'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('5 km')).style!.color,
        AppColors.light.textDisabled,
      );
      expect(_bar(AppColors.light.textDisabled), findsOneWidget);
    });

    testWidgets('tek değerli liste: çökmez', (tester) async {
      await _pump(tester, const _Host(initial: 3, values: [3.0]));
      await tester.tapAt(_at(tester, 0.5));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('değer listede yoksa en yakını gösterilir', (tester) async {
      await _pump(tester, const _Host(initial: 4.2));
      expect(find.text('5 km'), findsOneWidget);
    });
  });

  group('erişilebilirlik', () {
    testWidgets('ayarlanabilir değer: etiket, değer, artır/azalt', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <double>[];
      await _pump(tester, _Host(initial: 3, onValue: seen.add));
      final node = tester.getSemantics(find.bySemanticsLabel('Mesafe'));
      expect(node.value, '3 km');
      expect(node.increasedValue, '5 km');
      expect(node.decreasedValue, '1 km');
      tester.semantics.performAction(
        find.semantics.byLabel('Mesafe'),
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      tester.semantics.performAction(
        find.semantics.byLabel('Mesafe'),
        SemanticsAction.decrease,
      );
      await tester.pumpAndSettle();
      expect(seen, [5.0, 3.0]);
      handle.dispose();
    });

    testWidgets('uçlarda ilgili eylem yok', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const _Host(initial: 10));
      final node = tester.getSemantics(find.bySemanticsLabel('Mesafe'));
      expect(node.increasedValue, isEmpty);
      expect(node.decreasedValue, '5 km');
      handle.dispose();
    });

    testWidgets('yazı 2x: taşma yok', (tester) async {
      await _pump(tester, const _Host(), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
