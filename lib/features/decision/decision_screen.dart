import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../core/design_system/components/decision/decision_moment.dart';
import '../../core/design_system/components/people/app_avatar_group.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../l10n/app_localizations.dart';
import 'candidate_views.dart';

/// D8 · Karar anı (SCREENS D8): oybirliğinde animasyonlu karar anı, çoğunlukta sakin sonuç
/// ekranı. [animate] false ise (geçmişten yeniden açılış) koreografi oynatılmaz.
class DecisionScreen extends StatelessWidget {
  const DecisionScreen({
    super.key,
    required this.roomId,
    required this.animate,
  });

  final String roomId;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final room = scope.rooms.room(roomId);
    final d = room?.decision;
    if (d == null) {
      return Scaffold(backgroundColor: context.colors.canvas);
    }
    final c = d.candidate;
    return Scaffold(
      body: DecisionMoment(
        isUnanimous: d.unanimous,
        animate: animate,
        participants: [
          for (final m in d.members)
            AppAvatarPerson(userId: m.id, name: m.name),
        ],
        placeName: c.name,
        photo: CandidateViews.photo(context, c),
        meta: CandidateViews.meta(c),
        loveCount: d.loveCount,
        okCount: d.okCount,
        total: d.total,
        votes: d.votes,
        totalVotes: d.totalVotes,
        onDirections: () =>
            scope.opener.open(Uri.https('maps.apple.com', '/', {'q': c.name})),
        onShare: () =>
            scope.sharer.share(l10n.decisionShareText(c.name, d.whenLabel)),
        onClose: () => Navigator.of(context).popUntil((r) => r.isFirst),
      ),
    );
  }
}
