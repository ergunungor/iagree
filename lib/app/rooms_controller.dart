import 'package:flutter/foundation.dart';

import '../core/data/rooms_repository.dart';
import '../core/domain/room.dart';

enum RoomsStatus { idle, loading, ready, failed }

/// Odalarım verisinin durumu. Ekran yalnızca bunu dinler; sıralama kuralı (hero seçimi)
/// burada, tek yerde.
class RoomsController extends ChangeNotifier {
  RoomsController({required this.repository});

  final RoomsRepository repository;

  RoomsStatus _status = RoomsStatus.idle;
  List<Room> _rooms = const [];
  List<PastDecision> _history = const [];

  RoomsStatus get status => _status;
  List<Room> get rooms => _rooms;
  List<PastDecision> get history => _history;

  /// Aksiyon bekleyen en acil oda (öncelik: sonuçlar hazır → sıra sende → bekleniyor).
  /// Hiç oda yoksa null.
  Room? get hero => ordered.isEmpty ? null : ordered.first;

  /// Hero dışındaki odalar, aynı öncelik sırasıyla.
  List<Room> get others => ordered.isEmpty ? const [] : ordered.sublist(1);

  /// Öncelik sırasıyla odalar; aynı durumdakilerin sırası korunur.
  List<Room> get ordered {
    final sorted = [..._rooms];
    // List.sort kararlı değildir; indeksle eşitlik bozulur.
    final index = {for (var i = 0; i < _rooms.length; i++) _rooms[i].id: i};
    sorted.sort((a, b) {
      final byStage = a.stage.index.compareTo(b.stage.index);
      return byStage != 0 ? byStage : index[a.id]!.compareTo(index[b.id]!);
    });
    return sorted;
  }

  Future<void> load() async {
    _status = RoomsStatus.loading;
    notifyListeners();
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
}
