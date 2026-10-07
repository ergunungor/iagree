import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';

void main() {
  const regular = <String, IconData>{
    'share': AppIcons.share,
    'undo': AppIcons.undo,
    'check': AppIcons.check,
    'close': AppIcons.close,
    'heart': AppIcons.heart,
    'prohibit': AppIcons.prohibit,
    'search': AppIcons.search,
    'plus': AppIcons.plus,
    'minus': AppIcons.minus,
    'back': AppIcons.back,
    'chevronRight': AppIcons.chevronRight,
    'upDown': AppIcons.upDown,
    'link': AppIcons.link,
    'copy': AppIcons.copy,
    'warning': AppIcons.warning,
    'info': AppIcons.info,
    'star': AppIcons.star,
    'map': AppIcons.map,
    'userPlus': AppIcons.userPlus,
    'wifiOff': AppIcons.wifiOff,
  };
  const fill = <String, IconData>{
    'heartFill': AppIcons.heartFill,
    'starFill': AppIcons.starFill,
  };

  test('Regular ikonlar PhosphorRegular ailesinde', () {
    for (final e in regular.entries) {
      expect(e.value.fontFamily, 'PhosphorRegular', reason: e.key);
    }
  });

  test('Fill ikonlar PhosphorFill ailesinde', () {
    for (final e in fill.entries) {
      expect(e.value.fontFamily, 'PhosphorFill', reason: e.key);
    }
  });

  test('aynı ailede iki ikon aynı glyph\'i paylaşmaz', () {
    for (final group in [regular, fill]) {
      final points = group.values.map((i) => i.codePoint).toList();
      expect(points.toSet().length, points.length);
    }
  });

  test('Fill varyantı Regular\'dan farklı glyph', () {
    expect(AppIcons.heartFill.fontFamily, isNot(AppIcons.heart.fontFamily));
    expect(AppIcons.starFill.fontFamily, isNot(AppIcons.star.fontFamily));
  });

  test('her ikon phosphor_flutter kaynağındaki glyph ile aynı kod noktası', () {
    final config = jsonDecode(
      File('.dart_tool/package_config.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final root = Uri.parse(
      ((config['packages'] as List).firstWhere(
            (p) => p['name'] == 'phosphor_flutter',
          ) as Map)['rootUri']
          as String,
    ).toFilePath();
    final sources = {
      'PhosphorRegular': File('$root/lib/src/phosphor_icons_regular.dart')
          .readAsStringSync(),
      'PhosphorFill': File('$root/lib/src/phosphor_icons_fill.dart')
          .readAsStringSync(),
    };
    const phosphorName = {
      'share': 'export',
      'undo': 'arrowUUpLeft',
      'check': 'check',
      'close': 'x',
      'heart': 'heart',
      'heartFill': 'heart',
      'prohibit': 'prohibit',
      'search': 'magnifyingGlass',
      'plus': 'plus',
      'minus': 'minus',
      'back': 'caretLeft',
      'chevronRight': 'caretRight',
      'upDown': 'caretUpDown',
      'link': 'link',
      'copy': 'copy',
      'warning': 'warning',
      'info': 'info',
      'star': 'star',
      'starFill': 'star',
      'map': 'mapPin',
      'userPlus': 'userPlus',
      'wifiOff': 'wifiSlash',
    };
    for (final e in {...regular, ...fill}.entries) {
      final match = RegExp(
        'static const ${phosphorName[e.key]} = PhosphorFlatIconData\\((0x[0-9a-f]+),',
      ).firstMatch(sources[e.value.fontFamily]!);
      expect(match, isNotNull, reason: e.key);
      expect(e.value.codePoint, int.parse(match![1]!), reason: e.key);
    }
    expect(phosphorName.length, regular.length + fill.length);
  });

  test('ikonlar paket fontuna bağlı', () {
    for (final i in [...regular.values, ...fill.values]) {
      expect(i.fontPackage, 'phosphor_flutter');
    }
  });

  test('AppIconSize tokens.json ile aynı', () {
    final json = jsonDecode(
      File('docs/design-system/tokens.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final v = {
      for (final t in (json['iconSize'] as Map)['tokens'] as List)
        t['name'] as String: double.parse(
          (t['value'] as String).replaceAll('px', ''),
        ),
    };
    expect(AppIconSize.s14, v['icon-14']);
    expect(AppIconSize.s16, v['icon-16']);
    expect(AppIconSize.s20, v['icon-20']);
    expect(AppIconSize.s24, v['icon-24']);
    expect(AppIconSize.s32, v['icon-32']);
  });
}
