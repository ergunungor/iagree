import 'package:flutter/material.dart';

import '../../core/design_system/components/content/place_meta.dart';
import '../../core/design_system/components/deck/deck_card.dart';
import '../../core/design_system/foundations/context_extensions.dart';
import '../../core/domain/candidate.dart';
import '../../core/domain/room_catalog.dart';

/// [Candidate] verisini tasarım sistemi bileşenlerine çeviren yardımcılar. Fotoğraf/afiş
/// gelene kadar avatar tint'leriyle yer tutucu çizilir.
abstract final class CandidateViews {
  static Widget photo(BuildContext context, Candidate c, [int index = 0]) {
    final tints = context.colors.avatarTints;
    final i = c.tintIndexes[index % c.tintIndexes.length];
    return ColoredBox(color: tints[i % tints.length]);
  }

  static PlaceMeta meta(Candidate c) => PlaceMeta(
    rating: c.rating,
    category: c.kind == RoomKind.film ? c.genre : c.categoryLabel,
    priceLevel: c.priceLevel,
    distanceKm: c.distanceKm,
  );

  static Widget deckCard(
    BuildContext context,
    Candidate c, {
    VoidCallback? onDetails,
  }) {
    if (c.kind == RoomKind.film) {
      return DeckCard.film(
        name: c.name,
        poster: photo(context, c),
        rating: c.rating,
        genre: c.genre,
        durationMinutes: c.durationMinutes,
        platform: c.platform,
        closingInMinutes: c.closingInMinutes,
        onDetailsTap: onDetails,
      );
    }
    return DeckCard.place(
      name: c.name,
      photos: [
        for (var i = 0; i < c.tintIndexes.length; i++) photo(context, c, i),
      ],
      rating: c.rating,
      category: c.categoryLabel,
      priceLevel: c.priceLevel,
      distanceKm: c.distanceKm,
      closingInMinutes: c.closingInMinutes,
      onDetailsTap: onDetails,
    );
  }
}
