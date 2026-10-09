import 'package:flutter/material.dart';

import '../../app/link_actions.dart';
import '../../core/design_system/components/content/app_list_group.dart';
import '../../core/design_system/components/content/app_status_tag.dart';
import '../../core/design_system/components/deck/deck_action_bar.dart';
import '../../core/design_system/components/deck/swipe_deck.dart';
import '../../core/design_system/components/feedback/app_sheet.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/design_system/tokens/app_radius.dart';
import '../../core/design_system/tokens/app_spacing.dart';
import '../../core/domain/candidate.dart';
import '../../core/domain/room_catalog.dart';
import '../../l10n/app_localizations.dart';
import 'candidate_views.dart';

/// D5 · Detay sheet'i: karta dokununca açılır, Large detent. Mekanda fotoğraflar, adres
/// (Apple Maps), saatler ve menü/web bağlantısı; filmde platform, özet ve oyuncular. Altta
/// destenin dört aksiyonu sheet içinden de verilebilir: karar verilince sheet kapanır ve kart
/// destede uçar.
Future<void> showCandidateDetails(
  BuildContext context, {
  required Candidate candidate,
  required SwipeDeckController controller,
}) {
  return AppSheet.show<void>(
    context,
    title: candidate.name,
    detents: const [AppSheetDetent.large],
    builder: (_) => _Details(candidate: candidate),
    footer: Builder(
      builder: (sheetContext) => DeckActionBar(
        controller: controller,
        onAction: () => Navigator.of(sheetContext).pop(),
      ),
    ),
  );
}

class _Details extends StatelessWidget {
  const _Details({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        candidate.kind == RoomKind.film
            ? _Film(candidate: candidate)
            : _Place(candidate: candidate),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.parts, this.closing});

  final List<String> parts;
  final int? closing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          parts.join(' · '),
          style: context.text.bodySmall.copyWith(color: c.textSecondary),
        ),
        if (closing != null)
          Text(
            l10n.deckClosing(closing!),
            style: context.text.caption.copyWith(color: c.warning),
          ),
      ],
    );
  }
}

class _Place extends StatelessWidget {
  const _Place({required this.candidate});

  final Candidate candidate;

  static const double _photoWidth = 280;
  static const double _photoHeight = 200;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = candidate;
    final address = c.address;
    final website = c.websiteUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _photoHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: c.tintIndexes.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.xs),
            itemBuilder: (context, i) => ClipPath(
              clipper: ShapeBorderClipper(
                shape: AppRadius.border(AppRadius.md),
              ),
              child: SizedBox(
                width: _photoWidth,
                child: CandidateViews.photo(context, c, i),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _MetaLine(
          parts: CandidateViews.meta(c).parts(context),
          closing: c.closingInMinutes,
        ),
        const SizedBox(height: AppSpacing.md),
        AppListGroup(
          children: [
            if (address != null)
              AppListRow(
                title: l10n.detailAddress,
                subtitle: address,
                showsChevron: true,
                semanticLabel:
                    '${l10n.detailAddress}, $address. '
                    '${l10n.detailOpenMap}',
                onPressed: () => openExternal(
                  context,
                  Uri.https('maps.apple.com', '/', {
                    'q': c.name,
                    'address': address,
                  }),
                ),
              ),
            if (c.hoursLabel != null)
              AppListRow(
                title: l10n.detailHours,
                subtitle: c.hoursLabel,
                semanticLabel: '${l10n.detailHours}, ${c.hoursLabel}',
              ),
            if (website != null)
              AppListRow(
                title: l10n.detailWebsite,
                subtitle: Uri.parse(website).host,
                showsChevron: true,
                onPressed: () => openExternal(context, Uri.parse(website)),
              ),
          ],
        ),
      ],
    );
  }
}

class _Film extends StatelessWidget {
  const _Film({required this.candidate});

  final Candidate candidate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final text = context.text;
    final c = candidate;
    final meta = [
      ?CandidateViews.meta(c).ratingText(context),
      ?c.genre,
      if (c.durationMinutes != null) l10n.detailRuntime(c.durationMinutes!),
    ];

    Widget heading(String s) => Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.xs),
      child: Semantics(header: true, child: Text(s, style: text.title)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MetaLine(parts: meta),
        if (c.platform != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                l10n.detailPlatform,
                style: text.bodySmall.copyWith(color: colors.textSecondary),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppStatusTag.neutral(label: c.platform!),
            ],
          ),
        ],
        if (c.synopsis != null) ...[
          heading(l10n.detailSynopsis),
          Text(c.synopsis!, style: text.body),
        ],
        if (c.cast.isNotEmpty) ...[
          heading(l10n.detailCast),
          Text(
            c.cast.join(', '),
            style: text.body.copyWith(color: colors.textSecondary),
          ),
        ],
      ],
    );
  }
}
