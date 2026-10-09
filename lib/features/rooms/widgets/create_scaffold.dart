import 'package:flutter/material.dart';

import '../../../core/design_system/components/buttons/app_icon_button.dart';
import '../../../core/design_system/components/navigation/app_flow_progress.dart';
import '../../../core/design_system/foundations/app_icons.dart';
import '../../../core/design_system/foundations/context_extensions.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

/// Oda oluşturma adımlarının ortak iskeleti (SCREENS D1): solda ✕ ya da geri, ortada
/// "Oda oluştur", altında akış çubuğu; altta isteğe bağlı sabit eylem.
class CreateScaffold extends StatelessWidget {
  const CreateScaffold({
    super.key,
    required this.progress,
    required this.child,
    this.onClose,
    this.onBack,
    this.bottom,
  }) : assert((onClose == null) != (onBack == null));

  final double progress;
  final VoidCallback? onClose;
  final VoidCallback? onBack;
  final Widget child;

  /// Klavyenin üstünde duran sabit eylem alanı (Primary buton).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: Row(
                children: [
                  onClose != null
                      ? AppIconButton.plain(
                          icon: AppIcons.close,
                          semanticLabel: l10n.commonClose,
                          onPressed: onClose,
                        )
                      : AppIconButton.plain(
                          icon: AppIcons.back,
                          semanticLabel: l10n.commonBack,
                          onPressed: onBack,
                        ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.homeCreateRoom,
                        textAlign: TextAlign.center,
                        style: context.text.title,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.touchTarget),
                ],
              ),
            ),
            AppFlowProgress(value: progress),
            Expanded(child: child),
            if (bottom != null)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.sm,
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                  ),
                  child: bottom,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
