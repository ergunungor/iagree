import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/inputs/app_code_field.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

final _light = AppColors.light;

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget _field({
  TextEditingController? controller,
  bool error = false,
  ValueChanged<String>? onCompleted,
  ValueChanged<String>? onChanged,
}) => SizedBox(
  width: 350,
  child: AppCodeField(
    controller: controller,
    hasError: error,
    onCompleted: onCompleted,
    onChanged: onChanged,
  ),
);

/// Kutular `radius md` (14); imleç pill'i hariç.
bool _isBox(ShapeBorder s) =>
    s is RoundedSuperellipseBorder &&
    s.borderRadius == BorderRadius.circular(14);

/// Kutuların (Expanded > ConstrainedBox > DecoratedBox) dolgu renkleri.
List<Color?> _fills(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(AppCodeField),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((d) => d.decoration)
    .whereType<ShapeDecoration>()
    .where((d) => _isBox(d.shape))
    .map((d) => d.color)
    .toList();

List<Color> _borders(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(AppCodeField),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((d) => d.decoration)
    .whereType<ShapeDecoration>()
    .map((d) => d.shape)
    .where(_isBox)
    .whereType<RoundedSuperellipseBorder>()
    .map((s) => s.side.color)
    .toList();

/// İmleç sonsuz animasyon olduğundan `pumpAndSettle` kullanılamaz.
Future<void> _p(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double textScale = 1,
  bool disableAnimations = false,
}) async {
  await pumpApp(
    tester,
    child,
    dark: dark,
    textScale: textScale,
    disableAnimations: disableAnimations,
    settle: false,
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('6 kutu, gap 8, yükseklik ≥ 60, tam genişlik', (tester) async {
    _phone(tester);
    await _p(tester, _field());
    expect(_fills(tester).length, 6);
    final box = find.descendant(
      of: find.byType(AppCodeField),
      matching: find.byType(ConstrainedBox),
    );
    final rects = [
      for (final e in box.evaluate())
        if ((e.renderObject! as RenderBox).size.height >= 60 &&
            (e.renderObject! as RenderBox).size.width < 100)
          tester.getRect(find.byWidget(e.widget)),
    ];
    expect(rects.length, 6);
    expect(rects.first.height, greaterThanOrEqualTo(60));
    expect(rects[1].left - rects[0].right, closeTo(8, 0.01));
    expect(rects.last.right - rects.first.left, closeTo(350, 0.01));
  });

  testWidgets('boş: ilk kutu odakta (surfaceInputFocus + brand kenar)', (
    tester,
  ) async {
    _phone(tester);
    await _p(tester, _field());
    final fills = _fills(tester);
    expect(fills.first, _light.surfaceInputFocus);
    expect(fills.skip(1).every((f) => f == _light.surfaceMuted), isTrue);
    expect(_borders(tester).first, _light.brand);
  });

  testWidgets('yazdıkça kutular dolar, sıradaki kutu odağa geçer', (
    tester,
  ) async {
    _phone(tester);
    await _p(tester, _field());
    await tester.enterText(find.byType(TextField), '4829');
    await tester.pump();
    for (final d in ['4', '8', '2', '9']) {
      expect(find.text(d), findsOneWidget);
    }
    final fills = _fills(tester);
    expect(fills[4], _light.surfaceInputFocus);
    expect(fills[5], _light.surfaceMuted);
    expect(fills[0], _light.surfaceMuted);
    expect(find.text('4').evaluate().isNotEmpty, isTrue);
  });

  testWidgets('rakam dışı karakterler ve 6 haneden fazlası alınmaz', (
    tester,
  ) async {
    _phone(tester);
    final c = TextEditingController();
    addTearDown(c.dispose);
    await _p(tester, _field(controller: c));
    await tester.enterText(find.byType(TextField), '12a3-4 5678');
    await tester.pump();
    expect(c.text, '123456');
  });

  testWidgets('6. hanede onCompleted bir kez çağrılır', (tester) async {
    _phone(tester);
    final done = <String>[];
    await _p(tester, _field(onCompleted: done.add));
    await tester.enterText(find.byType(TextField), '12345');
    await tester.pump();
    expect(done, isEmpty);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(done, ['123456']);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(done.length, 1);
  });

  testWidgets('yapıştırma (6 hane birden) tamamlanır', (tester) async {
    _phone(tester);
    final done = <String>[];
    await _p(tester, _field(onCompleted: done.add));
    await tester.enterText(find.byType(TextField), '482910');
    await tester.pump();
    expect(done, ['482910']);
  });

  testWidgets('hata: bütün kutular 1,5px error kenarlı', (tester) async {
    _phone(tester);
    await _p(tester, _field(error: true));
    final borders = _borders(tester);
    expect(borders.where((b) => b == _light.error).length, 6);
    final widths = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<ShapeDecoration>()
        .map((d) => d.shape)
        .where(_isBox)
        .whereType<RoundedSuperellipseBorder>()
        .map((s) => s.side.width);
    expect(widths.every((w) => w == 1.5), isTrue);
  });

  testWidgets(
    'tüm kutular aynı kalınlıkta kenarlıkta: odak değişince kayma yok',
    (tester) async {
      _phone(tester);
      await _p(tester, _field());
      final before = tester.getRect(find.byType(AppCodeField));
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();
      expect(tester.getRect(find.byType(AppCodeField)), before);
    },
  );

  testWidgets('metin gizli alanda: yazı şeffaf, imleç yok', (tester) async {
    _phone(tester);
    await _p(tester, _field());
    final t = tester.widget<TextField>(find.byType(TextField));
    expect(t.style!.color, Colors.transparent);
    expect(t.showCursor, isFalse);
    expect(t.keyboardType, TextInputType.number);
    expect(t.autofillHints, contains(AutofillHints.oneTimeCode));
  });

  testWidgets('semantics: boş / kısmen dolu / dolu', (tester) async {
    _phone(tester);
    final handle = tester.ensureSemantics();
    await _p(tester, _field());
    expect(find.bySemanticsLabel('Kod alanı, 6 hane'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '4829');
    await tester.pump();
    expect(find.bySemanticsLabel('Kod: 4 8 2 9, 2 hane kaldı'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '482910');
    await tester.pump();
    expect(find.bySemanticsLabel('4 8 2 9 1 0'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('imleç yanıp söner; Reduce Motion\'da sabit', (tester) async {
    _phone(tester);
    await _p(tester, _field());
    expect(tester.hasRunningAnimations, isTrue);
    await _p(tester, _field(), disableAnimations: true);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('yazı 2x ve dark: taşma yok', (tester) async {
    _phone(tester);
    await _p(tester, _field(), textScale: 2, dark: true);
    await tester.enterText(find.byType(TextField), '482910');
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
