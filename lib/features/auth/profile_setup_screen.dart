import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../core/data/auth_repository.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/inputs/app_text_field.dart';
import '../../core/design_system/foundations/app_haptics.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/auth_page.dart';
import 'widgets/profile_photo_field.dart';

/// A5 · Profil kurulumu (SCREENS A5): yalnızca yeni kullanıcı. İsim Apple'dan geldiyse dolu
/// ve altında not; fotoğraf isteğe bağlı.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.pending});

  final NeedsProfile pending;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final TextEditingController _name = TextEditingController(
    text: widget.pending.suggestedName,
  );
  bool _missing = false;
  String? _photoPath;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _missing = true);
      AppHaptics.error();
      return;
    }
    final scope = AppScope.of(context);
    final user = await scope.auth.createProfile(
      email: widget.pending.email,
      name: name,
      photoPath: _photoPath,
    );
    if (!mounted) return;
    AppRoutes.finishSignIn(context, user);
  }

  Future<void> _pickPhoto() async {
    final path = await AppScope.of(context).photos.pick();
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final photo = ProfilePhotoField(
      userId: widget.pending.email,
      nameController: _name,
      image: _photoPath == null ? null : FileImage(File(_photoPath!)),
      hint: l10n.authOptional,
      onPressed: _pickPhoto,
    );

    final field = AppTextField(
      label: l10n.authNameLabel,
      controller: _name,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.name],
      errorText: _missing ? l10n.authNameRequired : null,
      helperText: widget.pending.fromApple ? l10n.authNameFromApple : null,
      onChanged: (_) {
        if (_missing) setState(() => _missing = false);
      },
      onSubmitted: (_) => _start(),
    );

    return AuthPage(
      title: l10n.authProfileTitle,
      subtitle: AuthSubtitle(l10n.authProfileSubtitle),
      topPadding: AppSpacing.giant,
      bottom: AppButton.primary(label: l10n.authStart, onPressed: _start),
      children: [
        const SizedBox(height: AppSpacing.xxxl),
        photo,
        const SizedBox(height: AppSpacing.xl),
        field,
      ],
    );
  }
}
