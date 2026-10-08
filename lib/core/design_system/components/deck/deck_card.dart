import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../foundations/app_icons.dart';
import '../../foundations/app_pressable.dart';
import '../../foundations/context_extensions.dart';
import '../../tokens/app_fixed_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import 'deck_decision_overlay.dart';

/// Deste kartı (DESIGN_SYSTEM.md §10 "SwipeDeck"): yalnızca **statik** kart. Sürükleme, arka
/// kart, üst bar ve butonlar `SwipeDeck`'in işi.
///
/// 3:4 oran, `radius xl`, `surface`, E2. Üstte ~%78 görsel alanı, altında **iki satırlık** bilgi
/// paneli: `h3` isim + `caption` meta. "Açık" bilgisi ve gerekçe yok; yalnızca istisna olarak
/// [closingInMinutes] ile `warning` renkli "Kapanıyor · 45 dk" satırı eklenir. Genişliği
/// ebeveyninden alır (deste ekran − 40 verir).
///
/// - [DeckCard.place]: en fazla 4 fotoğraf; sol yarıya dokunmak önceki, sağ yarıya sonraki
///   fotoğrafa geçirir (uçlarda sabit), üstte segment göstergesi.
/// - [DeckCard.film]: `surfaceMuted` zeminde ortalı 2:3 afiş; meta puan · tür · süre; sağda
///   platform etiketi.
///
/// Yazı büyüyünce bilgi paneli büyür, görsel alanı küçülür; kartın oranı değişmez.
class DeckCard extends StatefulWidget {
  const DeckCard.place({
    super.key,
    required this.name,
    this.photos = const [],
    this.rating,
    this.category,
    this.priceLevel,
    this.distanceKm,
    this.closingInMinutes,
    this.onDetailsTap,
  }) : _film = false,
       poster = null,
       genre = null,
       durationMinutes = null,
       platform = null,
       assert(photos.length <= maxPhotos, 'En fazla $maxPhotos fotoğraf.'),
       assert(priceLevel == null || (priceLevel >= 1 && priceLevel <= 3));

  const DeckCard.film({
    super.key,
    required this.name,
    required this.poster,
    this.rating,
    this.genre,
    this.durationMinutes,
    this.platform,
    this.closingInMinutes,
    this.onDetailsTap,
  }) : _film = true,
       photos = const [],
       category = null,
       priceLevel = null,
       distanceKm = null;

  /// Bir kartta en fazla kaç fotoğraf olur.
  static const int maxPhotos = 4;

  /// Genişlik / yükseklik (3:4).
  static const double aspectRatio = 3 / 4;

  final bool _film;

  /// Mekan/film adı.
  final String name;

  /// Mekan fotoğrafları. Her biri verilen alanı doldurur (`Image(fit: BoxFit.cover)` gibi).
  final List<Widget> photos;

  /// Puan (0–5 / 0–10 çağıran belirler); tek ondalıkla gösterilir.
  final double? rating;
  final String? category;

  /// 1–3: ₺ / ₺₺ / ₺₺₺.
  final int? priceLevel;
  final double? distanceKm;

  /// Verilirse üçüncü satırda `warning` ile "Kapanıyor · N dk".
  final int? closingInMinutes;

  /// Panele dokunulunca (detay sheet'i). Null ise panel dokunulmaz.
  final VoidCallback? onDetailsTap;

  /// Film varyantının afişi.
  final Widget? poster;
  final String? genre;
  final int? durationMinutes;

  /// "Netflix" gibi platform etiketi.
  final String? platform;

  @override
  State<DeckCard> createState() => _DeckCardState();
}

class _DeckCardState extends State<DeckCard> {
  static const double _panelFraction = 0.22;
  static const double _segmentTop = 10;
  static const double _segmentSide = 14;
  static const double _segmentHeight = 3;
  static const double _segmentGap = 4;
  static const double _segmentInactiveAlpha = 0.45;
  static const double _posterAspectRatio = 2 / 3;

  int _index = 0;

  @override
  void didUpdateWidget(DeckCard old) {
    super.didUpdateWidget(old);
    final last = widget.photos.isEmpty ? 0 : widget.photos.length - 1;
    if (_index > last) _index = last;
  }

  void _go(int delta) {
    final next = (_index + delta).clamp(0, widget.photos.length - 1);
    if (next != _index) setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final l10n = AppLocalizations.of(context);
    final shape = AppRadius.border(AppRadius.xl);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: AspectRatio(
        aspectRatio: DeckCard.aspectRatio,
        child: DecoratedBox(
          decoration: AppRadius.decoration(
            radius: AppRadius.xl,
            color: c.surface,
            elevation: context.elevation.e2,
          ),
          child: ClipPath(
            clipper: ShapeBorderClipper(shape: shape),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _withDecisionOverlay(
                        context,
                        widget._film
                            ? _filmArea(context, l10n)
                            : _photoArea(context, l10n),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight * _panelFraction,
                      ),
                      child: _panel(context, l10n),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── görsel alanı ─────────────

  /// `SwipeDeck` ön kartı sürüklenirken fotoğraf alanının üstüne karar etiketi ve tonu çizer.
  Widget _withDecisionOverlay(BuildContext context, Widget area) {
    final scope = DeckCardScope.maybeOf(context);
    if (scope == null) return area;
    return Stack(
      fit: StackFit.expand,
      children: [
        area,
        DeckDecisionOverlay(frame: scope.frame),
      ],
    );
  }

  Widget _photoArea(BuildContext context, AppLocalizations l10n) {
    final c = context.colors;
    final photos = widget.photos;
    if (photos.isEmpty) {
      return ColoredBox(
        color: c.surfaceMuted,
        child: Center(
          child: Icon(
            AppIcons.map,
            size: AppIconSize.s32,
            color: c.textTertiary,
          ),
        ),
      );
    }

    final multiple = photos.length > 1;
    final stack = Stack(
      fit: StackFit.expand,
      children: [
        AnimatedSwitcher(
          duration: context.motion.fast,
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: SizedBox.expand(child: photos[_index]),
          ),
        ),
        if (multiple)
          // Sol yarı önceki, sağ yarı sonraki. Erişilebilirlik için ayarlanabilir düğüm var.
          ExcludeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _go(-1),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _go(1),
                  ),
                ),
              ],
            ),
          ),
        if (multiple)
          Positioned(
            top: _segmentTop,
            left: _segmentSide,
            right: _segmentSide,
            child: ExcludeSemantics(child: _segments(photos.length)),
          ),
      ],
    );

    if (!multiple) return stack;
    final total = photos.length;
    String label(int i) => l10n.deckPhotoSemantics(i + 1, total);
    return Semantics(
      label: label(_index),
      value: label(_index),
      increasedValue: _index < total - 1 ? label(_index + 1) : label(_index),
      decreasedValue: _index > 0 ? label(_index - 1) : label(_index),
      onIncrease: _index < total - 1 ? () => _go(1) : null,
      onDecrease: _index > 0 ? () => _go(-1) : null,
      child: stack,
    );
  }

  Widget _segments(int count) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: _segmentGap),
          Expanded(
            child: SizedBox(
              height: _segmentHeight,
              child: DecoratedBox(
                decoration: AppRadius.decoration(
                  radius: AppRadius.pill,
                  color: i == _index
                      ? AppFixedColors.onMedia
                      : AppFixedColors.onMedia.withValues(
                          alpha: _segmentInactiveAlpha,
                        ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _filmArea(BuildContext context, AppLocalizations l10n) {
    final c = context.colors;
    return ColoredBox(
      color: c.surfaceMuted,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Center(
          child: Semantics(
            image: true,
            label: l10n.deckPosterSemantics(widget.name),
            child: ExcludeSemantics(
              child: AspectRatio(
                aspectRatio: _posterAspectRatio,
                child: DecoratedBox(
                  decoration: AppRadius.decoration(
                    radius: AppRadius.sm,
                    color: c.surfaceMuted,
                    elevation: context.elevation.e2,
                  ),
                  child: ClipPath(
                    clipper: ShapeBorderClipper(
                      shape: AppRadius.border(AppRadius.sm),
                    ),
                    child: widget.poster,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── bilgi paneli ─────────────

  Widget _panel(BuildContext context, AppLocalizations l10n) {
    final c = context.colors;
    final text = context.text;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final oneDecimal = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 1,
    );
    final w = widget;

    final metaStyle = text.caption.tabular.copyWith(color: c.textSecondary);
    final spans = <InlineSpan>[];
    void add(InlineSpan span) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: ' · '));
      spans.add(span);
    }

    if (w.rating != null) {
      add(
        TextSpan(
          children: [
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                AppIcons.starFill,
                size: AppIconSize.s14,
                color: c.textSecondary,
              ),
            ),
            TextSpan(text: ' ${oneDecimal.format(w.rating)}'),
          ],
        ),
      );
    }
    final secondary = w._film ? w.genre : w.category;
    if (secondary != null) add(TextSpan(text: secondary));
    if (!w._film && w.priceLevel != null) {
      add(TextSpan(text: '₺' * w.priceLevel!));
    }
    if (!w._film && w.distanceKm != null) {
      add(TextSpan(text: l10n.deckDistance(oneDecimal.format(w.distanceKm))));
    }
    if (w._film && w.durationMinutes != null) {
      add(TextSpan(text: _duration(l10n, w.durationMinutes!, spoken: false)));
    }

    final name = Text(
      w.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: text.h3,
    );

    final label = [
      w.name,
      if (w._film && w.platform != null) w.platform!,
      if (w.rating != null)
        l10n.deckRatingSemantics(oneDecimal.format(w.rating)),
      ?secondary,
      if (!w._film && w.priceLevel != null)
        switch (w.priceLevel!) {
          1 => l10n.deckPriceLow,
          2 => l10n.deckPriceMid,
          _ => l10n.deckPriceHigh,
        },
      if (!w._film && w.distanceKm != null)
        l10n.deckDistanceSemantics(oneDecimal.format(w.distanceKm)),
      if (w._film && w.durationMinutes != null)
        _duration(l10n, w.durationMinutes!, spoken: true),
      if (w.closingInMinutes != null)
        l10n.deckClosingSemantics(w.closingInMinutes!),
    ].join(', ');

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (w._film && w.platform != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: name),
                  const SizedBox(width: AppSpacing.xs),
                  _platformTag(context, w.platform!),
                ],
              )
            else
              name,
            const SizedBox(height: AppSpacing.xxs),
            if (spans.isNotEmpty)
              Text.rich(
                TextSpan(children: spans),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: metaStyle,
              ),
            if (w.closingInMinutes != null)
              Text(
                l10n.deckClosing(w.closingInMinutes!),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.caption.copyWith(color: c.warning),
              ),
          ],
        ),
      ),
    );

    final actions = DeckCardScope.maybeOf(context)?.actions ?? const {};
    if (w.onDetailsTap == null) {
      return Semantics(
        label: label,
        customSemanticsActions: actions,
        child: ExcludeSemantics(child: content),
      );
    }
    final pressable = AppPressable(
      onPressed: w.onDetailsTap,
      semanticLabel: label,
      semanticHint: l10n.deckDetails,
      scaleOnPress: false,
      builder: (context, pressed) => ExcludeSemantics(child: content),
    );
    if (actions.isEmpty) return pressable;
    // Özel eylemler aynı düğümde birleşsin: VoiceOver tek öğe okur, eylemler rotor'da.
    return MergeSemantics(
      child: Semantics(
        container: true,
        customSemanticsActions: actions,
        child: pressable,
      ),
    );
  }

  Widget _platformTag(BuildContext context, String platform) {
    final c = context.colors;
    return DecoratedBox(
      decoration: AppRadius.decoration(
        radius: AppRadius.xs,
        color: c.surfaceMuted,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.xl),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: Center(
            widthFactor: 1,
            child: Text(
              platform,
              maxLines: 1,
              style: context.text.overline.copyWith(color: c.textSecondary),
            ),
          ),
        ),
      ),
    );
  }

  /// 130 → "2 sa 10 dk"; 120 → "2 sa"; 45 → "45 dk".
  String _duration(AppLocalizations l10n, int minutes, {required bool spoken}) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) {
      return spoken
          ? l10n.deckDurationHMSemantics(h, m)
          : l10n.deckDurationHM(h, m);
    }
    if (h > 0) {
      return spoken ? l10n.deckDurationHSemantics(h) : l10n.deckDurationH(h);
    }
    return spoken ? l10n.deckDurationMSemantics(m) : l10n.deckDurationM(m);
  }
}
