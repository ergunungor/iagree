import 'package:flutter/material.dart';

import '../../foundations/app_animated_size.dart';
import '../../foundations/app_haptics.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Seçilebilir chip (DESIGN_SYSTEM.md §10 "Selection").
///
/// 36 min yükseklik, pill, yatay 16, `label` stili. Seçilince `brandSoft` + `onBrandSoft`
/// + 1,5px `brand` kenar ve solda 16'lık ✓; genişlik değişimi `springSnappy` ile. Chip'ler
/// arası 8 boşlukla `Wrap` içinde dizilir. Her değişimde selection haptic.
class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;

  /// Yeni seçili durumu verir; null ise chip pasif.
  final ValueChanged<bool>? onChanged;

  static const double _minHeight = 36;
  static const double _borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final enabled = onChanged != null;

    return AppPressable(
      onPressed: enabled
          ? () {
              AppHaptics.selection();
              onChanged!(!selected);
            }
          : null,
      semanticLabel: label,
      semanticSelected: selected,
      builder: (context, pressed) {
        final fill = !enabled
            ? c.surfaceMuted
            : selected
            ? c.brandSoft
            : (pressed ? c.surfacePressed : c.surfaceMuted);
        final contentColor = !enabled
            ? c.textDisabled
            : (selected ? c.onBrandSoft : c.textPrimary);
        // Kenarlık her zaman aynı kalınlıkta (seçili değilken saydam): boyut sıçramaz.
        final borderColor = enabled && selected ? c.brand : Colors.transparent;

        return AnimatedContainer(
          duration: motion.fast,
          curve: AppMotion.move,
          constraints: const BoxConstraints(minHeight: _minHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md - _borderWidth,
          ),
          decoration: AppRadius.decoration(
            radius: AppRadius.pill,
            color: fill,
            side: BorderSide(color: borderColor, width: _borderWidth),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppAnimatedSize(
                duration: motion.springSnappyDuration,
                curve: motion.springSnappyCurve,
                alignment: Alignment.centerLeft,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Icon(
                          AppIcons.check,
                          size: AppIconSize.s16,
                          color: contentColor,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Flexible(
                child: Text(
                  label,
                  style: context.text.label.copyWith(color: contentColor),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
