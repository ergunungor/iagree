import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/content/place_meta.dart';

import '../../support/pump_app.dart';

/// PlaceMeta bir BuildContext ister; küçük bir yardımcıyla çıktısını okur.
Future<T> _read<T>(
  WidgetTester tester,
  PlaceMeta meta,
  T Function(BuildContext, PlaceMeta) f, {
  Locale locale = const Locale('tr'),
}) async {
  late T result;
  await pumpApp(
    tester,
    Builder(
      builder: (context) {
        result = f(context, meta);
        return const SizedBox.shrink();
      },
    ),
    locale: locale,
  );
  return result;
}

void main() {
  testWidgets('tüm parçalar: 4,7 · Kahve · ₺ · 650 m', (tester) async {
    final text = await _read(
      tester,
      const PlaceMeta(
        rating: 4.7,
        category: 'Kahve',
        priceLevel: 1,
        distanceKm: 0.65,
      ),
      (c, m) => m.plain(c),
    );
    expect(text, '4,7 · Kahve · ₺ · 650 m');
  });

  testWidgets('en: ondalık nokta', (tester) async {
    final text = await _read(
      tester,
      const PlaceMeta(
        rating: 4.7,
        category: 'Kahve',
        priceLevel: 2,
        distanceKm: 1.4,
      ),
      (c, m) => m.plain(c),
      locale: const Locale('en'),
    );
    expect(text, '4.7 · Kahve · ₺₺ · 1.4 km');
  });

  testWidgets('boş öğeler atlanır', (tester) async {
    expect(
      await _read(
        tester,
        const PlaceMeta(category: 'Kafe', distanceKm: 2.5),
        (c, m) => m.plain(c),
      ),
      'Kafe · 2,5 km',
    );
    expect(await _read(tester, const PlaceMeta(), (c, m) => m.plain(c)), '');
    expect(
      await _read(tester, const PlaceMeta(rating: 4), (c, m) => m.plain(c)),
      '4,0',
    );
  });

  group('mesafe', () {
    final cases = {
      0.65: '650 m',
      0.8: '800 m',
      0.847: '850 m', // en yakın 10
      0.05: '50 m',
      0.996: '1 km', // 1000 m'ye yuvarlanıyorsa kilometre
      1.0: '1 km',
      1.2: '1,2 km',
      1.04: '1 km',
      12.34: '12,3 km',
    };
    for (final e in cases.entries) {
      testWidgets('${e.key} km → ${e.value}', (tester) async {
        expect(
          await _read(
            tester,
            PlaceMeta(distanceKm: e.key),
            (c, m) => m.distanceText(c),
          ),
          e.value,
        );
      });
    }
  });

  testWidgets('VoiceOver: sayıya ek yok, birimler açık', (tester) async {
    final spoken = await _read(
      tester,
      const PlaceMeta(
        rating: 4.7,
        category: 'Kahve',
        priceLevel: 3,
        distanceKm: 0.65,
      ),
      (c, m) => m.spoken(c),
    );
    expect(spoken, '4,7 puan, Kahve, yüksek fiyat, 650 metre');
    final km = await _read(
      tester,
      const PlaceMeta(distanceKm: 1.2),
      (c, m) => m.spoken(c),
    );
    expect(km, '1,2 kilometre');
  });

  test('fiyat seviyesi 1–3 dışında assert verir', () {
    expect(() => PlaceMeta(priceLevel: 0), throwsAssertionError);
    expect(() => PlaceMeta(priceLevel: 4), throwsAssertionError);
  });
}
