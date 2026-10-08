import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_fixed_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../agreement/agreement_arc.dart';
import '../content/app_card.dart';
import '../content/app_list_group.dart';
import '../content/place_meta.dart';
import '../people/app_avatar.dart';
import '../people/app_avatar_group.dart';
import '../selection/app_check_circle.dart';

/// Sonuç seçeneği, **oy öncesi** (DESIGN_SYSTEM.md §10 "ResultCard"): uyum yayı + tek seçim.
/// Oy sonrası görünüm [VoteOption]'dır.
///
/// Sonuçlarda en fazla 3 seçenek vardır. 1. sıra [ResultCard.hero], 2–3 [ResultCard.compact]
/// satırı (bir [AppListGroup] içinde).
///
/// **Gizlilik:** bu bileşen yalnızca "Çok isterim" diyenleri ([lovers]) isimle gösterebilir.
/// Pas, veto ve Olur için parametre yoktur; yani yanlışlıkla gösterilemez. Final oyları da
/// buraya hiç girmez: oy verilene kadar gizlidir.
class ResultCard extends StatelessWidget {
  /// 1. sıradaki seçenek: Media Card (16:10), isim, meta, sağda Arc M, gerekçe ve sevenler.
  const ResultCard.hero({
    super.key,
    required this.name,
    required this.photo,
    required this.loveCount,
    required this.okCount,
    required this.total,
    this.meta = const PlaceMeta(),
    this.lovers = const [],
    this.reasons = const [],
    this.selected = false,
    this.onSelected,
  }) : assert(reasons.length <= 2, 'Gerekçe satırı en fazla 2 öğe.');

  final String name;

  /// Fotoğraf; verilen alanı doldurur (`Image(fit: BoxFit.cover)` gibi).
  final Widget photo;

  /// "Çok isterim" ve "Olur" diyenler ile toplam kişi (Arc yüzdeyi bunlardan hesaplar).
  final int loveCount;
  final int okCount;
  final int total;

  final PlaceMeta meta;

  /// Çok isteyenler; xs avatarlar ve "Ayşe ve Can çok istiyor". Boşsa satır yok.
  final List<AppAvatarPerson> lovers;

  /// Verideki gerekçeler (örn. "Hepinize yakın", "Açık"); en fazla 2, " · " ile. Boşsa
  /// gösterilmez.
  final List<String> reasons;

  /// Tek seçimde bu seçenek seçili mi.
  final bool selected;

  /// Verilirse kart seçilebilir (oy öncesi); null ise yalnızca gösterim.
  final VoidCallback? onSelected;

  /// Hero görsel oranı (16:10).
  static const double mediaAspectRatio = 16 / 10;

  static const double _badgeSize = 28;
  static const double _badgeInset = AppSpacing.sm;
  static const double _badgeRing = 2;
  static const double _thumb = 56;
  static const double _rowPadding = AppSpacing.xs;

  /// 2. ve 3. sıradaki seçenek: bir [AppListGroup] satırı. Solda Check Circle ([onSelected]
  /// verilirse), 56 thumbnail, `title` + `caption`, sağda Arc S.
  static AppListRow compact({
    Key? key,
    required BuildContext context,
    required String name,
    required Widget photo,
    required int loveCount,
    required int okCount,
    required int total,
    PlaceMeta meta = const PlaceMeta(),
    bool selected = false,
    VoidCallback? onSelected,
  }) {
    final l10n = AppLocalizations.of(context);
    final selectable = onSelected != null;
    // Dar satırda puan yazılmaz (mockup); VoiceOver cümlesinde puan vardır.
    final metaText = meta.plain(context, includeRating: false);
    final label = resultSentence([
      name,
      meta.spoken(context),
      AgreementArc.semanticsOf(
        l10n,
        loveCount: loveCount,
        okCount: okCount,
        total: total,
      ),
    ]);

    return AppListRow(
      key: key,
      title: name,
      emphasized: true,
      subtitle: metaText.isEmpty ? null : metaText,
      leading: Row(
        children: [
          if (selectable) ...[
            AppCheckCircle(selected: selected),
            const SizedBox(width: AppSpacing.sm),
          ],
          _Thumb(photo),
        ],
      ),
      leadingExtent:
          _thumb + (selectable ? AppCheckCircle.size + AppSpacing.sm : 0),
      trailing: AgreementArc(
        loveCount: loveCount,
        okCount: okCount,
        total: total,
        size: AgreementArcSize.small,
      ),
      verticalPadding: _rowPadding,
      semanticLabel: label,
      semanticSelected: selectable ? selected : null,
      onPressed: onSelected,
    );
  }

  String _lovers(AppLocalizations l10n) {
    final n = lovers.map((p) => p.name).toList();
    return switch (n.length) {
      0 => '',
      1 => l10n.resultLovers1(n[0]),
      2 => l10n.resultLovers2(n[0], n[1]),
      3 => l10n.resultLovers3(n[0], n[1], n[2]),
      _ => l10n.resultLoversMore(n[0], n[1], n.length - 2),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = context.text;
    final l10n = AppLocalizations.of(context);
    final metaText = meta.plain(context);
    final loversText = _lovers(l10n);

    final label = resultSentence([
      name,
      meta.spoken(context),
      AgreementArc.semanticsOf(
        l10n,
        loveCount: loveCount,
        okCount: okCount,
        total: total,
      ),
      loversText,
    ]);

    final secondary = text.caption.tabular.copyWith(color: c.textSecondary);

    return AppCard(
      mediaAspectRatio: mediaAspectRatio,
      media: Stack(
        fit: StackFit.expand,
        children: [
          photo,
          Positioned(
            top: _badgeInset,
            right: _badgeInset,
            child: ExcludeSemantics(child: _Badge(selected: selected)),
          ),
        ],
      ),
      selected: selected,
      onPressed: onSelected,
      semanticLabel: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      Text(metaText, style: secondary),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AgreementArc(
                loveCount: loveCount,
                okCount: okCount,
                total: total,
                size: AgreementArcSize.medium,
              ),
            ],
          ),
          if (reasons.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(reasons.take(2).join(' · '), style: secondary),
          ],
          if (lovers.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                AppAvatarGroup(
                  people: lovers,
                  size: AppAvatarSize.xs,
                  ringColor: c.surface,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(child: Text(loversText, style: secondary)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Fotoğrafın sağ üstündeki seçim işareti: seçiliyken `brand` ✓ (2px `surface` halka),
/// değilken `mediaOverlay` dolgu + `onMedia` halka (seçilebilir olduğu görünsün).
class _Badge extends StatelessWidget {
  const _Badge({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return DecoratedBox(
      decoration: AppRadius.circle(
        color: selected ? c.brand : AppFixedColors.mediaOverlay,
        side: BorderSide(
          color: selected ? c.surface : AppFixedColors.onMedia,
          width: ResultCard._badgeRing,
        ),
      ),
      child: SizedBox.square(
        dimension: ResultCard._badgeSize,
        child: selected
            ? Icon(AppIcons.check, size: AppIconSize.s16, color: c.onBrand)
            : null,
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb(this.photo);

  final Widget photo;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: ResultCard._thumb,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: AppRadius.border(AppRadius.sm)),
        child: photo,
      ),
    );
  }
}

/// VoiceOver cümlesi: parçalar birer cümle olur ("A. B. C.").
String resultSentence(List<String> parts) => parts
    .where((p) => p.isNotEmpty)
    .map((p) => p.endsWith('.') ? p : '$p.')
    .join(' ');

/// Başka dosyalar da (VoteOption) aynı küçük resmi kullanır.
Widget resultThumb(Widget photo) => _Thumb(photo);

/// Aynı seçim işareti (VoteOption'da "senin oyun").
Widget resultBadge({required bool selected}) => _Badge(selected: selected);
