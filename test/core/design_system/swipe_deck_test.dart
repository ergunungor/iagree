import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/deck/deck_card.dart';
import 'package:iagree/core/design_system/components/deck/swipe_deck.dart';
import 'package:iagree/core/design_system/components/deck/swipe_deck_physics.dart';

import '../../support/pump_app.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532); // 390 × 844
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

class _Log {
  final swiped = <(String, DeckDecision)>[];
  int completed = 0;
}

Widget _deck(
  _Log log, {
  List<String> items = const ['a', 'b', 'c'],
  double shiftY = 0,
}) => Transform.translate(
  offset: Offset(0, shiftY),
  child: SizedBox(
    width: 350,
    child: SwipeDeck<String>(
      items: items,
      onSwiped: (item, d) => log.swiped.add((item, d)),
      onCompleted: () => log.completed++,
      itemBuilder: (context, item) => DeckCard.place(
        key: ValueKey('card-$item'),
        name: 'Mekan $item',
        photos: const [
          ColoredBox(color: Colors.red),
          ColoredBox(color: Colors.blue),
        ],
        rating: 4.6,
        category: 'Kafe',
      ),
    ),
  ),
);

Finder _card(String item) => find.byKey(ValueKey('card-$item'));

/// Dönmeden etkilenmeyen nokta: kartın alt orta noktası (dönme pivotu).
Offset _pivot(WidgetTester tester, String item) {
  final f = _card(item);
  return (tester.getBottomLeft(f) + tester.getBottomRight(f)) / 2;
}

double _width(WidgetTester tester, String item) =>
    (tester.getBottomRight(_card(item)) - tester.getTopLeft(_card(item))).dx;

/// Ön kartı yavaşça (düşük hızla) sürükleyip bırakır.
Future<void> _slowDrag(WidgetTester tester, Offset by) async {
  await tester.timedDrag(_card('a'), by, const Duration(seconds: 2));
}

void main() {
  group('yığın', () {
    testWidgets('ön kart 1, arka kart 0,95 ölçekte ve 8pt aşağıda', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _deck(_Log()));
      expect(_width(tester, 'a'), closeTo(350, 0.01));
      expect(_width(tester, 'b'), closeTo(350 * 0.95, 0.01));
      expect(_card('c'), findsNothing); // yalnızca iki kart kurulur
      // Arka kartın alt orta noktası ön kartınkinden 8 − (350·4/3)·0.025 yukarıda kalır.
      final dy = _pivot(tester, 'b').dy - _pivot(tester, 'a').dy;
      expect(dy, closeTo(8 - 350 * 4 / 3 * 0.025, 0.01));
    });

    testWidgets('boş liste: çökme yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _deck(_Log(), items: const []));
      expect(tester.takeException(), isNull);
    });
  });

  group('sürükleme', () {
    testWidgets('yatayda 1:1 takip', (tester) async {
      _phone(tester);
      await pumpApp(tester, _deck(_Log()));
      final start = _pivot(tester, 'a');
      final g = await tester.startGesture(start - const Offset(0, 200));
      await g.moveBy(const Offset(40, 0));
      await g.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(_pivot(tester, 'a').dx - start.dx, closeTo(80, 0.5));
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('yukarı 1:1, aşağı parmağın 0,55\'i', (tester) async {
      _phone(tester);
      await pumpApp(tester, _deck(_Log()));
      final start = _pivot(tester, 'a');
      var g = await tester.startGesture(start - const Offset(0, 200));
      await g.moveBy(const Offset(0, -40));
      await g.moveBy(const Offset(0, -40));
      await tester.pump();
      expect(_pivot(tester, 'a').dy - start.dy, closeTo(-80, 0.5));
      await g.up();
      await tester.pumpAndSettle();

      g = await tester.startGesture(start - const Offset(0, 200));
      await g.moveBy(const Offset(0, 40));
      await g.moveBy(const Offset(0, 40));
      await tester.pump();
      expect(_pivot(tester, 'a').dy - start.dy, closeTo(80 * 0.55, 0.5));
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('baskın eksende diğer eksen 24pt ile sınırlı, dönme yok', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _deck(_Log()));
      final start = _pivot(tester, 'a');
      final g = await tester.startGesture(start - const Offset(0, 200));
      await g.moveBy(const Offset(20, -200));
      await tester.pump();
      final moved = _pivot(tester, 'a') - start;
      expect(moved.dy, closeTo(-200, 0.5));
      expect(moved.dx.abs(), lessThanOrEqualTo(24.01));
      expect(
        tester.getTopLeft(_card('a')).dx,
        closeTo(tester.getBottomLeft(_card('a')).dx, 0.5),
      );
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'bırakmadan eksen değiştirilir: sağa çekip yukarı çıkınca Çok isterim',
      (tester) async {
        _phone(tester);
        final log = _Log();
        await pumpApp(tester, _deck(log));
        final start = _pivot(tester, 'a');
        final g = await tester.startGesture(start - const Offset(0, 200));
        await g.moveBy(const Offset(100, 0));
        await tester.pump();
        expect(find.text('Olur'), findsOneWidget);
        expect(_pivot(tester, 'a').dx - start.dx, closeTo(100, 0.5));

        // Vazgeç: parmak bırakılmadan yukarı çıkar.
        await g.moveBy(const Offset(0, -150));
        await g.moveBy(const Offset(0, -150));
        await tester.pump();
        expect(find.text('Olur'), findsNothing);
        expect(find.text('Çok isterim'), findsOneWidget);
        final moved = _pivot(tester, 'a') - start;
        expect(moved.dy, closeTo(-300, 0.5));
        expect(
          moved.dx,
          lessThanOrEqualTo(24.01),
        ); // yatay hareket geri çekildi

        await g.up();
        await tester.pumpAndSettle();
        expect(log.swiped, [('a', DeckDecision.love)]);
      },
    );

    testWidgets('sağa çekip vazgeçip merkeze dönünce karar yok', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log));
      final start = _pivot(tester, 'a');
      final g = await tester.startGesture(start - const Offset(0, 200));
      await g.moveBy(const Offset(130, 0));
      await tester.pump();
      expect(find.text('Olur'), findsOneWidget);
      await g.moveBy(const Offset(-130, 0)); // başlangıca döndü
      await tester.pump();
      expect(find.text('Olur'), findsNothing);
      await g.up();
      await tester.pumpAndSettle();
      expect(log.swiped, isEmpty);
    });

    testWidgets('yatayda alt ortadan dönme (dx/genişlik × 12°)', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _deck(_Log()));
      final start = _pivot(tester, 'a');
      final g = await tester.startGesture(start - const Offset(0, 200));
      await g.moveBy(const Offset(87.5, 0)); // 87,5/350 × 12° = 3°
      await tester.pump();
      final tl = tester.getTopLeft(_card('a'));
      final bl = tester.getBottomLeft(_card('a'));
      final dx = tl.dx - bl.dx;
      final dy = bl.dy - tl.dy;
      // Dönmüş dikey kenar: yatay kayma = H · sin(3°), pozitif dönmede üst sağa kayar.
      expect(dx / dy, closeTo(0.0524, 0.002)); // tan(3°) ≈ 0,0524
      await g.up();
      await tester.pumpAndSettle();
    });
  });

  group('eşikler ve karar', () {
    testWidgets('eşik altı bırakınca yerine döner, karar yok', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log));
      final start = _pivot(tester, 'a');
      await _slowDrag(tester, const Offset(90, 0)); // eşik 105
      await tester.pumpAndSettle();
      expect(log.swiped, isEmpty);
      expect(_pivot(tester, 'a').dx, closeTo(start.dx, 0.5));
      expect(_pivot(tester, 'a').dy, closeTo(start.dy, 0.5));
    });

    final distanceCases = {
      '→ Olur (%30)': (const Offset(120, 0), DeckDecision.ok),
      '← Pas (%30)': (const Offset(-120, 0), DeckDecision.pass),
      '↑ Çok isterim (%25)': (const Offset(0, -130), DeckDecision.love),
      // ↓: kartın görünen ofseti %35 → 163,45; parmak ≈ 297 pt.
      '↓ Olmaz (%35, direnç dahil)': (const Offset(0, 300), DeckDecision.veto),
    };
    for (final e in distanceCases.entries) {
      testWidgets('mesafe: ${e.key}', (tester) async {
        _phone(tester);
        final log = _Log();
        await pumpApp(tester, _deck(log));
        await _slowDrag(tester, e.value.$1);
        await tester.pumpAndSettle();
        expect(log.swiped, [('a', e.value.$2)]);
        expect(_card('a'), findsNothing);
        expect(_card('b'), findsOneWidget);
        expect(_width(tester, 'b'), closeTo(350, 0.5)); // öne geldi
      });
    }

    testWidgets('↓ eşiğin hemen altında (parmak 290) karar yok', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log));
      await _slowDrag(tester, const Offset(0, 290)); // kart 159,5 < 163,45
      await tester.pumpAndSettle();
      expect(log.swiped, isEmpty);
    });

    final flings = {
      '→ Olur': (const Offset(60, 0), DeckDecision.ok),
      '← Pas': (const Offset(-60, 0), DeckDecision.pass),
      '↑ Çok isterim': (const Offset(0, -60), DeckDecision.love),
    };
    for (final e in flings.entries) {
      testWidgets('hız: kısa mesafe ama hızlı fırlatma ${e.key}', (
        tester,
      ) async {
        _phone(tester);
        final log = _Log();
        await pumpApp(tester, _deck(log));
        await tester.fling(_card('a'), e.value.$1, 1500);
        await tester.pumpAndSettle();
        expect(log.swiped, [('a', e.value.$2)]);
      });
    }

    testWidgets('yavaş fırlatma (500 pt/s) kısa mesafede karar vermez', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log));
      await tester.fling(_card('a'), const Offset(60, 0), 500);
      await tester.pumpAndSettle();
      expect(log.swiped, isEmpty);
    });

    testWidgets('Olmaz: hızlı ama kısa aşağı fırlatma sayılmaz', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log));
      await tester.fling(_card('a'), const Offset(0, 60), 4000);
      await tester.pumpAndSettle();
      expect(log.swiped, isEmpty);
    });

    testWidgets('kararlar sırayla: a sonra b, deste bitince onCompleted', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log, items: const ['a', 'b']));
      await _slowDrag(tester, const Offset(130, 0));
      await tester.pumpAndSettle();
      expect(log.completed, 0);
      await tester.timedDrag(
        _card('b'),
        const Offset(-130, 0),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(log.swiped, [('a', DeckDecision.ok), ('b', DeckDecision.pass)]);
      expect(log.completed, 1);
      expect(find.byType(DeckCard), findsNothing);
    });
  });

  group('uçuş', () {
    testWidgets('uçan kart ekran dışına çıkar, süre ≤ 225 ms', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log));
      final g = await tester.startGesture(
        _pivot(tester, 'a') - const Offset(0, 200),
      );
      await g.moveBy(const Offset(60, 0));
      await g.moveBy(const Offset(60, 0));
      await g.up();
      await tester.pump(); // uçuş başlar
      await tester.pump(const Duration(milliseconds: 230));
      await tester.pump();
      expect(_card('a'), findsNothing); // uçuş bitti, kart kaldırıldı
      expect(log.swiped.single.$2, DeckDecision.ok);
    });

    testWidgets('uçuş sırasında yeni sürükleme başlamaz', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log));
      await tester.fling(_card('a'), const Offset(200, 0), 2000);
      await tester.pump(const Duration(milliseconds: 20));
      final g = await tester.startGesture(const Offset(195, 300));
      await g.moveBy(const Offset(200, 0));
      await g.up();
      await tester.pumpAndSettle();
      expect(log.swiped.length, 1);
    });
  });

  group('etiket ve ton', () {
    Future<TestGesture> startDrag(WidgetTester tester) async {
      await pumpApp(tester, _deck(_Log()));
      return tester.startGesture(_pivot(tester, 'a') - const Offset(0, 200));
    }

    testWidgets('dinlenmede etiket yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _deck(_Log()));
      for (final t in ['Olur', 'Pas', 'Çok isterim', 'Olmaz']) {
        expect(find.text(t), findsNothing);
      }
    });

    final labels = {
      'Olur': const Offset(60, 0),
      'Pas': const Offset(-60, 0),
      'Çok isterim': const Offset(0, -60),
      'Olmaz': const Offset(0, 60),
    };
    for (final e in labels.entries) {
      testWidgets('${e.key} etiketi yönüne göre görünür, yalnız o', (
        tester,
      ) async {
        _phone(tester);
        final g = await startDrag(tester);
        await g.moveBy(e.value);
        await tester.pump();
        expect(find.text(e.key), findsOneWidget);
        for (final other in labels.keys.where((k) => k != e.key)) {
          expect(find.text(other), findsNothing);
        }
        await g.up();
        await tester.pumpAndSettle();
        expect(find.text(e.key), findsNothing); // bırakınca kaybolur
      });
    }

    testWidgets('opaklık eşikte 1, yarıda ~0,5', (tester) async {
      _phone(tester);
      final g = await startDrag(tester);
      await g.moveBy(const Offset(52.5, 0));
      await tester.pump();
      double opacity() => tester
          .widget<Opacity>(
            find
                .ancestor(of: find.text('Olur'), matching: find.byType(Opacity))
                .first,
          )
          .opacity;
      expect(opacity(), closeTo(0.5, 0.01));
      await g.moveBy(const Offset(60, 0));
      await tester.pump();
      expect(opacity(), 1);
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('renk tonu foto alanında, bilgi panelinde değil', (
      tester,
    ) async {
      _phone(tester);
      final g = await startDrag(tester);
      await g.moveBy(const Offset(120, 0));
      await tester.pump();
      final label = tester.getRect(find.text('Olur'));
      final name = tester.getRect(find.text('Mekan a'));
      expect(label.bottom, lessThan(name.top)); // etiket fotoğraf alanında
      await g.up();
      await tester.pumpAndSettle();
    });
  });

  group('haptic', () {
    final calls = <String>[];

    setUp(() {
      calls.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              calls.add(call.arguments as String);
            }
            return null;
          });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('eşiğe her girişte bir kez selection', (tester) async {
      _phone(tester);
      await pumpApp(tester, _deck(_Log()));
      final g = await tester.startGesture(
        _pivot(tester, 'a') - const Offset(0, 200),
      );
      await g.moveBy(const Offset(60, 0));
      await tester.pump();
      expect(calls, isEmpty);
      await g.moveBy(const Offset(60, 0)); // 120 > 105: giriş
      await g.moveBy(const Offset(20, 0)); // içeride: tekrar yok
      await tester.pump();
      expect(calls, ['HapticFeedbackType.selectionClick']);
      await g.moveBy(const Offset(-80, 0)); // 60: çıkış
      await tester.pump();
      expect(calls.length, 1);
      await g.moveBy(const Offset(70, 0)); // 130: yeniden giriş
      await tester.pump();
      expect(calls.length, 2);
      await g.up();
      await tester.pumpAndSettle();
    });

    testWidgets('eşik altında hiç titreşim yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _deck(_Log()));
      await _slowDrag(tester, const Offset(90, 0));
      await tester.pumpAndSettle();
      expect(calls, isEmpty);
    });
  });

  group('alt 20pt koruması', () {
    testWidgets('alt kenarda başlayan dokunuş kartı oynatmaz', (tester) async {
      _phone(tester);
      final log = _Log();
      // Kartı aşağı kaydır: alt kenarı ekranın dışına taşar, y=835 kartın içinde ve korumada.
      await pumpApp(tester, _deck(log, shiftY: 400));
      final g = await tester.startGesture(const Offset(195, 835));
      await g.moveBy(const Offset(150, 0));
      await tester.pump();
      expect(_pivot(tester, 'a').dx, closeTo(195, 0.5));
      await g.up();
      await tester.pumpAndSettle();
      expect(log.swiped, isEmpty);
    });

    testWidgets('aynı kartta alt kenar dışında başlayan sürükleme çalışır', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log, shiftY: 400));
      final g = await tester.startGesture(const Offset(195, 700));
      await g.moveBy(const Offset(75, 0));
      await g.moveBy(const Offset(75, 0));
      await g.up();
      await tester.pumpAndSettle();
      expect(log.swiped.single.$2, DeckDecision.ok);
    });
  });

  group('dokunma hâlâ çalışır', () {
    testWidgets('fotoğraf alanına dokunmak fotoğraf değiştirir, deste oynamaz', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log));
      final rect = tester.getRect(_card('a'));
      await tester.tapAt(Offset(rect.right - 30, rect.top + 100));
      await tester.pumpAndSettle();
      expect(log.swiped, isEmpty);
      expect(_pivot(tester, 'a').dx, closeTo(195, 0.5));
      // 2. segment aktif oldu: ön kartın göstergesinde ikinci parça opak beyaz.
      final segs = find.descendant(
        of: _card('a'),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 3 && w.child is DecoratedBox,
        ),
      );
      expect(segs, findsNWidgets(2));
      Color colorOf(int i) =>
          ((tester.widget<SizedBox>(segs.at(i)).child! as DecoratedBox)
                      .decoration
                  as ShapeDecoration)
              .color!;
      expect(colorOf(0).a, lessThan(1));
      expect(colorOf(1).a, 1);
    });
  });

  group('Reduce Motion', () {
    testWidgets('karar anında, çökme yok; öne gelen kart tam boyutta', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log), disableAnimations: true);
      await _slowDrag(tester, const Offset(130, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 5));
      expect(log.swiped.single.$2, DeckDecision.ok);
      expect(_card('a'), findsNothing);
      expect(_width(tester, 'b'), closeTo(350, 0.01));
      expect(tester.takeException(), isNull);
    });
  });

  group('yazı 2x', () {
    testWidgets('taşma yok; sürükleme çalışır', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _deck(log), textScale: 2);
      await _slowDrag(tester, const Offset(130, 0));
      await tester.pumpAndSettle();
      expect(log.swiped.single.$2, DeckDecision.ok);
      expect(tester.takeException(), isNull);
    });
  });
}
