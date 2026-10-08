import 'package:flutter/foundation.dart';

/// Bir odanın kullanıcı açısından durumu. Sıra, Odalarım'daki öncelik sırasıdır (SCREENS C1):
/// sonuçlar hazır (oy ver) → sıra sende (seç) → başkaları bekleniyor.
enum RoomStage { resultsReady, yourTurn, waiting }

/// Sonuç listesinde öne çıkan mekan (hero kartın önizlemesi).
@immutable
class PlacePreview {
  const PlacePreview({
    required this.name,
    required this.agreementPercent,
    this.tintIndex = 0,
  });

  final String name;

  /// 0–100.
  final int agreementPercent;

  /// Fotoğraf gelene kadar yer tutucu zemin rengi (avatar tint dizisinden).
  final int tintIndex;
}

/// Odalarım listesindeki bir oda.
///
/// [categoryLabel] ve [whenLabel] veriden gelir (kategori listesi sunucu tarafında tanımlı,
/// SCREENS D1); gerçek veri katmanı tarihi biçimleyerek verecek.
@immutable
class Room {
  const Room({
    required this.id,
    required this.name,
    required this.categoryLabel,
    required this.whenLabel,
    required this.stage,
    required this.participantCount,
    this.readyCount = 0,
    this.previews = const [],
  });

  final String id;
  final String name;
  final String categoryLabel;
  final String whenLabel;
  final RoomStage stage;
  final int participantCount;

  /// Seçimini bitiren kişi sayısı (bekleme durumunda "3/5 hazır").
  final int readyCount;

  /// En çok uyuşan mekanlar; yalnızca [RoomStage.resultsReady].
  final List<PlacePreview> previews;
}

/// Geçmiş karar (Odalarım altında yatay karo).
@immutable
class PastDecision {
  const PastDecision({
    required this.id,
    required this.title,
    required this.dateLabel,
    this.tintIndex = 0,
  });

  final String id;
  final String title;
  final String dateLabel;
  final int tintIndex;
}
