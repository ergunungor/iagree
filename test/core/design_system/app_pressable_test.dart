import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/foundations/app_pressable.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );
  await tester.pumpAndSettle();
}

Finder get _pressable => find.byType(AppPressable);

Finder _ring(Color color) => find.byWidgetPredicate((w) {
  if (w is! DecoratedBox) return false;
  final d = w.decoration;
  return d is ShapeDecoration &&
      d.shape is CircleBorder &&
      (d.shape as CircleBorder).side.color == color;
});

Widget _box(bool pressed) => SizedBox.square(
  dimension: 20,
  child: ColoredBox(color: pressed ? Colors.red : Colors.blue),
);

void main() {
  void noop() {}

  testWidgets('builder basılı durumu alır', (tester) async {
    await _pump(
      tester,
      AppPressable(
        onPressed: noop,
        semanticLabel: 'x',
        builder: (c, p) => _box(p),
      ),
    );
    ColoredBox box() => tester.widget<ColoredBox>(
      find.descendant(of: _pressable, matching: find.byType(ColoredBox)),
    );
    expect(box().color, Colors.blue);
    final g = await tester.startGesture(tester.getCenter(_pressable));
    await tester.pump();
    expect(box().color, Colors.red);
    await g.up();
    await tester.pumpAndSettle();
    expect(box().color, Colors.blue);
  });

  testWidgets('scaleOnPress: 0.97; kapalıyken Transform yok', (tester) async {
    await _pump(
      tester,
      AppPressable(
        onPressed: noop,
        semanticLabel: 'x',
        builder: (c, p) => _box(p),
      ),
    );
    final g = await tester.startGesture(tester.getCenter(_pressable));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final t = tester.widget<Transform>(
      find.descendant(of: _pressable, matching: find.byType(Transform)).first,
    );
    expect(t.transform.entry(0, 0), closeTo(0.97, 1e-3));
    await g.up();
    await tester.pumpAndSettle();

    await _pump(
      tester,
      AppPressable(
        onPressed: noop,
        semanticLabel: 'x',
        scaleOnPress: false,
        builder: (c, p) => _box(p),
      ),
    );
    expect(
      find.descendant(of: _pressable, matching: find.byType(Transform)),
      findsNothing,
    );
  });

  testWidgets('dokunma alanı en az 44x44, tam genişlikte yayılır', (
    tester,
  ) async {
    await _pump(
      tester,
      AppPressable(
        onPressed: noop,
        semanticLabel: 'x',
        builder: (c, p) => _box(p),
      ),
    );
    expect(tester.getSize(_pressable), const Size(44, 44));
    await _pump(
      tester,
      AppPressable(
        onPressed: noop,
        semanticLabel: 'x',
        minWidth: double.infinity,
        builder: (c, p) => _box(p),
      ),
    );
    expect(tester.getSize(_pressable).width, 800);
  });

  testWidgets('disabled ve busy: basış yok sayılır', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      AppPressable(
        onPressed: null,
        semanticLabel: 'x',
        builder: (c, p) => _box(p),
      ),
    );
    await tester.tap(_pressable);
    await _pump(
      tester,
      AppPressable(
        onPressed: () => taps++,
        isBusy: true,
        semanticLabel: 'x',
        builder: (c, p) => _box(p),
      ),
    );
    await tester.tap(_pressable);
    expect(taps, 0);
  });

  testWidgets('busy: VoiceOver\'a enabled görünür, disabled görünmez', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      AppPressable(
        onPressed: noop,
        isBusy: true,
        semanticLabel: 'Kaydet',
        builder: (c, p) => _box(p),
      ),
    );
    expect(
      tester.getSemantics(_pressable),
      matchesSemantics(
        label: 'Kaydet',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );
    await _pump(
      tester,
      AppPressable(
        onPressed: null,
        semanticLabel: 'Kaydet',
        builder: (c, p) => _box(p),
      ),
    );
    expect(
      tester.getSemantics(_pressable),
      matchesSemantics(
        label: 'Kaydet',
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('klavye: Tab odak halkasını gösterir, Enter etkinleştirir', (
    tester,
  ) async {
    var taps = 0;
    await _pump(
      tester,
      AppPressable(
        onPressed: () => taps++,
        semanticLabel: 'x',
        focusShape: const CircleBorder(),
        builder: (c, p) => _box(p),
      ),
    );
    expect(_ring(AppColors.light.focusRing), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(_ring(AppColors.light.focusRing), findsOneWidget);
    expect(_ring(AppColors.light.canvas), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });
}
