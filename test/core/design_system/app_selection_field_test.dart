import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/content/app_list_group.dart';
import 'package:iagree/core/design_system/components/feedback/app_sheet.dart';
import 'package:iagree/core/design_system/components/inputs/app_selection_field.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/foundations/app_pressable.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

const _options = [
  AppSelectionOption(value: 'bugun', label: 'Bugün'),
  AppSelectionOption(value: 'hafta', label: 'Bu hafta sonu'),
  AppSelectionOption(value: 'baska', label: 'Başka zaman'),
];

class _Host extends StatefulWidget {
  const _Host({this.initial, this.enabled = true, this.onValue});
  final String? initial;
  final bool enabled;
  final ValueChanged<String>? onValue;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late String? value = widget.initial;

  @override
  Widget build(BuildContext context) => AppSelectionField<String>(
    label: 'Ne zaman',
    options: _options,
    value: value,
    hintText: 'Seç',
    onChanged: widget.enabled
        ? (v) {
            setState(() => value = v);
            widget.onValue?.call(v);
          }
        : null,
  );
}

Finder get _field => find.byType(AppSelectionField<String>);
Finder get _box =>
    find.descendant(of: _field, matching: find.byType(AnimatedContainer));
ShapeDecoration _deco(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(_box).decoration! as ShapeDecoration;

void main() {
  group('görünüm', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets(
        'TextField görünümü: surfaceMuted, radius md, min 52, etiket üstte $name',
        (tester) async {
          _phone(tester);
          await pumpApp(tester, const _Host(), dark: dark);
          expect(_deco(tester).color, c.surfaceMuted);
          expect(
            (_deco(tester).shape as RoundedSuperellipseBorder).borderRadius,
            BorderRadius.circular(14),
          );
          expect(tester.getSize(_box).height, greaterThanOrEqualTo(52));
          final label = tester.widget<Text>(find.text('Ne zaman'));
          expect(label.style!.color, c.textSecondary);
          expect(
            tester.getBottomLeft(find.text('Ne zaman')).dy,
            lessThan(tester.getTopLeft(_box).dy),
          );
        },
      );
    }

    testWidgets(
      'sağda yukarı-aşağı chevron 20; değer yoksa ipucu textTertiary',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, const _Host());
        final icon = tester.widget<Icon>(find.byIcon(AppIcons.upDown));
        expect(icon.size, 20);
        expect(
          tester.getCenter(find.byIcon(AppIcons.upDown)).dx,
          greaterThan(tester.getCenter(_box).dx),
        );
        expect(
          tester.widget<Text>(find.text('Seç')).style!.color,
          AppColors.light.textTertiary,
        );
      },
    );

    testWidgets('seçili değer gösterilir, textPrimary', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Host(initial: 'hafta'));
      final t = tester.widget<Text>(find.text('Bu hafta sonu'));
      expect(t.style!.color, AppColors.light.textPrimary);
      expect(find.text('Seç'), findsNothing);
    });

    testWidgets('pasif: textDisabled, açılmaz', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Host(initial: 'bugun', enabled: false));
      expect(
        tester.widget<Text>(find.text('Bugün')).style!.color,
        AppColors.light.textDisabled,
      );
      await tester.tap(_box);
      await tester.pumpAndSettle();
      expect(AppSheet.isOpen, isFalse);
    });
  });

  group('sheet ile seçim', () {
    testWidgets(
      'dokununca dropdown değil bottom sheet açılır; seçenekler listede',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, const _Host());
        await tester.tap(_box);
        await tester.pumpAndSettle();
        expect(AppSheet.isOpen, isTrue);
        expect(find.byType(DropdownButton), findsNothing);
        expect(find.byType(AppListGroup), findsOneWidget);
        for (final o in _options) {
          expect(
            find.descendant(
              of: find.byType(AppListGroup),
              matching: find.text(o.label),
            ),
            findsOneWidget,
          );
        }
        // Başlık varsayılan olarak etiket.
        expect(find.text('Ne zaman'), findsWidgets);
      },
    );

    testWidgets(
      'seçili seçenekte sağda ✓; seçince sheet kapanır ve onChanged çağrılır',
      (tester) async {
        _phone(tester);
        final seen = <String>[];
        await pumpApp(tester, _Host(initial: 'bugun', onValue: seen.add));
        await tester.tap(_box);
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(AppListGroup),
            matching: find.byIcon(AppIcons.check),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.descendant(
            of: find.byType(AppListGroup),
            matching: find.text('Başka zaman'),
          ),
        );
        await tester.pumpAndSettle();
        expect(AppSheet.isOpen, isFalse);
        expect(seen, ['baska']);
        expect(find.text('Başka zaman'), findsOneWidget);
      },
    );

    testWidgets(
      'sheet açıkken alan odaklı görünür (surfaceInputFocus + brand kenar)',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, const _Host());
        await tester.tap(_box);
        await tester.pumpAndSettle();
        expect(_deco(tester).color, AppColors.light.surfaceInputFocus);
        expect(
          (_deco(tester).shape as OutlinedBorder).side.color,
          AppColors.light.brand,
        );
        await tester.tapAt(const Offset(200, 20)); // scrim
        await tester.pumpAndSettle();
        expect(_deco(tester).color, AppColors.light.surfaceMuted);
        expect(
          (_deco(tester).shape as OutlinedBorder).side.color,
          Colors.transparent,
        );
      },
    );

    testWidgets('sheet\'i seçmeden kapatmak onChanged çağırmaz', (
      tester,
    ) async {
      _phone(tester);
      final seen = <String>[];
      await pumpApp(tester, _Host(onValue: seen.add));
      await tester.tap(_box);
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 20));
      await tester.pumpAndSettle();
      expect(seen, isEmpty);
    });

    testWidgets('sheet başlığı özelleştirilebilir', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        AppSelectionField<String>(
          label: 'Zaman',
          sheetTitle: 'Zamanı seç',
          options: _options,
          value: null,
          onChanged: (_) {},
        ),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(AppSelectionField<String>),
          matching: find.byType(AnimatedContainer),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Zamanı seç'), findsOneWidget);
    });
  });

  group('erişilebilirlik ve ölçek', () {
    testWidgets('buton: etiket, değer/ipucu', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const _Host(initial: 'hafta'));
      final node = tester.getSemantics(
        find.descendant(of: _field, matching: find.byType(AppPressable)),
      );
      expect(node.label, 'Ne zaman');
      expect(node.value, 'Bu hafta sonu');
      expect(node.flagsCollection.isButton, isTrue);
      handle.dispose();
    });

    testWidgets('yazı 2x: alan büyür, taşma yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, const _Host(initial: 'hafta'), textScale: 2);
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_box).height, greaterThan(52));
    });
  });
}
