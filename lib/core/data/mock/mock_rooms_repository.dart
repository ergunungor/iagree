import '../../domain/room.dart';
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

/// Sahte oda verisi: gecikmeli, senaryolu.
class MockRoomsRepository implements RoomsRepository {
  MockRoomsRepository({
    this.scenario = MockRoomsScenario.mixed,
    this.latency = const Duration(milliseconds: 400),
  });

  MockRoomsScenario scenario;
  final Duration latency;

  @override
  Future<List<Room>> rooms() async {
    await Future<void>.delayed(latency);
    switch (scenario) {
      case MockRoomsScenario.empty:
        return const [];
      case MockRoomsScenario.failing:
        throw Exception('mock: yükleme hatası');
      case MockRoomsScenario.waitingOnly:
        return const [_cuma, _brunch];
      case MockRoomsScenario.mixed:
        return const [_dogumGunu, _cuma, _kahvalti];
    }
  }

  @override
  Future<List<PastDecision>> history() async {
    await Future<void>.delayed(latency);
    if (scenario == MockRoomsScenario.empty ||
        scenario == MockRoomsScenario.failing) {
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
