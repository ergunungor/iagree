import 'package:flutter/material.dart';

import '../../foundations/app_haptics.dart';
import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// [AppSegmentedControl]'ün bir segmenti.
class AppSegment<T> {
  const AppSegment({required this.value, required this.label});

  final T value;

  /// Görünen ve VoiceOver'da okunan metin; yerelleştirilmiş olmalı.
  final String label;
}

/// En fazla 4 segmentli seçici (DESIGN_SYSTEM.md §10 "Segmented").
///
/// Kap `surfaceMuted`, `radius md`, padding 4; seçili segment `surfaceRaised` + E1, `radius sm`,
/// 600 ağırlık. Seçili göstergesi segmentler arasında kayar. Her değişimde selection haptic.
class AppSegmentedControl<T> extends StatelessWidget {
  AppSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
  }) : assert(segments.length >= 2 && segments.length <= 4),
       assert(segments.any((s) => s.value == value));

  final List<AppSegment<T>> segments;
  final T value;

  /// Null ise pasif.
  final ValueChanged<T>? onChanged;

  static const double _inset = AppSpacing.xxs;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final n = segments.length;
    final selectedIndex = segments.indexWhere((s) => s.value == value);
    final enabled = onChanged != null;

    return DecoratedBox(
      decoration: AppRadius.decoration(
        radius: AppRadius.md,
        color: c.surfaceMuted,
      ),
      child: Stack(
        children: [
          // Seçili göstergesi: segment genişliğinde, segmentler arasında kayar.
          Positioned.fill(
            child: AnimatedAlign(
              duration: motion.standard,
              curve: AppMotion.move,
              alignment: Alignment(-1 + 2 * selectedIndex / (n - 1), 0),
              // Gösterge, segment hücresiyle aynı kutuda; 4'lük boşluk kutunun içinde.
              child: FractionallySizedBox(
                widthFactor: 1 / n,
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.all(_inset),
                  child: DecoratedBox(
                    decoration: AppRadius.decoration(
                      radius: AppRadius.sm,
                      color: c.surfaceRaised,
                      elevation: context.elevation.e1,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: AppPressable(
                    // Seçili segment de etkin görünür (VoiceOver "soluk" demesin); ona
                    // dokunmak bir şey yapmaz.
                    onPressed: enabled
                        ? () {
                            if (segment.value == value) return;
                            AppHaptics.selection();
                            onChanged!(segment.value);
                          }
                        : null,
                    semanticLabel: segment.label,
                    semanticSelected: segment.value == value,
                    scaleOnPress: false,
                    minWidth: double.infinity,
                    builder: (context, pressed) {
                      final isSelected = segment.value == value;
                      return Padding(
                        padding: const EdgeInsets.all(_inset),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: AppSpacing.touchTarget - 2 * _inset,
                          ),
                          child: Center(
                            heightFactor: 1,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: AppSpacing.xxs,
                              ),
                              child: Text(
                                segment.label,
                                textAlign: TextAlign.center,
                                style: context.text.label.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: !enabled
                                      ? c.textDisabled
                                      : isSelected
                                      ? c.textPrimary
                                      : (pressed
                                            ? c.textPrimary
                                            : c.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
