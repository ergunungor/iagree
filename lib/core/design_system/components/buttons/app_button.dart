import 'package:flutter/cupertino.dart';
import 'package:flutter/physics.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_fixed_colors.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

enum AppButtonVariant {
  primary,
  secondary,
  tertiary,
  destructive,
  destructiveStrong,
  moment,
  momentGhost,
  momentText,
}

enum AppButtonSize { large, medium, small }

/// Tek buton sınıfı (DESIGN_SYSTEM.md §9, §10). Ekran başına tek Primary.
///
/// Titreşim vermez; çağıran `onPressed` içinde `AppHaptics` kullanır.
class AppButton extends StatefulWidget {
  const AppButton._({
    super.key,
    required this.variant,
    required this.label,
    required this.onPressed,
    this.icon,
    this.size = AppButtonSize.large,
    this.fullWidth,
    this.isLoading = false,
  });

  const AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.large,
    bool? fullWidth,
    bool isLoading = false,
  }) : this._(
         key: key,
         variant: AppButtonVariant.primary,
         label: label,
         onPressed: onPressed,
         icon: icon,
         size: size,
         fullWidth: fullWidth,
         isLoading: isLoading,
       );

  const AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.large,
    bool? fullWidth,
    bool isLoading = false,
  }) : this._(
         key: key,
         variant: AppButtonVariant.secondary,
         label: label,
         onPressed: onPressed,
         icon: icon,
         size: size,
         fullWidth: fullWidth,
         isLoading: isLoading,
       );

  const AppButton.tertiary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.large,
    bool? fullWidth,
    bool isLoading = false,
  }) : this._(
         key: key,
         variant: AppButtonVariant.tertiary,
         label: label,
         onPressed: onPressed,
         icon: icon,
         size: size,
         fullWidth: fullWidth,
         isLoading: isLoading,
       );

  const AppButton.destructive({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.large,
    bool? fullWidth,
    bool isLoading = false,
  }) : this._(
         key: key,
         variant: AppButtonVariant.destructive,
         label: label,
         onPressed: onPressed,
         icon: icon,
         size: size,
         fullWidth: fullWidth,
         isLoading: isLoading,
       );

  /// Yalnızca alert modal'ın destructive aksiyonu.
  const AppButton.destructiveStrong({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.large,
    bool? fullWidth,
    bool isLoading = false,
  }) : this._(
         key: key,
         variant: AppButtonVariant.destructiveStrong,
         label: label,
         onPressed: onPressed,
         icon: icon,
         size: size,
         fullWidth: fullWidth,
         isLoading: isLoading,
       );

  /// Karar anı (momentBg zemini) için. Disabled ve loading desteklenmez.
  const AppButton.moment({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.large,
    bool? fullWidth,
  }) : this._(
         key: key,
         variant: AppButtonVariant.moment,
         label: label,
         onPressed: onPressed,
         icon: icon,
         size: size,
         fullWidth: fullWidth,
       );

  const AppButton.momentGhost({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.large,
    bool? fullWidth,
  }) : this._(
         key: key,
         variant: AppButtonVariant.momentGhost,
         label: label,
         onPressed: onPressed,
         icon: icon,
         size: size,
         fullWidth: fullWidth,
       );

  const AppButton.momentText({
    Key? key,
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    AppButtonSize size = AppButtonSize.large,
    bool? fullWidth,
  }) : this._(
         key: key,
         variant: AppButtonVariant.momentText,
         label: label,
         onPressed: onPressed,
         icon: icon,
         size: size,
         fullWidth: fullWidth,
       );

  final AppButtonVariant variant;
  final String label;

  /// Null ise buton disabled.
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonSize size;

  /// Boşsa: Large tam genişlik, diğerleri içeriğe sığar.
  final bool? fullWidth;
  final bool isLoading;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _Palette {
  const _Palette({
    required this.content,
    this.fill,
    this.pressedFill,
    this.disabledFill,
    this.disabledContent,
  });

  final Color content;

  /// Null: dolgusuz (tertiary, momentText).
  final Color? fill;
  final Color? pressedFill;
  final Color? disabledFill;
  final Color? disabledContent;
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  static const double _pressedScale = 0.97;
  static const double _pressedOpacity = 0.5;
  static const double _ringWidth = AppSpacing.xxs / 2;

  // 0 = bırakılmış, 1 = basılı. Sınırsız: spring dönüşünde taşabilir.
  late final AnimationController _press = AnimationController.unbounded(
    vsync: this,
  );
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null;
  bool get _interactive => _enabled && !widget.isLoading;

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down(AppMotion motion) {
    setState(() => _pressed = true);
    if (motion.reduceMotion) return;
    _press.animateTo(1, duration: motion.fast, curve: AppMotion.enter);
  }

  void _up(AppMotion motion) {
    if (!_pressed) return;
    setState(() => _pressed = false);
    if (motion.reduceMotion) return;
    _press.animateWith(
      SpringSimulation(motion.springSnappy, _press.value, 0, _press.velocity),
    );
  }

  /// Basılı dolgu: token varsa o, yoksa "bir ton koyu" (HSL parlaklığı −%6).
  static Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.06).clamp(0.0, 1.0)).toColor();
  }

  _Palette _palette(AppColors c) {
    switch (widget.variant) {
      case AppButtonVariant.primary:
        return _Palette(
          fill: c.brand,
          pressedFill: c.brandPressed,
          content: c.onBrand,
          disabledFill: c.surfaceMuted,
          disabledContent: c.textDisabled,
        );
      case AppButtonVariant.secondary:
        return _Palette(
          fill: c.surfaceMuted,
          pressedFill: c.surfacePressed,
          content: c.textPrimary,
          disabledFill: c.surfaceMuted,
          disabledContent: c.textDisabled,
        );
      case AppButtonVariant.tertiary:
        return _Palette(content: c.brand, disabledContent: c.textDisabled);
      case AppButtonVariant.destructive:
        return _Palette(
          fill: c.errorSoft,
          pressedFill: _darken(c.errorSoft),
          content: c.error,
          disabledFill: c.surfaceMuted,
          disabledContent: c.textDisabled,
        );
      case AppButtonVariant.destructiveStrong:
        return _Palette(
          fill: c.error,
          pressedFill: _darken(c.error),
          content: c.onError,
          disabledFill: c.surfaceMuted,
          disabledContent: c.textDisabled,
        );
      case AppButtonVariant.moment:
        return _Palette(
          fill: AppFixedColors.momentInk,
          pressedFill: _darken(AppFixedColors.momentInk),
          content: AppFixedColors.momentBg,
        );
      case AppButtonVariant.momentGhost:
        return _Palette(
          fill: AppFixedColors.momentGhost,
          pressedFill: _darken(AppFixedColors.momentGhost),
          content: AppFixedColors.momentInk,
        );
      case AppButtonVariant.momentText:
        return const _Palette(content: AppFixedColors.momentInk);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final palette = _palette(c);

    final (minHeight, horizontal, iconSize) = switch (widget.size) {
      AppButtonSize.large => (52.0, AppSpacing.xl, AppIconSize.s20),
      AppButtonSize.medium => (
        AppSpacing.touchTarget,
        AppSpacing.lg,
        AppIconSize.s20,
      ),
      AppButtonSize.small => (32.0, AppSpacing.sm, AppIconSize.s16),
    };
    final fullWidth = widget.fullWidth ?? widget.size == AppButtonSize.large;

    final contentColor = _enabled
        ? palette.content
        : (palette.disabledContent ?? palette.content);
    final Color? fill = !_enabled
        ? palette.disabledFill
        : (_pressed ? palette.pressedFill : palette.fill);
    final dimOnPress = palette.fill == null && _enabled && _pressed;

    final textStyle =
        (widget.size == AppButtonSize.small
                ? context.text.buttonSmall
                : context.text.button)
            .copyWith(color: contentColor);

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: iconSize, color: contentColor),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(
          child: Text(
            widget.label,
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );

    final body = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontal,
        // Small'da 20 satır + 2×xxs = 28 < 32; diğerlerinde xs.
        vertical: widget.size == AppButtonSize.small
            ? AppSpacing.xxs
            : AppSpacing.xs,
      ),
      child: widget.isLoading
          ? Stack(
              alignment: Alignment.center,
              children: [
                // Genişlik sabit kalsın diye etiket görünmez ama yerinde.
                Opacity(opacity: 0, child: content),
                CupertinoActivityIndicator(
                  color: contentColor,
                  radius: iconSize / 2,
                ),
              ],
            )
          : content,
    );

    final visual = AnimatedBuilder(
      animation: _press,
      builder: (context, child) => Transform.scale(
        scale: 1 + (_pressedScale - 1) * _press.value,
        child: child,
      ),
      child: ConstrainedBox(
        // Sabit tutulur: animasyonlu AnimatedContainer constraint'leri enterpole edemez.
        constraints: BoxConstraints(
          minWidth: fullWidth ? double.infinity : 0,
          minHeight: minHeight,
        ),
        child: AnimatedContainer(
          duration: motion.fast,
          curve: AppMotion.move,
          decoration: AppRadius.decoration(radius: AppRadius.pill, color: fill),
          child: AnimatedOpacity(
            duration: motion.fast,
            opacity: dimOnPress ? _pressedOpacity : 1,
            child: Center(widthFactor: 1, heightFactor: 1, child: body),
          ),
        ),
      ),
    );

    final ring = _focused
        ? [
            Positioned.fill(
              left: -2 * _ringWidth,
              right: -2 * _ringWidth,
              top: -2 * _ringWidth,
              bottom: -2 * _ringWidth,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: AppRadius.border(
                      AppRadius.pill,
                      side: BorderSide(color: c.focusRing, width: _ringWidth),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              left: -_ringWidth,
              right: -_ringWidth,
              top: -_ringWidth,
              bottom: -_ringWidth,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: AppRadius.border(
                      AppRadius.pill,
                      side: BorderSide(color: c.canvas, width: _ringWidth),
                    ),
                  ),
                ),
              ),
            ),
          ]
        : const <Widget>[];

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
      value: widget.isLoading
          ? AppLocalizations.of(context).commonLoading
          : null,
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
              minWidth: fullWidth ? double.infinity : AppSpacing.touchTarget,
              minHeight: AppSpacing.touchTarget,
            ),
            child: Align(
              widthFactor: fullWidth ? null : 1,
              heightFactor: 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: [...ring, visual],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
