import 'package:flutter/widgets.dart';

import '../../core/design_system/foundations/app_icons.dart';

/// Kategori/tema kimliğinden ikon. Kategori listesi veriden geldiği için tanınmayan kimlik
/// "Fark etmez" ikonuna düşer.
abstract final class RoomIcons {
  static IconData category(String id) => switch (id) {
    'food' => AppIcons.food,
    'coffee' => AppIcons.coffee,
    'film' => AppIcons.film,
    'sport' => AppIcons.sport,
    'bar' => AppIcons.bar,
    'concert' => AppIcons.concert,
    'game' => AppIcons.game,
    'outdoor' => AppIcons.outdoor,
    'culture' => AppIcons.culture,
    _ => AppIcons.anything,
  };

  static IconData theme(String id) => switch (id) {
    'rain' => AppIcons.rain,
    'match' => AppIcons.tv,
    'calm' => AppIcons.moon,
    _ => AppIcons.anything,
  };
}
