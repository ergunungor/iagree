import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

/// iOS başlatma ekranı (SCREENS.md A1): yalnızca canvas rengi, light ve dark için ayrı.
void main() {
  Color fromComponents(Map<String, dynamic> c) {
    int v(String key) =>
        int.parse((c[key] as String).replaceFirst('0x', ''), radix: 16);
    return Color.fromARGB(0xFF, v('red'), v('green'), v('blue'));
  }

  final colorset = jsonDecode(
    File('ios/Runner/Assets.xcassets/LaunchBackground.colorset/Contents.json')
        .readAsStringSync(),
  ) as Map<String, dynamic>;
  final colors = (colorset['colors'] as List).cast<Map<String, dynamic>>();

  test('LaunchBackground: light canvas, dark canvas (luminosity dark)', () {
    expect(colors.length, 2);
    final light = colors.firstWhere((c) => !c.containsKey('appearances'));
    final dark = colors.firstWhere((c) => c.containsKey('appearances'));
    expect(((dark['appearances'] as List).single as Map)['value'], 'dark');
    expect(
      fromComponents(
        (light['color'] as Map<String, dynamic>)['components']
            as Map<String, dynamic>,
      ),
      AppColors.light.canvas,
    );
    expect(
      fromComponents(
        (dark['color'] as Map<String, dynamic>)['components']
            as Map<String, dynamic>,
      ),
      AppColors.dark.canvas,
    );
  });

  test('storyboard: arka plan LaunchBackground, görsel/metin yok', () {
    final sb = File('ios/Runner/Base.lproj/LaunchScreen.storyboard')
        .readAsStringSync();
    expect(
      sb,
      contains('<color key="backgroundColor" name="LaunchBackground"/>'),
    );
    expect(sb, isNot(contains('imageView')));
    expect(sb, isNot(contains('LaunchImage')));
    expect(sb, isNot(contains('<label')));
  });

  test(
    'Info.plist LaunchScreen storyboard\'unu kullanıyor, eski LaunchImage yok',
    () {
      expect(
        File('ios/Runner/Info.plist').readAsStringSync(),
        contains('<string>LaunchScreen</string>'),
      );
      expect(
        Directory('ios/Runner/Assets.xcassets/LaunchImage.imageset')
            .existsSync(),
        isFalse,
      );
    },
  );
}
