import 'package:flutter/material.dart';

import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Kart (DESIGN_SYSTEM.md §10 "Card").
///
/// `surface`, `radius lg`, padding 16, E1. [onPressed] verilirse **tek başına dokunulabilir
/// nesnedir** (basınca 0.97 + `textPrimary` %4 örtü) ve tek öğe olarak okunur; metin gruplamak
/// için kart kullanılmaz. [media] verilirse üstte 4:3 görsel. [selected] ise 2px `brand`
/// kenar (boyut değişmez). Increase Contrast açıkken `borderControl` kenarı.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.media,
    this.onPressed,
    this.semanticLabel,
    this.selected = false,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
  }) : assert(
         onPressed == null || semanticLabel != null,
         'Dokunulabilir kart tek öğe olarak okunur: semanticLabel gerekli.',
       );

  /// Kartın içeriği (görselin altındaki metin alanı da burası).
  final Widget child;

  /// Üstte 4:3 oranında, kenardan kenara görsel.
  final Widget? media;

  /// Verilirse kart interaktif; null ise sadece bir kap.
  final VoidCallback? onPressed;

  /// Interaktif kartın VoiceOver etiketi (örn. "Trattoria Lume. İtalyan, orta fiyat, 1,2
  /// kilometre."); yerelleştirilmiş olmalı.
  final String? semanticLabel;
  final bool selected;
  final EdgeInsetsGeometry padding;

  static const double _selectedBorder = 2;
  static const double _hairline = 1;
  static const double _mediaAspectRatio = 4 / 3;
  static const double _pressedOverlayAlpha = 0.04;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final e1 = context.elevation.e1;
    final highContrast = MediaQuery.highContrastOf(context);
    final shape = AppRadius.border(AppRadius.lg);

    Widget content({required bool pressed}) {
      return DecoratedBox(
        decoration: AppRadius.decoration(
          radius: AppRadius.lg,
          color: c.surface,
          elevation: e1,
          side: highContrast
              ? BorderSide(color: c.borderControl, width: _hairline)
              : null,
        ),
        child: ClipPath(
          clipper: ShapeBorderClipper(shape: shape),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (media != null)
                    AspectRatio(aspectRatio: _mediaAspectRatio, child: media),
                  Padding(padding: padding, child: child),
                ],
              ),
              if (onPressed != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: motion.fast,
                      opacity: pressed ? 1 : 0,
                      child: ColoredBox(
                        color: c.textPrimary.withValues(
                          alpha: _pressedOverlayAlpha,
                        ),
                      ),
                    ),
                  ),
                ),
              // Seçili kenarlık içeriğin üstünde, yerleşimi etkilemeden çizilir.
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: AppRadius.border(
                          AppRadius.lg,
                          side: BorderSide(
                            color: c.brand,
                            width: _selectedBorder,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    if (onPressed == null) return content(pressed: false);

    return AppPressable(
      onPressed: onPressed,
      semanticLabel: semanticLabel!,
      semanticSelected: selected ? true : null,
      focusShape: shape,
      minWidth: double.infinity,
      builder: (context, pressed) => content(pressed: pressed),
    );
  }
}
