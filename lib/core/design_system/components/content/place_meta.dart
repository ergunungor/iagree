import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';

/// Mekan meta bilgisi: puan, kategori, fiyat seviyesi, mesafe. `DeckCard`, `ResultCard` ve
/// `VoteOption` aynı biçimi kullanır (DESIGN_SYSTEM.md: sayılar Türkçe biçimde: `4,7`,
/// `1,2 km`, `650 m`). Boş öğeler atlanır; en fazla 4 öğe olur.
@immutable
class PlaceMeta {
  const PlaceMeta({
    this.rating,
    this.category,
    this.priceLevel,
    this.distanceKm,
  }) : assert(priceLevel == null || (priceLevel >= 1 && priceLevel <= 3));

  final double? rating;
  final String? category;

  /// 1–3: ₺ / ₺₺ / ₺₺₺.
  final int? priceLevel;
  final double? distanceKm;

  static NumberFormat _oneDecimal(BuildContext context) =>
      NumberFormat.decimalPatternDigits(
        locale: Localizations.localeOf(context).toLanguageTag(),
        decimalDigits: 1,
      );

  /// "4,7"; yoksa null.
  String? ratingText(BuildContext context) =>
      rating == null ? null : _oneDecimal(context).format(rating);

  /// "₺₺"; yoksa null.
  String? get priceText => priceLevel == null ? null : '₺' * priceLevel!;

  /// Mesafe birimi ve değeri: 1 km altı metre (en yakın 10'a yuvarlı), üstü kilometre.
  /// Yuvarlama 1000 m'ye varırsa kilometreye geçer; tam kilometre ondalıksız ("1 km").
  (bool, String)? _distance(BuildContext context) {
    final km = distanceKm;
    if (km == null) return null;
    final meters = (km * 100).round() * 10;
    if (km < 1 && meters < 1000) return (true, '$meters');
    final locale = Localizations.localeOf(context).toLanguageTag();
    final whole = (km * 10).round() % 10 == 0;
    return (
      false,
      whole
          ? NumberFormat.decimalPattern(locale).format(km.round())
          : _oneDecimal(context).format(km),
    );
  }

  /// "650 m" ya da "1,2 km"; yoksa null.
  String? distanceText(BuildContext context) {
    final d = _distance(context);
    if (d == null) return null;
    final l10n = AppLocalizations.of(context);
    return d.$1
        ? l10n.placeDistanceMeters(int.parse(d.$2))
        : l10n.deckDistance(d.$2);
  }

  /// "650 metre" ya da "1,2 kilometre"; yoksa null.
  String? spokenDistance(BuildContext context) {
    final d = _distance(context);
    if (d == null) return null;
    final l10n = AppLocalizations.of(context);
    return d.$1
        ? l10n.placeDistanceMetersSemantics(int.parse(d.$2))
        : l10n.deckDistanceSemantics(d.$2);
  }

  /// Görünen parçalar: puan, kategori, fiyat, mesafe (olanlar).
  ///
  /// [includeRating] false ise puan yazılmaz (sonuçlardaki compact satır: dar alan, mockup).
  List<String> parts(BuildContext context, {bool includeRating = true}) => [
    if (includeRating) ?ratingText(context),
    ?category,
    ?priceText,
    ?distanceText(context),
  ];

  /// "4,7 · Kahve · ₺ · 650 m".
  String plain(BuildContext context, {bool includeRating = true}) =>
      parts(context, includeRating: includeRating).join(' · ');

  /// VoiceOver parçaları: "4,7 puan", "Kahve", "uygun fiyat", "650 metre". Sayıya ek yok.
  List<String> spokenParts(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      if (rating != null) l10n.deckRatingSemantics(ratingText(context)!),
      ?category,
      if (priceLevel != null)
        switch (priceLevel!) {
          1 => l10n.deckPriceLow,
          2 => l10n.deckPriceMid,
          _ => l10n.deckPriceHigh,
        },
      ?spokenDistance(context),
    ];
  }

  String spoken(BuildContext context) => spokenParts(context).join(', ');
}
