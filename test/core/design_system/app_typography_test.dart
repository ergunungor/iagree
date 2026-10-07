import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/foundations/clamped_text_scale.dart';
import 'package:iagree/core/design_system/tokens/app_typography.dart';

/// docs/design-system/tokens.json ile kodlanan stillerin birebir eşleştiğini doğrular.
Map<String, TextStyle> _styles(AppTypography t) => {
  'display': t.display,
  'h1': t.h1,
  'h2': t.h2,
  'h3': t.h3,
  'title': t.title,
  'body': t.body,
  'bodySmall': t.bodySmall,
  'label': t.label,
  'button': t.button,
  'caption': t.caption,
  'overline': t.overline,
};

double _px(String v) => double.parse(v.replaceAll('px', ''));

String _camel(String n) {
  final p = n.split('-');
  return p.first +
      p.skip(1).map((x) => x[0].toUpperCase() + x.substring(1)).join();
}

void main() {
  final json = jsonDecode(
    File('docs/design-system/tokens.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final specs = [
    for (final g in (json['type'] as Map)['groups'] as List)
      for (final s in g['styles'] as List) s as Map<String, dynamic>,
  ];
  final styles = _styles(AppTypography.regular);

  test('tokens.json içindeki her stil kodda karşılanıyor ve tersi', () {
    expect(
      specs.map((s) => _camel(s['name'] as String)).toSet(),
      styles.keys.toSet(),
    );
  });

  for (final spec in specs) {
    final name = _camel(spec['name'] as String);
    test('$name boyut, satır yüksekliği, ağırlık, letter spacing', () {
      final style = styles[name]!;
      final size = _px(spec['fontSize'] as String);
      expect(style.fontSize, size);
      expect(
        style.height,
        closeTo(_px(spec['lineHeight'] as String) / size, 1e-9),
      );
      expect(style.fontWeight!.value, spec['fontWeight']);
      expect(style.letterSpacing, _px(spec['letterSpacing'] as String));
    });
  }

  test('Fraunces yalnızca display ve h1', () {
    final all = {
      ..._styles(AppTypography.regular),
      'buttonSmall': AppTypography.regular.buttonSmall,
    };
    for (final e in all.entries) {
      expect(
        e.value.fontFamily,
        e.key == 'display' || e.key == 'h1' ? 'Fraunces' : isNull,
        reason: e.key,
      );
    }
    final axes = {
      for (final v in AppTypography.regular.display.fontVariations!)
        v.axis: v.value,
    };
    expect(axes, {'SOFT': 50, 'WONK': 0, 'wght': 500});
  });

  test('buttonSmall: 15/20, 600', () {
    final s = AppTypography.regular.buttonSmall;
    expect(s.fontSize, 15);
    expect(s.height, closeTo(20 / 15, 1e-9));
    expect(s.fontWeight, FontWeight.w600);
  });

  test('bold() ağırlıkları +100 yapar, Fraunces wght dahil', () {
    final b = AppTypography.regular.bold();
    expect(b.body.fontWeight, FontWeight.w500);
    expect(b.h2.fontWeight, FontWeight.w800);
    expect(b.display.fontWeight, FontWeight.w600);
    expect(
      {for (final v in b.display.fontVariations!) v.axis: v.value}['wght'],
      600,
    );
    expect(AppTypography.regular.body.fontWeight, FontWeight.w400);
  });

  test('tabular rakam özelliği ekler', () {
    expect(
      AppTypography.regular.caption.tabular.fontFeatures,
      contains(const FontFeature.tabularFigures()),
    );
  });

  testWidgets('ClampedTextScale 2.0 ölçeği üst sınıra indirir', (tester) async {
    double? display, arc, plain;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
        child: Column(
          children: [
            ClampedTextScale.display(
              child: Builder(
                builder: (c) {
                  display = MediaQuery.textScalerOf(c).scale(10);
                  return const SizedBox();
                },
              ),
            ),
            ClampedTextScale.arcNumber(
              child: Builder(
                builder: (c) {
                  arc = MediaQuery.textScalerOf(c).scale(10);
                  return const SizedBox();
                },
              ),
            ),
            Builder(
              builder: (c) {
                plain = MediaQuery.textScalerOf(c).scale(10);
                return const SizedBox();
              },
            ),
          ],
        ),
      ),
    );
    expect(display, closeTo(13, 1e-9));
    expect(arc, closeTo(15, 1e-9));
    expect(plain, closeTo(20, 1e-9));
  });
}
