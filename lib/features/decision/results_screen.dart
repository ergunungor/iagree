import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/app_router.dart';
import '../../app/app_scope.dart';
import '../../app/rooms_controller.dart';
import '../../core/data/mock/mock_rooms_repository.dart';
import '../../core/design_system/components/buttons/app_button.dart';
import '../../core/design_system/components/content/app_list_group.dart';
import '../../core/design_system/components/feedback/app_empty_state.dart';
import '../../core/design_system/components/feedback/app_skeleton.dart';
import '../../core/design_system/components/feedback/app_toast.dart';
import '../../core/design_system/components/navigation/app_nav_bar.dart';
import '../../core/design_system/components/people/app_avatar_group.dart';
import '../../core/design_system/components/result/result_card.dart';
import '../../core/design_system/components/result/vote_option.dart';
import '../../core/design_system/foundations/app_haptics.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_radius.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/domain/candidate.dart';
import '../../core/domain/room.dart';
import '../../l10n/app_localizations.dart';
import 'candidate_views.dart';

/// D7 · Sonuçlar (SCREENS D7): en fazla 3 seçenek. Oy öncesi tek seçim + "Oyumu ver"; oy
/// sonrası uyum yayları kaybolur, oy verenler görünür. Herkes oy verince karar anına geçilir.
///
/// Eşitlikte oda sahibinin "Son söz sende" seçimi henüz yok (sahte motor eşitliği çözüyor).
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key, required this.roomId});

  final String roomId;

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  RoomResults? _results;
  bool _failed = false;
  late final RoomsController _rooms;
  bool _started = false;
  bool _busy = false;
  bool _left = false;
  int _selected = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _rooms = AppScope.of(context).rooms..addListener(_onChange);
    _load();
  }

  @override
  void dispose() {
    _rooms.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (_left || !mounted) return;
    final room = AppScope.of(context).rooms.room(widget.roomId);
    if (room?.stage == RoomStage.decided) {
      _left = true;
      AppRoutes.replaceWithDecision(context, widget.roomId, animate: true);
    }
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final r = await AppScope.of(context).rooms.results(widget.roomId);
      if (!mounted) return;
      setState(() {
        _results = r;
        final mine = r.options.indexWhere((o) => o.candidate.id == r.myVoteId);
        if (mine >= 0) _selected = mine;
      });
    } on Object {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _vote() async {
    final results = _results;
    if (results == null || _busy) return;
    setState(() => _busy = true);
    try {
      await AppScope.of(context).rooms
          .vote(widget.roomId, results.options[_selected].candidate.id);
      await _load();
      AppHaptics.success();
    } on Object {
      if (!mounted) return;
      AppHaptics.error();
      AppToast.show(
        context,
        message: AppLocalizations.of(context).resultsVoteFailed,
        kind: AppToastKind.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final results = _results;
    return Scaffold(
      backgroundColor: context.colors.canvas,
      appBar: AppInlineNavBar(
        title: l10n.resultsTitle,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: _failed
          ? Align(
              alignment: const Alignment(0, -0.35),
              child: AppEmptyState.error(
                title: l10n.homeLoadFailedTitle,
                message: l10n.homeLoadFailedBody,
                actionLabel: l10n.homeRetry,
                onAction: _load,
              ),
            )
          : results == null
          ? const _Loading()
          : _Body(
              results: results,
              selected: _selected,
              busy: _busy,
              onSelect: (i) => setState(() => _selected = i),
              onVote: _vote,
              roomId: widget.roomId,
            ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.results,
    required this.selected,
    required this.busy,
    required this.onSelect,
    required this.onVote,
    required this.roomId,
  });

  final RoomResults results;
  final int selected;
  final bool busy;
  final ValueChanged<int> onSelect;
  final VoidCallback onVote;
  final String roomId;

  List<AppAvatarPerson> _people(
    BuildContext context,
    List<RoomMember> members,
  ) {
    final l10n = AppLocalizations.of(context);
    final me = AppScope.of(context).session.user;
    return [
      for (final m in members)
        AppAvatarPerson(
          userId: m.id,
          name: m.id == me?.id || m == results.members.first
              ? l10n.resultsYou
              : m.name,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = results.options;
    final voted = results.iVoted;

    AppListRow optionRow(int i) {
      final o = options[i];
      final c = o.candidate;
      if (voted) {
        return VoteOption.compact(
          context: context,
          name: c.name,
          photo: CandidateViews.photo(context, c),
          voters: _people(context, results.votes[c.id] ?? const []),
          isMine: results.myVoteId == c.id,
        );
      }
      return ResultCard.compact(
        context: context,
        name: c.name,
        photo: CandidateViews.photo(context, c),
        loveCount: o.loveCount,
        okCount: o.okCount,
        total: o.total,
        meta: CandidateViews.meta(c),
        selected: selected == i,
        onSelected: () => onSelect(i),
      );
    }

    final first = options.first;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Semantics(
          header: true,
          child: Text(l10n.resultsHeading, style: context.text.h1),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (voted)
          VoteOption.hero(
            name: first.candidate.name,
            photo: CandidateViews.photo(context, first.candidate),
            meta: CandidateViews.meta(first.candidate),
            voters: _people(
              context,
              results.votes[first.candidate.id] ?? const [],
            ),
            isLeading: true,
            isMine: results.myVoteId == first.candidate.id,
          )
        else
          ResultCard.hero(
            name: first.candidate.name,
            photo: CandidateViews.photo(context, first.candidate),
            loveCount: first.loveCount,
            okCount: first.okCount,
            total: first.total,
            meta: CandidateViews.meta(first.candidate),
            lovers: [
              for (final m in first.lovers)
                AppAvatarPerson(userId: m.id, name: m.name),
            ],
            selected: selected == 0,
            onSelected: () => onSelect(0),
          ),
        if (options.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          AppListGroup(
            children: [for (var i = 1; i < options.length; i++) optionRow(i)],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (!voted)
          AppButton.primary(
            label: l10n.resultsVote,
            isLoading: busy,
            onPressed: onVote,
          )
        else ...[
          if (results.waitingCount > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Text(
                l10n.resultsWaiting(results.waitingCount),
                textAlign: TextAlign.center,
                style: context.text.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ),
          AppButton.secondary(
            label: l10n.resultsNudge,
            onPressed: () =>
                AppToast.show(context, message: l10n.resultsNudged),
          ),
          if (kDebugMode) _DebugVote(roomId: roomId),
        ],
      ],
    );
  }
}

/// Debug: diğer kişilerin oy vermesini taklit eder.
class _DebugVote extends StatelessWidget {
  const _DebugVote({required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    final rooms = AppScope.of(context).rooms;
    final repo = rooms.repository;
    if (repo is! MockRoomsRepository) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: AppButton.tertiary(
        label: 'Herkes oy verdi (debug)',
        size: AppButtonSize.small,
        fullWidth: false,
        onPressed: () {
          repo.simulateEveryoneVoted(roomId);
          rooms.refresh();
        },
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSkeleton(height: 38),
          SizedBox(height: AppSpacing.lg),
          AppSkeleton(height: 280, radius: AppRadius.lg),
          SizedBox(height: AppSpacing.sm),
          AppSkeleton(height: 130, radius: AppRadius.lg),
        ],
      ),
    );
  }
}
