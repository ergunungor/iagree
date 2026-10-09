import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/app/app.dart';
import 'package:iagree/app/platform_services.dart';
import 'package:iagree/app/rooms_controller.dart';
import 'package:iagree/app/settings_controller.dart';
import 'package:iagree/core/data/mock/mock_auth_repository.dart';
import 'package:iagree/core/data/mock/mock_rooms_repository.dart';
import 'package:iagree/core/design_system/components/buttons/app_button.dart';
import 'package:iagree/core/design_system/components/inputs/app_slider.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/features/home/home_screen.dart';
import 'package:iagree/features/rooms/create_details_screen.dart';
import 'package:iagree/features/rooms/create_what_screen.dart';
import 'package:iagree/features/rooms/room_screen.dart';

late MockRoomsRepository _repo;
final List<String> _haptics = [];
final List<String> _clipboard = [];
final List<String> _shared = [];
LocationAccess _access = LocationAccess.granted;

class _Sharer implements LinkSharer {
  @override
  Future<void> share(String link) async => _shared.add(link);
}

class _Location implements LocationService {
  @override
  Future<LocationAccess> request() async => _access;
}

Future<void> _launch(
  WidgetTester tester, {
  MockRoomsScenario scenario = MockRoomsScenario.mixed,
  double textScale = 1,
  Brightness brightness = Brightness.light,
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
  _haptics.clear();
  _clipboard.clear();
  _shared.clear();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') _haptics.add('x');
        if (call.method == 'Clipboard.setData') {
          _clipboard.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  _repo = MockRoomsRepository(
    scenario: scenario,
    latency: const Duration(milliseconds: 50),
  );
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: IAgreeApp(
        auth: MockAuthRepository(startSignedIn: true),
        rooms: RoomsController(repository: _repo),
        settings: SettingsController(),
        sharer: _Sharer(),
        location: _Location(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

Future<void> _settle(WidgetTester tester, [int ms = 700]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

Future<void> _openCreate(WidgetTester tester) async {
  await tester.tap(find.byIcon(AppIcons.plus));
  await _settle(tester);
  await tester.pump(const Duration(milliseconds: 200)); // katalog yüklenir
}

Future<void> _pickDistrict(WidgetTester tester, String name) async {
  await tester.tap(find.text('Konum seç'));
  await _settle(tester);
  await tester.tap(find.text(name));
  await _settle(tester);
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.text('Odayı kur'));
  await _settle(tester); // sahte gecikme biter, rota geçişi başlar
  await _settle(tester); // geçiş biter
}

Future<void> _tapCategory(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.text(label),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(find.text(label));
  await _settle(tester);
}

Future<void> _toRoom(WidgetTester tester) async {
  await _openCreate(tester);
  await _tapCategory(tester, 'Yemek');
  await _settle(tester);
  await _pickDistrict(tester, 'Moda, Kadıköy');
  await _submit(tester);
}

Future<void> _tapMore(WidgetTester tester) async {
  await tester.tap(find.byIcon(AppIcons.more));
  await _settle(tester);
}

void main() {
  group('adım 1: Ne yapıyorsunuz?', () {
    testWidgets('+ tam ekran modal açar; tema ve kategoriler gelir', (
      tester,
    ) async {
      await _launch(tester);
      await tester.tap(find.byIcon(AppIcons.plus));
      await _settle(tester);
      expect(find.byType(CreateWhatScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Ne yapıyorsunuz?'), findsOneWidget);
      expect(find.text('Bugüne özel'), findsOneWidget);
      expect(find.text('Yağmurlu hava'), findsOneWidget);
      expect(find.text('Kategoriler'), findsOneWidget);
      for (final c in ['Yemek', 'Kahve', 'Film ve dizi', 'Fark etmez']) {
        expect(find.text(c), findsOneWidget, reason: c);
      }
    });

    testWidgets('✕ Odalarım\'a döner', (tester) async {
      await _launch(tester);
      await _openCreate(tester);
      await tester.tap(find.byIcon(AppIcons.close));
      await _settle(tester);
      expect(find.byType(CreateWhatScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('kategoriye dokunmak doğrudan 2. adıma geçer', (tester) async {
      await _launch(tester);
      await _openCreate(tester);
      await tester.tap(find.text('Kahve'));
      await _settle(tester);
      expect(find.byType(CreateDetailsScreen), findsOneWidget);
      expect(find.text('Nerede, ne zaman?'), findsOneWidget);
    });
  });

  group('adım 2: Nerede, ne zaman?', () {
    testWidgets('mekan: konum, mesafe, zaman, bütçe, oda adı önerisi', (
      tester,
    ) async {
      await _launch(tester);
      await _openCreate(tester);
      await tester.tap(find.text('Yemek'));
      await _settle(tester);
      expect(find.text('Nerede'), findsOneWidget);
      expect(find.byType(AppSlider), findsOneWidget);
      expect(find.text('3 km'), findsOneWidget);
      expect(find.text('Ne zaman'), findsOneWidget);
      expect(find.text('Bütçe'), findsOneWidget);
      expect(find.text('₺₺'), findsOneWidget);
      expect(find.text('Hangi platform?'), findsNothing);
      final name = tester.widget<TextField>(find.byType(TextField).last);
      expect(name.controller!.text, 'Bu akşam yemek');
    });

    testWidgets('tema kartı: kategori ve zaman hazır gelir', (tester) async {
      await _launch(tester);
      await _openCreate(tester);
      await tester.tap(find.text('Yağmurlu hava'));
      await _settle(tester);
      final name = tester.widget<TextField>(find.byType(TextField).last);
      expect(name.controller!.text, 'Şimdi kahve');
    });

    testWidgets('zaman değişince öneri güncellenir; elle yazılan ad korunur', (
      tester,
    ) async {
      await _launch(tester);
      await _openCreate(tester);
      await tester.tap(find.text('Yemek'));
      await _settle(tester);
      await tester.tap(find.text('Hafta sonu'));
      await tester.pump();
      var name = tester.widget<TextField>(find.byType(TextField).last);
      expect(name.controller!.text, 'Hafta sonu yemek');
      await tester.enterText(find.byType(TextField).last, 'Bizimkiler');
      await tester.pump();
      await tester.ensureVisible(find.text('Şimdi'));
      await tester.pump();
      await tester.tap(find.text('Şimdi'));
      await tester.pump();
      name = tester.widget<TextField>(find.byType(TextField).last);
      expect(name.controller!.text, 'Bizimkiler');
    });

    testWidgets('Tarih seç: sheet, seçince chip tarihi gösterir', (
      tester,
    ) async {
      await _launch(tester);
      await _openCreate(tester);
      await tester.tap(find.text('Yemek'));
      await _settle(tester);
      await tester.tap(find.text('Tarih seç'));
      await _settle(tester);
      expect(find.text('Seç'), findsOneWidget);
      await tester.tap(find.text('Seç'));
      await _settle(tester);
      expect(find.text('Tarih seç'), findsNothing);
      final name = tester.widget<TextField>(find.byType(TextField).last);
      expect(name.controller!.text, isNot('Bu akşam yemek'));
      expect(name.controller!.text, endsWith(' yemek'));
    });

    testWidgets('konum seçilmeden Odayı kur: hata + error haptic, ilerlemez', (
      tester,
    ) async {
      await _launch(tester);
      await _openCreate(tester);
      await tester.tap(find.text('Yemek'));
      await _settle(tester);
      _haptics.clear();
      await _submit(tester);
      expect(find.text('Bir konum seç.'), findsOneWidget);
      expect(_haptics, isNotEmpty);
      expect(find.byType(CreateDetailsScreen), findsOneWidget);
    });

    testWidgets('boş oda adı işaretlenir', (tester) async {
      await _launch(tester);
      await _openCreate(tester);
      await tester.tap(find.text('Yemek'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField).last, '  ');
      await _submit(tester);
      expect(find.text('Oda adı gir.'), findsOneWidget);
    });

    testWidgets('film: konum/bütçe yok, platform zorunlu', (tester) async {
      await _launch(tester);
      await _openCreate(tester);
      await tester.tap(find.text('Film ve dizi'));
      await _settle(tester);
      expect(find.text('Nerede'), findsNothing);
      expect(find.text('Bütçe'), findsNothing);
      expect(find.text('Hangi platform?'), findsOneWidget);
      await _submit(tester);
      expect(find.text('En az bir platform seç.'), findsOneWidget);
      await tester.tap(find.text('Netflix'));
      await tester.pump();
      await _submit(tester);
      expect(find.byType(RoomScreen), findsOneWidget);
      expect(find.text('Netflix'), findsOneWidget); // çerçeve etiketi
    });
  });

  group('oda ekranı (D2)', () {
    testWidgets('kurulunca oda açılır: ad, çerçeve etiketleri, davet', (
      tester,
    ) async {
      await _launch(tester);
      await _toRoom(tester);
      expect(find.byType(RoomScreen), findsOneWidget);
      expect(find.byType(CreateDetailsScreen), findsNothing);
      expect(find.text('Bu akşam yemek'), findsOneWidget);
      for (final tag in ['Yemek', 'Bu akşam', '₺₺', 'Moda, Kadıköy · 3 km']) {
        expect(find.text(tag), findsOneWidget, reason: tag);
      }
      expect(find.text('Arkadaşlarını çağır'), findsOneWidget);
      expect(find.text('iagree.app/r/oda-1'), findsOneWidget);
      expect(find.text('Önce ben seçeyim'), findsOneWidget);
      final primaries = tester
          .widgetList<AppButton>(find.byType(AppButton))
          .where((b) => b.variant == AppButtonVariant.primary);
      expect(primaries.single.label, 'Linki paylaş');
    });

    testWidgets('geri Odalarım\'a döner; yeni oda listede "Sıra sende"', (
      tester,
    ) async {
      await _launch(tester);
      await _toRoom(tester);
      await tester.tap(find.byIcon(AppIcons.back));
      await _settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(RoomScreen), findsNothing);
      expect(find.text('Bu akşam yemek'), findsOneWidget);
    });

    testWidgets('Odalarım\'dan yeni odaya dokunmak odayı açar', (tester) async {
      await _launch(tester);
      await _toRoom(tester);
      await tester.tap(find.byIcon(AppIcons.back));
      await _settle(tester);
      await tester.tap(find.text('Bu akşam yemek'));
      await _settle(tester);
      expect(find.byType(RoomScreen), findsOneWidget);
    });

    testWidgets('Kopyala: link panoya gider, toast çıkar', (tester) async {
      await _launch(tester);
      await _toRoom(tester);
      await tester.tap(find.text('Kopyala'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(_clipboard, ['iagree.app/r/oda-1']);
      expect(find.text('Link kopyalandı'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('ilk katılımcı gelince Primary "Seçmeye başla" olur', (
      tester,
    ) async {
      await _launch(tester);
      await _toRoom(tester);
      await tester.tap(find.text('Arkadaş katıldı (debug)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('2 kişi odada'), findsOneWidget);
      expect(find.text('Arkadaşlarını çağır'), findsNothing);
      final primaries = tester
          .widgetList<AppButton>(find.byType(AppButton))
          .where((b) => b.variant == AppButtonVariant.primary);
      expect(primaries.single.label, 'Seçmeye başla');
      expect(find.text('iagree.app/r/oda-1'), findsOneWidget); // link kalır
    });

    testWidgets('oda adını değiştir', (tester) async {
      await _launch(tester);
      await _toRoom(tester);
      await _tapMore(tester);
      await tester.tap(find.text('Oda adını değiştir'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField).last, 'Cuma planı');
      await tester.tap(find.text('Kaydet'));
      await _settle(tester);
      expect(find.text('Cuma planı'), findsOneWidget);
      expect(find.text('Bu akşam yemek'), findsNothing);
    });

    testWidgets('odayı sil: alert, onayla → Odalarım\'da yok', (tester) async {
      await _launch(tester);
      await _toRoom(tester);
      await _tapMore(tester);
      await tester.tap(find.text('Odayı sil'));
      await _settle(tester);
      expect(find.text('Oda silinsin mi?'), findsOneWidget);
      await tester.tap(find.text('Odayı sil').last);
      await _settle(tester);
      expect(find.byType(RoomScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Bu akşam yemek'), findsNothing);
    });

    testWidgets('odayı sil: Vazgeç odada bırakır', (tester) async {
      await _launch(tester);
      await _toRoom(tester);
      await _tapMore(tester);
      await tester.tap(find.text('Odayı sil'));
      await _settle(tester);
      await tester.tap(find.text('Vazgeç'));
      await _settle(tester);
      expect(find.byType(RoomScreen), findsOneWidget);
    });
  });

  group('paylaşım ve konum', () {
    testWidgets('Linki paylaş: paylaşım servisine davet linki gider', (
      tester,
    ) async {
      await _launch(tester);
      await _toRoom(tester);
      await tester.tap(find.text('Linki paylaş'));
      await tester.pump();
      expect(_shared, ['https://iagree.app/r/oda-1']);
    });

    testWidgets('Konumum: izin verilirse seçilir, etikette "Konumum"', (
      tester,
    ) async {
      _access = LocationAccess.granted;
      await _launch(tester);
      await _openCreate(tester);
      await _tapCategory(tester, 'Yemek');
      await _pickDistrict(tester, 'Konumum');
      expect(find.text('Bir konum seç.'), findsNothing);
      await _submit(tester);
      expect(find.text('Konumum · 3 km'), findsOneWidget);
    });

    testWidgets('Konumum: izin reddedilirse toast, semt seçilmiş sayılmaz', (
      tester,
    ) async {
      _access = LocationAccess.denied;
      await _launch(tester);
      await _openCreate(tester);
      await _tapCategory(tester, 'Yemek');
      await _pickDistrict(tester, 'Konumum');
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        find.text('Konum izni verilmedi. Semt seçebilirsin.'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 4));
      await _submit(tester);
      expect(find.byType(CreateDetailsScreen), findsOneWidget);
      expect(find.text('Bir konum seç.'), findsOneWidget);
      _access = LocationAccess.granted;
    });
  });

  group('boş hesaptan ilk oda', () {
    testWidgets('HomeEmpty Primary\'si oda kurmayı açar', (tester) async {
      await _launch(tester, scenario: MockRoomsScenario.empty);
      await tester.tap(find.text('Oda oluştur'));
      await _settle(tester);
      expect(find.byType(CreateWhatScreen), findsOneWidget);
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
        await _openCreate(tester);
        expect(tester.takeException(), isNull);
        await _tapCategory(tester, 'Yemek');
        expect(tester.takeException(), isNull);
        await _pickDistrict(tester, 'Moda, Kadıköy');
        await _submit(tester);
        expect(find.byType(RoomScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Arkadaş katıldı (debug)'),
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.ensureVisible(find.text('Arkadaş katıldı (debug)'));
        await tester.pump();
        await tester.tap(find.text('Arkadaş katıldı (debug)'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
