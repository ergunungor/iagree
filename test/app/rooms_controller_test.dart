import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/app/rooms_controller.dart';
import 'package:iagree/core/data/mock/mock_rooms_repository.dart';
import 'package:iagree/core/domain/room.dart';

RoomsController _controller(MockRoomsScenario s) => RoomsController(
  repository: MockRoomsRepository(scenario: s, latency: Duration.zero),
);

void main() {
  test('yüklemeden önce idle, sonra ready', () async {
    final c = _controller(MockRoomsScenario.mixed);
    expect(c.status, RoomsStatus.idle);
    final future = c.load();
    expect(c.status, RoomsStatus.loading);
    await future;
    expect(c.status, RoomsStatus.ready);
  });

  test('hero: sonuçlar hazır > sıra sende > bekleniyor', () async {
    final c = _controller(MockRoomsScenario.mixed);
    await c.load();
    expect(c.hero!.stage, RoomStage.resultsReady);
    expect(c.others.map((r) => r.stage), [
      RoomStage.yourTurn,
      RoomStage.waiting,
    ]);
  });

  test('aynı durumdaki odaların sırası korunur', () async {
    final c = _controller(MockRoomsScenario.waitingOnly);
    await c.load();
    expect(c.ordered.map((r) => r.id), ['r3', 'r4']);
  });

  test('oda yoksa hero null, diğerleri boş', () async {
    final c = _controller(MockRoomsScenario.empty);
    await c.load();
    expect(c.hero, isNull);
    expect(c.others, isEmpty);
    expect(c.status, RoomsStatus.ready);
  });

  test('hata: failed; sonra senaryo düzelince tekrar yüklenir', () async {
    final repo = MockRoomsRepository(
      scenario: MockRoomsScenario.failing,
      latency: Duration.zero,
    );
    final c = RoomsController(repository: repo);
    await c.load();
    expect(c.status, RoomsStatus.failed);
    repo.scenario = MockRoomsScenario.mixed;
    await c.load();
    expect(c.status, RoomsStatus.ready);
    expect(c.rooms, isNotEmpty);
  });
}
