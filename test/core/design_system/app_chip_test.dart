import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/selection/app_chip.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

class _Host extends StatefulWidget {
  const _Host({
    this.initial = false,
    this.enabled = true,
    this.onValue,
    this.label = 'Bugün',
  });
  final bool initial;
  final bool enabled;
  final ValueChanged<bool>? onValue;
  final String label;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late bool selected = widget.initial;

  @override
  Widget build(BuildContext context) => AppChip(
    label: widget.label,
    selected: selected,
    onChanged: widget.enabled
        ? (v) {
            setState(() => selected = v);
            widget.onValue?.call(v);
          }
        : null,
  );
}

Finder get _chip => find.byType(AppChip);
Finder get _box =>
    find.descendant(of: _chip, matching: find.byType(AnimatedContainer));
ShapeDecoration _deco(WidgetTester tester) =>
    tester.widget<AnimatedContainer>(_box).decoration! as ShapeDecoration;
BorderSide _side(WidgetTester tester) =>
    (_deco(tester).shape as OutlinedBorder).side;
Text _text(WidgetTester tester, String s) => tester.widget<Text>(find.text(s));

void main() {
  group('görünüm', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets(
        'seçili değil $name: surfaceMuted, textPrimary, kenarlık saydam, ✓ yok',
        (tester) async {
          await pumpApp(tester, const _Host(), dark: dark);
          expect(_deco(tester).color, c.surfaceMuted);
          expect(_text(tester, 'Bugün').style!.color, c.textPrimary);
          expect(_side(tester).color, Colors.transparent);
          expect(find.byIcon(AppIcons.check), findsNothing);
        },
      );

      testWidgets(
        'seçili $name: brandSoft, onBrandSoft, 1,5px brand, solda 16\'lık ✓',
        (tester) async {
          await pumpApp(tester, const _Host(initial: true), dark: dark);
          expect(_deco(tester).color, c.brandSoft);
          expect(_text(tester, 'Bugün').style!.color, c.onBrandSoft);
          expect(_side(tester).color, c.brand);
          expect(_side(tester).width, 1.5);
          final icon = tester.widget<Icon>(find.byIcon(AppIcons.check));
          expect(icon.size, 16);
          expect(icon.color, c.onBrandSoft);
          expect(
            tester.getCenter(find.byIcon(AppIcons.check)).dx,
            lessThan(tester.getCenter(find.text('Bugün')).dx),
          );
        },
      );
    }

    testWidgets('36 min yükseklik, pill, label stili, dokunma alanı 44', (
      tester,
    ) async {
      await pumpApp(tester, const _Host());
      expect(tester.getSize(_box).height, 36);
      expect(tester.getSize(_chip).height, greaterThanOrEqualTo(44));
      final shape = _deco(tester).shape as RoundedSuperellipseBorder;
      expect(shape.borderRadius, BorderRadius.circular(999));
      expect(_text(tester, 'Bugün').style!.fontSize, 15);
    });

    testWidgets('yatay padding 16 (kenarlık dahil)', (tester) async {
      await pumpApp(tester, const _Host());
      final box = tester.getRect(_box);
      final text = tester.getRect(find.text('Bugün'));
      expect(text.left - box.left, closeTo(16, 0.5));
      expect(box.right - text.right, closeTo(16, 0.5));
    });

    testWidgets('pasif: surfaceMuted, textDisabled, seçilemez', (tester) async {
      await pumpApp(tester, const _Host(enabled: false));
      expect(_deco(tester).color, AppColors.light.surfaceMuted);
      expect(_text(tester, 'Bugün').style!.color, AppColors.light.textDisabled);
      await tester.tap(_chip);
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.check), findsNothing);
    });
  });

  group('seçim ve animasyon', () {
    testWidgets('dokununca seçilir ve tekrar dokununca kalkar', (tester) async {
      final seen = <bool>[];
      await pumpApp(tester, _Host(onValue: seen.add));
      await tester.tap(_chip);
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.check), findsOneWidget);
      await tester.tap(_chip);
      await tester.pumpAndSettle();
      expect(find.byIcon(AppIcons.check), findsNothing);
      expect(seen, [true, false]);
    });

    testWidgets(
      'seçilince genişlik ✓ + 8 kadar artar; kenarlık yüzünden yükseklik değişmez',
      (tester) async {
        await pumpApp(tester, const _Host());
        final before = tester.getSize(_box);
        await tester.tap(_chip);
        await tester.pumpAndSettle();
        final after = tester.getSize(_box);
        expect(after.width - before.width, closeTo(16 + 8, 0.5));
        expect(after.height, before.height);
      },
    );

    testWidgets(
      'genişlik spring ile açılır: ara karelerde artış sürer, sonunda tam değer',
      (tester) async {
        await pumpApp(tester, const _Host());
        final start = tester.getSize(_box).width;
        await tester.tap(_chip);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        final mid = tester.getSize(_box).width;
        expect(mid, greaterThan(start));
        expect(mid, lessThan(start + 24.5 + 2)); // en fazla küçük bir taşma
        await tester.pumpAndSettle();
        expect(tester.getSize(_box).width, closeTo(start + 24, 0.5));
      },
    );

    testWidgets('Reduce Motion: genişlik anında değişir', (tester) async {
      await pumpApp(tester, const _Host(), disableAnimations: true);
      final start = tester.getSize(_box).width;
      await tester.tap(_chip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1));
      expect(tester.getSize(_box).width, closeTo(start + 24, 0.5));
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
      await tester.tap(_chip);
      await tester.pumpAndSettle();
      await tester.tap(_chip);
      await tester.pumpAndSettle();
      expect(calls, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
      ]);
    });
  });

  group('erişilebilirlik ve düzen', () {
    testWidgets('semantics: buton, etiket, seçili durumu', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const _Host());
      expect(
        tester.getSemantics(_chip),
        matchesSemantics(
          label: 'Bugün',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasSelectedState: true,
          isSelected: false,
        ),
      );
      await tester.tap(_chip);
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(_chip),
        matchesSemantics(
          label: 'Bugün',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasSelectedState: true,
          isSelected: true,
        ),
      );
      handle.dispose();
    });

    testWidgets(
      'Wrap içinde chip\'ler arası 8 boşlukla dizilir ve satır atlar',
      (tester) async {
        await pumpApp(
          tester,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final l in [
                'Şimdi',
                'Bugün',
                'Bu hafta sonu',
                'Cuma akşamı',
              ])
                AppChip(label: l, selected: false, onChanged: (_) {}),
            ],
          ),
        );
        final a = tester.getRect(find.byType(AppChip).at(0));
        final b = tester.getRect(find.byType(AppChip).at(1));
        expect(b.left - a.right, closeTo(8, 1));
      },
    );

    testWidgets('yazı 2x: chip metinle büyür, taşma yok', (tester) async {
      await pumpApp(
        tester,
        const _Host(initial: true, label: 'Bu hafta sonu'),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(_box).height, greaterThan(36));
    });
  });
}
