import 'dart:io';

import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/user_image.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/buttons/app_icon_button.dart';
import '../../core/design_system/components/feedback/app_alert.dart';
import '../../core/design_system/components/feedback/app_toast.dart';
import '../../core/design_system/components/inputs/app_text_field.dart';
import '../../core/design_system/foundations/app_haptics.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../l10n/app_localizations.dart';
import '../auth/widgets/profile_photo_field.dart';

/// Profil düzenleme (C2 "Düzenle"): tam ekran modal. Üstte ✕ ve başlık, ortada fotoğraf ve
/// isim, e-posta salt okunur, altta tek Primary "Kaydet".
///
/// "Kaydet" yalnızca bir şey değiştiyse etkindir. Değişiklik varken ✕ ya da aşağı çekerek
/// kapatma, geri alınamaz bir kayıp olduğu için alert ile onaylanır; değişiklik yoksa doğrudan
/// kapanır.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final String _initialName;
  late final String? _initialPhoto;
  String? _photoPath;
  bool _missing = false;
  bool _busy = false;
  bool _closing = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final user = AppScope.of(context).session.user!;
    _initialName = user.name;
    _initialPhoto = user.photoPath;
    _photoPath = user.photoPath;
    _name = TextEditingController(text: user.name);
    _email = TextEditingController(text: user.email);
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _changed =>
      _name.text.trim() != _initialName || _photoPath != _initialPhoto;

  Future<void> _pickPhoto() async {
    final path = await AppScope.of(context).photos.pick();
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _missing = true);
      AppHaptics.error();
      return;
    }
    final session = AppScope.of(context).session;
    final navigator = Navigator.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      await session.updateProfile(
        name: name,
        photoPath: _photoPath,
        removePhoto: _photoPath == null && _initialPhoto != null,
      );
      AppHaptics.success();
      _closeAfterFrame(navigator);
    } on Object {
      if (!mounted) return;
      setState(() => _busy = false);
      AppHaptics.error();
      AppToast.show(
        context,
        message: l10n.editSaveFailed,
        kind: AppToastKind.error,
      );
    }
  }

  /// `PopScope.canPop` değeri bir sonraki karede güncellenir; pop o zamana bırakılır.
  void _closeAfterFrame(NavigatorState navigator) {
    setState(() => _closing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted) navigator.pop();
    });
  }

  /// Kapatma isteği: değişiklik yoksa kapanır, varsa alert sorar.
  Future<void> _requestClose() async {
    if (!_changed) {
      Navigator.of(context).pop();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final navigator = Navigator.of(context);
    final discard = await AppAlert.show(
      context,
      title: l10n.editDiscardTitle,
      message: l10n.editDiscardMessage,
      actionLabel: l10n.editDiscardConfirm,
      cancelLabel: l10n.editKeepEditing,
    );
    if (discard) {
      _closeAfterFrame(navigator);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final user = AppScope.of(context).session.user!;
    final image = _photoPath == null
        ? null
        : (_photoPath == _initialPhoto
              ? userImage(user)
              : FileImage(File(_photoPath!)));

    return PopScope(
      canPop: _closing || !_changed,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestClose();
      },
      child: Scaffold(
        backgroundColor: c.canvas,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
                child: Row(
                  children: [
                    AppIconButton.plain(
                      icon: AppIcons.close,
                      semanticLabel: l10n.commonClose,
                      onPressed: _requestClose,
                    ),
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          l10n.editTitle,
                          textAlign: TextAlign.center,
                          style: context.text.title,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.touchTarget),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.xl,
                    AppSpacing.screenPadding,
                    AppSpacing.xl,
                  ),
                  children: [
                    ProfilePhotoField(
                      userId: user.id,
                      nameController: _name,
                      image: image,
                      caption: _photoPath == null
                          ? l10n.authAddPhoto
                          : l10n.editChangePhoto,
                      onPressed: _pickPhoto,
                    ),
                    if (_photoPath != null)
                      Center(
                        child: AppButton.tertiary(
                          label: l10n.editRemovePhoto,
                          size: AppButtonSize.small,
                          fullWidth: false,
                          onPressed: () => setState(() => _photoPath = null),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    AppTextField(
                      label: l10n.authNameLabel,
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.name],
                      errorText: _missing ? l10n.authNameRequired : null,
                      onChanged: (_) => setState(() => _missing = false),
                      onSubmitted: (_) => _changed ? _save() : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      label: l10n.authEmailLabel,
                      controller: _email,
                      enabled: false,
                      helperText: l10n.editEmailHelper,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  AppSpacing.md,
                ),
                child: AppButton.primary(
                  label: l10n.editSave,
                  isLoading: _busy,
                  onPressed: _changed ? _save : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
