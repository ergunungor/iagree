import 'dart:convert';
import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_elevation.dart';
import 'package:iagree/core/design_system/tokens/app_radius.dart';
import 'package:iagree/core/design_system/tokens/app_spacing.dart';

/// docs/design-system/tokens.json ile kodlanan spacing, radius ve gölgelerin eşleştiğini doğrular.
double _px(String v) => double.parse(v.replaceAll('px', ''));

Map<String, String> _values(
  Map<String, dynamic> json,
  String section,
  String prefix,
) => {
  for (final t in (json[section] as Map)['tokens'] as List)
    (t['name'] as String).replaceFirst(prefix, ''): t['value'] as String,
};

void main() {
  final json = jsonDecode(
    File('docs/design-system/tokens.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('spacing değerleri tokens.json ile aynı', () {
    final v = _values(json, 'spacing', 'space-');
    expect(AppSpacing.xxs, _px(v['xxs']!));
    expect(AppSpacing.xs, _px(v['xs']!));
    expect(AppSpacing.sm, _px(v['sm']!));
    expect(AppSpacing.md, _px(v['md']!));
    expect(AppSpacing.lg, _px(v['lg']!));
    expect(AppSpacing.xl, _px(v['xl']!));
    expect(AppSpacing.xxl, _px(v['xxl']!));
    expect(AppSpacing.xxxl, _px(v['xxxl']!));
    expect(AppSpacing.huge, _px(v['huge']!));
    expect(AppSpacing.giant, _px(v['giant']!));
    expect(AppSpacing.screenPadding, _px(v['screen-padding']!));
    expect(AppSpacing.sectionGap, _px(v['section-gap']!));
    expect(AppSpacing.cardPadding, _px(v['card-padding']!));
    expect(AppSpacing.touchTarget, _px(v['touch-target']!));
  });

  test('radius değerleri tokens.json ile aynı', () {
    final v = _values(json, 'radius', 'radius-');
    expect(AppRadius.xs, _px(v['xs']!));
    expect(AppRadius.sm, _px(v['sm']!));
    expect(AppRadius.md, _px(v['md']!));
    expect(AppRadius.lg, _px(v['lg']!));
    expect(AppRadius.xl, _px(v['xl']!));
    expect(AppRadius.pill, _px(v['pill']!));
  });

  group('elevation', () {
    final shadows = {
      for (final t in (json['shadow'] as Map)['tokens'] as List)
        t['name'] as String: t['value'] as Map<String, dynamic>,
    };
    final levels = {
      'shadow-e1': (AppElevation.light.e1, AppElevation.dark.e1),
      'shadow-e2': (AppElevation.light.e2, AppElevation.dark.e2),
      'shadow-e3': (AppElevation.light.e3, AppElevation.dark.e3),
    };
    final shadowRe = RegExp(
      r'(-?\d+)(?:px)? (-?\d+)(?:px)? (\d+)px rgba\((\d+),(\d+),(\d+),([\d.]+)\)',
    );

    void expectShadows(AppElevationLevel level, String css, String label) {
      final matches = shadowRe.allMatches(css).toList();
      expect(level.shadows.length, matches.length, reason: label);
      for (var i = 0; i < matches.length; i++) {
        final m = matches[i];
        final s = level.shadows[i];
        expect(
          s.offset,
          Offset(double.parse(m[1]!), double.parse(m[2]!)),
          reason: label,
        );
        expect(s.blurRadius, double.parse(m[3]!), reason: label);
        expect(s.spreadRadius, 0, reason: label);
        expect(
          s.color.r * 255,
          closeTo(double.parse(m[4]!), 0.5),
          reason: label,
        );
        expect(
          s.color.g * 255,
          closeTo(double.parse(m[5]!), 0.5),
          reason: label,
        );
        expect(
          s.color.b * 255,
          closeTo(double.parse(m[6]!), 0.5),
          reason: label,
        );
        expect(s.color.a, closeTo(double.parse(m[7]!), 1 / 255), reason: label);
      }
    }

    for (final e in levels.entries) {
      test(
        '${e.key} light',
        () => expectShadows(
          e.value.$1,
          shadows[e.key]!['light'] as String,
          e.key,
        ),
      );
    }
    test('shadow-e2 ve e3 dark', () {
      expectShadows(
        AppElevation.dark.e2,
        shadows['shadow-e2']!['dark'] as String,
        'e2',
      );
      expectShadows(
        AppElevation.dark.e3,
        shadows['shadow-e3']!['dark'] as String,
        'e3',
      );
    });
    test('dark e1: gölge yok, 1px border hairline', () {
      expect(shadows['shadow-e1']!['dark'], '0 0 0 1px #38323e');
      expect(AppElevation.dark.e1.shadows, isEmpty);
      expect(AppElevation.dark.e1.side.width, 1);
      expect(AppElevation.dark.e1.side.color, AppColors.dark.border);
      expect(AppElevation.light.e1.side, BorderSide.none);
    });
  });

  group('AppRadius', () {
    test('border RoundedSuperellipseBorder döndürür', () {
      final b = AppRadius.border(AppRadius.lg);
      expect(b, isA<RoundedSuperellipseBorder>());
      expect(b.borderRadius, BorderRadius.circular(20));
    });

    test('top yalnızca üst köşeleri yuvarlar', () {
      final r = AppRadius.top(AppRadius.xl);
      expect(r.topLeft, const Radius.circular(28));
      expect(r.topRight, const Radius.circular(28));
      expect(r.bottomLeft, Radius.zero);
      expect(r.bottomRight, Radius.zero);
    });

    test('inner = outer - padding, 0 altına inmez', () {
      expect(AppRadius.inner(28, 8), 20);
      expect(AppRadius.inner(6, 16), 0);
    });

    test('decoration: elevation gölge ve hairline taşır, side ezer', () {
      final dark = AppRadius.decoration(
        radius: 20,
        elevation: AppElevation.dark.e1,
      );
      expect((dark.shape as RoundedSuperellipseBorder).side.width, 1);
      expect(dark.shadows, isEmpty);

      final light = AppRadius.decoration(
        radius: 20,
        elevation: AppElevation.light.e1,
      );
      expect(light.shadows!.length, 2);

      const brandSide = BorderSide(width: 2);
      final selected = AppRadius.decoration(
        radius: 20,
        side: brandSide,
        elevation: AppElevation.dark.e1,
      );
      expect((selected.shape as RoundedSuperellipseBorder).side.width, 2);
    });

    test('pill 100x52 alanda düzgün kapsül verir', () {
      final path = AppRadius.border(AppRadius.pill)
          .getOuterPath(const Rect.fromLTWH(0, 0, 100, 52));
      expect(path.getBounds(), const Rect.fromLTWH(0, 0, 100, 52));
      expect(path.contains(const Offset(50, 26)), isTrue);
      expect(path.contains(const Offset(1, 26)), isTrue);
      expect(path.contains(const Offset(26, 0.5)), isTrue);
      expect(path.contains(const Offset(2, 2)), isFalse);
      expect(path.contains(const Offset(98, 50)), isFalse);
    });
  });
}
