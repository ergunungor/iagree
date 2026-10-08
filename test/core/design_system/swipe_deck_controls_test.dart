import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/deck/deck_action_bar.dart';
import 'package:iagree/core/design_system/components/deck/deck_card.dart';
import 'package:iagree/core/design_system/components/deck/deck_top_bar.dart';
import 'package:iagree/core/design_system/components/deck/swipe_deck.dart';
import 'package:iagree/core/design_system/components/deck/swipe_deck_physics.dart';
import 'package:iagree/core/design_system/components/deck/swipe_deck_scaffold.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/foundations/app_pressable.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

final _light = AppColors.light;

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532); // 390 × 844
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

class _Log {
  final swiped = <(String, DeckDecision)>[];
  final undone = <(String, DeckDecision)>[];
  int completed = 0;
  int hintShown = 0;
  int back = 0;
}

Widget _screen(
  _Log log, {
  SwipeDeckController? controller,
  List<String> items = const ['a', 'b', 'c'],
  bool hint = false,
  double height = 700,
}) => SizedBox(
  width: 350,
  height: height,
  child: SwipeDeckScaffold<String>(
    items: items,
    controller: controller,
    showHint: hint,
    onHintShown: () => log.hintShown++,
    onBack: () => log.back++,
    onSwiped: (i, d) => log.swiped.add((i, d)),
    onUndo: (i, d) => log.undone.add((i, d)),
    onCompleted: () => log.completed++,
    itemBuilder: (context, item) => DeckCard.place(
      key: ValueKey('card-$item'),
      name: 'Mekan $item',
      photos: const [ColoredBox(color: Colors.red)],
      rating: 4.6,
      category: 'Kafe',
    ),
  ),
);

Finder _card(String item) => find.byKey(ValueKey('card-$item'));

Offset _pivot(WidgetTester tester, String item) {
  final f = _card(item);
  return (tester.getBottomLeft(f) + tester.getBottomRight(f)) / 2;
}

double _width(WidgetTester tester, String item) =>
    (tester.getBottomRight(_card(item)) - tester.getTopLeft(_card(item))).dx;

/// Alt butonlar soldan sağa: 0 Pas, 1 Olmaz, 2 Çok isterim, 3 Olur.
Finder _button(int i) => find
    .descendant(
      of: find.byType(DeckActionBar),
      matching: find.byType(AppPressable),
    )
    .at(i);

Finder get _undo => find.descendant(
  of: find.byType(DeckTopBar),
  matching: find.byIcon(AppIcons.undo),
);

bool _undoEnabled(WidgetTester tester) =>
    tester
        .widget<AppPressable>(
          find.ancestor(of: _undo, matching: find.byType(AppPressable)),
        )
        .onPressed !=
    null;

Future<void> _tapButton(WidgetTester tester, int i) async {
  await tester.tap(_button(i));
}

void main() {
  final haptics = <String>[];

  setUp(() {
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('alt butonlar', () {
    testWidgets(
      'sıra ve boyutlar: Pas 56 · Olmaz 44 · Çok isterim 44 · Olur 56',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, _screen(_Log()));
        expect(
          find.byType(AppPressable).evaluate().length,
          greaterThanOrEqualTo(4),
        );
        final sizes = [for (var i = 0; i < 4; i++) tester.getSize(_button(i))];
        expect(sizes.map((s) => s.width), [56, 44, 44, 56]);
        expect(sizes.map((s) => s.height), [56, 44, 44, 56]);
        final xs = [
          for (var i = 0; i < 4; i++) tester.getCenter(_button(i)).dx,
        ];
        expect(xs, orderedEquals([...xs]..sort()));
        // Aralık 16.
        expect(
          tester.getTopLeft(_button(1)).dx - tester.getTopRight(_button(0)).dx,
          16,
        );
      },
    );

    testWidgets(
      'renkler: surface + ikon renkleri; Olur brand dolgu + onBrand',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, _screen(_Log()));
        Color iconColor(int i) => tester
            .widget<Icon>(
              find.descendant(of: _button(i), matching: find.byType(Icon)),
            )
            .color!;
        expect(iconColor(0), _light.textSecondary);
        expect(iconColor(1), _light.error);
        expect(iconColor(2), _light.brand);
        expect(iconColor(3), _light.onBrand);
        Color? fill(int i) => tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: _button(i),
                matching: find.byType(DecoratedBox),
              ),
            )
            .map((d) => d.decoration)
            .whereType<ShapeDecoration>()
            .first
            .color;
        expect(fill(0), _light.surface);
        expect(fill(1), _light.surface);
        expect(fill(2), _light.surface);
        expect(fill(3), _light.brand);
      },
    );

    final cases = {
      0: DeckDecision.pass,
      1: DeckDecision.veto,
      2: DeckDecision.love,
      3: DeckDecision.ok,
    };
    for (final e in cases.entries) {
      testWidgets('butona basınca kart uçar: ${e.value.name}', (tester) async {
        _phone(tester);
        final log = _Log();
        await pumpApp(tester, _screen(log));
        await _tapButton(tester, e.key);
        await tester.pumpAndSettle();
        expect(log.swiped, [('a', e.value)]);
        expect(_card('a'), findsNothing);
        expect(_card('b'), findsOneWidget);
        expect(_width(tester, 'b'), closeTo(_width(tester, 'b'), 0.01));
      });
    }

    testWidgets('uçuş süresi emphasis (300 ms), exit eğrisi', (tester) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log()));
      await _tapButton(tester, 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(_card('a'), findsOneWidget); // hâlâ uçuyor
      expect(_pivot(tester, 'a').dx, greaterThan(195));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(_card('a'), findsNothing);
    });

    testWidgets('uçuş sırasında ikinci basış yok sayılır', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log));
      await _tapButton(tester, 3);
      await tester.pump(const Duration(milliseconds: 50));
      await _tapButton(tester, 0);
      await tester.pumpAndSettle();
      expect(log.swiped.length, 1);
    });

    testWidgets('deste bitince butonlar pasif ve soluk', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log, items: const ['a']));
      await _tapButton(tester, 3);
      await tester.pumpAndSettle();
      expect(log.completed, 1);
      expect(tester.widget<AppPressable>(_button(3)).onPressed, isNull);
      await tester.tap(_button(3));
      await tester.pumpAndSettle();
      expect(log.swiped.length, 1);
    });

    testWidgets('sürüklerken ilgili buton vurgulanır, diğerleri soluklaşır', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log()));
      final base = tester.getSize(_button(3)).width;
      final g = await tester.startGesture(
        _pivot(tester, 'a') - const Offset(0, 200),
      );
      await g.moveBy(const Offset(110, 0)); // eşik 105: ilerleme 1
      await tester.pump();
      final scaled = tester
          .getRect(
            find
                .descendant(of: _button(3), matching: find.byType(SizedBox))
                .first,
          )
          .width;
      expect(scaled, closeTo(base * DeckActionBar.highlightScale, 0.5));
      double opacityOf(int i) => tester
          .widget<Opacity>(
            find
                .descendant(of: _button(i), matching: find.byType(Opacity))
                .first,
          )
          .opacity;
      expect(opacityOf(0), closeTo(DeckActionBar.fadedOpacity, 0.01));
      expect(opacityOf(1), closeTo(DeckActionBar.fadedOpacity, 0.01));
      expect(opacityOf(3), 1);
      await g.up();
      await tester.pumpAndSettle();
      expect(
        tester
            .getRect(
              find
                  .descendant(of: _button(3), matching: find.byType(SizedBox))
                  .first,
            )
            .width,
        closeTo(base, 0.5),
      );
      expect(opacityOf(0), 1);
    });

    testWidgets('Çok isterim vurgusu: brand dolgu + onBrand ikon', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log()));
      final g = await tester.startGesture(
        _pivot(tester, 'a') - const Offset(0, 200),
      );
      await g.moveBy(const Offset(0, -120));
      await tester.pump();
      final fill = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: _button(2),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<ShapeDecoration>()
          .first
          .color!;
      expect(fill.toARGB32(), _light.brand.toARGB32());
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: _button(2), matching: find.byType(Icon)),
            )
            .color,
        _light.onBrand,
      );
      await g.up();
      await tester.pumpAndSettle();
    });
  });

  group('üst bar', () {
    testWidgets('1/3, ilerleme çubuğu pill, caption tabular', (tester) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log()));
      final t = tester.widget<Text>(find.text('1/3'));
      expect(t.style!.fontSize, 13);
      expect(t.style!.color, _light.textSecondary);
      expect(
        t.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(tester.getSize(find.byType(AnimatedBuilder).first), isNotNull);
    });

    testWidgets('kartlar ilerledikçe sayaç ve progress artar; sonda 3/3', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log()));
      await _tapButton(tester, 3);
      await tester.pumpAndSettle();
      expect(find.text('2/3'), findsOneWidget);
      await _tapButton(tester, 3);
      await tester.pumpAndSettle();
      await _tapButton(tester, 3);
      await tester.pumpAndSettle();
      expect(find.text('3/3'), findsOneWidget);
    });

    testWidgets('geri düğmesi onBack çağırır', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log));
      await tester.tap(
        find.descendant(
          of: find.byType(DeckTopBar),
          matching: find.byIcon(AppIcons.back),
        ),
      );
      expect(log.back, 1);
    });

    testWidgets('Geri al başta pasif, karardan sonra aktif', (tester) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log()));
      expect(_undoEnabled(tester), isFalse);
      await _tapButton(tester, 3);
      await tester.pump(const Duration(milliseconds: 50));
      expect(_undoEnabled(tester), isFalse); // uçuş sürerken kapalı
      await tester.pumpAndSettle();
      expect(_undoEnabled(tester), isTrue);
    });

    testWidgets('üst bar öğeleri 44pt hit alanında, ikonlar 24', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log()));
      for (final icon in [AppIcons.back, AppIcons.undo]) {
        final p = find.ancestor(
          of: find.descendant(
            of: find.byType(DeckTopBar),
            matching: find.byIcon(icon),
          ),
          matching: find.byType(AppPressable),
        );
        expect(tester.getSize(p).width, greaterThanOrEqualTo(44));
        expect(tester.getSize(p).height, greaterThanOrEqualTo(44));
      }
    });
  });

  group('Geri al', () {
    testWidgets('son kart çıktığı yönden geri gelir, onUndo çağrılır', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log));
      final start = _pivot(tester, 'a');
      await _tapButton(tester, 3); // Olur → sağa
      await tester.pumpAndSettle();
      expect(_card('a'), findsNothing);

      await tester.tap(_undo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // Sağ dışından geliyor.
      expect(_pivot(tester, 'a').dx, greaterThan(start.dx + 200));
      await tester.pumpAndSettle();
      expect(_pivot(tester, 'a').dx, closeTo(start.dx, 0.5));
      expect(_pivot(tester, 'a').dy, closeTo(start.dy, 0.5));
      expect(log.undone, [('a', DeckDecision.ok)]);
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('yukarı çıkan kart yukarıdan, sola giden soldan geri gelir', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log));
      final start = _pivot(tester, 'a');
      await _tapButton(tester, 2); // Çok isterim → yukarı
      await tester.pumpAndSettle();
      await tester.tap(_undo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(_pivot(tester, 'a').dy, lessThan(start.dy - 300));
      await tester.pumpAndSettle();

      await _tapButton(tester, 0); // Pas → sola
      await tester.pumpAndSettle();
      await tester.tap(_undo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(_pivot(tester, 'a').dx, lessThan(start.dx - 200));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'şimdiki ön kart arka kata iner (0,95), geri gelen tam boyutta',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, _screen(_Log()));
        await _tapButton(tester, 3);
        await tester.pumpAndSettle();
        await tester.tap(_undo);
        await tester.pumpAndSettle();
        expect(_width(tester, 'a'), closeTo(_width(tester, 'a'), 0.01));
        expect(_width(tester, 'b'), lessThan(_width(tester, 'a')));
        expect(_width(tester, 'b') / _width(tester, 'a'), closeTo(0.95, 0.005));
      },
    );

    testWidgets('tek seviye: iki karar sonrası bir kez geri alınır', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log));
      await _tapButton(tester, 3);
      await tester.pumpAndSettle();
      await _tapButton(tester, 0);
      await tester.pumpAndSettle();
      await tester.tap(_undo);
      await tester.pumpAndSettle();
      expect(log.undone, [('b', DeckDecision.pass)]);
      expect(_card('b'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);
      expect(_undoEnabled(tester), isFalse); // a'ya daha geri gidilmez
    });

    testWidgets('deste bittikten sonra son kart geri alınabilir', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log, items: const ['a']));
      await _tapButton(tester, 3);
      await tester.pumpAndSettle();
      expect(log.completed, 1);
      await tester.tap(_undo);
      await tester.pumpAndSettle();
      expect(_card('a'), findsOneWidget);
      expect(tester.widget<AppPressable>(_button(3)).onPressed, isNotNull);
    });

    testWidgets('geri alınan kart yeniden sürüklenebilir', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log));
      await _tapButton(tester, 3);
      await tester.pumpAndSettle();
      await tester.tap(_undo);
      await tester.pumpAndSettle();
      await tester.timedDrag(
        _card('a'),
        const Offset(-130, 0),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(log.swiped.last, ('a', DeckDecision.pass));
    });
  });

  group('haptic', () {
    testWidgets(
      'Olur/Pas light, Çok isterim medium, Olmaz rigid, Geri al light',
      (tester) async {
        _phone(tester);
        await pumpApp(
          tester,
          _screen(_Log(), items: const ['a', 'b', 'c', 'd', 'e']),
        );
        await _tapButton(tester, 3);
        await tester.pumpAndSettle();
        expect(haptics, ['HapticFeedbackType.lightImpact']);
        haptics.clear();
        await _tapButton(tester, 0);
        await tester.pumpAndSettle();
        expect(haptics, ['HapticFeedbackType.lightImpact']);
        haptics.clear();
        await _tapButton(tester, 2);
        await tester.pumpAndSettle();
        expect(haptics, ['HapticFeedbackType.mediumImpact']);
        haptics.clear();
        await _tapButton(tester, 1);
        await tester.pumpAndSettle();
        expect(haptics, [
          'HapticFeedbackType.heavyImpact',
        ]); // rigid → heavy (Android)
        haptics.clear();
        await tester.tap(_undo);
        await tester.pumpAndSettle();
        expect(haptics, ['HapticFeedbackType.lightImpact']);
      },
    );

    testWidgets(
      'sürükleyerek karar da aynı haptic\'i verir (eşik selection + karar)',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, _screen(_Log()));
        await tester.timedDrag(
          _card('a'),
          const Offset(0, -130),
          const Duration(seconds: 2),
        );
        await tester.pumpAndSettle();
        expect(haptics, [
          'HapticFeedbackType.selectionClick',
          'HapticFeedbackType.mediumImpact',
        ]);
      },
    );
  });

  group('erişilebilirlik', () {
    testWidgets('üst bar ve butonlar etiketli', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _screen(_Log()));
      expect(find.bySemanticsLabel('Kart 1, toplam 3'), findsOneWidget);
      expect(find.bySemanticsLabel('Odaya dön'), findsOneWidget);
      expect(find.bySemanticsLabel('Geri al'), findsOneWidget);
      for (final l in ['Pas', 'Olmaz', 'Çok isterim', 'Olur']) {
        expect(find.bySemanticsLabel(l), findsWidgets);
      }
      handle.dispose();
    });

    testWidgets(
      'kartın bilgi panelinde 4 özel eylem; eylem kartı yönlendirir',
      (tester) async {
        _phone(tester);
        final handle = tester.ensureSemantics();
        final log = _Log();
        await pumpApp(tester, _screen(log));
        final node = tester.getSemantics(
          find.bySemanticsLabel(RegExp('Mekan a, 4,6 puan')),
        );
        final ids = node.getSemanticsData().customSemanticsActionIds!;
        final labels = {
          for (final id in ids) CustomSemanticsAction.getAction(id)!.label,
        };
        expect(labels, {'Olur', 'Pas', 'Çok isterim', 'Olmaz'});

        final action = ids.firstWhere(
          (id) => CustomSemanticsAction.getAction(id)!.label == 'Çok isterim',
        );
        tester.semantics.performAction(
          find.semantics.byLabel(RegExp('Mekan a, 4,6 puan')),
          SemanticsAction.customAction,
          args: action,
        );
        await tester.pumpAndSettle();
        expect(log.swiped, [('a', DeckDecision.love)]);
        handle.dispose();
      },
    );

    testWidgets('arka kartta özel eylem yok', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _screen(_Log()));
      // Arka kart (b) etiketi yalnızca ön kartınkinden ayrı bir düğümde ve eylemsiz.
      final back = find.bySemanticsLabel(RegExp('Mekan b, 4,6 puan'));
      if (back.evaluate().isNotEmpty) {
        final ids = tester
            .getSemantics(back)
            .getSemanticsData()
            .customSemanticsActionIds;
        expect(ids == null || ids.isEmpty, isTrue);
      }
      handle.dispose();
    });
  });

  group('Reduce Motion', () {
    testWidgets('buton: kart uçmaz, yerinde solar (200 ms)', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log), disableAnimations: true);
      final start = _pivot(tester, 'a');
      await _tapButton(tester, 3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_card('a'), findsOneWidget);
      expect(_pivot(tester, 'a'), start); // yer değiştirmedi
      final opacity = tester
          .widget<FadeTransition>(
            find
                .ancestor(of: _card('a'), matching: find.byType(FadeTransition))
                .first,
          )
          .opacity
          .value;
      expect(opacity, inExclusiveRange(0.2, 0.8));
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(_card('a'), findsNothing);
      expect(log.swiped.single.$2, DeckDecision.ok);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Geri al: kart solarak geri gelir, yerinde', (tester) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log()), disableAnimations: true);
      final start = _pivot(tester, 'a');
      await _tapButton(tester, 3);
      await tester.pumpAndSettle();
      await tester.tap(_undo);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_pivot(tester, 'a'), start);
      await tester.pumpAndSettle();
      expect(_card('a'), findsOneWidget);
    });

    testWidgets('sürüklemeyle karar da solar, çökme yok', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log), disableAnimations: true);
      await tester.timedDrag(
        _card('a'),
        const Offset(130, 0),
        const Duration(seconds: 2),
      );
      await tester.pumpAndSettle();
      expect(log.swiped.single.$2, DeckDecision.ok);
      expect(tester.takeException(), isNull);
    });
  });

  group('öğretici kıpırdama', () {
    testWidgets(
      '24pt sağa-sola, 2 döngü, 1,2 sn; sonra yerinde, bir kez bildirir',
      (tester) async {
        _phone(tester);
        final log = _Log();
        await pumpApp(tester, _screen(log, hint: true), settle: false);
        await tester.pump(); // ilk kare
        await tester.pump(); // post-frame: başlar
        final start = _pivot(tester, 'a');
        await tester.pump(const Duration(milliseconds: 150));
        expect(_pivot(tester, 'a').dx - start.dx, closeTo(24, 1.5)); // sağ tepe
        await tester.pump(const Duration(milliseconds: 300));
        expect(
          _pivot(tester, 'a').dx - start.dx,
          closeTo(-24, 1.5),
        ); // sol tepe
        await tester.pump(const Duration(milliseconds: 300));
        expect(_pivot(tester, 'a').dx - start.dx, closeTo(24, 1.5)); // 2. döngü
        expect(log.hintShown, 0);
        await tester.pumpAndSettle();
        expect(_pivot(tester, 'a'), start);
        expect(log.hintShown, 1);
        expect(log.swiped, isEmpty);
      },
    );

    testWidgets('dört yön ipucu kıpırdama sürerken görünür, sonra kaybolur', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log(), hint: true), settle: false);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      for (final l in ['Çok isterim', 'Pas', 'Olmaz']) {
        expect(find.text(l), findsOneWidget);
      }
      // Kıpırdamada karar etiketi yok: 'Olur' yalnızca ipucu pill'inde.
      expect(find.text('Olur'), findsOneWidget);
      await tester.pumpAndSettle();
      for (final l in ['Çok isterim', 'Pas', 'Olmaz', 'Olur']) {
        expect(find.text(l), findsNothing);
      }
    });

    testWidgets('dokununca kıpırdama kesilir ve bildirilir', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log, hint: true), settle: false);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final g = await tester.startGesture(
        _pivot(tester, 'a') - const Offset(0, 200),
      );
      await g.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(log.hintShown, 1);
      expect(_pivot(tester, 'a').dx - 195, closeTo(40, 1));
      await g.up();
      await tester.pumpAndSettle();
      expect(log.hintShown, 1);
    });

    testWidgets('showHint false: kıpırdama yok', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log), settle: false);
      await tester.pump();
      await tester.pump();
      final start = _pivot(tester, 'a');
      await tester.pump(const Duration(milliseconds: 150));
      expect(_pivot(tester, 'a'), start);
      expect(log.hintShown, 0);
    });

    testWidgets('Reduce Motion: kıpırdama yok, ipucu gösterilmiş sayılmaz', (
      tester,
    ) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(
        tester,
        _screen(log, hint: true),
        disableAnimations: true,
        settle: false,
      );
      await tester.pump();
      await tester.pump();
      final start = _pivot(tester, 'a');
      await tester.pump(const Duration(milliseconds: 300));
      expect(_pivot(tester, 'a'), start);
      expect(log.hintShown, 0);
    });
  });

  group('yerleşim', () {
    testWidgets('kart, üst bar ile butonlar arasında dikey ortada', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log()));
      final bar = tester.getRect(find.byType(DeckTopBar));
      final actions = tester.getRect(find.byType(DeckActionBar));
      final card = tester.getRect(_card('a'));
      // Butonların üstünde 8pt boşluk var; kart bar ile o boşluğun arasında ortalı.
      final mid = (bar.bottom + actions.top - 8) / 2;
      expect(card.center.dy, closeTo(mid, 1));
    });

    testWidgets('yükseklik azsa kart küçülür, 3:4 korunur', (tester) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log(), height: 480));
      final card = tester.getRect(_card('a'));
      expect(card.width / card.height, closeTo(0.75, 0.001));
      expect(card.width, lessThan(350));
      expect(tester.takeException(), isNull);
    });

    testWidgets('yazı 2x: taşma yok, buton ve çubuk çalışır', (tester) async {
      _phone(tester);
      final log = _Log();
      await pumpApp(tester, _screen(log), textScale: 2);
      await _tapButton(tester, 3);
      await tester.pumpAndSettle();
      expect(log.swiped.single.$2, DeckDecision.ok);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark tema: çökme yok, butonlar dark renkte', (tester) async {
      _phone(tester);
      await pumpApp(tester, _screen(_Log()), dark: true);
      final c = tester
          .widget<Icon>(
            find.descendant(of: _button(2), matching: find.byType(Icon)),
          )
          .color;
      expect(c, AppColors.dark.brand);
    });
  });
}
