import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_radius.dart';
import 'swipe_deck_physics.dart';

/// `SwipeDeck`'in karta ilettiği bilgi: sürükleme durumu (etiket ve ton için) ve erişilebilirlik
/// eylemleri. `DeckCard` kapsamı bulursa fotoğraf alanının üstüne overlay'i çizer ve bilgi
/// paneline özel eylemleri ekler. Kapsam yoksa kart statik çalışır.
class DeckCardScope extends InheritedWidget {
  const DeckCardScope({
    super.key,
    required this.frame,
    this.actions = const {},
    required super.child,
  });

  final ValueListenable<SwipeFrame> frame;

  /// VoiceOver özel eylemleri (Olur, Pas, Çok isterim, Olmaz). Yalnızca ön kartta dolu.
  final Map<CustomSemanticsAction, VoidCallback> actions;

  static DeckCardScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DeckCardScope>();

  @override
  bool updateShouldNotify(DeckCardScope old) =>
      old.frame != frame || !mapEquals(old.actions, actions);
}

/// Sürükleme sırasında kartın üstündeki karar etiketi ve renk tonu (DESIGN_SYSTEM.md §10
/// "SwipeDeck" tablosu, mockup `DeckSwipe`). Etiket opaklığı eşiğe kadar 0→1, ton eşikte en
/// fazla %20. Dokunmayı ve VoiceOver'ı etkilemez.
class DeckDecisionOverlay extends StatelessWidget {
  const DeckDecisionOverlay({super.key, required this.frame});

  final ValueListenable<SwipeFrame> frame;

  static const double _labelTop = 20;
  static const double _labelSide = 16;
  static const double _labelMinHeight = 36;
  static const double _labelPadding = 14;
  static const double _labelGap = 6;
  static const double _iconSize = 18;
  static const double _vetoBorder = 1.5;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: ValueListenableBuilder<SwipeFrame>(
          valueListenable: frame,
          builder: (context, f, _) {
            final d = f.direction;
            if (d == null || f.progress <= 0) return const SizedBox.shrink();
            final style = _styleOf(context, d);
            return Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: style.tint.withValues(alpha: f.tintAlpha)),
                Positioned(
                  top: _labelTop,
                  left: d == DeckDecision.pass ? null : _labelSide,
                  right: d == DeckDecision.pass ? _labelSide : null,
                  child: Opacity(
                    opacity: f.labelOpacity,
                    child: _label(context, d, style),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _label(BuildContext context, DeckDecision d, _Style style) {
    final l10n = AppLocalizations.of(context);
    final text = switch (d) {
      DeckDecision.ok => l10n.deckDecisionOk,
      DeckDecision.pass => l10n.deckDecisionPass,
      DeckDecision.love => l10n.deckDecisionLove,
      DeckDecision.veto => l10n.deckDecisionVeto,
    };
    final veto = d == DeckDecision.veto;
    return DecoratedBox(
      decoration: AppRadius.decoration(
        radius: AppRadius.pill,
        color: style.background,
        side: veto
            ? BorderSide(color: style.foreground, width: _vetoBorder)
            : null,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: _labelMinHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _labelPadding),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(style.icon, size: _iconSize, color: style.foreground),
              const SizedBox(width: _labelGap),
              Text(
                text,
                style: context.text.title.copyWith(
                  color: style.foreground,
                  decoration: veto ? TextDecoration.lineThrough : null,
                  decorationColor: style.foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Style _styleOf(BuildContext context, DeckDecision d) {
    final c = context.colors;
    return switch (d) {
      DeckDecision.ok => _Style(
        tint: c.brandMuted,
        background: c.brandSoft,
        foreground: c.brand,
        icon: AppIcons.check,
      ),
      DeckDecision.pass => _Style(
        tint: c.textTertiary,
        background: c.surfaceMuted,
        foreground: c.textPrimary,
        icon: AppIcons.close,
      ),
      DeckDecision.love => _Style(
        tint: c.brand,
        background: c.brand,
        foreground: c.onBrand,
        icon: AppIcons.heartFill,
      ),
      DeckDecision.veto => _Style(
        tint: c.error,
        background: c.surface,
        foreground: c.error,
        icon: AppIcons.prohibit,
      ),
    };
  }
}

class _Style {
  const _Style({
    required this.tint,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final Color tint;
  final Color background;
  final Color foreground;
  final IconData icon;
}
