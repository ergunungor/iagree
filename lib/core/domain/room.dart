import 'package:flutter/foundation.dart';

import 'candidate.dart';
import 'room_catalog.dart';

/// Bir odanın kullanıcı açısından durumu. Sıra, Odalarım'daki öncelik sırasıdır (SCREENS C1):
/// sonuçlar hazır (oy ver) → sıra sende (seç) → başkaları bekleniyor.
enum RoomStage { resultsReady, yourTurn, waiting, decided }

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
    this.frameTags = const [],
    this.members = const [],
    this.inviteSlug = '',
    this.decision,
    this.kind = RoomKind.place,
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

  /// Oda çerçevesi etiketleri (kategori, zaman, bütçe, yer/platform); oda ekranında başlığın
  /// altında.
  final List<String> frameTags;

  /// Odadaki kişiler; oda sahibi ilk sırada. Boşsa yalnızca [participantCount] bilinir.
  final List<RoomMember> members;

  /// Davet linkinin son parçası (`iagree.app/r/<slug>`).
  final String inviteSlug;

  /// Mekan ya da film/dizi odası (deste kartları buna göre).
  final RoomKind kind;

  /// Karar verildiyse sonuç ([RoomStage.decided]).
  final Decision? decision;

  /// Henüz kimse katılmadı: oda ekranı davet durumunda açılır.
  bool get isInviting => participantCount <= 1;

  Room copyWith({
    String? name,
    int? participantCount,
    List<RoomMember>? members,
    RoomStage? stage,
    int? readyCount,
    Decision? decision,
  }) => Room(
    id: id,
    name: name ?? this.name,
    categoryLabel: categoryLabel,
    whenLabel: whenLabel,
    stage: stage ?? this.stage,
    participantCount: participantCount ?? this.participantCount,
    readyCount: readyCount ?? this.readyCount,
    previews: previews,
    frameTags: frameTags,
    members: members ?? this.members,
    inviteSlug: inviteSlug,
    decision: decision ?? this.decision,
    kind: kind,
  );
}

/// Odadaki bir kişi.
@immutable
class RoomMember {
  const RoomMember({required this.id, required this.name});

  final String id;
  final String name;
}

/// Geçmiş karar (Odalarım altında yatay karo).
@immutable
class PastDecision {
  const PastDecision({
    required this.id,
    required this.title,
    required this.dateLabel,
    this.tintIndex = 0,
    this.roomId,
  });

  /// Bu karar bir odaya aitse odanın kimliği (dokununca karar anı açılır).
  final String? roomId;

  final String id;
  final String title;
  final String dateLabel;
  final int tintIndex;
}
