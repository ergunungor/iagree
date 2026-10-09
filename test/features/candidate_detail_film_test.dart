import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/app/app.dart';
import 'package:iagree/core/design_system/components/deck/swipe_deck.dart';
import 'package:iagree/core/domain/candidate.dart';
import 'package:iagree/core/domain/room_catalog.dart';
import 'package:iagree/features/decision/candidate_detail_sheet.dart';

const _film = Candidate(
  id: 'f1',
  name: 'Gece Yarısı Treni',
  kind: RoomKind.film,
  rating: 7.9,
  genre: 'Gerilim',
  durationMinutes: 112,
  platform: 'Netflix',
  synopsis: 'Bir tren yolculuğunda tanık olunan olay.',
  cast: ['Elif Aras', 'Kerem Ulus'],
);

void main() {
  testWidgets('film: özet, oyuncular ve platform; adres/saat satırı yok', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.localeTestValue = const Locale('tr');
    tester.platformDispatcher.localesTestValue = const [Locale('tr')];
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final controller = SwipeDeckController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      IAgreeApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showCandidateDetails(
                  context,
                  candidate: _film,
                  controller: controller,
                ),
                child: const Text('aç'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('aç'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Özet'), findsOneWidget);
    expect(
      find.text('Bir tren yolculuğunda tanık olunan olay.'),
      findsOneWidget,
    );
    expect(find.text('Oyuncular'), findsOneWidget);
    expect(find.text('Elif Aras, Kerem Ulus'), findsOneWidget);
    expect(find.text('Nereden izlenir'), findsOneWidget);
    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('7,9 · Gerilim · 112 dk'), findsOneWidget);
    expect(find.text('Adres'), findsNothing);
    expect(find.text('Saatler'), findsNothing);
  });
}
