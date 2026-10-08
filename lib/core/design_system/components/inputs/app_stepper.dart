import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_haptics.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../buttons/app_icon_button.dart';

/// `[−] değer [+]` (DESIGN_SYSTEM.md §10 "Stepper").
///
/// İki taraf Soft ikon butonu; değer `title` + tabular. Basılı tutunca hızlanarak tekrarlar,
/// her adımda selection haptic verir. [min] ve [max]'ta ilgili buton pasif olur.
class AppStepper extends StatelessWidget {
  const AppStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    required this.semanticLabel,
    this.step = 1,
    this.valueFormatter,
  }) : assert(min <= max),
       assert(step > 0);

  final int value;

  /// Null ise stepper tamamen pasif.
  final ValueChanged<int>? onChanged;
  final int min;
  final int max;
  final int step;

  /// VoiceOver etiketi (örn. "Kişi sayısı"); yerelleştirilmiş olmalı.
  final String semanticLabel;

  /// Görünen metin (örn. "4 kişi"); boşsa sayının kendisi.
  final String Function(int value)? valueFormatter;

  /// Değer alanının genişliği: en uzun olası metne (min, max, şimdiki) göre sabitlenir, böylece
  /// basamak sayısı değişince butonlar kaymaz.
  double _valueWidth(BuildContext context, TextStyle style) {
    double measure(int v) {
      final painter = TextPainter(
        text: TextSpan(text: _format(v), style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width;
      painter.dispose();
      return width;
    }

    return [min, max, value].map(measure).reduce((a, b) => a > b ? a : b);
  }

  String _format(int v) => valueFormatter?.call(v) ?? '$v';

  void _set(int next) {
    final clamped = next.clamp(min, max);
    if (clamped == value) return;
    AppHaptics.selection();
    onChanged?.call(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canDecrease = onChanged != null && value - step >= min;
    final canIncrease = onChanged != null && value + step <= max;
    final valueStyle = context.text.title.tabular;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIconButton.soft(
          icon: AppIcons.minus,
          semanticLabel: l10n.commonDecrease,
          onPressed: canDecrease ? () => _set(value - step) : null,
          repeatOnHold: true,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: SizedBox(
            width: _valueWidth(context, valueStyle),
            // VoiceOver'da ayarlanabilir değer: yukarı/aşağı kaydırarak değiştirilir.
            child: Semantics(
              label: semanticLabel,
              value: _format(value),
              increasedValue: canIncrease ? _format(value + step) : null,
              decreasedValue: canDecrease ? _format(value - step) : null,
              onIncrease: canIncrease ? () => _set(value + step) : null,
              onDecrease: canDecrease ? () => _set(value - step) : null,
              excludeSemantics: true,
              child: Text(
                _format(value),
                textAlign: TextAlign.center,
                style: valueStyle.copyWith(
                  color: onChanged == null
                      ? context.colors.textDisabled
                      : context.colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
        AppIconButton.soft(
          icon: AppIcons.plus,
          semanticLabel: l10n.commonIncrease,
          onPressed: canIncrease ? () => _set(value + step) : null,
          repeatOnHold: true,
        ),
      ],
    );
  }
}
