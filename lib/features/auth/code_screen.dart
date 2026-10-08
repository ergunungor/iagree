import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../core/data/auth_repository.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/feedback/app_toast.dart';
import '../../core/design_system/components/inputs/app_code_field.dart';
import '../../core/design_system/foundations/app_haptics.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/design_system/tokens/app_typography.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/auth_page.dart';

/// A4 · Doğrulama kodu (SCREENS A4): 6 kutu, altıncı hanede otomatik gönderim, yeniden
/// gönder geri sayımı, yanlış kodda `error` kenar + error haptic + temizleme.
class CodeScreen extends StatefulWidget {
  const CodeScreen({
    super.key,
    required this.email,
    this.resendSeconds = defaultResendSeconds,
  });

  final String email;

  /// Yeniden gönder için bekleme süresi (sn).
  final int resendSeconds;

  static const int defaultResendSeconds = 45;

  @override
  State<CodeScreen> createState() => _CodeScreenState();
}

class _CodeScreenState extends State<CodeScreen> {
  final TextEditingController _code = TextEditingController();
  Timer? _timer;
  late int _remaining = widget.resendSeconds;
  bool _wrong = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    _remaining = widget.resendSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _remaining = (_remaining - 1).clamp(0, 1 << 30));
      if (_remaining == 0) t.cancel();
    });
  }

  String _clock(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  Future<void> _verify(String code) async {
    if (_busy) return;
    _busy = true;
    final scope = AppScope.of(context);
    final outcome = await scope.auth.verifyCode(widget.email, code);
    _busy = false;
    if (!mounted) return;
    switch (outcome) {
      case WrongCode():
        AppHaptics.error();
        setState(() => _wrong = true);
        _code.clear();
      case SignedIn(:final user):
        AppRoutes.finishSignIn(context, user);
      case NeedsProfile():
        AppRoutes.pushProfile(context, outcome);
    }
  }

  Future<void> _resend() async {
    await AppScope.of(context).auth.sendCode(widget.email);
    if (!mounted) return;
    setState(_startCountdown);
  }

  /// Gönderim adresini kalın yazar; çeviride adresin konumu değişse de çalışır.
  InlineSpan _subtitle(AppLocalizations l10n) {
    final full = l10n.authCodeSubtitle(widget.email);
    final i = full.indexOf(widget.email);
    if (i < 0) return TextSpan(text: full);
    return TextSpan(
      children: [
        TextSpan(text: full.substring(0, i)),
        TextSpan(
          text: widget.email,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        TextSpan(text: full.substring(i + widget.email.length)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final text = context.text;

    return AuthPage(
      title: l10n.authCodeTitle,
      subtitle: AuthSubtitle.rich(_subtitle(l10n)),
      onBack: () => Navigator.of(context).maybePop(),
      bottom: AppButton.secondary(
        label: l10n.authOpenMail,
        icon: AppIcons.mail,
        onPressed: () => AppToast.show(context, message: l10n.authMailSoon),
      ),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppButton.tertiary(
            label: l10n.authChangeAddress,
            size: AppButtonSize.small,
            fullWidth: false,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCodeField(
          controller: _code,
          hasError: _wrong,
          onChanged: (_) {
            if (_wrong) setState(() => _wrong = false);
          },
          onCompleted: _verify,
        ),
        if (_wrong)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Semantics(
              liveRegion: true,
              child: Row(
                children: [
                  Icon(AppIcons.warning, size: AppIconSize.s14, color: c.error),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      l10n.authCodeWrong,
                      style: text.caption.copyWith(color: c.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.authCodeHint,
          style: text.bodySmall.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxs),
        if (_remaining > 0)
          Text(
            l10n.authResendIn(_clock(_remaining)),
            style: text.bodySmall.tabular.copyWith(color: c.textTertiary),
          )
        else
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton.tertiary(
              label: l10n.authResend,
              size: AppButtonSize.small,
              fullWidth: false,
              onPressed: _resend,
            ),
          ),
      ],
    );
  }
}
