import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import 'swipe_deck.dart';
import 'swipe_deck_physics.dart';

/// Deste alt butonları (DESIGN_SYSTEM.md §10 "SwipeDeck"): soldan sağa **Pas 56 · Olmaz 44 ·
/// Çok isterim 44 · Olur 56**. Pas/Olmaz/Çok isterim `surface` + E1 (ikon `textSecondary` /
/// `error` / `brand`), Olur `brand` dolgu + `onBrand`. Basınca kart ilgili yöne uçar.
///
/// Kart sürüklenirken ilgili buton vurgulanır (ölçek, dolgu), diğerleri soluklaşır.
class DeckActionBar extends StatelessWidget {
  const DeckActionBar({super.key, required this.controller});

  final SwipeDeckController controller;

  /// Vurgulu buton ölçeği.
  static const double highlightScale = 1.12;

  /// Diğer butonların vurgu sırasında düştüğü opaklık.
  static const double fadedOpacity = 0.35;

  static const double _doneOpacity = 0.35;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => ValueListenableBuilder<SwipeFrame>(
        valueListenable: controller.frame,
        builder: (context, frame, _) {
          final done = controller.isDone;
          Widget button(DeckDecision d, double size, double iconSize) {
            return _ActionButton(
              decision: d,
              size: size,
              iconSize: iconSize,
              frame: frame,
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
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.decision,
    required this.size,
    required this.iconSize,
    required this.frame,
    required this.enabled,
    required this.onPressed,
  });

  final DeckDecision decision;
  final double size;
  final double iconSize;
  final SwipeFrame frame;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final dragging = frame.direction != null && frame.progress > 0;
    final active = dragging && frame.direction == decision;
    final p = active ? frame.labelOpacity : 0.0;
    final opacity = dragging && !active
        ? 1 - (1 - DeckActionBar.fadedOpacity) * frame.labelOpacity
        : 1.0;

    final (label, icon) = switch (decision) {
      DeckDecision.pass => (l10n.deckDecisionPass, AppIcons.close),
      DeckDecision.veto => (l10n.deckDecisionVeto, AppIcons.prohibit),
      DeckDecision.love => (l10n.deckDecisionLove, AppIcons.heartFill),
      DeckDecision.ok => (l10n.deckDecisionOk, AppIcons.check),
    };
    final (fill, iconColor) = _colors(c, p);
    final filled = decision == DeckDecision.ok;

    return AppPressable(
      onPressed: enabled ? onPressed : null,
      semanticLabel: label,
      focusShape: const CircleBorder(),
      builder: (context, pressed) => Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: 1 + (DeckActionBar.highlightScale - 1) * p,
          child: DecoratedBox(
            decoration: AppRadius.circle(
              color: fill,
              elevation: filled ? null : context.elevation.e1,
            ),
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: Icon(icon, size: iconSize, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Dolgu ve ikon rengi; [p] vurgu ilerlemesi (0–1).
  (Color, Color) _colors(AppColors c, double p) => switch (decision) {
    DeckDecision.pass => (
      Color.lerp(c.surface, c.surfacePressed, p)!,
      c.textSecondary,
    ),
    DeckDecision.veto => (Color.lerp(c.surface, c.errorSoft, p)!, c.error),
    DeckDecision.love => (
      Color.lerp(c.surface, c.brand, p)!,
      Color.lerp(c.brand, c.onBrand, p)!,
    ),
    DeckDecision.ok => (c.brand, c.onBrand),
  };
}
