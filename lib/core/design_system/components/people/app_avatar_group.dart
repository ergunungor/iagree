import 'package:flutter/material.dart';

import '../../foundations/context_extensions.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import 'app_avatar.dart';

/// [AppAvatarGroup]'taki bir kişi.
class AppAvatarPerson {
  const AppAvatarPerson({required this.userId, required this.name, this.image});

  final String userId;
  final String name;
  final ImageProvider? image;
}

/// Üst üste binen avatar grubu (DESIGN_SYSTEM.md §10 "Avatar").
///
/// %30 üst üste, her avatarın çevresinde [ringColor] halka (varsayılan `canvas`, 2px), en
/// fazla [maxVisible] avatar ve sığmayanlar için `surfaceMuted` pill "+N" sayacı. **Oda sahibi
/// listenin ilk elemanı olmalıdır** (sıralama çağırana aittir).
class AppAvatarGroup extends StatelessWidget {
  const AppAvatarGroup({
    super.key,
    required this.people,
    this.size = AppAvatarSize.sm,
    this.maxVisible = 4,
    this.ringColor,
    this.ringWidth = 2,
    this.semanticLabel,
  }) : assert(maxVisible > 0);

  final List<AppAvatarPerson> people;
  final AppAvatarSize size;
  final int maxVisible;

  /// Boşsa `canvas`. Karar anında `momentBg`.
  final Color? ringColor;
  final double ringWidth;

  /// Grubun tek öğe olarak okunan etiketi (örn. "Ayşe, Can ve 3 kişi daha"); yerelleştirilmiş
  /// olmalı. Boşsa grup süs sayılır.
  final String? semanticLabel;

  /// Bir sonraki avatar, öncekinin bu kadarını (%30) kaplar.
  static const double overlap = 0.3;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final ring = ringColor ?? c.canvas;
    final visible = people.take(maxVisible).toList();
    final hidden = people.length - visible.length;
    final dimension = size.dimension;

    Widget avatar(AppAvatarPerson p) => DecoratedBox(
      decoration: AppRadius.circle(color: ring),
      child: Padding(
        padding: EdgeInsets.all(ringWidth),
        child: AppAvatar(
          userId: p.userId,
          name: p.name,
          image: p.image,
          size: size,
        ),
      ),
    );

    Widget counter() => DecoratedBox(
      decoration: AppRadius.decoration(radius: AppRadius.pill, color: ring),
      child: Padding(
        padding: EdgeInsets.all(ringWidth),
        child: DecoratedBox(
          decoration: AppRadius.decoration(
            radius: AppRadius.pill,
            color: c.surfaceMuted,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: dimension,
              minHeight: dimension,
            ),
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  '+$hidden',
                  textScaler: TextScaler.noScaling,
                  maxLines: 1,
                  style: context.text.label.tabular.copyWith(
                    fontSize: dimension * 0.4,
                    height: 1,
                    fontWeight: FontWeight.w600,
                    color: c.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final items = <Widget>[
      for (final p in visible) avatar(p),
      if (hidden > 0) counter(),
    ];

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < items.length; i++)
          // Son öğe dışındakiler genişliğinin %70'ini yer tutar; sonraki bindirir.
          Align(
            alignment: Alignment.centerLeft,
            widthFactor: i == items.length - 1 ? 1 : 1 - overlap,
            child: items[i],
          ),
      ],
    );

    if (semanticLabel == null) return ExcludeSemantics(child: row);
    return Semantics(label: semanticLabel, excludeSemantics: true, child: row);
  }
}
