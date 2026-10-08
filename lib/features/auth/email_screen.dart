import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/inputs/app_text_field.dart';
import '../../core/design_system/foundations/app_haptics.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/auth_page.dart';

/// A3 · E-posta (SCREENS A3): tek alan, e-posta klavyesi, "Kodu gönder" klavyenin üstünde.
class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  static final RegExp _valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  final TextEditingController _email = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _email.text.trim();
    if (!_valid.hasMatch(value)) {
      // Eksik alanla basılınca alan işaretlenir + error haptic (CTA politikası).
      setState(() => _invalid = true);
      AppHaptics.error();
      return;
    }
    final auth = AppScope.of(context).auth;
    await auth.sendCode(value);
    if (!mounted) return;
    AppRoutes.pushCode(context, email: value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthPage(
      title: l10n.authEmailTitle,
      subtitle: AuthSubtitle(l10n.authEmailSubtitle),
      onBack: () => Navigator.of(context).maybePop(),
      bottom: AppButton.primary(label: l10n.authEmailSend, onPressed: _submit),
      children: [
        const SizedBox(height: AppSpacing.xxl),
        AppTextField(
          label: l10n.authEmailLabel,
          controller: _email,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          autocorrect: false,
          errorText: _invalid ? l10n.authEmailInvalid : null,
          onChanged: (_) {
            if (_invalid) setState(() => _invalid = false);
          },
          onSubmitted: (_) => _submit(),
        ),
      ],
    );
  }
}
