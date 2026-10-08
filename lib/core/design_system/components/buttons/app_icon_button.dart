import 'package:flutter/widgets.dart';

import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_fixed_colors.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

enum AppIconButtonStyle { plain, soft, media }

/// Yalnızca ikonlu buton (DESIGN_SYSTEM.md §10 "IconButton"). Dokunma alanı hep en az 44×44.
///
/// - **plain:** dolgusuz, ikon 24, nav bar için.
/// - **soft:** 36'lık daire, `surfaceMuted` dolgu, ikon 20.
/// - **media:** 36'lık daire, siyah %35 dolgu, beyaz ikon 20; fotoğraf üstü için.
///
/// [semanticLabel] zorunlu ve yerelleştirilmiş olmalı. Titreşim vermez.
class AppIconButton extends StatelessWidget {
  const AppIconButton.plain({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.repeatOnHold = false,
  }) : style = AppIconButtonStyle.plain,
       assert(semanticLabel != '');

  const AppIconButton.soft({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.repeatOnHold = false,
  }) : style = AppIconButtonStyle.soft,
       assert(semanticLabel != '');

  /// Fotoğraf üstü için. Disabled desteklenmez (`onPressed` zorunlu).
  const AppIconButton.media({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required VoidCallback this.onPressed,
  }) : style = AppIconButtonStyle.media,
       repeatOnHold = false,
       assert(semanticLabel != '');

  final AppIconButtonStyle style;
  final IconData icon;
  final String semanticLabel;

  /// Null ise disabled.
  final VoidCallback? onPressed;

  /// Basılı tutulunca [onPressed]'i hızlanarak tekrarlar (stepper).
  final bool repeatOnHold;

  static const double _circle = 36;
  static const double _pressedOpacity = 0.5;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final enabled = onPressed != null;

    final iconSize = style == AppIconButtonStyle.plain
        ? AppIconSize.s24
        : AppIconSize.s20;
    final iconColor = switch (style) {
      AppIconButtonStyle.media => AppFixedColors.onMedia,
      _ => enabled ? c.textPrimary : c.textDisabled,
    };

    return AppPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      repeatOnHold: repeatOnHold,
      // Plain dolgusuz: yalnızca opaklıkla tepki verir.
      scaleOnPress: style != AppIconButtonStyle.plain,
      focusShape: style == AppIconButtonStyle.plain
          ? null
          : const CircleBorder(),
      builder: (context, pressed) {
        final glyph = AnimatedOpacity(
          duration: motion.fast,
          // Plain ve media'da basılı: ikon %50. Soft'ta dolgu koyulaşır.
          opacity: pressed && enabled && style != AppIconButtonStyle.soft
              ? _pressedOpacity
              : 1,
          child: Icon(icon, size: iconSize, color: iconColor),
        );
        if (style == AppIconButtonStyle.plain) {
          return SizedBox.square(
            dimension: AppSpacing.touchTarget,
            child: Center(child: glyph),
          );
        }
        final fill = style == AppIconButtonStyle.media
            ? AppFixedColors.mediaOverlay
            : (pressed && enabled ? c.surfacePressed : c.surfaceMuted);
        return Padding(
          // 36'lık daire 44'lük dokunma alanının ortasında.
          padding: const EdgeInsets.all((AppSpacing.touchTarget - _circle) / 2),
          child: AnimatedContainer(
            duration: motion.fast,
            curve: AppMotion.move,
            width: _circle,
            height: _circle,
            decoration: AppRadius.circle(color: fill),
            child: Center(child: glyph),
          ),
        );
      },
    );
  }
}
