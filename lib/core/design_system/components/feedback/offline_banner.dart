import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_animated_size.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_motion.dart';
import '../../tokens/app_spacing.dart';

/// Çevrimdışı banner'ı (DESIGN_SYSTEM.md §10 "Toast"): nav bar altında **kalıcı**,
/// `warningSoft` zemin + `warning` içerik, "Bağlantı yok. Değişikliklerin bağlanınca
/// gönderilecek." Warning toast yoktur; çevrimdışı durumu bununla anlatılır.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final motion = context.motion;
    return AppAnimatedSize(
      duration: motion.standard,
      curve: AppMotion.enter,
      alignment: Alignment.topCenter,
      child: visible
          ? Semantics(
              liveRegion: true,
              container: true,
              child: ColoredBox(
                color: c.warningSoft,
                child: SizedBox(
                  width: double.infinity,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenPadding,
                      vertical: AppSpacing.sm,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          AppIcons.wifiOff,
                          size: AppIconSize.s20,
                          color: c.warning,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).offlineBannerMessage,
                            style: context.text.bodySmall.copyWith(
                              color: c.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
