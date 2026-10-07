import 'package:flutter/material.dart';

import '../../foundations/context_extensions.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_fixed_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

enum AppLogoVariant {
  /// Marka kullanımı: i ve ✓ `brand`, kalanı `textPrimary`. Yalnızca canvas/surface üstünde.
  twoTone,

  /// Tek renk, açık zemin.
  ink,

  /// Tek renk, Plum (`momentBg`) zemin.
  cream,

  /// Tek renk, koyu tema.
  plumLight,
}

/// iA monogramı (DESIGN_SYSTEM.md §1, assets/logo/). [size] işaretin yüksekliğidir.
///
/// İşaret döndürülmez, eğilmez, gölge ya da gradient almaz; çevresinde en az işaret
/// yüksekliğinin %25'i boşluk bırakmak çağıran ekranın işidir.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    required AppLogoVariant this.variant,
    this.size = AppSpacing.giant,
    this.wordmark = false,
  });

  /// Temaya göre seçer: light → [AppLogoVariant.twoTone], dark → [AppLogoVariant.plumLight].
  const AppLogo.auto({
    super.key,
    this.size = AppSpacing.giant,
    this.wordmark = false,
  }) : variant = null;

  final AppLogoVariant? variant;
  final double size;

  /// İşaretin yanına Fraunces 500 "iAgree" ekler (işaret ≈ metin boyutunun 1,3 katı).
  final bool wordmark;

  /// İşaret yüksekliğinin metin boyutuna oranı.
  static const double markToTextRatio = 1.3;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v =
        variant ?? (isDark ? AppLogoVariant.plumLight : AppLogoVariant.twoTone);

    final (accent, base) = switch (v) {
      AppLogoVariant.twoTone => (c.brand, c.textPrimary),
      AppLogoVariant.ink => (c.textPrimary, c.textPrimary),
      AppLogoVariant.cream => (
        AppFixedColors.momentInk,
        AppFixedColors.momentInk,
      ),
      AppLogoVariant.plumLight => (AppColors.dark.brand, AppColors.dark.brand),
    };

    final mark = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: AppLogoMarkPainter(accent: accent, base: base),
      ),
    );

    final Widget child;
    if (!wordmark) {
      child = mark;
    } else {
      // Marka adı her zaman Fraunces 500: Bold Text'ten etkilenmesin diye `regular`.
      final h1 = AppTypography.regular.h1;
      final fontSize = size / markToTextRatio;
      // Dar alanda taşmak yerine küçülür: logo ne kırpılır ne de taşar.
      child = FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            mark,
            const SizedBox(width: AppSpacing.xxs),
            Text(
              'iAgree',
              softWrap: false,
              textScaler: TextScaler.noScaling,
              style: h1.copyWith(
                color: base,
                fontSize: fontSize,
                height: 1,
                letterSpacing: h1.letterSpacing! * fontSize / h1.fontSize!,
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      label: 'iAgree',
      image: true,
      excludeSemantics: true,
      child: child,
    );
  }
}

/// İşareti 120×120'lik tasarım alanında çizer (assets/logo/*.svg ile aynı geometri).
class AppLogoMarkPainter extends CustomPainter {
  const AppLogoMarkPainter({required this.accent, required this.base});

  /// i'nin noktası ve ✓.
  final Color accent;

  /// A'nın sağ bacağı ve yatay çizgisi.
  final Color base;

  static const double viewBox = 120;
  static const Offset dotCenter = Offset(21, 50);
  static const double dotRadius = 7.5;
  static const double strokeWidth = 12;
  static const List<Offset> check = [
    Offset(34, 70),
    Offset(50, 94),
    Offset(76, 22),
  ];
  static const List<Offset> leg = [Offset(76, 22), Offset(102, 94)];
  static const List<Offset> bar = [Offset(75, 70), Offset(92, 70)];

  Paint _stroke(Color color) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  Path _polyline(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / viewBox, size.height / viewBox);
    canvas.drawCircle(dotCenter, dotRadius, Paint()..color = accent);
    canvas.drawPath(_polyline(check), _stroke(accent));
    canvas.drawPath(_polyline(leg), _stroke(base));
    canvas.drawPath(_polyline(bar), _stroke(base));
  }

  @override
  bool shouldRepaint(AppLogoMarkPainter old) =>
      old.accent != accent || old.base != base;
}
