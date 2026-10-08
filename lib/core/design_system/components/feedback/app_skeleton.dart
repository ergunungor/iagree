import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Skeleton (DESIGN_SYSTEM.md §10 "States / Loading").
///
/// `surfaceMuted`, opaklık 1 → 0,6 nabzı; **shimmer yok**, en fazla 3 satır. Reduce Motion'da
/// nabız yok. İçerik yüklenirken kullanılır; 300 ms'den kısa bekleyişlerde hiçbir şey
/// gösterilmez (bu karar çağıranın).
class AppSkeleton extends StatefulWidget {
  /// Tek blok.
  const AppSkeleton({
    super.key,
    this.width,
    this.height = _defaultHeight,
    this.radius = AppRadius.xs,
  }) : lines = 1,
       _isGroup = false;

  /// 1–3 satırlık metin iskeleti; son satır daha kısadır.
  const AppSkeleton.lines({
    super.key,
    this.lines = 3,
    this.height = _defaultHeight,
    this.radius = AppRadius.xs,
  }) : assert(lines >= 1 && lines <= _maxLines, 'En fazla 3 satır'),
       width = null,
       _isGroup = true;

  final double? width;
  final double height;
  final double radius;
  final int lines;
  final bool _isGroup;

  static const double _defaultHeight = 16;
  static const int _maxLines = 3;
  static const double _lowestOpacity = 0.6;
  static const double _lastLineWidthFactor = 0.6;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = context.motion;
    if (motion.reduceMotion) {
      _pulse.stop();
      _pulse.value = 0;
      _started = false;
    } else if (!_started) {
      _started = true;
      // Her yön emphasis süre (expressive yalnızca Arc ve karar anı); 1 → 0,6 → 1.
      _pulse.duration = motion.emphasis;
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _block(BuildContext context, {double? width, double? widthFactor}) {
    final box = DecoratedBox(
      decoration: AppRadius.decoration(
        radius: widget.radius,
        color: context.colors.surfaceMuted,
      ),
      child: SizedBox(width: width, height: widget.height),
    );
    if (widthFactor == null) return box;
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: box,
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = widget._isGroup
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < widget.lines; i++) ...[
                if (i > 0) const SizedBox(height: AppSpacing.xs),
                _block(
                  context,
                  widthFactor: i == widget.lines - 1 && widget.lines > 1
                      ? AppSkeleton._lastLineWidthFactor
                      : null,
                ),
              ],
            ],
          )
        : _block(context, width: widget.width);

    final pulsing = FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: AppSkeleton._lowestOpacity,
      ).animate(_pulse),
      child: content,
    );

    // Grup bir kez "Yükleniyor" olarak okunur; tek bloklar süstür.
    if (widget._isGroup) {
      return Semantics(
        label: AppLocalizations.of(context).commonLoading,
        excludeSemantics: true,
        child: pulsing,
      );
    }
    return ExcludeSemantics(child: pulsing);
  }
}
