import 'package:flutter/material.dart';

import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../content/app_list_group.dart';
import '../feedback/app_sheet.dart';

/// [AppSelectionField]'ın bir seçeneği.
class AppSelectionOption<T> {
  const AppSelectionOption({required this.value, required this.label});

  final T value;

  /// Görünen ve VoiceOver'da okunan metin; yerelleştirilmiş olmalı.
  final String label;
}

/// Seçim alanı (DESIGN_SYSTEM.md §10 "SearchField / SelectionField").
///
/// [AppTextField] görünümü (etiket üstte, 52 min, `surfaceMuted`, `radius md`) + sağda yukarı-aşağı
/// chevron. Dokununca **bottom sheet** açılır (dropdown yok): tekli seçim listesi, seçili
/// seçeneğin sağında `brand` ✓. Sheet açıkken alan odaklı görünür.
class AppSelectionField<T> extends StatefulWidget {
  const AppSelectionField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.sheetTitle,
  });

  final String label;
  final List<AppSelectionOption<T>> options;

  /// Seçili değer; null ise [hintText] gösterilir.
  final T? value;

  /// Null ise alan pasif.
  final ValueChanged<T>? onChanged;
  final String? hintText;

  /// Sheet başlığı; boşsa [label].
  final String? sheetTitle;

  @override
  State<AppSelectionField<T>> createState() => _AppSelectionFieldState<T>();
}

class _AppSelectionFieldState<T> extends State<AppSelectionField<T>> {
  static const double _minHeight = 52;
  static const double _borderWidth = 1.5;

  bool _open = false;

  String? get _selectedLabel {
    for (final o in widget.options) {
      if (o.value == widget.value) return o.label;
    }
    return null;
  }

  Future<void> _openSheet() async {
    if (AppSheet.isOpen) return;
    setState(() => _open = true);
    final picked = await AppSheet.show<T>(
      context,
      title: widget.sheetTitle ?? widget.label,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: AppListGroup(
          children: [
            for (final option in widget.options)
              AppListRow(
                title: option.label,
                selected: option.value == widget.value,
                onPressed: () => Navigator.of(sheetContext).pop(option.value),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _open = false);
    if (picked != null) widget.onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final text = context.text;
    final enabled = widget.onChanged != null && widget.options.isNotEmpty;
    final selected = _selectedLabel;

    final Color fill = _open && enabled ? c.surfaceInputFocus : c.surfaceMuted;
    final Color border = _open && enabled ? c.brand : Colors.transparent;
    final valueText = selected ?? widget.hintText ?? '';
    final valueColor = !enabled
        ? c.textDisabled
        : (selected == null ? c.textTertiary : c.textPrimary);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: text.label.copyWith(color: c.textSecondary),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppPressable(
          onPressed: enabled ? _openSheet : null,
          semanticLabel: widget.label,
          semanticValue: selected ?? widget.hintText,
          scaleOnPress: false,
          focusShape: AppRadius.border(AppRadius.md),
          minWidth: double.infinity,
          builder: (context, pressed) => AnimatedContainer(
            duration: motion.fast,
            curve: AppMotion.move,
            constraints: const BoxConstraints(minHeight: _minHeight),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md - _borderWidth,
              vertical: AppSpacing.sm - _borderWidth,
            ),
            decoration: AppRadius.decoration(
              radius: AppRadius.md,
              color: pressed && enabled ? c.surfacePressed : fill,
              side: BorderSide(color: border, width: _borderWidth),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    valueText,
                    style: text.body.copyWith(color: valueColor),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(
                  AppIcons.upDown,
                  size: AppIconSize.s20,
                  color: enabled ? c.textSecondary : c.textDisabled,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
