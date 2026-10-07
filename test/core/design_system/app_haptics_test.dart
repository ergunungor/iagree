import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/foundations/app_haptics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(AppHaptics.channel, null);
    messenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  final actions = <String, void Function()>{
    'selection': AppHaptics.selection,
    'light': AppHaptics.light,
    'medium': AppHaptics.medium,
    'rigid': AppHaptics.rigid,
    'success': AppHaptics.success,
    'error': AppHaptics.error,
  };

  test('iOS: her metot kendi adıyla native kanala gider', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(AppHaptics.channel, (call) async {
      calls.add(call.method);
      return null;
    });
    for (final a in actions.values) {
      a();
    }
    await Future<void>.delayed(Duration.zero);
    expect(calls, actions.keys.toList());
  });

  test('Android: HapticFeedback eşlemesi', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        calls.add(call.arguments as String);
      }
      return null;
    });
    for (final a in actions.values) {
      a();
    }
    await Future<void>.delayed(Duration.zero);
    expect(calls, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
      'HapticFeedbackType.mediumImpact',
      'HapticFeedbackType.heavyImpact',
    ]);
  });

  test('iOS: kanal hatası ve eksik native taraf sessizce yutulur', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // Handler yok: MissingPluginException.
    expect(() => AppHaptics.rigid(), returnsNormally);
    messenger.setMockMethodCallHandler(AppHaptics.channel, (call) async {
      throw PlatformException(code: 'boom');
    });
    expect(() => AppHaptics.success(), returnsNormally);
    await Future<void>.delayed(Duration.zero);
  });
}
