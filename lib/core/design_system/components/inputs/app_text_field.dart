import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_animated_size.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../foundations/text_input_controllers.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Tek satırlık metin alanı (DESIGN_SYSTEM.md §10 "TextField").
///
/// Etiket üstte, 8 boşlukla; floating label yok. Dolgu `surfaceMuted`, varsayılan kenarlık
/// yok. Odakta dolgu `surfaceInputFocus` + 1,5px `brand`; doluysa sağda temizle ikonu.
/// Hata: 1,5px `error` + altta ⚠ ve `error` metin. Disabled: `textDisabled`.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.autocorrect = true,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
  });

  /// Alanın üstündeki etiket; aynı zamanda VoiceOver etiketi. Yerelleştirilmiş olmalı.
  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;

  /// Doluysa alan hata durumunda: kenarlık `error`, altında ⚠ + metin.
  final String? errorText;

  /// Hata yokken alanın altında `caption` `textSecondary` açıklama (örn. "Apple hesabından geldi").
  final String? helperText;
  final bool enabled;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final bool autocorrect;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField>
    with TextInputControllersMixin<AppTextField> {
  static const double _minHeight = 52;
  static const double _borderWidth = 1.5;

  @override
  TextEditingController? get externalController => widget.controller;
  @override
  FocusNode? get externalFocusNode => widget.focusNode;

  @override
  void initState() {
    super.initState();
    initControllers();
  }

  @override
  void didUpdateWidget(AppTextField old) {
    super.didUpdateWidget(old);
    didUpdateControllers(old.controller, old.focusNode);
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  void _clear() {
    controller.clear();
    widget.onChanged?.call('');
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final text = context.text;
    final hasError = widget.errorText != null;
    final showClear = widget.enabled && hasFocus && hasText;

    final Color fill = !widget.enabled
        ? c.surfaceMuted
        : (hasFocus ? c.surfaceInputFocus : c.surfaceMuted);
    // Kenarlık her zaman aynı kalınlıkta (idle'da saydam): odak değişince yerleşim kaymaz.
    final Color borderColor = !widget.enabled
        ? Colors.transparent
        : hasError
        ? c.error
        : (hasFocus ? c.brand : Colors.transparent);
    final inputColor = widget.enabled ? c.textPrimary : c.textDisabled;

    final field = AnimatedContainer(
      duration: motion.fast,
      curve: AppMotion.move,
      constraints: const BoxConstraints(minHeight: _minHeight),
      decoration: AppRadius.decoration(
        radius: AppRadius.md,
        color: fill,
        side: BorderSide(color: borderColor, width: _borderWidth),
      ),
      padding: const EdgeInsets.only(left: AppSpacing.md - _borderWidth),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            // Dikey padding yalnızca metin tarafında: 44 pt'lik temizle butonu satırı
            // yükseltmesin (yükseklik 52 min, yalnızca metinle büyür).
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm - _borderWidth,
              ),
              // Etiket alanın kendi düğümüne bağlanır; temizle ikonu ayrı kalır.
              child: MergeSemantics(
                child: Semantics(
                  label: widget.label,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: widget.enabled,
                    autofocus: widget.autofocus,
                    keyboardType: widget.keyboardType,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.textCapitalization,
                    autofillHints: widget.autofillHints,
                    autocorrect: widget.autocorrect,
                    inputFormatters: widget.inputFormatters,
                    onChanged: widget.onChanged,
                    onSubmitted: widget.onSubmitted,
                    style: text.body.copyWith(color: inputColor),
                    cursorColor: c.brand,
                    keyboardAppearance: Theme.of(context).brightness,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      hintText: widget.hintText,
                      hintStyle: text.body.copyWith(color: c.textTertiary),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (showClear)
            AppPressable(
              onPressed: _clear,
              semanticLabel: AppLocalizations.of(context).commonClear,
              scaleOnPress: false,
              focusShape: const CircleBorder(),
              builder: (context, pressed) => SizedBox.square(
                dimension: AppSpacing.touchTarget,
                child: Center(
                  child: AnimatedOpacity(
                    duration: motion.fast,
                    opacity: pressed ? 0.5 : 1,
                    child: Icon(
                      AppIcons.close,
                      size: AppIconSize.s20,
                      color: c.textTertiary,
                    ),
                  ),
                ),
              ),
            )
          else
            const SizedBox(width: AppSpacing.md - _borderWidth),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? focusNode.requestFocus : null,
          child: ExcludeSemantics(
            child: Text(
              widget.label,
              style: text.label.copyWith(color: c.textSecondary),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.enabled ? focusNode.requestFocus : null,
          child: field,
        ),
        AppAnimatedSize(
          duration: motion.standard,
          curve: AppMotion.enter,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Semantics(
                    container: true,
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          // İkon, caption'ın ilk satırıyla hizalı.
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xxs / 2,
                          ),
                          child: Icon(
                            AppIcons.warning,
                            size: AppIconSize.s14,
                            color: c.error,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Expanded(
                          child: Text(
                            widget.errorText!,
                            style: text.caption.copyWith(color: c.error),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : (widget.helperText != null
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: Text(
                          widget.helperText!,
                          style: text.caption.copyWith(color: c.textSecondary),
                        ),
                      )
                    : const SizedBox(width: double.infinity)),
        ),
      ],
    );
  }
}
