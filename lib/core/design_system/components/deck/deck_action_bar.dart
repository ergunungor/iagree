import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import 'swipe_deck.dart';
import 'swipe_deck_physics.dart';

/// Deste alt butonları (DESIGN_SYSTEM.md §10 "SwipeDeck"): soldan sağa **Pas 56 · Olmaz 44 ·
/// Çok isterim 44 · Olur 56**. Pas/Olmaz/Çok isterim `surface` + E1 (ikon `textSecondary` /
/// `error` / `brand`), Olur `brand` dolgu + `onBrand`. Basınca kart ilgili yöne uçar.
///
/// Sürükleme geri bildirimi butonlarda değil, ekran zemininde ve kartta verilir
/// (`SwipeDeckScaffold`); butonlar sürükleme boyunca sabit kalır.
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({super.key, required this.controller});

  final SwipeDeckController controller;

  static const double _doneOpacity = 0.35;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final done = controller.isDone;
        Widget button(DeckDecision d, double size, double iconSize) {
          return _ActionButton(
            decision: d,
            size: size,
            iconSize: iconSize,
            enabled: !done,
            onPressed: () => controller.swipe(d),
          );
        }

        return Opacity(
          opacity: done ? _doneOpacity : 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              button(DeckDecision.pass, 56, AppIconSize.s24),
              const SizedBox(width: AppSpacing.md),
              button(
                DeckDecision.veto,
                AppSpacing.touchTarget,
                AppIconSize.s20,
              ),
              const SizedBox(width: AppSpacing.md),
              button(
                DeckDecision.love,
                AppSpacing.touchTarget,
                AppIconSize.s20,
              ),
              const SizedBox(width: AppSpacing.md),
              button(DeckDecision.ok, 56, AppIconSize.s24),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.decision,
    required this.size,
    required this.iconSize,
    required this.enabled,
    required this.onPressed,
  });

  final DeckDecision decision;
  final double size;
  final double iconSize;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final (label, icon, iconColor) = switch (decision) {
      DeckDecision.pass => (
        l10n.deckDecisionPass,
        AppIcons.close,
        c.textSecondary,
      ),
      DeckDecision.veto => (l10n.deckDecisionVeto, AppIcons.prohibit, c.error),
      DeckDecision.love => (l10n.deckDecisionLove, AppIcons.heartFill, c.brand),
      DeckDecision.ok => (l10n.deckDecisionOk, AppIcons.check, c.onBrand),
    };
    final filled = decision == DeckDecision.ok;

    return AppPressable(
      onPressed: enabled ? onPressed : null,
      semanticLabel: label,
      focusShape: const CircleBorder(),
      builder: (context, pressed) => DecoratedBox(
        decoration: AppRadius.circle(
          color: filled ? c.brand : c.surface,
          elevation: filled ? null : context.elevation.e1,
        ),
        child: SizedBox.square(
          dimension: size,
          child: Center(
            child: Icon(icon, size: iconSize, color: iconColor),
          ),
        ),
      ),
    );
  }
}
