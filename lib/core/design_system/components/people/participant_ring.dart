import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import 'app_avatar.dart';

/// Katılımcının odadaki durumu.
enum ParticipantStatus {
  /// Davet edildi, henüz katılmadı: kesik çizgili boş daire.
  invited,

  /// Katıldı: halka yok.
  joined,

  /// Seçim yapıyor: `brand` yay, [ParticipantRing.progress] kadar dolar.
  choosing,

  /// Seçimi bitirdi: tam `brand` halka ve sağ altta ✓ rozeti.
  ready,
}

/// Avatarın etrafında tek halka (DESIGN_SYSTEM.md §10 "ParticipantRing"): 2pt kalınlık,
/// avatardan 2pt boşluk. Durumlar arası yerleşim kaymasın diye halkanın yeri her durumda
/// ayrılıdır: kutu [AppAvatarSize] + 8.
class ParticipantRing extends StatefulWidget {
  const ParticipantRing({
    super.key,
    required this.userId,
    required this.name,
    required this.status,
    this.progress = 0,
    this.image,
    this.size = AppAvatarSize.md,
  }) : assert(progress >= 0 && progress <= 1);

  final String userId;
  final String name;
  final ParticipantStatus status;

  /// 0–1; yalnızca [ParticipantStatus.choosing]'de kullanılır.
  final double progress;
  final ImageProvider? image;
  final AppAvatarSize size;

  static const double strokeWidth = 2;
  static const double gap = 2;
  static const double badgeSize = 18;
  static const double badgeRing = 2;

  /// Halka dahil dış kutu.
  static double outerSize(AppAvatarSize size) =>
      size.dimension + 2 * (gap + strokeWidth);

  @override
  State<ParticipantRing> createState() => _ParticipantRingState();
}

class _ParticipantRingState extends State<ParticipantRing>
    with SingleTickerProviderStateMixin {
  // Rozet ölçeği: 0 = yok, 1 = tam; springBouncy ile taşabilir.
  late final AnimationController _badge = AnimationController.unbounded(
    vsync: this,
    value: widget.status == ParticipantStatus.ready ? 1 : 0,
  );

  @override
  void didUpdateWidget(ParticipantRing old) {
    super.didUpdateWidget(old);
    if (old.status == widget.status) return;
    if (widget.status == ParticipantStatus.ready) {
      final motion = AppMotion.of(context);
      if (motion.reduceMotion) {
        _badge.value = 1;
      } else {
        _badge.value = 0;
        _badge.animateWith(SpringSimulation(motion.springBouncy, 0, 1, 0));
      }
    } else {
      _badge.value = 0;
    }
  }

  @override
  void dispose() {
    _badge.dispose();
    super.dispose();
  }

  String _semantics(AppLocalizations l10n) => switch (widget.status) {
    ParticipantStatus.invited => l10n.participantInvited(widget.name),
    ParticipantStatus.joined => l10n.participantJoined(widget.name),
    ParticipantStatus.choosing => l10n.participantChoosing(
      widget.name,
      (widget.progress * 100).round(),
    ),
    ParticipantStatus.ready => l10n.participantReady(widget.name),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final avatarSize = widget.size.dimension;
    final outer = ParticipantRing.outerSize(widget.size);
    final ringValue = switch (widget.status) {
      ParticipantStatus.ready => 1.0,
      ParticipantStatus.choosing => widget.progress,
      _ => 0.0,
    };
    final isInvited = widget.status == ParticipantStatus.invited;

    return Semantics(
      label: _semantics(AppLocalizations.of(context)),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: outer,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (isInvited)
              CustomPaint(
                size: Size.square(outer),
                painter: DashedCirclePainter(
                  color: c.borderControl,
                  diameter: avatarSize,
                  strokeWidth: ParticipantRing.strokeWidth,
                ),
              )
            else ...[
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: ringValue, end: ringValue),
                duration: motion.emphasis,
                curve: AppMotion.move,
                builder: (context, value, _) => CustomPaint(
                  size: Size.square(outer),
                  painter: ParticipantArcPainter(
                    sweep: value,
                    color: c.brand,
                    strokeWidth: ParticipantRing.strokeWidth,
                  ),
                ),
              ),
              AppAvatar(
                userId: widget.userId,
                name: widget.name,
                image: widget.image,
                size: widget.size,
              ),
            ],
            if (widget.status == ParticipantStatus.ready)
              _badgeWidget(c, avatarSize, outer),
          ],
        ),
      ),
    );
  }

  Widget _badgeWidget(AppColors c, double avatarSize, double outer) {
    // Rozetin merkezi avatar dairesinin sağ alt (45°) noktasında.
    final offset = avatarSize / 2 * math.sqrt1_2;
    final diameter = ParticipantRing.badgeSize + 2 * ParticipantRing.badgeRing;
    final center = outer / 2 + offset;
    return Positioned(
      left: center - diameter / 2,
      top: center - diameter / 2,
      child: AnimatedBuilder(
        animation: _badge,
        builder: (context, child) =>
            Transform.scale(scale: _badge.value.clamp(0.0, 2.0), child: child),
        child: DecoratedBox(
          decoration: AppRadius.circle(color: c.canvas),
          child: Padding(
            padding: const EdgeInsets.all(ParticipantRing.badgeRing),
            child: DecoratedBox(
              decoration: AppRadius.circle(color: c.brand),
              child: SizedBox.square(
                dimension: ParticipantRing.badgeSize,
                child: Center(
                  child: Icon(
                    AppIcons.check,
                    size: AppIconSize.s14,
                    color: c.onBrand,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// `choosing`/`ready` halkası: 12 yönünden saat yönünde [sweep] (0–1) kadar yay.
class ParticipantArcPainter extends CustomPainter {
  const ParticipantArcPainter({
    required this.sweep,
    required this.color,
    required this.strokeWidth,
  });

  final double sweep;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (sweep <= 0) return;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = sweep >= 1 ? StrokeCap.butt : StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * sweep, false, paint);
  }

  @override
  bool shouldRepaint(ParticipantArcPainter old) =>
      old.sweep != sweep ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}

/// `invited` halkası: avatar yerine kesik çizgili boş daire ([diameter] çapında).
class DashedCirclePainter extends CustomPainter {
  const DashedCirclePainter({
    required this.color,
    required this.diameter,
    required this.strokeWidth,
    this.dashLength = 4,
    this.gapLength = 4,
  });

  final Color color;
  final double diameter;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  /// Çemberdeki çizgi sayısı (eşit aralıkla).
  int get dashCount {
    final circumference = math.pi * (diameter - strokeWidth);
    return math.max(1, (circumference / (dashLength + gapLength)).round());
  }

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (diameter - strokeWidth) / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final step = 2 * math.pi / dashCount;
    final dashSweep = step * dashLength / (dashLength + gapLength);
    for (var i = 0; i < dashCount; i++) {
      canvas.drawArc(rect, -math.pi / 2 + i * step, dashSweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(DashedCirclePainter old) =>
      old.color != color ||
      old.diameter != diameter ||
      old.strokeWidth != strokeWidth;
}
