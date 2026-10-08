import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/context_extensions.dart';
import '../../foundations/text_input_controllers.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';

/// Doğrulama kodu alanı (SCREENS A4): [length] kutu, son hane girilince [onCompleted].
///
/// Altında gizli, şeffaf bir `TextField` vardır: klavye, yapıştırma ve iOS'un SMS kodu
/// önerisi (`oneTimeCode`) normal bir metin alanı gibi çalışır; kutular yalnızca onun
/// içeriğini çizer. Boş kutular `surfaceMuted`; sıradaki kutu `surfaceInputFocus` + 1,5px
/// `brand` ve yanıp sönen imleç; [hasError] iken bütün kutular 1,5px `error`. VoiceOver tek
/// metin alanı okur ("Kod: 4 8 2 9, 2 hane kaldı").
class AppCodeField extends StatefulWidget {
  const AppCodeField({
    super.key,
    this.length = 6,
    this.controller,
    this.hasError = false,
    this.autofocus = true,
    this.onChanged,
    this.onCompleted,
  }) : assert(length > 0);

  final int length;
  final TextEditingController? controller;

  /// Yanlış kod: bütün kutular `error` kenarlı. Metin değişince çağıran temizler.
  final bool hasError;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  /// Son hane girildiğinde (bir kez).
  final ValueChanged<String>? onCompleted;

  @override
  State<AppCodeField> createState() => _AppCodeFieldState();
}

class _AppCodeFieldState extends State<AppCodeField>
    with TextInputControllersMixin<AppCodeField> {
  static const double _boxMinHeight = 60;
  static const double _border = 1.5;
  static const double _caretWidth = 2;
  static const double _caretHeight = 26;

  @override
  TextEditingController? get externalController => widget.controller;
  @override
  FocusNode? get externalFocusNode => null;

  int _lastLength = 0;

  @override
  void initState() {
    super.initState();
    initControllers();
    controller.addListener(_onText);
  }

  @override
  void didUpdateWidget(AppCodeField old) {
    super.didUpdateWidget(old);
    didUpdateControllers(old.controller, null);
  }

  @override
  void dispose() {
    controller.removeListener(_onText);
    disposeControllers();
    super.dispose();
  }

  void _onText() {
    final n = controller.text.length;
    if (n == widget.length && _lastLength != widget.length) {
      widget.onCompleted?.call(controller.text);
    }
    _lastLength = n;
  }

  String _semantics(AppLocalizations l10n) {
    final text = controller.text;
    if (text.isEmpty) return l10n.authCodeEmptySemantics(widget.length);
    final digits = text.split('').join(' ');
    final remaining = widget.length - text.length;
    return remaining == 0 ? digits : l10n.authCodeSemantics(digits, remaining);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([controller, focusNode]),
      builder: (context, _) {
        final value = controller.text;
        final current = focusNode.hasFocus && value.length < widget.length
            ? value.length
            : -1;

        Widget box(int i) {
          final filled = i < value.length;
          final isCurrent = i == current && !widget.hasError;
          final border = widget.hasError
              ? c.error
              : (isCurrent ? c.brand : Colors.transparent);
          return Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _boxMinHeight),
              child: DecoratedBox(
                decoration: AppRadius.decoration(
                  radius: AppRadius.md,
                  color: isCurrent ? c.surfaceInputFocus : c.surfaceMuted,
                  // Kenarlık her zaman aynı kalınlıkta: odak değişince kutu kaymaz.
                  side: BorderSide(color: border, width: _border),
                ),
                child: Center(
                  child: filled
                      ? Text(
                          value[i],
                          style: text.h2
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: c.textPrimary,
                              )
                              .tabular,
                        )
                      : (isCurrent ? const _Caret() : null),
                ),
              ),
            ),
          );
        }

        return Stack(
          children: [
            ExcludeSemantics(
              child: Row(
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.xs),
                    box(i),
                  ],
                ],
              ),
            ),
            // Gizli metin alanı: tüm alanı kaplar, dokunuş klavyeyi açar.
            Positioned.fill(
              child: MergeSemantics(
                child: Semantics(
                  label: _semantics(l10n),
                  textField: true,
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: widget.autofocus,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    autocorrect: false,
                    enableSuggestions: false,
                    showCursor: false,
                    enableInteractiveSelection: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    onChanged: widget.onChanged,
                    keyboardAppearance: Theme.of(context).brightness,
                    style: const TextStyle(color: Colors.transparent),
                    cursorColor: Colors.transparent,
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                      counterText: '',
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Sıradaki kutudaki yanıp sönen imleç. Reduce Motion'da sabit.
class _Caret extends StatefulWidget {
  const _Caret();

  @override
  State<_Caret> createState() => _CaretState();
}

class _CaretState extends State<_Caret> with SingleTickerProviderStateMixin {
  late final AnimationController _blink = AnimationController(vsync: this);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!context.motion.reduceMotion) {
      _blink.duration = AppMotion.regular.expressive;
      _blink.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: 1,
        end: 0,
      ).animate(CurvedAnimation(parent: _blink, curve: Curves.easeInOut)),
      child: DecoratedBox(
        decoration: AppRadius.decoration(
          radius: AppRadius.pill,
          color: context.colors.brand,
        ),
        child: const SizedBox(
          width: _AppCodeFieldState._caretWidth,
          height: _AppCodeFieldState._caretHeight,
        ),
      ),
    );
  }
}
