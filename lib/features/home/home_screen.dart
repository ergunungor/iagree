import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/gallery/design_system_gallery.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../l10n/app_localizations.dart';

/// Geçici ana ekran (C1 gelene kadar): oturum açıldığını gösterir. E3'te Odalarım ile
/// değişecek.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = AppScope.of(context).session;
    final user = session.user;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(user?.name ?? '', style: context.text.h1),
              const SizedBox(height: AppSpacing.xs),
              Text(
                user?.email ?? '',
                style: context.text.body.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const Spacer(),
              if (kDebugMode) ...[
                AppButton.secondary(
                  label: 'Tasarım galerisi (debug)',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DesignSystemGallery(),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              AppButton.tertiary(
                label: l10n.homeSignOut,
                onPressed: session.signOut,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
