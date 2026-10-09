import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iagree/app/app.dart';
import 'package:iagree/app/platform_services.dart';
import 'package:iagree/app/rooms_controller.dart';
import 'package:iagree/app/settings_controller.dart';
import 'package:iagree/core/data/mock/mock_auth_repository.dart';
import 'package:iagree/core/data/mock/mock_rooms_repository.dart';
import 'package:iagree/core/design_system/components/buttons/app_button.dart';
import 'package:iagree/core/design_system/components/deck/deck_action_bar.dart';
import 'package:iagree/core/design_system/components/decision/decision_moment.dart';
import 'package:iagree/core/design_system/foundations/app_pressable.dart';
import 'package:iagree/features/decision/deck_screen.dart';
import 'package:iagree/features/decision/decision_screen.dart';
import 'package:iagree/features/decision/results_screen.dart';
import 'package:iagree/features/decision/waiting_screen.dart';
import 'package:iagree/features/home/home_screen.dart';

late MockRoomsRepository _repo;
final List<String> _opened = [];
final List<String> _shared = [];

class _Opener implements UrlOpener {
  @override
  Future<bool> open(Uri uri) async {
    _opened.add(uri.toString());
    return true;
  }
}

Future<void> _launch(
  WidgetTester tester, {
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool notifyPromptSeen = false,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localeTestValue = const Locale('tr');
  tester.platformDispatcher.localesTestValue = const [Locale('tr')];
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  _opened.clear();
  _notifyRequests = 0;
  _shared.clear();
  _repo = MockRoomsRepository(latency: const Duration(milliseconds: 50));
  SharedPreferences.setMockInitialValues({
    'deckHintSeen': true,
    'notificationPromptSeen': notifyPromptSeen,
  });
  final settings = SettingsController();
  await settings.load();
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: IAgreeApp(
        auth: MockAuthRepository(startSignedIn: true),
        rooms: RoomsController(repository: _repo),
        settings: settings,
        opener: _Opener(),
        sharer: _Sharer(),
        notifications: _Notify(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

int _notifyRequests = 0;

class _Notify implements NotificationService {
  @override
  Future<NotificationAccess> status() async => NotificationAccess.granted;

  @override
  Future<NotificationAccess> request() async {
    _notifyRequests++;
    return NotificationAccess.granted;
  }
}

class _Sharer implements LinkSharer {
  @override
  Future<void> share(String link) async => _shared.add(link);
}

Future<void> _settle(WidgetTester tester, [int ms = 700]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

/// Alt butonlar soldan sağa: 0 Pas, 1 Olmaz, 2 Çok isterim, 3 Olur.
Finder _button(int i) => find
    .descendant(
      of: find.byType(DeckActionBar),
      matching: find.byType(AppPressable),
    )
    .at(i);

Future<void> _finishDeck(WidgetTester tester, {int cards = 6}) async {
  await _settle(tester, 300); // deste yüklenir
  for (var i = 0; i < cards; i++) {
    await tester.tap(_button(i.isEven ? 3 : 2));
    await _settle(tester, 600);
  }
  await _settle(tester); // gönderim + geçiş
  await _settle(tester);
}

Future<void> _openYourTurnRoom(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Doğum günü planı'));
  await tester.pump();
  await tester.tap(find.text('Doğum günü planı'));
  await _settle(tester);
}

void main() {
  group('deste → bekleme', () {
    testWidgets('deste yüklenir; kartlar bitince Bekleme açılır', (
      tester,
    ) async {
      await _launch(tester);
      await _openYourTurnRoom(tester);
      expect(find.byType(DeckScreen), findsOneWidget);
      await _finishDeck(tester);
      expect(find.byType(DeckScreen), findsNothing);
      expect(find.byType(WaitingScreen), findsOneWidget);
      expect(find.text('Sen hazırsın'), findsOneWidget);
      expect(find.text('Odaya dön'), findsOneWidget);
    });

    testWidgets('Bekleme: Primary yok, Odaya dön Odalarım\'a götürür', (
      tester,
    ) async {
      await _launch(tester);
      await _openYourTurnRoom(tester);
      await _finishDeck(tester);
      final primaries = tester
          .widgetList<AppButton>(find.byType(AppButton))
          .where((b) => b.variant == AppButtonVariant.primary);
      expect(primaries, isEmpty);
      await tester.tap(find.text('Odaya dön'));
      await _settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      // Oda artık "bekleniyor": listede 3/5 hazır sayacı.
      expect(find.text('3/5 hazır'), findsNWidgets(2));
    });

    testWidgets('bekleyen odaya dokunmak Bekleme\'yi açar', (tester) async {
      await _launch(tester);
      await tester.tap(find.text('Cuma akşamı'));
      await _settle(tester);
      expect(find.byType(WaitingScreen), findsOneWidget);
      expect(find.text('2 kişi daha seçiyor'), findsOneWidget);
    });
  });

  group('bildirim izni kartı', () {
    testWidgets('Bekleme\'de bir kez çıkar; Evet izni ister, kart kalkar', (
      tester,
    ) async {
      await _launch(tester);
      await _openYourTurnRoom(tester);
      await _finishDeck(tester);
      expect(find.text('Sonuçlar hazır olunca haber verelim mi?'), findsOne);
      await tester.tap(find.text('Evet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_notifyRequests, 1);
      expect(find.text('Bildirimler açıldı'), findsOneWidget);
      expect(
        find.text('Sonuçlar hazır olunca haber verelim mi?'),
        findsNothing,
      );
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('Şimdi değil: izin istenmez, kart kalkar', (tester) async {
      await _launch(tester);
      await _openYourTurnRoom(tester);
      await _finishDeck(tester);
      await tester.tap(find.text('Şimdi değil'));
      await tester.pump();
      expect(_notifyRequests, 0);
      expect(
        find.text('Sonuçlar hazır olunca haber verelim mi?'),
        findsNothing,
      );
    });

    testWidgets('daha önce gösterildiyse çıkmaz', (tester) async {
      await _launch(tester, notifyPromptSeen: true);
      await _openYourTurnRoom(tester);
      await _finishDeck(tester);
      expect(
        find.text('Sonuçlar hazır olunca haber verelim mi?'),
        findsNothing,
      );
    });
  });

  group('oybirliği', () {
    testWidgets('herkes bitirince karar anı; kapanınca geçmişe düşer', (
      tester,
    ) async {
      await _launch(tester);
      await _openYourTurnRoom(tester);
      await _finishDeck(tester);
      await tester.tap(find.text('Herkes bitirdi: oybirliği (debug)'));
      await _settle(tester, 300);
      await tester.pumpAndSettle();
      expect(find.byType(DecisionScreen), findsOneWidget);
      expect(find.byType(DecisionMoment), findsOneWidget);
      expect(find.text('Hepiniz anlaştınız.'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Kapat'));
      await _settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      // Oda aktif listeden çıkar, geçmiş kararlara girer.
      expect(find.text('Doğum günü planı'), findsNothing);
    });

    testWidgets('Yol tarifi Apple Maps\'i, Gruba paylaş paylaşımı açar', (
      tester,
    ) async {
      await _launch(tester);
      await _openYourTurnRoom(tester);
      await _finishDeck(tester);
      await tester.tap(find.text('Herkes bitirdi: oybirliği (debug)'));
      await _settle(tester, 300);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(AppButton, 'Yol tarifi al'));
      await tester.pump();
      expect(_opened.single, startsWith('https://maps.apple.com/'));
      await tester.tap(find.widgetWithText(AppButton, 'Gruba paylaş'));
      await tester.pump();
      expect(_shared.single, contains('iAgree'));
    });
  });

  group('oylama', () {
    testWidgets('sonuçlar: en fazla 3 seçenek, pas/olmaz hiçbir yerde yok', (
      tester,
    ) async {
      await _launch(tester);
      await _openYourTurnRoom(tester);
      await _finishDeck(tester);
      await tester.tap(find.text('Herkes bitirdi: oylama (debug)'));
      await _settle(tester, 300);
      await _settle(tester);
      expect(find.byType(ResultsScreen), findsOneWidget);
      expect(find.text('Hangisi olsun?'), findsOneWidget);
      expect(find.text('Oyumu ver'), findsOneWidget);
      expect(find.textContaining('Pas'), findsNothing);
      expect(find.textContaining('Olmaz'), findsNothing);
    });

    testWidgets('Oyumu ver: oy sonrası Dürt; herkes oy verince karar anı', (
      tester,
    ) async {
      await _launch(tester);
      await _openYourTurnRoom(tester);
      await _finishDeck(tester);
      await tester.tap(find.text('Herkes bitirdi: oylama (debug)'));
      await _settle(tester, 300);
      await _settle(tester);
      await tester.tap(find.text('Oyumu ver'));
      await _settle(tester, 300);
      await _settle(tester);
      expect(find.text('Oyumu ver'), findsNothing);
      expect(find.text('Dürt'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Herkes oy verdi (debug)'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Herkes oy verdi (debug)'));
      await _settle(tester, 300);
      await _settle(tester);
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(DecisionScreen), findsOneWidget);
      expect(find.text('Karar verildi.'), findsOneWidget);
      expect(find.textContaining('oyla seçildi'), findsOneWidget);
    });

    testWidgets('Odalarım hero "Oy ver" sonuçları açar', (tester) async {
      await _launch(tester);
      await tester.tap(find.text('Oy ver'));
      await _settle(tester, 300);
      await _settle(tester);
      expect(find.byType(ResultsScreen), findsOneWidget);
      expect(find.text('Mavi Kapı Kahve'), findsWidgets);
    });
  });

  group('detay sheet\'i (D5)', () {
    testWidgets(
      'karta dokununca açılır: adres, saatler, web; adres haritayı açar',
      (tester) async {
        await _launch(tester);
        await _openYourTurnRoom(tester);
        await _settle(tester, 300);
        await tester.tap(find.text('Trattoria Lume'));
        await _settle(tester);
        expect(find.text('Adres'), findsOneWidget);
        expect(find.text('Moda Cd. 112, Kadıköy'), findsOneWidget);
        expect(find.text('Saatler'), findsOneWidget);
        expect(find.text('Menü ve web sitesi'), findsOneWidget);
        await tester.tap(find.text('Adres'));
        await tester.pump();
        expect(_opened.single, startsWith('https://maps.apple.com/'));
        expect(_opened.single, contains('Trattoria'));
      },
    );

    testWidgets('sheet içinden karar: sheet kapanır, deste ilerler', (
      tester,
    ) async {
      await _launch(tester);
      await _openYourTurnRoom(tester);
      await _settle(tester, 300);
      expect(find.text('1/6'), findsOneWidget);
      await tester.tap(find.text('Trattoria Lume'));
      await _settle(tester);
      // Sheet içindeki aksiyon çubuğu: Olur (son buton).
      final sheetButtons = find.descendant(
        of: find.byType(DeckActionBar).last,
        matching: find.byType(AppPressable),
      );
      await tester.tap(sheetButtons.last);
      await _settle(tester, 600);
      await _settle(tester, 600);
      expect(find.text('Adres'), findsNothing);
      expect(find.text('2/6'), findsOneWidget);
    });
  });

  group('eşitlik: son söz', () {
    Future<void> toVoted(WidgetTester tester) async {
      await _launch(tester);
      await _openYourTurnRoom(tester);
      await _finishDeck(tester);
      await tester.tap(find.text('Herkes bitirdi: oylama (debug)'));
      await _settle(tester, 300);
      await _settle(tester);
      await tester.tap(find.text('Oyumu ver'));
      await _settle(tester, 300);
      await _settle(tester);
    }

    Future<void> tie(WidgetTester tester, String label) async {
      await tester.scrollUntilVisible(
        find.text(label),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text(label));
      await tester.pump();
      await tester.tap(find.text(label));
      await _settle(tester, 300);
      await _settle(tester);
    }

    testWidgets(
      'oda sahibi: iki seçenek, seçince Primary açılır, karar verilir',
      (tester) async {
        await toVoted(tester);
        await tie(tester, 'Eşitlik: son söz bende (debug)');
        expect(find.text('Oylar eşit çıktı'), findsOneWidget);
        expect(
          find.text('Son söz sende. Eşit çıkan seçeneklerden birini seç.'),
          findsOneWidget,
        );
        final confirm = find.widgetWithText(AppButton, 'Bunu seç');
        expect(tester.widget<AppButton>(confirm).onPressed, isNull);
        await tester.tap(find.text('Mavi Kapı Kahve').first);
        await tester.pump();
        expect(tester.widget<AppButton>(confirm).onPressed, isNotNull);
        await tester.tap(confirm);
        await _settle(tester, 300);
        await tester.pumpAndSettle();
        expect(find.byType(DecisionScreen), findsOneWidget);
        expect(find.text('Karar verildi.'), findsOneWidget);
      },
    );

    testWidgets('diğer üyeler: karar sahibi yazılır, buton yok', (
      tester,
    ) async {
      await toVoted(tester);
      await tie(tester, 'Eşitlik: son söz başkasında (debug)');
      expect(find.text('Oylar eşit çıktı'), findsOneWidget);
      expect(find.textContaining('Son kararı oda sahibi'), findsOneWidget);
      expect(find.text('Bunu seç'), findsNothing);
    });
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('taşma yok: ${dark ? 'dark' : 'light'}, ${scale}x', (
        tester,
      ) async {
        await _launch(
          tester,
          textScale: scale,
          brightness: dark ? Brightness.dark : Brightness.light,
        );
        await _openYourTurnRoom(tester);
        await _settle(tester, 300);
        expect(tester.takeException(), isNull);
        await _finishDeck(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Herkes bitirdi: oylama (debug)'));
        await _settle(tester, 300);
        await _settle(tester);
        expect(find.byType(ResultsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
