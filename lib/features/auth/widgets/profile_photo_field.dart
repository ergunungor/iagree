import 'package:flutter/material.dart';

import '../../../core/design_system/components/people/app_avatar.dart';
import '../../../core/design_system/foundations/app_icons.dart';
import '../../../core/design_system/foundations/app_pressable.dart';
import '../../../core/design_system/foundations/context_extensions.dart';
import '../../../core/design_system/tokens/app_radius.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Profil fotoğrafı alanı (A5 ve profil düzenleme): avatar xl + kamera rozeti + "Fotoğraf
/// ekle" etiketi; hepsi tek dokunma hedefi. Baş harfler [nameController]'dan canlı gelir.
class ProfilePhotoField extends StatelessWidget {
  const ProfilePhotoField({
    super.key,
    required this.userId,
    required this.nameController,
    required this.onPressed,
    this.image,
    this.caption,
    this.hint,
  });

  final String userId;
  final TextEditingController nameController;
  final VoidCallback onPressed;
  final ImageProvider? image;

  /// Avatarın altındaki etiket; boşsa "Fotoğraf ekle".
  final String? caption;

  /// Etiketin altındaki sönük açıklama (örn. "İsteğe bağlı").
  final String? hint;

  /// Rozet: 36'lık daire, avatarın sağ altında.
  static const double _badge = 36;
  static const double _badgeOffset = AppSpacing.xxs;
  static const double _badgeRing = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final text = context.text;
    final label = caption ?? l10n.authAddPhoto;
    return Center(
      child: AppPressable(
        onPressed: onPressed,
        semanticLabel: label,
        focusShape: AppRadius.border(AppRadius.lg),
        scaleOnPress: false,
        builder: (context, pressed) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ListenableBuilder(
                  listenable: nameController,
                  builder: (context, _) => AppAvatar(
                    userId: userId,
                    name: nameController.text,
                    image: image,
                    size: AppAvatarSize.xl,
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
            Text(label, style: text.buttonSmall.copyWith(color: c.brand)),
            if (hint != null)
              Text(hint!, style: text.caption.copyWith(color: c.textTertiary)),
          ],
        ),
      ),
    );
  }
}
