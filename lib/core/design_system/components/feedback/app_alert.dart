import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../buttons/app_button.dart';

/// Alert modal (DESIGN_SYSTEM.md §10 "Alert").
///
/// **Yalnızca geri alınamaz işlemler için.** Geri alınabilir işlemlerde modal açılmaz: işlem
/// yapılır ve "Geri al" toast'ı gösterilir. Genişlik ekran − 48 (en fazla 340), `surfaceRaised`,
/// `radius lg`, padding 24, ortalı `h3` + en fazla 2 cümle `bodySmall`. Butonlar dikey: eylem
/// üstte, Tertiary "Vazgeç" altta. Onay butonu işlemi tekrarlar ("Odayı sil", asla "Tamam").
abstract final class AppAlert {
  static const double _maxWidth = 340;
  static const double _scaleFrom = 1.05;

  /// Alert'i gösterir. Eyleme basılırsa `true`, "Vazgeç"e basılırsa `false` döner. Scrim'e
  /// dokunarak kapanmaz: kullanıcı bilinçli seçmelidir.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String actionLabel,
    String? message,
    String? cancelLabel,
    bool destructive = true,
  }) async {
    final motion = AppMotion.of(context);
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierLabel: l10n.commonClose,
      barrierColor: colors.scrim,
      transitionDuration: motion.standard,
      pageBuilder: (dialogContext, animation, secondaryAnimation) => _AlertBody(
        title: title,
        message: message,
        actionLabel: actionLabel,
        cancelLabel: cancelLabel ?? l10n.commonCancel,
        destructive: destructive,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.enter,
          reverseCurve: AppMotion.exit,
        );
        // 1,05 → 1 ölçek + fade; çıkış girişten %25 kısa.
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: _scaleFrom, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
    return result ?? false;
  }
}

class _AlertBody extends StatelessWidget {
  const _AlertBody({
    required this.title,
    required this.actionLabel,
    required this.cancelLabel,
    required this.destructive,
    this.message,
  });

  final String title;
  final String? message;
  final String actionLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final size = MediaQuery.sizeOf(context);
    final width = math.min(size.width - 2 * AppSpacing.xl, AppAlert._maxWidth);

    // showGeneralDialog'un Material'i yok: onsuz metinler uyarı stiliyle (sarı altı çizgi) çizilir.
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: title,
          child: SizedBox(
            width: width,
            child: DecoratedBox(
              decoration: AppRadius.decoration(
                radius: AppRadius.lg,
                color: c.surfaceRaised,
                elevation: context.elevation.e3,
              ),
              child: ConstrainedBox(
                // Büyük yazıda alert ekrandan taşmasın, içeride kayar.
                constraints: BoxConstraints(maxHeight: size.height * 0.8),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                          style: context.text.bodySmall.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      if (destructive)
                        AppButton.destructiveStrong(
                          label: actionLabel,
                          onPressed: () => Navigator.of(context).pop(true),
                        )
                      else
                        AppButton.primary(
                          label: actionLabel,
                          onPressed: () => Navigator.of(context).pop(true),
                        ),
                      const SizedBox(height: AppSpacing.xs),
                      AppButton.tertiary(
                        label: cancelLabel,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
