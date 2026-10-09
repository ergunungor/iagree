import '../../domain/room.dart';
import '../../domain/room_catalog.dart';
import '../rooms_repository.dart';

/// Debug menüsünden seçilebilen veri senaryoları.
enum MockRoomsScenario {
  /// Hiç odası yok (HomeEmpty).
  empty,

  /// Üç durumda odalar + geçmiş (HomeC).
  mixed,

  /// Yalnızca başkalarını bekleyen odalar.
  waitingOnly,

  /// Yükleme hatası.
  failing,
}

/// Sahte oda verisi: gecikmeli, senaryolu, bellekte değiştirilebilir. Senaryo değişince
/// bellek o senaryonun başlangıç verisine döner.
class MockRoomsRepository implements RoomsRepository {
  MockRoomsRepository({
    MockRoomsScenario scenario = MockRoomsScenario.mixed,
    this.latency = const Duration(milliseconds: 400),
    // ignore: prefer_initializing_formals
  }) : _scenario = scenario;

  final Duration latency;
  MockRoomsScenario _scenario;
  List<Room>? _store;
  int _serial = 0;

  MockRoomsScenario get scenario => _scenario;

  set scenario(MockRoomsScenario value) {
    _scenario = value;
    _store = null;
  }

  List<Room> get _rooms => _store ??= switch (_scenario) {
    MockRoomsScenario.empty || MockRoomsScenario.failing => [],
    MockRoomsScenario.waitingOnly => [_cuma, _brunch],
    MockRoomsScenario.mixed => [_dogumGunu, _cuma, _kahvalti],
  };

  Future<void> _wait() => Future<void>.delayed(latency);

  @override
  Future<List<Room>> rooms() async {
    await _wait();
    if (_scenario == MockRoomsScenario.failing) {
      throw Exception('mock: yükleme hatası');
    }
    return List.unmodifiable(_rooms);
  }

  @override
  Future<List<PastDecision>> history() async {
    await _wait();
    if (_scenario == MockRoomsScenario.empty ||
        _scenario == MockRoomsScenario.failing) {
      return const [];
    }
    return const [
      PastDecision(
        id: 'h1',
        title: 'Trattoria Lume',
        dateLabel: '3 Ekim',
        tintIndex: 1,
      ),
      PastDecision(
        id: 'h2',
        title: 'Mavi Kapı Kahve',
        dateLabel: '28 Eylül',
        tintIndex: 4,
      ),
      PastDecision(
        id: 'h3',
        title: 'Gece Kuşu Bar',
        dateLabel: '14 Eylül',
        tintIndex: 2,
      ),
    ];
  }

  @override
  Future<RoomCatalog> catalog() async {
    await _wait();
    return _catalog;
  }

  @override
  Future<Room> createRoom(RoomDraft draft, {required RoomMember owner}) async {
    await _wait();
    _serial++;
    final room = Room(
      id: 'new-$_serial',
      name: draft.name,
      categoryLabel: draft.category.label,
      whenLabel: draft.whenLabel,
      stage: RoomStage.yourTurn,
      participantCount: 1,
      frameTags: draft.frameTags,
      members: [owner],
      inviteSlug: 'oda-$_serial',
    );
    _rooms.add(room);
    return room;
  }

  @override
  Future<Room> renameRoom(String id, String name) async {
    await _wait();
    final i = _rooms.indexWhere((r) => r.id == id);
    _rooms[i] = _rooms[i].copyWith(name: name);
    return _rooms[i];
  }

  @override
  Future<void> deleteRoom(String id) async {
    await _wait();
    _rooms.removeWhere((r) => r.id == id);
  }

  /// Debug: bir arkadaşın davet linkinden odaya katılmasını taklit eder.
  void simulateJoin(String roomId) {
    final i = _rooms.indexWhere((r) => r.id == roomId);
    if (i < 0) return;
    final room = _rooms[i];
    const guests = ['Can Kaya', 'Deniz Er', 'Mert Zor', 'Zeynep Bal'];
    final guest = guests[(room.members.length - 1).clamp(0, guests.length - 1)];
    _rooms[i] = room.copyWith(
      participantCount: room.participantCount + 1,
      members: [
        ...room.members,
        RoomMember(id: 'g-${room.members.length}', name: guest),
      ],
    );
  }

  static const RoomCatalog _catalog = RoomCatalog(
    categories: [
      RoomCategory(id: 'food', label: 'Yemek', inlineLabel: 'yemek'),
      RoomCategory(id: 'coffee', label: 'Kahve', inlineLabel: 'kahve'),
      RoomCategory(
        id: 'film',
        label: 'Film ve dizi',
        inlineLabel: 'film ve dizi',
        kind: RoomKind.film,
      ),
      RoomCategory(id: 'sport', label: 'Spor', inlineLabel: 'spor'),
      RoomCategory(id: 'bar', label: 'Bar', inlineLabel: 'bar'),
      RoomCategory(id: 'concert', label: 'Konser', inlineLabel: 'konser'),
      RoomCategory(id: 'game', label: 'Oyun', inlineLabel: 'oyun'),
      RoomCategory(id: 'outdoor', label: 'Açık hava', inlineLabel: 'açık hava'),
      RoomCategory(id: 'culture', label: 'Kültür', inlineLabel: 'kültür'),
      RoomCategory(id: 'anything', label: 'Fark etmez', inlineLabel: 'plan'),
    ],
    themes: [
      RoomTheme(
        id: 'rain',
        label: 'Yağmurlu hava',
        categoryId: 'coffee',
        when: RoomWhen.now,
        tintIndex: 4,
      ),
      RoomTheme(
        id: 'match',
        label: 'Maç akşamı',
        categoryId: 'bar',
        when: RoomWhen.tonight,
        tintIndex: 3,
      ),
      RoomTheme(
        id: 'calm',
        label: 'Sakin bir akşam',
        categoryId: 'food',
        when: RoomWhen.tonight,
        tintIndex: 2,
      ),
    ],
    platforms: ['Netflix', 'Prime Video', 'Disney+', 'Apple TV+', 'MUBI'],
    districts: [
      'Moda, Kadıköy',
      'Beşiktaş',
      'Cihangir, Beyoğlu',
      'Karaköy',
      'Nişantaşı, Şişli',
      'Bebek',
      'Üsküdar',
    ],
  );

  static const Room _kahvalti = Room(
    id: 'r1',
    name: 'Hafta sonu kahvaltı',
    categoryLabel: 'Kahve',
    whenLabel: 'Cumartesi 10:00',
    stage: RoomStage.resultsReady,
    participantCount: 4,
    readyCount: 4,
    previews: [
      PlacePreview(name: 'Mavi Kapı', agreementPercent: 100, tintIndex: 4),
      PlacePreview(name: 'Bahçe Bistro', agreementPercent: 75, tintIndex: 3),
      PlacePreview(name: 'Köşe Fırın', agreementPercent: 75, tintIndex: 0),
    ],
  );

  static const Room _dogumGunu = Room(
    id: 'r2',
    name: 'Doğum günü planı',
    categoryLabel: 'Aktivite',
    whenLabel: '18 Ekim',
    stage: RoomStage.yourTurn,
    participantCount: 5,
    readyCount: 2,
  );

  static const Room _cuma = Room(
    id: 'r3',
    name: 'Cuma akşamı',
    categoryLabel: 'Yemek',
    whenLabel: 'Bu akşam 20:00',
    stage: RoomStage.waiting,
    participantCount: 5,
    readyCount: 3,
  );

  static const Room _brunch = Room(
    id: 'r4',
    name: 'Pazar brunch',
    categoryLabel: 'Kahve',
    whenLabel: 'Pazar 11:30',
    stage: RoomStage.waiting,
    participantCount: 3,
    readyCount: 1,
  );
}
