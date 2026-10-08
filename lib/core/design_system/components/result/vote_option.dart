import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../content/app_card.dart';
import '../content/app_list_group.dart';
import '../content/place_meta.dart';
import '../people/app_avatar.dart';
import '../people/app_avatar_group.dart';
import 'result_card.dart';

/// Sonuç seçeneği, **oy sonrası** (DESIGN_SYSTEM.md §10 "VoteOption"): uyum yayları kaybolur,
/// her seçenekte oy verenlerin avatarları ve oy sayısı görünür; önde olan 2px `brand` ile
/// vurgulanır. Oy öncesi görünüm [ResultCard]'dır.
///
/// **Oy verilene kadar sonuçlar gizlidir:** bu bileşen yalnızca kullanıcı oyunu verdikten
/// sonra, oy verenlerle kurulur. Eşitlikte ([isLeading] hiçbirinde yok) "Son söz sende" ekranın
/// işidir. Pas ve veto bu ekranda zaten yoktur.
class VoteOption extends StatelessWidget {
  /// 1. sıradaki seçenek: Media Card (16:10), isim + meta, sağda avatarlar ve oy sayısı.
  const VoteOption.hero({
    super.key,
    required this.name,
    required this.photo,
    required this.voters,
    this.meta = const PlaceMeta(),
    this.isLeading = false,
    this.isMine = false,
  });

  final String name;
  final Widget photo;

  /// Bu seçeneğe oy verenler (kullanıcının kendisi dahilse adı "Sen" gibi çağıran tarafından
  /// yerelleştirilmiş verilir). Boşsa "oy yok".
  final List<AppAvatarPerson> voters;

  final PlaceMeta meta;

  /// Önde olan seçenek: 2px `brand`.
  final bool isLeading;

  /// Kullanıcının kendi oyu bu seçenekte: ✓ işareti.
  final bool isMine;

  /// 2. ve 3. sıradaki seçenek: bir [AppListGroup] satırı (56 thumbnail, isim, avatarlar,
  /// sayı). [isLeading] ise satır 2px `brand` halkayla vurgulanır.
  static AppListRow compact({
    Key? key,
    required BuildContext context,
    required String name,
    required Widget photo,
    required List<AppAvatarPerson> voters,
    bool isLeading = false,
    bool isMine = false,
  }) {
    return AppListRow(
      key: key,
      title: name,
      emphasized: true,
      leading: resultThumb(photo),
      leadingExtent: 56,
      trailing: _VoteCount(voters: voters),
      verticalPadding: AppSpacing.xs,
      highlighted: isLeading,
      semanticLabel: _label(
        AppLocalizations.of(context),
        name: name,
        voters: voters,
        isLeading: isLeading,
        isMine: isMine,
      ),
    );
  }

  static String _label(
    AppLocalizations l10n, {
    required String name,
    required List<AppAvatarPerson> voters,
    required bool isLeading,
    required bool isMine,
  }) {
    final base = voters.isEmpty
        ? l10n.voteOptionNoVotes(name)
        : (isLeading ? l10n.voteOptionVotesLeading : l10n.voteOptionVotes)(
            name,
            voters.length,
            voters.map((v) => v.name).join(', '),
          );
    return resultSentence([base, if (isMine) l10n.voteOptionMine]);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final metaText = meta.plain(context);

    return AppCard(
      mediaAspectRatio: ResultCard.mediaAspectRatio,
      media: Stack(
        fit: StackFit.expand,
        children: [
          photo,
          if (isMine)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: ExcludeSemantics(child: resultBadge(selected: true)),
            ),
        ],
      ),
      selected: isLeading,
      child: Semantics(
        container: true,
        label: _label(
          l10n,
          name: name,
          voters: voters,
          isLeading: isLeading,
          isMine: isMine,
        ),
        child: ExcludeSemantics(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.h3,
                    ),
                    if (metaText.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        metaText,
                        style: text.caption.tabular.copyWith(
                          color: c.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _VoteCount(voters: voters),
            ],
          ),
        ),
      ),
    );
  }
}

/// Oy verenlerin avatarları + oy sayısı (`title`, tabular). 0 oyda avatar yok, sayı
/// `textTertiary`.
class _VoteCount extends StatelessWidget {
  const _VoteCount({required this.voters});

  final List<AppAvatarPerson> voters;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (voters.isNotEmpty) ...[
          AppAvatarGroup(
            people: voters,
            size: AppAvatarSize.sm,
            ringColor: c.surface,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          '${voters.length}',
          style: context.text.title.tabular.copyWith(
            color: voters.isEmpty ? c.textTertiary : c.textPrimary,
          ),
        ),
      ],
    );
  }
}
