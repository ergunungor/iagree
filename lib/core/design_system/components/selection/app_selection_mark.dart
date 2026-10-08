import 'package:flutter/material.dart';

import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';

/// Checkbox ve Check Circle'ın ortak görseli (etkileşimsiz): boş kutu/daire ya da `brand`
/// dolgu + `onBrand` ✓. Dokunma, semantics ve haptic sarmalayan bileşenlerde.
class AppSelectionMark extends StatelessWidget {
  const AppSelectionMark({
    super.key,
    required this.selected,
    required this.size,
    required this.iconSize,
    this.circle = false,
    this.enabled = true,
  });

  final bool selected;
  final double size;
  final double iconSize;

  /// Daire (Check Circle) ya da `radius xs` kutu (Checkbox).
  final bool circle;
  final bool enabled;

  static const double _borderWidth = 1.5;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;

    final Color fill = !enabled
        ? c.surfaceMuted
        : (selected ? c.brand : Colors.transparent);
    final Color border = !enabled
        ? Colors.transparent
        : (selected ? c.brand : c.borderControl);
    final side = BorderSide(color: border, width: _borderWidth);

    return AnimatedContainer(
      duration: motion.fast,
      curve: AppMotion.move,
      width: size,
      height: size,
      decoration: circle
          ? AppRadius.circle(color: fill, side: side)
          : AppRadius.decoration(radius: AppRadius.xs, color: fill, side: side),
      child: AnimatedOpacity(
        duration: motion.fast,
        opacity: selected ? 1 : 0,
        child: Center(
          child: Icon(
            AppIcons.check,
            size: iconSize,
            color: enabled ? c.onBrand : c.textDisabled,
          ),
        ),
      ),
    );
  }
}
