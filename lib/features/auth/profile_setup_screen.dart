import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../core/data/auth_repository.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/inputs/app_text_field.dart';
import '../../core/design_system/components/people/app_avatar.dart';
import '../../core/design_system/foundations/app_haptics.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/app_pressable.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_radius.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/auth_page.dart';

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

  /// Rozet: 36'lık daire, avatarın sağ altında.
  static const double _badge = 36;
  static const double _badgeOffset = AppSpacing.xxs;
  static const double _badgeRing = 3;

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
    final c = context.colors;
    final text = context.text;

    // Avatar, "Fotoğraf ekle" ve "İsteğe bağlı" tek dokunma hedefidir.
    final photo = Center(
      child: AppPressable(
        onPressed: _pickPhoto,
        semanticLabel: l10n.authAddPhoto,
        focusShape: AppRadius.border(AppRadius.lg),
        scaleOnPress: false,
        builder: (context, pressed) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ListenableBuilder(
                  listenable: _name,
                  builder: (context, _) => AppAvatar(
                    userId: widget.pending.email,
                    name: _name.text,
                    size: AppAvatarSize.xl,
                    image: _photoPath == null
                        ? null
                        : FileImage(File(_photoPath!)),
                  ),
                ),
                Positioned(
                  right: -_badgeOffset,
                  bottom: -_badgeOffset,
                  child: DecoratedBox(
                    decoration: AppRadius.circle(
                      color: c.surfaceMuted,
                      side: BorderSide(color: c.canvas, width: _badgeRing),
                    ),
                    child: SizedBox.square(
                      dimension: _badge,
                      child: Icon(
                        AppIcons.camera,
                        size: AppIconSize.s20,
                        color: c.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.authAddPhoto,
              style: text.buttonSmall.copyWith(color: c.brand),
            ),
            Text(
              l10n.authOptional,
              style: text.caption.copyWith(color: c.textTertiary),
            ),
          ],
        ),
      ),
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
