import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../core/design_system/components/deck/swipe_deck_physics.dart';
import '../../core/design_system/components/deck/swipe_deck_scaffold.dart';
import '../../core/design_system/components/feedback/app_empty_state.dart';
import '../../core/design_system/components/feedback/app_skeleton.dart';
import '../../core/design_system/components/feedback/app_toast.dart';
import '../../core/design_system/components/buttons/app_icon_button.dart';
import '../../core/design_system/foundations/app_haptics.dart';
import '../../core/design_system/foundations/app_icons.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_radius.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/domain/candidate.dart';
import '../../l10n/app_localizations.dart';
import 'candidate_views.dart';

/// D4 · Deste (SCREENS D4): tam ekran kart destesi. Kararlar bellekte toplanır (geri alma
/// destekli) ve deste bitince tek seferde gönderilir; sonra Bekleme ekranına geçilir.
class DeckScreen extends StatefulWidget {
  const DeckScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<DeckScreen> createState() => _DeckScreenState();
}

class _DeckScreenState extends State<DeckScreen> {
  final Map<String, Pick> _picks = {};
  List<Candidate>? _deck;
  bool _failed = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final deck = await AppScope.of(context).rooms.deck(widget.roomId);
      if (mounted) setState(() => _deck = deck);
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  static Pick _pickOf(DeckDecision d) => switch (d) {
    DeckDecision.ok => Pick.ok,
    DeckDecision.pass => Pick.pass,
    DeckDecision.love => Pick.love,
    DeckDecision.veto => Pick.veto,
  };

  Future<void> _submit() async {
    final rooms = AppScope.of(context).rooms;
    try {
      await rooms.submitPicks(widget.roomId, _picks);
      if (!mounted) return;
      AppRoutes.replaceWithWaiting(context, widget.roomId);
    } on Object {
      if (!mounted) return;
      AppHaptics.error();
      AppToast.show(
        context,
        message: AppLocalizations.of(context).deckSubmitFailed,
        kind: AppToastKind.error,
        actionLabel: AppLocalizations.of(context).homeRetry,
        onAction: _submit,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = AppScope.of(context).settings;
    final deck = _deck;
    return Scaffold(
      backgroundColor: context.colors.canvas,
      body: _failed
          ? _Failed(onRetry: _load)
          : deck == null
          ? const _Loading()
          : SwipeDeckScaffold<Candidate>(
              items: deck,
              showHint: !settings.deckHintSeen,
              onHintShown: settings.markDeckHintSeen,
              onBack: () => Navigator.of(context).maybePop(),
              onSwiped: (c, d) => _picks[c.id] = _pickOf(d),
              onUndo: (c, _) => _picks.remove(c.id),
              onCompleted: _submit,
              itemBuilder: CandidateViews.deckCard,
            ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  static const double _cardAspect = 0.72;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Center(
          child: AspectRatio(
            aspectRatio: _cardAspect,
            child: const AppSkeleton(
              height: double.infinity,
              radius: AppRadius.xl,
            ),
          ),
        ),
      ),
    );
  }
}

class _Failed extends StatelessWidget {
  const _Failed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs),
              child: AppIconButton.plain(
                icon: AppIcons.back,
                semanticLabel: l10n.commonBack,
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: const Alignment(0, -0.35),
              child: AppEmptyState.error(
                title: l10n.homeLoadFailedTitle,
                message: l10n.homeLoadFailedBody,
                actionLabel: l10n.homeRetry,
                onAction: onRetry,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
