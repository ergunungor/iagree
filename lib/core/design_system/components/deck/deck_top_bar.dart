import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../buttons/app_icon_button.dart';
import '../navigation/app_flow_progress.dart';
import 'swipe_deck.dart';

/// Deste üst barı (DESIGN_SYSTEM.md §10 "SwipeDeck"): geri (odaya) · 4px progress · "8/15"
/// (`caption`, tabular) · Geri al ikonu. Durumu [SwipeDeckController]'dan okur.
///
/// VoiceOver ilerlemeyi tek öğe okur ("Kart 8, toplam 15"); sayı eki yoktur.
class DeckTopBar extends StatelessWidget {
  const DeckTopBar({super.key, required this.controller, this.onBack});

  final SwipeDeckController controller;

  /// Geri (odaya). Null ise düğme pasif.
  final VoidCallback? onBack;

  /// İkonun kenara hizalanması: ikon 24, dokunma alanı 44 (nav bar ile aynı).
  static const double _edge =
      AppSpacing.screenPadding - (AppSpacing.touchTarget - AppIconSize.s24) / 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final total = controller.total;
        final position = total == 0 ? 0 : math.min(controller.index + 1, total);
        final progress = total == 0 ? 0.0 : position / total;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _edge),
          child: Row(
            children: [
              AppIconButton.plain(
                icon: AppIcons.back,
                semanticLabel: l10n.deckBackSemantics,
                onPressed: onBack,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Semantics(
                  label: l10n.deckProgressSemantics(position, total),
                  child: ExcludeSemantics(
                    child: Row(
                      children: [
                        Expanded(
                          child: AppFlowProgress(
                            value: progress,
                            rounded: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '$position/$total',
                          style: context.text.caption.tabular.copyWith(
                            color: c.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              AppIconButton.plain(
                icon: AppIcons.undo,
                semanticLabel: l10n.deckUndoSemantics,
                onPressed: controller.canUndo ? controller.undo : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
