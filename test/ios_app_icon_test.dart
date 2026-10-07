import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

/// iOS uygulama ikonu kataloğu: tek boyut, açık + koyu, App Store kurallarına uygun.
void main() {
  const dir = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  final contents = jsonDecode(
    File('$dir/Contents.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final images = (contents['images'] as List).cast<Map<String, dynamic>>();

  test('katalog: açık ve koyu (luminosity dark), universal ios 1024', () {
    expect(images.length, 2);
    for (final i in images) {
      expect(i['idiom'], 'universal');
      expect(i['platform'], 'ios');
      expect(i['size'], '1024x1024');
    }
    final dark = images.where((i) => i.containsKey('appearances')).single;
    expect((dark['appearances'] as List).single, {
      'appearance': 'luminosity',
      'value': 'dark',
    });
    expect(images.where((i) => !i.containsKey('appearances')).length, 1);
  });

  test('dosyalar var, assets/logo ile bayt bayt aynı', () {
    final byName = {
      for (final i in images)
        i['filename'] as String: i.containsKey('appearances')
            ? 'assets/logo/app-icon-dark-1024.png'
            : 'assets/logo/app-icon-1024.png',
    };
    for (final e in byName.entries) {
      expect(
        File('$dir/${e.key}').readAsBytesSync(),
        File(e.value).readAsBytesSync(),
        reason: e.key,
      );
    }
  });

  test('PNG\'ler 1024x1024 ve alfasız (RGB), eski varsayılan ikonlar yok', () {
    for (final i in images) {
      final b = File('$dir/${i['filename']}').readAsBytesSync();
      final width = ByteData.sublistView(b, 16, 20).getUint32(0);
      final height = ByteData.sublistView(b, 20, 24).getUint32(0);
      expect([width, height], [1024, 1024]);
      expect(b[24], 8, reason: 'bit derinliği');
      expect(b[25], 2, reason: 'renk tipi 2 = RGB (alfa yok)');
    }
    final pngs = Directory(dir)
        .listSync()
        .where((f) => f.path.endsWith('.png'))
        .length;
    expect(pngs, 2);
  });
}
