import 'package:flutter/foundation.dart';

import 'room.dart';
import 'room_catalog.dart';

/// Kullanıcının bir karta verdiği karar (Olur / Pas / Çok isterim / Olmaz). Bireysel kararlar
/// oylama bitene kadar gizlidir; yalnızca "Çok isterim" diyenler sonuçlarda isimle görünebilir.
enum Pick { ok, pass, love, veto }

/// Destedeki bir seçenek: mekan ya da film/dizi. Fotoğraf/afiş gelene kadar [tintIndexes]
/// yer tutucu renkleri verir.
@immutable
class Candidate {
  const Candidate({
    required this.id,
    required this.name,
    this.kind = RoomKind.place,
    this.tintIndexes = const [0],
    this.rating,
    this.categoryLabel,
    this.priceLevel,
    this.distanceKm,
    this.genre,
    this.durationMinutes,
    this.platform,
    this.closingInMinutes,
    this.address,
    this.hoursLabel,
    this.websiteUrl,
    this.synopsis,
    this.cast = const [],
  });

  final String id;
  final String name;
  final RoomKind kind;
  final List<int> tintIndexes;
  final double? rating;

  /// Mekan: kategori ("İtalyan"). Film: kullanılmaz.
  final String? categoryLabel;
  final int? priceLevel;
  final double? distanceKm;

  /// Film: tür, süre (dk), platform.
  final String? genre;
  final int? durationMinutes;
  final String? platform;

  /// "Kapanıyor · 45 dk" istisnası.
  final int? closingInMinutes;

  /// Detay sayfası (D5). Mekan: adres, saat metni (veriden biçimli), menü/web adresi.
  final String? address;
  final String? hoursLabel;
  final String? websiteUrl;

  /// Film: özet ve oyuncular.
  final String? synopsis;
  final List<String> cast;
}

/// Sonuç listesindeki bir seçenek (SCREENS D7). Pas ve veto için alan yoktur: yanlışlıkla
/// gösterilemez.
@immutable
class ResultOption {
  const ResultOption({
    required this.candidate,
    required this.loveCount,
    required this.okCount,
    required this.total,
    this.lovers = const [],
  });

  final Candidate candidate;
  final int loveCount;
  final int okCount;
  final int total;

  /// "Çok isterim" diyenler.
  final List<RoomMember> lovers;
}

/// Oylar eşit çıktığında son söz oda sahibinindir (SCREENS D7).
@immutable
class TieBreak {
  const TieBreak({
    required this.tiedIds,
    required this.owner,
    required this.iAmOwner,
  });

  /// Eşit çıkan seçeneklerin kimlikleri.
  final List<String> tiedIds;
  final RoomMember owner;
  final bool iAmOwner;
}

/// Oy aşamasının durumu.
@immutable
class RoomResults {
  const RoomResults({
    required this.options,
    required this.members,
    this.votes = const {},
    this.myVoteId,
    this.tie,
  });

  /// En fazla 3, uyuma göre sıralı.
  final List<ResultOption> options;
  final List<RoomMember> members;

  /// Seçenek kimliği → oy verenler. Yalnızca kullanıcı oy verdikten sonra gösterilir.
  final Map<String, List<RoomMember>> votes;
  final String? myVoteId;

  /// Doluysa oylar eşit: karar oda sahibinde.
  final TieBreak? tie;

  bool get iVoted => myVoteId != null;

  int get voterCount => votes.values.fold(0, (a, v) => a + v.length);

  /// Henüz oy vermeyenler (kullanıcı hariç).
  int get waitingCount => members.length - voterCount;
}

/// Verilen karar (SCREENS D8).
@immutable
class Decision {
  const Decision({
    required this.candidate,
    required this.unanimous,
    required this.loveCount,
    required this.okCount,
    required this.total,
    required this.votes,
    required this.totalVotes,
    required this.members,
    required this.whenLabel,
  });

  final Candidate candidate;
  final bool unanimous;
  final int loveCount;
  final int okCount;
  final int total;
  final int votes;
  final int totalVotes;
  final List<RoomMember> members;
  final String whenLabel;
}
