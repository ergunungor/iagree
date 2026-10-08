import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/selection/app_check_circle.dart';
import 'package:iagree/core/design_system/components/selection/app_checkbox.dart';
import 'package:iagree/core/design_system/components/selection/app_selection_mark.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

class _BoxHost extends StatefulWidget {
  const _BoxHost({this.initial = false, this.enabled = true, this.onValue});
  final bool initial;
  final bool enabled;
  final ValueChanged<bool>? onValue;

  @override
  State<_BoxHost> createState() => _BoxHostState();
}

class _BoxHostState extends State<_BoxHost> {
  late bool value = widget.initial;

  @override
  Widget build(BuildContext context) => AppCheckbox(
    value: value,
    semanticLabel: 'Koşulları kabul ediyorum',
    onChanged: widget.enabled
        ? (v) {
            setState(() => value = v);
            widget.onValue?.call(v);
          }
        : null,
  );
}

class _CircleHost extends StatefulWidget {
  const _CircleHost();

  @override
  State<_CircleHost> createState() => _CircleHostState();
}

class _CircleHostState extends State<_CircleHost> {
  bool value = false;

  @override
  Widget build(BuildContext context) => AppCheckCircle(
    selected: value,
    semanticLabel: 'Seçenek',
    onChanged: (v) {
      setState(() => value = v);
    },
  );
}

Finder get _mark => find.byType(AppSelectionMark);
Finder get _markBox =>
    find.descendant(of: _mark, matching: find.byType(AnimatedContainer));
ShapeDecoration _deco(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(_markBox).decoration! as ShapeDecoration;
BorderSide _side(WidgetTester tester) =>
    (_deco(tester).shape as OutlinedBorder).side;

void main() {
  group('Checkbox', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets(
        'seçili değil $name: 22 kutu, radius xs, 1,5px borderControl, ✓ görünmez',
        (tester) async {
          await pumpApp(tester, const _BoxHost(), dark: dark);
          expect(tester.getSize(_markBox), const Size(22, 22));
          expect(
            (_deco(tester).shape as RoundedSuperellipseBorder).borderRadius,
            BorderRadius.circular(6),
          );
          expect(_side(tester).color, c.borderControl);
          expect(_side(tester).width, 1.5);
          expect(_deco(tester).color, Colors.transparent);
          expect(
            tester
                .widget<AnimatedOpacity>(
                  find.descendant(
                    of: _mark,
                    matching: find.byType(AnimatedOpacity),
                  ),
                )
                .opacity,
            0,
          );
        },
      );

      testWidgets('seçili $name: brand dolgu + onBrand ✓', (tester) async {
        await pumpApp(tester, const _BoxHost(initial: true), dark: dark);
        expect(_deco(tester).color, c.brand);
        expect(_side(tester).color, c.brand);
        final icon = tester.widget<Icon>(find.byIcon(AppIcons.check));
        expect(icon.color, c.onBrand);
        expect(
          tester
              .widget<AnimatedOpacity>(
                find.descendant(
                  of: _mark,
                  matching: find.byType(AnimatedOpacity),
                ),
              )
              .opacity,
          1,
        );
      });
    }

    testWidgets('dokunma alanı 44x44', (tester) async {
      await pumpApp(tester, const _BoxHost());
      expect(tester.getSize(find.byType(AppCheckbox)), const Size(44, 44));
    });

    testWidgets('dokununca değişir, selection haptic', (tester) async {
      final calls = <String>[];
      final seen = <bool>[];
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
      await pumpApp(tester, _BoxHost(onValue: seen.add));
      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();
      expect(seen, [true, false]);
      expect(calls, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
      ]);
    });

    testWidgets('pasif: surfaceMuted, ✓ textDisabled, değişmez', (
      tester,
    ) async {
      final seen = <bool>[];
      await pumpApp(
        tester,
        _BoxHost(initial: true, enabled: false, onValue: seen.add),
      );
      expect(_deco(tester).color, AppColors.light.surfaceMuted);
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.check)).color,
        AppColors.light.textDisabled,
      );
      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();
      expect(seen, isEmpty);
    });

    testWidgets('semantics: etiket, işaretli durumu', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const _BoxHost());
      expect(
        tester.getSemantics(find.byType(AppCheckbox)),
        matchesSemantics(
          label: 'Koşulları kabul ediyorum',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasCheckedState: true,
          isChecked: false,
        ),
      );
      await tester.tap(find.byType(AppCheckbox));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.byType(AppCheckbox))
            .flagsCollection
            .isChecked
            .toString(),
        contains('isTrue'),
      );
      handle.dispose();
    });
  });

  group('Check Circle', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets(
        'seçili değil $name: 24 daire, borderControl; seçili: brand + onBrand ✓ 16',
        (tester) async {
          await pumpApp(tester, const _CircleHost(), dark: dark);
          expect(tester.getSize(_markBox), const Size(24, 24));
          expect(_deco(tester).shape, isA<CircleBorder>());
          expect(_side(tester).color, c.borderControl);
          await tester.tap(find.byType(AppCheckCircle));
          await tester.pumpAndSettle();
          expect(_deco(tester).color, c.brand);
          final icon = tester.widget<Icon>(find.byIcon(AppIcons.check));
          expect(icon.color, c.onBrand);
          expect(icon.size, 16);
        },
      );
    }

    testWidgets('onChanged yoksa yalnızca görsel: dokunulamaz, semantics yok', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const AppCheckCircle(selected: true));
      expect(find.byType(GestureDetector), findsNothing);
      expect(find.bySemanticsLabel('Seçenek'), findsNothing);
      expect(tester.getSize(_markBox), const Size(24, 24));
      handle.dispose();
    });

    testWidgets('onChanged verilirse semanticLabel zorunlu', (tester) async {
      expect(
        () => AppCheckCircle(selected: false, onChanged: (_) {}),
        throwsAssertionError,
      );
    });

    testWidgets('etkileşimli: 44x44 alan, işaretli semantics', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const _CircleHost());
      expect(tester.getSize(find.byType(AppCheckCircle)), const Size(44, 44));
      expect(tester.getSemantics(find.byType(AppCheckCircle)).label, 'Seçenek');
      handle.dispose();
    });
  });

  testWidgets('Reduce Motion: işaret anında oturur', (tester) async {
    await pumpApp(tester, const _BoxHost(), disableAnimations: true);
    await tester.tap(find.byType(AppCheckbox));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.takeException(), isNull);
  });
}
