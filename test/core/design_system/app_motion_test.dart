import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/tokens/app_motion.dart';

/// docs/design-system/tokens.json ile kodlanan süre, eğri ve spring değerlerinin eşleştiğini doğrular.
Map<String, String> _values(
  Map<String, dynamic> json,
  String section,
  String prefix,
) => {
  for (final t in (json[section] as Map)['tokens'] as List)
    (t['name'] as String).replaceFirst(prefix, ''): t['value'] as String,
};

double _damping(SpringDescription s) =>
    s.damping / (2 * math.sqrt(s.stiffness * s.mass));
double _response(SpringDescription s) =>
    2 * math.pi / math.sqrt(s.stiffness / s.mass);

void main() {
  final json = jsonDecode(
    File('docs/design-system/tokens.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('süreler tokens.json ile aynı', () {
    final v = _values(json, 'duration', 'duration-');
    int ms(String k) => int.parse(v[k]!.replaceAll('ms', ''));
    final m = AppMotion.regular;
    expect(m.fast.inMilliseconds, ms('fast'));
    expect(m.standard.inMilliseconds, ms('standard'));
    expect(m.emphasis.inMilliseconds, ms('emphasis'));
    expect(m.expressive.inMilliseconds, ms('expressive'));
  });

  test('eğriler tokens.json ile aynı', () {
    final v = _values(json, 'easing', 'ease-');
    Cubic parse(String css) {
      final n = RegExp(r'cubic-bezier\(([^)]+)\)')
          .firstMatch(css)![1]!
          .split(',')
          .map((e) => double.parse(e.trim()))
          .toList();
      return Cubic(n[0], n[1], n[2], n[3]);
    }

    void same(Cubic actual, String css) {
      final e = parse(css);
      expect([actual.a, actual.b, actual.c, actual.d], [e.a, e.b, e.c, e.d]);
    }

    same(AppMotion.enter, v['enter']!);
    same(AppMotion.exit, v['exit']!);
    same(AppMotion.move, v['move']!);
  });

  test('spring damping ratio ve response spec tablosuyla uyuşuyor', () {
    final m = AppMotion.regular;
    expect(m.springSnappy.stiffness, 439);
    expect(m.springStandard.stiffness, 195);
    expect(m.springBouncy.stiffness, 158);
    expect(_damping(m.springSnappy), closeTo(0.9, 1e-9));
    expect(_damping(m.springStandard), closeTo(0.85, 1e-9));
    expect(_damping(m.springBouncy), closeTo(0.7, 1e-9));
    expect(_response(m.springSnappy), closeTo(0.30, 0.01));
    expect(_response(m.springStandard), closeTo(0.45, 0.01));
    expect(_response(m.springBouncy), closeTo(0.50, 0.01));
  });

  test('reduced: süreler 0, spring aynı stiffness ile kritik sönümlü', () {
    final r = AppMotion.reduced;
    expect(r.reduceMotion, isTrue);
    for (final d in [r.fast, r.standard, r.emphasis, r.expressive]) {
      expect(d, Duration.zero);
    }
    for (final s in [r.springSnappy, r.springStandard, r.springBouncy]) {
      expect(_damping(s), closeTo(1, 1e-9));
    }
    expect(r.springSnappy.stiffness, AppMotion.regular.springSnappy.stiffness);
  });

  testWidgets('of(context) disableAnimations ile reduced döner', (
    tester,
  ) async {
    late AppMotion on, off;
    Widget probe(bool disabled, void Function(AppMotion) sink) => MediaQuery(
      data: MediaQueryData(disableAnimations: disabled),
      child: Builder(
        builder: (c) {
          sink(AppMotion.of(c));
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(probe(true, (m) => on = m));
    await tester.pumpWidget(probe(false, (m) => off = m));
    expect(on.reduceMotion, isTrue);
    expect(off.reduceMotion, isFalse);
  });
}
