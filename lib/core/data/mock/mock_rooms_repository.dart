import '../../domain/candidate.dart';
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
    _picks.clear();
    _myVote.clear();
  }

  List<Room> get _rooms => _store ??= [
    for (final r in switch (_scenario) {
      MockRoomsScenario.empty || MockRoomsScenario.failing => const <Room>[],
      MockRoomsScenario.waitingOnly => const [_cuma, _brunch],
      MockRoomsScenario.mixed => const [_dogumGunu, _cuma, _kahvalti],
    })
      r.members.isEmpty ? r.copyWith(members: _members(r)) : r,
  ];

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
      kind: draft.category.kind,
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

  // --- Deste, sonuçlar, oylama (sahte motor) -------------------------------------------

  final Map<String, Map<String, Pick>> _picks = {};
  final Map<String, String> _myVote = {};

  static const List<String> _guestNames = [
    'Can Kaya',
    'Deniz Er',
    'Mert Zor',
    'Zeynep Bal',
  ];

  Room _room(String id) => _rooms.firstWhere((r) => r.id == id);

  void _put(Room room) {
    final i = _rooms.indexWhere((r) => r.id == room.id);
    _rooms[i] = room;
  }

  /// Oda üyeleri; veri yoksa sahte isimlerle tamamlanır (kullanıcı ilk sırada).
  List<RoomMember> _members(Room room) {
    if (room.members.isNotEmpty) return room.members;
    return [
      const RoomMember(id: 'u-ayse', name: 'Ayşe Yılmaz'),
      for (var i = 0; i < room.participantCount - 1; i++)
        RoomMember(id: 'g-$i', name: _guestNames[i % _guestNames.length]),
    ];
  }

  @override
  Future<List<Candidate>> deck(String roomId) async {
    await _wait();
    return _room(roomId).kind == RoomKind.film ? _filmDeck : _placeDeck;
  }

  @override
  Future<Room> submitPicks(String roomId, Map<String, Pick> picks) async {
    await _wait();
    _picks[roomId] = Map.of(picks);
    final room = _room(roomId);
    final updated = room.copyWith(
      stage: RoomStage.waiting,
      readyCount: (room.readyCount + 1).clamp(1, room.participantCount),
    );
    _put(updated);
    return updated;
  }

  /// En fazla 3 seçenek: kullanıcının olumlu verdikleri önde, sonra kalanlar. Diğer kişilerin
  /// kararları sahte ama tutarlıdır (ilk seçenek en uyumlu).
  List<ResultOption> _options(Room room) {
    final members = _members(room);
    final total = members.length < 2 ? 2 : members.length;
    final mine = _picks[room.id] ?? const <String, Pick>{};
    final deck = room.kind == RoomKind.film ? _filmDeck : _placeDeck;
    bool positive(Candidate c) =>
        mine[c.id] == Pick.love || mine[c.id] == Pick.ok;
    final ordered = [
      ...deck.where(positive),
      ...deck.where((c) => !positive(c) && mine[c.id] != Pick.veto),
    ].take(3).toList();
    return [
      for (var k = 0; k < ordered.length; k++)
        () {
          final c = ordered[k];
          final others = total - 1;
          final othersPositive = (others - k).clamp(0, others);
          final loveOthers = k == 0 && othersPositive > 0 ? 1 : 0;
          final love = loveOthers + (mine[c.id] == Pick.love ? 1 : 0);
          final ok =
              (othersPositive - loveOthers) + (mine[c.id] == Pick.ok ? 1 : 0);
          return ResultOption(
            candidate: c,
            loveCount: love,
            okCount: ok,
            total: total,
            lovers: [
              if (mine[c.id] == Pick.love) members.first,
              if (loveOthers > 0 && members.length > 1) members[1],
            ],
          );
        }(),
    ];
  }

  @override
  Future<RoomResults> results(String roomId) async {
    await _wait();
    final room = _room(roomId);
    final options = _options(room);
    final members = _members(room);
    final myVote = _myVote[roomId];
    final votes = <String, List<RoomMember>>{};
    if (myVote != null) {
      votes[myVote] = [members.first];
    }
    return RoomResults(
      options: options,
      members: members,
      votes: votes,
      myVoteId: myVote,
    );
  }

  @override
  Future<Room> vote(String roomId, String candidateId) async {
    await _wait();
    _myVote[roomId] = candidateId;
    return _room(roomId);
  }

  /// Debug: herkes seçimini bitirdi. Oybirliği ya da oylama gerektiren sonuç.
  void simulateEveryoneDone(String roomId, {required bool unanimous}) {
    final room = _room(roomId);
    if (unanimous) {
      final top = _options(room).first;
      final members = _members(room);
      final total = members.length < 2 ? 2 : members.length;
      _put(
        room.copyWith(
          stage: RoomStage.decided,
          readyCount: total,
          decision: Decision(
            candidate: top.candidate,
            unanimous: true,
            loveCount: 1,
            okCount: total - 1,
            total: total,
            votes: total,
            totalVotes: total,
            members: members,
            whenLabel: room.whenLabel,
          ),
        ),
      );
    } else {
      _put(room.copyWith(stage: RoomStage.resultsReady));
    }
  }

  /// Debug: herkes oy verdi; kazanan çoğunlukla seçilir.
  void simulateEveryoneVoted(String roomId) {
    final room = _room(roomId);
    final options = _options(room);
    final members = _members(room);
    final total = members.length < 2 ? 2 : members.length;
    final winner = options.first;
    final myVote = _myVote[roomId];
    // Diğerleri ilk seçeneğe oy verir; kullanıcı başka seçeneğe verdiyse çoğunluk yine ilkinde.
    final votes = myVote == winner.candidate.id ? total : total - 1;
    _put(
      room.copyWith(
        stage: RoomStage.decided,
        decision: Decision(
          candidate: winner.candidate,
          unanimous: false,
          loveCount: winner.loveCount,
          okCount: winner.okCount,
          total: total,
          votes: votes,
          totalVotes: total,
          members: members,
          whenLabel: room.whenLabel,
        ),
      ),
    );
  }

  static const List<Candidate> _placeDeck = [
    Candidate(
      id: 'p1',
      name: 'Trattoria Lume',
      tintIndexes: [1, 3],
      rating: 4.6,
      categoryLabel: 'İtalyan',
      priceLevel: 2,
      distanceKm: 1.2,
    ),
    Candidate(
      id: 'p2',
      name: 'Mavi Kapı Kahve',
      tintIndexes: [4, 0],
      rating: 4.7,
      categoryLabel: 'Kahve',
      priceLevel: 1,
      distanceKm: 0.65,
    ),
    Candidate(
      id: 'p3',
      name: 'Çınar Meyhane',
      tintIndexes: [2, 1],
      rating: 4.4,
      categoryLabel: 'Meyhane',
      priceLevel: 3,
      distanceKm: 2.4,
      closingInMinutes: 45,
    ),
    Candidate(
      id: 'p4',
      name: 'Sahil Börekçisi',
      tintIndexes: [0, 2],
      rating: 4.5,
      categoryLabel: 'Fırın',
      priceLevel: 1,
      distanceKm: 1.9,
    ),
    Candidate(
      id: 'p5',
      name: 'Lale Sofrası',
      tintIndexes: [3, 4],
      rating: 4.3,
      categoryLabel: 'Ev yemeği',
      priceLevel: 2,
      distanceKm: 3.1,
    ),
    Candidate(
      id: 'p6',
      name: 'Nar Bistro',
      tintIndexes: [1, 2],
      rating: 4.5,
      categoryLabel: 'Bistro',
      priceLevel: 2,
      distanceKm: 0.9,
    ),
  ];

  static const List<Candidate> _filmDeck = [
    Candidate(
      id: 'f1',
      name: 'Gece Yarısı Treni',
      kind: RoomKind.film,
      tintIndexes: [2],
      rating: 7.9,
      genre: 'Gerilim',
      durationMinutes: 112,
      platform: 'Netflix',
    ),
    Candidate(
      id: 'f2',
      name: 'Limon Ağacı',
      kind: RoomKind.film,
      tintIndexes: [0],
      rating: 8.1,
      genre: 'Dram',
      durationMinutes: 98,
      platform: 'MUBI',
    ),
    Candidate(
      id: 'f3',
      name: 'Büyük Kaçış',
      kind: RoomKind.film,
      tintIndexes: [3],
      rating: 7.4,
      genre: 'Macera',
      durationMinutes: 125,
      platform: 'Prime Video',
    ),
    Candidate(
      id: 'f4',
      name: 'Son Dans',
      kind: RoomKind.film,
      tintIndexes: [1],
      rating: 7.7,
      genre: 'Komedi',
      durationMinutes: 104,
      platform: 'Disney+',
    ),
  ];

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
