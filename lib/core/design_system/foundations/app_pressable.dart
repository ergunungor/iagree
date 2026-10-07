import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart';

import '../tokens/app_motion.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'context_extensions.dart';

/// Dokunulabilir her bileşenin ortak davranışı (DESIGN_SYSTEM.md §9):
/// basınca 0.97 scale + `springSnappy` dönüşü, Reduce Motion, odak halkası, klavye
/// etkinleştirme, `Semantics` ve en az 44×44 dokunma alanı.
///
/// Görseli [builder] çizer; basılı durumu da oradan öğrenir.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    required this.builder,
    this.semanticValue,
    this.isBusy = false,
    this.scaleOnPress = true,
    this.focusShape,
    this.minWidth = AppSpacing.touchTarget,
  });

  /// Null ise bileşen disabled.
  final VoidCallback? onPressed;
  final String semanticLabel;
  final String? semanticValue;

  /// Meşgulken (loading) basış yok sayılır ama VoiceOver'a enabled görünür.
  final bool isBusy;

  /// Dolgulu bileşenlerde true; dolgusuz olanlar yalnızca opaklıkla tepki verir.
  final bool scaleOnPress;

  /// Odak halkasının şekli; boşsa pill.
  final OutlinedBorder? focusShape;

  /// Tam genişlik için `double.infinity`.
  final double minWidth;

  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable>
    with SingleTickerProviderStateMixin {
  static const double _pressedScale = 0.97;
  static const double _ringWidth = AppSpacing.xxs / 2;

  // 0 = bırakılmış, 1 = basılı. Sınırsız: spring dönüşünde taşabilir.
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;
  bool get _interactive => _enabled && !widget.isBusy;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down(AppMotion motion) {
    setState(() => _pressed = true);
    if (motion.reduceMotion || !widget.scaleOnPress) return;
    _press.animateTo(1, duration: motion.fast, curve: AppMotion.enter);
  }

  void _up(AppMotion motion) {
    if (!_pressed) return;
    setState(() => _pressed = false);
    if (motion.reduceMotion || !widget.scaleOnPress) return;
    _press.animateWith(
      SpringSimulation(motion.springSnappy, _press.value, 0, _press.velocity),
    );
  }

  Widget _ring(BuildContext context, double inset, Color color) {
    final shape = widget.focusShape ?? AppRadius.border(AppRadius.pill);
    return Positioned.fill(
      left: -inset,
      right: -inset,
      top: -inset,
      bottom: -inset,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            shape: shape.copyWith(
              side: BorderSide(color: color, width: _ringWidth),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;

    Widget visual = widget.builder(context, _pressed);
    if (widget.scaleOnPress) {
      visual = AnimatedBuilder(
        animation: _press,
        builder: (context, child) => Transform.scale(
          scale: 1 + (_pressedScale - 1) * _press.value,
          child: child,
        ),
        child: visual,
      );
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      value: widget.semanticValue,
      onTap: _interactive ? widget.onPressed : null,
      excludeSemantics: true,
      child: FocusableActionDetector(
        enabled: _interactive,
        onShowFocusHighlight: (v) => setState(() => _focused = v),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _interactive ? (_) => _down(motion) : null,
          onTapUp: _interactive ? (_) => _up(motion) : null,
          onTapCancel: _interactive ? () => _up(motion) : null,
          onTap: _interactive ? widget.onPressed : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: widget.minWidth,
              minHeight: AppSpacing.touchTarget,
            ),
            child: Align(
              widthFactor: widget.minWidth == double.infinity ? null : 1,
              heightFactor: 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Odak halkası: 2px canvas boşluk + 2px focusRing.
                  if (_focused) ...[
                    _ring(context, 2 * _ringWidth, c.focusRing),
                    _ring(context, _ringWidth, c.canvas),
                  ],
                  visual,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
