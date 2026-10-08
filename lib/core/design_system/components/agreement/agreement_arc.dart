import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/clamped_text_scale.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_typography.dart';
import '../../tokens/app_fixed_colors.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_spacing.dart';
import 'agreement_math.dart';

/// AgreementArc boyutu (DESIGN_SYSTEM.md §10 tablosu).
enum AgreementArcSize {
  /// 32 / çizgi 4. Yüzde yayın sağında. Kişi sayısını üst bileşen gösterir.
  small(width: 32, stroke: 4),

  /// 64 / çizgi 6. Yüzde yay içinde (`title`).
  medium(width: 64, stroke: 6),

  /// 160 / çizgi 14. Yüzde yay içinde (34 bold). Karar anı.
  large(width: 160, stroke: 14);

  const AgreementArcSize({required this.width, required this.stroke});

  final double width;
  final double stroke;

  /// Yayın merkez çizgisinin yarıçapı.
  double get radius => (width - stroke) / 2;

  /// Kutu yüksekliği: yarım daire + taban çizgisinin altına taşan yuvarlak uç.
  double get arcHeight => width / 2 + stroke / 2;
}

/// Uyum yayı (DESIGN_SYSTEM.md §10 "AgreementArc").
///
/// Sayıları alır, yüzdeyi kendisi hesaplar ([AgreementMath.percent]: aşağı yuvarlanır, `%100`
/// yalnızca herkes olumluysa). Soldan sağa `brand` (Çok isterim), 2pt boşluk, `brandMuted`
/// (Olur); kalan iz `surfacePressed`. [onMoment] karar anı içindir: `momentInk` dolgu,
/// `momentTrack` iz, tek ton. Veto edilen seçenek sonuçlarda yer almadığından Arc'a hiç gelmez.
///
/// İlk görünüşte 100 ms gecikmeyle `expressive` + `enter` ile dolar, yüzde eşzamanlı sayar.
/// Reduce Motion'da ve [animate] false iken doğrudan son değer. Sayılar sonradan değişirse
/// yay anında yeni değere geçer; dolma yalnızca ilk görünüşe aittir.
class AgreementArc extends StatefulWidget {
  const AgreementArc({
    super.key,
    required this.loveCount,
    required this.okCount,
    required this.total,
    this.size = AgreementArcSize.medium,
    this.onMoment = false,
    this.animate = true,
    this.reveal,
  }) : assert(loveCount >= 0 && okCount >= 0 && total >= 0),
       assert(loveCount + okCount <= total);

  /// "Çok isterim" diyenler.
  final int loveCount;

  /// "Olur" diyenler.
  final int okCount;

  /// Toplam kişi.
  final int total;

  final AgreementArcSize size;
  final bool onMoment;

  /// Arc'ın VoiceOver cümlesi; üst bileşenler (sonuç kartları) kendi tek cümlelerine katar.
  static String semanticsOf(
    AppLocalizations l10n, {
    required int loveCount,
    required int okCount,
    required int total,
  }) {
    final percent = AgreementMath.percent(
      loveCount: loveCount,
      okCount: okCount,
      total: total,
    );
    final positive = loveCount + okCount;
    return loveCount > 0
        ? l10n.agreementArcSemanticsLove(percent, total, positive, loveCount)
        : l10n.agreementArcSemantics(percent, total, positive);
  }

  /// İlk görünüşte dolma animasyonu.
  final bool animate;

  /// Verilirse dolma süresini ve eğrisini kendi içindeki animasyon yerine bu belirler (0→1);
  /// karar anı gibi koreografinin parçası olan kullanımlar içindir. [animate] yok sayılır.
  final Animation<double>? reveal;

  @override
  State<AgreementArc> createState() => _AgreementArcState();
}

class _AgreementArcState extends State<AgreementArc>
    with SingleTickerProviderStateMixin {
  static const Duration _delay = Duration(milliseconds: 100);

  late final AnimationController _controller = AnimationController(vsync: this);
  CurvedAnimation? _curved;
  late Animation<double> _reveal;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    if (widget.reveal != null) {
      _reveal = widget.reveal!;
      return;
    }
    final motion = context.motion;
    if (!widget.animate || motion.reduceMotion) {
      _controller.value = 1;
      _reveal = _controller;
      return;
    }
    // Gecikme controller süresinin başındaki boş dilimdir: Future.delayed gerekmez,
    // dispose sonrası geri çağrı riski olmaz.
    final total = _delay + motion.expressive;
    _controller.duration = total;
    _curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        _delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: AppMotion.enter,
      ),
    );
    _reveal = _curved!;
    _controller.forward();
  }

  @override
  void dispose() {
    _curved?.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _percentText(BuildContext context, int percent) =>
      NumberFormat.percentPattern(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(percent / 100);

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final percent = AgreementMath.percent(
      loveCount: w.loveCount,
      okCount: w.okCount,
      total: w.total,
    );
    final positive = w.loveCount + w.okCount;
    final label = AgreementArc.semanticsOf(
      l10n,
      loveCount: w.loveCount,
      okCount: w.okCount,
      total: w.total,
    );

    final numberStyle =
        switch (w.size) {
          AgreementArcSize.small => context.text.arcNumberSmall,
          AgreementArcSize.medium => context.text.title,
          AgreementArcSize.large => context.text.arcNumberLarge,
        }.tabular.copyWith(
          color: w.onMoment ? AppFixedColors.momentInk : c.textPrimary,
        );

    final spec = w.size;
    final segments = arcSegments(
      loveCount: w.loveCount,
      okCount: w.okCount,
      total: w.total,
      radius: spec.radius,
      strokeWidth: spec.stroke,
      singleTone: w.onMoment,
    );

    return Semantics(
      label: label,
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _reveal,
          builder: (context, _) {
            final t = _reveal.value;
            final shown = (percent * t).floor();
            final number = ClampedTextScale.arcNumber(
              child: Text(
                _percentText(context, shown),
                maxLines: 1,
                style: numberStyle,
              ),
            );

            final arc = SizedBox(
              width: spec.width,
              height: spec.arcHeight,
              child: Stack(
                children: [
                  CustomPaint(
                    size: Size(spec.width, spec.arcHeight),
                    painter: _ArcPainter(
                      segments: segments,
                      reveal: t,
                      radius: spec.radius,
                      strokeWidth: spec.stroke,
                      center: Offset(spec.width / 2, spec.width / 2),
                      trackColor: w.onMoment
                          ? AppFixedColors.momentTrack
                          : c.surfacePressed,
                      loveColor: w.onMoment
                          ? AppFixedColors.momentInk
                          : c.brand,
                      okColor: c.brandMuted,
                    ),
                  ),
                  if (spec != AgreementArcSize.small)
                    Positioned(
                      left: spec.stroke + AppSpacing.xs,
                      right: spec.stroke + AppSpacing.xs,
                      // Sayının tabanı yayın taban çizgisinde.
                      bottom: spec.stroke / 2,
                      child: Center(
                        child: FittedBox(fit: BoxFit.scaleDown, child: number),
                      ),
                    ),
                ],
              ),
            );

            if (spec == AgreementArcSize.small) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  arc,
                  const SizedBox(width: AppSpacing.xs),
                  number,
                ],
              );
            }
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                arc,
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  l10n.agreementArcPeople(positive, w.total),
                  style: context.text.caption.tabular.copyWith(
                    color: w.onMoment
                        ? AppFixedColors.momentInk
                        : c.textSecondary,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({
    required this.segments,
    required this.reveal,
    required this.radius,
    required this.strokeWidth,
    required this.center,
    required this.trackColor,
    required this.loveColor,
    required this.okColor,
  });

  final List<ArcSegment> segments;

  /// 0–1: dolgunun soldan ne kadarının çizildiği.
  final double reveal;
  final double radius;
  final double strokeWidth;
  final Offset center;
  final Color trackColor;
  final Color loveColor;
  final Color okColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    Paint stroke(Color color) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..color = color
      ..isAntiAlias = true;

    canvas.drawArc(rect, math.pi, math.pi, false, stroke(trackColor));

    if (segments.isEmpty || reveal <= 0) return;
    final revealEnd = reveal * segments.last.end;
    for (final s in segments) {
      final end = math.min(s.end, revealEnd);
      if (end < s.start) continue;
      canvas.drawArc(
        rect,
        math.pi + s.start * math.pi,
        (end - s.start) * math.pi,
        false,
        stroke(s.tone == ArcTone.love ? loveColor : okColor),
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.reveal != reveal ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.loveColor != loveColor ||
      old.okColor != okColor ||
      old.segments.length != segments.length ||
      !_sameSegments(old.segments);

  bool _sameSegments(List<ArcSegment> other) {
    for (var i = 0; i < segments.length; i++) {
      if (other[i] != segments[i]) return false;
    }
    return true;
  }
}
