import 'package:flutter/material.dart';

import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_spacing.dart';
import '../buttons/app_button.dart';
import '../people/app_avatar.dart';
import '../people/participant_ring.dart';

/// Boş ve hata durumu (DESIGN_SYSTEM.md §10 "States").
///
/// Stok illüstrasyon yok: yapısal görsel (kesik çizgili avatarlar ya da nötr 32'lik ikon) →
/// `h3` başlık → 1–2 satır `bodySmall` → tek buton. İçerik dikeyde ~%40'a yerleşir. Ekranda
/// zaten sabit bir Primary varsa (örn. "Oda oluştur") bileşenin kendi butonu verilmez.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.visual,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  }) : assert((actionLabel == null) == (onAction == null));

  /// Boş durum: üç kesik çizgili avatar (davet bekleyen boş yerler).
  const AppEmptyState.dashedAvatars({
    Key? key,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) : this(
         key: key,
         visual: const _DashedAvatars(),
         title: title,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
       );

  /// Ekran seviyesi hata: nötr 32'lik ikon. Hata renkli değildir (`textSecondary`);
  /// `error` yalnızca alan hataları ve yıkıcı eylemler içindir.
  factory AppEmptyState.error({
    Key? key,
    required String title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    IconData icon = AppIcons.warning,
  }) {
    return AppEmptyState(
      key: key,
      visual: _ErrorIcon(icon),
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  final Widget visual;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Merkezin dikeydeki yeri: %40 → hizalama −0,2.
  static const double _verticalAlignment = -0.2;
  static const double _maxWidth = 340;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final content = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxWidth),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          visual,
          const SizedBox(height: AppSpacing.xl),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.h3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: context.text.bodySmall.copyWith(color: c.textSecondary),
            ),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppButton.primary(
              label: actionLabel!,
              onPressed: onAction,
              size: AppButtonSize.medium,
              fullWidth: false,
            ),
          ],
        ],
      ),
    );

    // Yer varsa içerik ~%40'ta ortalı; büyük yazıda sığmazsa kaydırılır (taşmaz).
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.only(
          top: AppSpacing.huge,
          left: AppSpacing.screenPadding,
          right: AppSpacing.screenPadding,
          bottom: AppSpacing.xl,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.hasBoundedHeight
                ? (constraints.maxHeight - AppSpacing.huge - AppSpacing.xl)
                      .clamp(0.0, double.infinity)
                : 0,
          ),
          child: Align(
            alignment: const Alignment(0, _verticalAlignment),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _DashedAvatars extends StatelessWidget {
  const _DashedAvatars();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            const ParticipantRing(
              userId: '',
              name: '',
              status: ParticipantStatus.invited,
              size: AppAvatarSize.lg,
            ),
        ],
      ),
    );
  }
}

class _ErrorIcon extends StatelessWidget {
  const _ErrorIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Icon(
        icon,
        size: AppIconSize.s32,
        color: context.colors.textSecondary,
      ),
    );
  }
}
