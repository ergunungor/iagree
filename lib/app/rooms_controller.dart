import 'package:flutter/foundation.dart';

import '../core/data/rooms_repository.dart';
import '../core/domain/candidate.dart';
import '../core/domain/room.dart';
import '../core/domain/room_catalog.dart';

enum RoomsStatus { idle, loading, ready, failed }

/// Odalarım verisinin durumu. Ekran yalnızca bunu dinler; sıralama kuralı (hero seçimi)
/// burada, tek yerde.
class RoomsController extends ChangeNotifier {
  RoomsController({required this.repository});

  final RoomsRepository repository;

  RoomsStatus _status = RoomsStatus.idle;
  List<Room> _rooms = const [];
  List<PastDecision> _history = const [];
  RoomCatalog? _catalog;

  RoomsStatus get status => _status;
  List<Room> get rooms => _rooms;

  /// Geçmiş kararlar: karara bağlanan odalar (yeniden eskiye) + eski kararlar.
  List<PastDecision> get history => [
    for (final r in _rooms.reversed)
      if (r.stage == RoomStage.decided && r.decision != null)
        PastDecision(
          id: 'room-${r.id}',
          title: r.decision!.candidate.name,
          dateLabel: r.decision!.whenLabel,
          tintIndex: r.decision!.candidate.tintIndexes.first,
          roomId: r.id,
        ),
    ..._history,
  ];

  /// Aksiyon bekleyen en acil oda (öncelik: sonuçlar hazır → sıra sende → bekleniyor).
  /// Hiç oda yoksa null.
  Room? get hero => ordered.isEmpty ? null : ordered.first;

  /// Hero dışındaki odalar, aynı öncelik sırasıyla.
  List<Room> get others => ordered.isEmpty ? const [] : ordered.sublist(1);

  /// Öncelik sırasıyla odalar; aynı durumdakilerin sırası korunur.
  List<Room> get ordered {
    final sorted = [
      for (final r in _rooms)
        if (r.stage != RoomStage.decided) r,
    ];
    // List.sort kararlı değildir; indeksle eşitlik bozulur.
    final index = {for (var i = 0; i < sorted.length; i++) sorted[i].id: i};
    sorted.sort((a, b) {
      final byStage = a.stage.index.compareTo(b.stage.index);
      return byStage != 0 ? byStage : index[a.id]!.compareTo(index[b.id]!);
    });
    return sorted;
  }

  /// Oda kurma seçenekleri; [loadCatalog] bitene kadar null.
  RoomCatalog? get catalog => _catalog;

  Room? room(String id) {
    for (final r in _rooms) {
      if (r.id == id) return r;
    }
    return null;
  }

  /// [silent] ise durum "yükleniyor"a düşmez: ekran içeriği yerinde kalır (arka plan tazeleme).
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _status = RoomsStatus.loading;
      notifyListeners();
    }
    try {
      final results = await Future.wait([
        repository.rooms(),
        repository.history(),
      ]);
      _rooms = results[0] as List<Room>;
      _history = results[1] as List<PastDecision>;
      _status = RoomsStatus.ready;
    } on Object {
      _status = RoomsStatus.failed;
    }
    notifyListeners();
  }

  Future<RoomCatalog> loadCatalog() async =>
      _catalog ??= await repository.catalog();

  /// Oda kurar ve listeye ekler.
  Future<Room> create(RoomDraft draft, {required RoomMember owner}) async {
    final room = await repository.createRoom(draft, owner: owner);
    _rooms = [..._rooms, room];
    notifyListeners();
    return room;
  }

  Future<void> rename(String id, String name) async {
    final updated = await repository.renameRoom(id, name);
    _rooms = [for (final r in _rooms) r.id == id ? updated : r];
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await repository.deleteRoom(id);
    _rooms = [
      for (final r in _rooms)
        if (r.id != id) r,
    ];
    notifyListeners();
  }

  Future<List<Candidate>> deck(String roomId) => repository.deck(roomId);

  Future<RoomResults> results(String roomId) => repository.results(roomId);

  Future<void> submitPicks(String roomId, Map<String, Pick> picks) async {
    final updated = await repository.submitPicks(roomId, picks);
    _replace(updated);
  }

  Future<void> vote(String roomId, String candidateId) async {
    final updated = await repository.vote(roomId, candidateId);
    _replace(updated);
  }

  /// Sunucu/arka plan değişikliğinden sonra listeyi sessizce tazeler.
  Future<void> refresh() => load(silent: true);

  void _replace(Room updated) {
    _rooms = [for (final r in _rooms) r.id == updated.id ? updated : r];
    notifyListeners();
  }

  Future<void> breakTie(String roomId, String candidateId) async {
    final updated = await repository.breakTie(roomId, candidateId);
    _replace(updated);
  }
}
