import 'package:flutter/material.dart';

import '../../foundations/app_haptics.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_elevation.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

/// Ayrık değerli slider (DESIGN_SYSTEM.md §10 "Slider").
///
/// İz 4px `surfaceMuted`, dolu kısım `brand`, thumb 28'lik daire (E1; sürüklerken E2). Serbest
/// değer yok: yalnızca [values] listesindekiler seçilir ve konumlar eşit aralıklıdır
/// (ör. 1, 3, 5, 10 km). Her yeni değere geçişte selection haptic.
class AppSlider extends StatefulWidget {
  AppSlider({
    super.key,
    required this.values,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.valueFormatter,
  }) : assert(values.isNotEmpty);

  final List<double> values;

  /// [values] içindeki bir değer; yoksa en yakını gösterilir.
  final double value;

  /// Null ise slider pasif.
  final ValueChanged<double>? onChanged;

  /// VoiceOver etiketi (örn. "Mesafe"); yerelleştirilmiş olmalı.
  final String semanticLabel;

  /// Görünen değer metni (örn. "3 km"); boşsa sayının kendisi.
  final String Function(double value)? valueFormatter;

  @override
  State<AppSlider> createState() => _AppSliderState();
}

class _AppSliderState extends State<AppSlider> {
  static const double _trackHeight = 4;
  static const double _thumbSize = 28;

  bool _dragging = false;

  int get _index {
    var best = 0;
    for (var i = 1; i < widget.values.length; i++) {
      if ((widget.values[i] - widget.value).abs() <
          (widget.values[best] - widget.value).abs()) {
        best = i;
      }
    }
    return best;
  }

  String _format(double v) {
    final custom = widget.valueFormatter;
    if (custom != null) return custom(v);
    return v == v.roundToDouble() ? v.round().toString() : v.toString();
  }

  void _select(int index) {
    if (widget.onChanged == null) return;
    final clamped = index.clamp(0, widget.values.length - 1);
    if (clamped == _index) return;
    AppHaptics.selection();
    widget.onChanged!(widget.values[clamped]);
  }

  /// Parmağın yatay konumundan en yakın değerin indeksi (iz, thumb yarıçapı kadar içeride).
  int _indexAt(double dx, double width) {
    const inset = _thumbSize / 2;
    final inner = width - _thumbSize;
    if (widget.values.length == 1 || inner <= 0) return 0;
    final fraction = ((dx - inset) / inner).clamp(0.0, 1.0);
    return (fraction * (widget.values.length - 1)).round();
  }

  void _setDragging(bool v) {
    if (_dragging != v) setState(() => _dragging = v);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final enabled = widget.onChanged != null;
    final n = widget.values.length;
    final index = _index;
    final fraction = n == 1 ? 0.0 : index / (n - 1);
    final filledColor = enabled ? c.brand : c.textDisabled;
    final AppElevationLevel thumbElevation = _dragging
        ? context.elevation.e2
        : context.elevation.e1;
    final canIncrease = enabled && index < n - 1;
    final canDecrease = enabled && index > 0;

    return Semantics(
      label: widget.semanticLabel,
      value: _format(widget.values[index]),
      increasedValue: canIncrease ? _format(widget.values[index + 1]) : null,
      decreasedValue: canDecrease ? _format(widget.values[index - 1]) : null,
      onIncrease: canIncrease ? () => _select(index + 1) : null,
      onDecrease: canDecrease ? () => _select(index - 1) : null,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _format(widget.values[index]),
            style: context.text.title.tabular.copyWith(
              color: enabled ? c.textPrimary : c.textDisabled,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final inner = width - _thumbSize;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: enabled
                    ? (d) {
                        _setDragging(true);
                        _select(_indexAt(d.localPosition.dx, width));
                      }
                    : null,
                onTapUp: enabled ? (_) => _setDragging(false) : null,
                onTapCancel: enabled ? () => _setDragging(false) : null,
                onHorizontalDragStart: enabled
                    ? (_) => _setDragging(true)
                    : null,
                onHorizontalDragUpdate: enabled
                    ? (d) => _select(_indexAt(d.localPosition.dx, width))
                    : null,
                onHorizontalDragEnd: enabled
                    ? (_) => _setDragging(false)
                    : null,
                onHorizontalDragCancel: enabled
                    ? () => _setDragging(false)
                    : null,
                child: SizedBox(
                  height: AppSpacing.touchTarget,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: fraction, end: fraction),
                    duration: motion.fast,
                    curve: AppMotion.move,
                    builder: (context, t, _) => Stack(
                      alignment: Alignment.centerLeft,
                      clipBehavior: Clip.none,
                      children: [
                        // İz.
                        Positioned(
                          left: _thumbSize / 2,
                          right: _thumbSize / 2,
                          child: DecoratedBox(
                            decoration: AppRadius.decoration(
                              radius: AppRadius.pill,
                              color: c.surfaceMuted,
                            ),
                            child: const SizedBox(height: _trackHeight),
                          ),
                        ),
                        // Dolu kısım: solda başlar, thumb merkezine kadar.
                        Positioned(
                          left: _thumbSize / 2,
                          child: DecoratedBox(
                            decoration: AppRadius.decoration(
                              radius: AppRadius.pill,
                              color: filledColor,
                            ),
                            child: SizedBox(
                              width: t * inner,
                              height: _trackHeight,
                            ),
                          ),
                        ),
                        // Thumb.
                        Positioned(
                          left: t * inner,
                          child: DecoratedBox(
                            decoration: AppRadius.circle(
                              color: c.surface,
                              elevation: thumbElevation,
                            ),
                            child: const SizedBox.square(dimension: _thumbSize),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
