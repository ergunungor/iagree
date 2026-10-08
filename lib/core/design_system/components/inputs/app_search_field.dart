import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../foundations/text_input_controllers.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../buttons/app_button.dart';

/// Arama alanı (DESIGN_SYSTEM.md §10 "SearchField").
///
/// 44 yükseklik, `radius md`, solda 20'lik büyüteç (`textTertiary`). Odakta sağda Tertiary
/// "Vazgeç" belirir; dokununca metni temizler, odağı bırakır ve [onCancel]'ı çağırır.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    required this.hintText,
    this.controller,
    this.focusNode,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.onCancel,
  });

  /// İpucu metni; aynı zamanda VoiceOver etiketi (örn. "Mekan ara"). Yerelleştirilmiş olmalı.
  final String hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final bool enabled;
  final bool autofocus;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  /// "Vazgeç"e dokunulunca, metin temizlenip odak bırakıldıktan sonra.
  final VoidCallback? onCancel;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField>
    with TextInputControllersMixin<AppSearchField> {
  static const double _minHeight = 44;

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
  void didUpdateWidget(AppSearchField old) {
    super.didUpdateWidget(old);
    didUpdateControllers(old.controller, old.focusNode);
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  void _cancel() {
    controller.clear();
    widget.onChanged?.call('');
    focusNode.unfocus();
    widget.onCancel?.call();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    final text = context.text;
    final inputColor = widget.enabled ? c.textPrimary : c.textDisabled;

    final field = Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.enabled ? focusNode.requestFocus : null,
        child: Container(
          constraints: const BoxConstraints(minHeight: _minHeight),
          decoration: AppRadius.decoration(
            radius: AppRadius.md,
            color: c.surfaceMuted,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  AppIcons.search,
                  size: AppIconSize.s20,
                  color: c.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                // Etiket alanın kendi düğümüne bağlanır; "Vazgeç" ayrı kalır.
                child: MergeSemantics(
                  child: Semantics(
                    label: widget.hintText,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: widget.enabled,
                      autofocus: widget.autofocus,
                      textInputAction: TextInputAction.search,
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
            ],
          ),
        ),
      ),
    );

    return Row(
      children: [
        field,
        AnimatedSize(
          duration: motion.standard,
          curve: AppMotion.enter,
          alignment: Alignment.centerRight,
          child: widget.enabled && hasFocus
              ? Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xs),
                  child: AppButton.tertiary(
                    label: AppLocalizations.of(context).commonCancel,
                    size: AppButtonSize.small,
                    onPressed: _cancel,
                  ),
                )
              : const SizedBox(width: 0, height: 0),
        ),
      ],
    );
  }
}
