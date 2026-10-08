import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/selection/app_toggle.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

class _Host extends StatefulWidget {
  const _Host({this.initial = false, this.enabled = true, this.onValue});
  final bool initial;
  final bool enabled;
  final ValueChanged<bool>? onValue;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late bool value = widget.initial;

  @override
  Widget build(BuildContext context) => AppToggle(
    value: value,
    semanticLabel: 'Bildirimler',
    onChanged: widget.enabled
        ? (v) {
            setState(() => value = v);
            widget.onValue?.call(v);
          }
        : null,
  );
}

Finder get _toggle => find.byType(AppToggle);
Finder get _switch => find.byType(CupertinoSwitch);

void main() {
  for (final dark in [false, true]) {
    final c = dark ? AppColors.dark : AppColors.light;
    final name = dark ? 'dark' : 'light';

    testWidgets('CupertinoSwitch: açık brand, kapalı trackOff $name', (
      tester,
    ) async {
      await pumpApp(tester, const _Host(initial: true), dark: dark);
      var sw = tester.widget<CupertinoSwitch>(_switch);
      expect(sw.activeTrackColor, c.brand);
      expect(sw.inactiveTrackColor, c.trackOff);
      expect(sw.value, isTrue);
      await tester.tap(_switch);
      await tester.pumpAndSettle();
      sw = tester.widget<CupertinoSwitch>(_switch);
      expect(sw.value, isFalse);
    });
  }

  testWidgets('dokunma alanı en az 44 yükseklik', (tester) async {
    await pumpApp(tester, const _Host());
    expect(tester.getSize(_toggle).height, greaterThanOrEqualTo(44));
  });

  testWidgets('anahtarın dışındaki 44\'lük bölgeye dokunuş da çevirir', (
    tester,
  ) async {
    final seen = <bool>[];
    await pumpApp(tester, _Host(onValue: seen.add));
    final sw = tester.getRect(_switch);
    final area = tester.getRect(_toggle);
    expect(area.height, greaterThan(sw.height));
    await tester.tapAt(Offset(sw.center.dx, area.top + 1));
    await tester.pumpAndSettle();
    expect(seen, [true]);
  });

  testWidgets('değişimde light haptic (tek sefer), onChanged çağrılır', (
    tester,
  ) async {
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
    await pumpApp(tester, _Host(onValue: seen.add));
    await tester.tap(_switch);
    await tester.pumpAndSettle();
    expect(seen, [true]);
    expect(calls, ['HapticFeedbackType.lightImpact']);
  });

  testWidgets('pasif: çevrilmez', (tester) async {
    final seen = <bool>[];
    await pumpApp(
      tester,
      _Host(enabled: false, initial: true, onValue: seen.add),
    );
    await tester.tap(_switch, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(seen, isEmpty);
    expect(tester.widget<CupertinoSwitch>(_switch).value, isTrue);
  });

  testWidgets('semantics: etiket + açık/kapalı durumu', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpApp(tester, const _Host(initial: true));
    expect(
      tester.getSemantics(_toggle),
      isSemantics(label: 'Bildirimler', hasToggledState: true, isToggled: true),
    );
    handle.dispose();
  });
}
