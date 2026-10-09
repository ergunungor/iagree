import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/app/app.dart';
import 'package:iagree/app/platform_services.dart';
import 'package:iagree/app/rooms_controller.dart';
import 'package:iagree/app/settings_controller.dart';
import 'package:iagree/core/data/mock/mock_auth_repository.dart';
import 'package:iagree/core/data/mock/mock_rooms_repository.dart';
import 'package:iagree/core/design_system/components/buttons/app_button.dart';
import 'package:iagree/core/design_system/components/buttons/app_icon_button.dart';
import 'package:iagree/core/design_system/components/feedback/app_empty_state.dart';
import 'package:iagree/core/design_system/components/feedback/app_skeleton.dart';
import 'package:iagree/core/design_system/components/people/app_avatar.dart';
import 'package:iagree/features/account/account_screen.dart';
import 'package:iagree/features/account/edit_profile_screen.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/features/auth/welcome_screen.dart';
import 'package:iagree/features/decision/deck_screen.dart';
import 'package:iagree/features/home/home_screen.dart';

late MockRoomsRepository _repo;
late SettingsController _settings;
final List<Uri> _opened = [];
String? _picked;

class _Photos implements PhotoPicker {
  @override
  Future<String?> pick() async => _picked;
}

class _Opener implements UrlOpener {
  @override
  Future<bool> open(Uri uri) async {
    _opened.add(uri);
    return true;
  }
}

Future<void> _launch(
  WidgetTester tester, {
  MockRoomsScenario scenario = MockRoomsScenario.mixed,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool load = true,
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
  _repo = MockRoomsRepository(
    scenario: scenario,
    latency: const Duration(milliseconds: 100),
  );
  _settings = SettingsController();
  _opened.clear();
  _picked = null;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: IAgreeApp(
        auth: MockAuthRepository(startSignedIn: true),
        rooms: RoomsController(repository: _repo),
        settings: _settings,
        opener: _Opener(),
        photos: _Photos(),
      ),
    ),
  );
  await tester.pump(); // oturum yükleme
  await tester.pump();
  if (load) await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _openAccount(WidgetTester tester) async {
  await tester.tap(find.byType(AppAvatar));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  group('Odalarım: karışık', () {
    testWidgets('hero sonuçlar hazır odası; tek Primary "Oy ver"', (
      tester,
    ) async {
      await _launch(tester);
      expect(find.text('Sonuçlar hazır'), findsWidgets);
      expect(find.text('Hafta sonu kahvaltı'), findsOneWidget);
      expect(
        find.text(
          'Herkes seçti. En çok uyuşan 3 mekan hazır, son kararı oylayın.',
        ),
        findsOneWidget,
      );
      expect(find.text('%100 uyum'), findsOneWidget);
      expect(find.text('Mavi Kapı'), findsOneWidget);
      final primaries = tester
          .widgetList<AppButton>(find.byType(AppButton))
          .where((b) => b.variant == AppButtonVariant.primary);
      expect(primaries, hasLength(1));
      expect(find.text('Oy ver'), findsOneWidget);
    });

    testWidgets('diğer odalar: Sıra sende etiketi ve 3/5 hazır sayacı', (
      tester,
    ) async {
      await _launch(tester);
      expect(find.text('Diğer odalar'), findsOneWidget);
      expect(find.text('Doğum günü planı'), findsOneWidget);
      expect(find.text('Sıra sende'), findsOneWidget);
      expect(find.text('Cuma akşamı'), findsOneWidget);
      expect(find.text('3/5 hazır'), findsOneWidget);
      // Sıra: hero dışında önce "sıra sende", sonra bekleyen.
      expect(
        tester.getTopLeft(find.text('Doğum günü planı')).dy,
        lessThan(tester.getTopLeft(find.text('Cuma akşamı')).dy),
      );
    });

    testWidgets('geçmiş kararlar yatay şeritte', (tester) async {
      await _launch(tester);
      await tester.scrollUntilVisible(
        find.text('Geçmiş kararlar'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -400));
      await tester.pump();
      expect(find.text('Trattoria Lume'), findsOneWidget);
      expect(find.text('3 Ekim'), findsOneWidget);
    });

    testWidgets('başlık, bölüm başlıkları header olarak okunur', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _launch(tester);
      expect(
        tester.getSemantics(find.text('Odalarım')).flagsCollection.isHeader,
        isTrue,
      );
      expect(
        tester.getSemantics(find.text('Diğer odalar')).flagsCollection.isHeader,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('satır tek öğe olarak okunur: ad, meta, durum', (tester) async {
      final handle = tester.ensureSemantics();
      await _launch(tester);
      expect(
        find.bySemanticsLabel(
          'Doğum günü planı. Aktivite · 18 Ekim. Sıra sende',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('sıra sende odasına dokunmak desteyi açar', (tester) async {
      await _launch(tester);
      await tester.tap(find.text('Doğum günü planı'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(DeckScreen), findsOneWidget);
    });
  });

  group('Odalarım: diğer durumlar', () {
    testWidgets('yükleme sürerken iskelet', (tester) async {
      await _launch(tester, load: false);
      expect(find.byType(AppSkeleton), findsWidgets);
      expect(find.text('Hafta sonu kahvaltı'), findsNothing);
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('yalnızca bekleyen: hero Secondary "Odaya git", önizleme yok', (
      tester,
    ) async {
      await _launch(tester, scenario: MockRoomsScenario.waitingOnly);
      expect(find.text('Bekleniyor'), findsOneWidget);
      expect(find.text('Odaya git'), findsOneWidget);
      final buttons = tester.widgetList<AppButton>(find.byType(AppButton));
      expect(
        buttons.where((b) => b.variant == AppButtonVariant.primary),
        isEmpty,
      );
      expect(find.textContaining('uyum'), findsNothing);
    });

    testWidgets('hiç oda yok: boş durum + altta Primary "Oda oluştur"', (
      tester,
    ) async {
      await _launch(tester, scenario: MockRoomsScenario.empty);
      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('Henüz bir odan yok'), findsOneWidget);
      expect(find.text('Oda oluştur'), findsOneWidget);
      // Boş durumda üstte "+" yok: tek yol alttaki Primary.
      expect(find.byTooltip('Oda oluştur'), findsNothing);
    });

    testWidgets('hata: tekrar dene yeniden yükler', (tester) async {
      await _launch(tester, scenario: MockRoomsScenario.failing);
      expect(find.text('Odalar yüklenemedi'), findsOneWidget);
      _repo.scenario = MockRoomsScenario.mixed;
      await tester.tap(find.text('Tekrar dene'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Hafta sonu kahvaltı'), findsOneWidget);
    });
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      for (final scenario in MockRoomsScenario.values) {
        testWidgets(
          'taşma yok: ${dark ? 'dark' : 'light'}, ${scale}x, ${scenario.name}',
          (tester) async {
            await _launch(
              tester,
              scenario: scenario,
              textScale: scale,
              brightness: dark ? Brightness.dark : Brightness.light,
            );
            expect(tester.takeException(), isNull);
            expect(find.byType(HomeScreen), findsOneWidget);
          },
        );
      }
    }
  }

  group('Profili düzenle', () {
    Future<void> openEdit(WidgetTester tester) async {
      await _launch(tester);
      await _openAccount(tester);
      await tester.tap(find.text('Düzenle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
    }

    Finder save() => find.widgetWithText(AppButton, 'Kaydet');

    testWidgets('açılır: isim dolu, e-posta salt okunur, Kaydet pasif', (
      tester,
    ) async {
      await openEdit(tester);
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Profili düzenle'), findsOneWidget);
      expect(find.text('E-posta adresi değiştirilemez.'), findsOneWidget);
      expect(tester.widget<AppButton>(save()).onPressed, isNull);
      expect(
        tester.widget<TextField>(find.byType(TextField).first).controller!.text,
        'Ayşe Yılmaz',
      );
      expect(
        tester.widgetList<TextField>(find.byType(TextField)).last.enabled,
        isFalse,
      );
    });

    testWidgets('isim değişince Kaydet etkin; kaydedince Profil güncellenir', (
      tester,
    ) async {
      await openEdit(tester);
      await tester.enterText(find.byType(TextField).first, 'Ayşe Demir');
      await tester.pump();
      expect(tester.widget<AppButton>(save()).onPressed, isNotNull);
      await tester.tap(save());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.text('Ayşe Demir'), findsOneWidget);
    });

    testWidgets('boş isim: hata, kaydedilmez', (tester) async {
      await openEdit(tester);
      await tester.enterText(find.byType(TextField).first, '  ');
      await tester.pump();
      await tester.tap(save());
      await tester.pump();
      expect(find.text('Adını yaz.'), findsOneWidget);
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('fotoğraf seç, sonra kaldır', (tester) async {
      await openEdit(tester);
      _picked = '/tmp/ornek.png';
      await tester.tap(find.text('Fotoğraf ekle'));
      await tester.pump();
      expect(find.text('Fotoğrafı değiştir'), findsOneWidget);
      expect(find.text('Fotoğrafı kaldır'), findsOneWidget);
      expect(tester.widget<AppButton>(save()).onPressed, isNotNull);
      await tester.tap(find.text('Fotoğrafı kaldır'));
      await tester.pump();
      expect(find.text('Fotoğraf ekle'), findsOneWidget);
      expect(tester.widget<AppButton>(save()).onPressed, isNull);
    });

    testWidgets('değişiklik yokken ✕ doğrudan kapatır', (tester) async {
      await openEdit(tester);
      await tester.tap(find.widgetWithIcon(AppIconButton, AppIcons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(EditProfileScreen), findsNothing);
    });

    testWidgets('değişiklik varken ✕ alert sorar; Düzenlemeye devam', (
      tester,
    ) async {
      await openEdit(tester);
      await tester.enterText(find.byType(TextField).first, 'Başka');
      await tester.pump();
      await tester.tap(find.widgetWithIcon(AppIconButton, AppIcons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Değişiklikler silinsin mi?'), findsOneWidget);
      await tester.tap(find.text('Düzenlemeye devam'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(EditProfileScreen), findsOneWidget);
    });

    testWidgets('değişiklikleri sil: kapanır, isim değişmez', (tester) async {
      await openEdit(tester);
      await tester.enterText(find.byType(TextField).first, 'Başka');
      await tester.pump();
      await tester.tap(find.widgetWithIcon(AppIconButton, AppIcons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Değişiklikleri sil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(EditProfileScreen), findsNothing);
      expect(find.text('Ayşe Yılmaz'), findsOneWidget);
    });
  });

  group('Profil bağlantıları', () {
    testWidgets('Gizlilik ve koşullar: sheet, seçilen adres açılır', (
      tester,
    ) async {
      await _launch(tester);
      await _openAccount(tester);
      await tester.tap(find.text('Gizlilik ve koşullar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Gizlilik politikası'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_opened.single.toString(), 'https://iagree.app/privacy');
    });

    testWidgets('Bize yaz: destek e-postası açılır', (tester) async {
      await _launch(tester);
      await _openAccount(tester);
      await tester.tap(find.text('Bize yaz'));
      await tester.pump();
      expect(_opened.single.scheme, 'mailto');
      expect(_opened.single.path, 'destek@iagree.app');
    });
  });

  group('Profil', () {
    testWidgets('avatar profile götürür; isim ve e-posta görünür', (
      tester,
    ) async {
      await _launch(tester);
      await _openAccount(tester);
      expect(find.byType(AccountScreen), findsOneWidget);
      expect(find.text('Ayşe Yılmaz'), findsOneWidget);
      expect(find.text('ayse@ornek.com'), findsOneWidget);
      expect(find.text('Bildirimler'), findsOneWidget);
      expect(find.text('Sistem'), findsOneWidget);
      expect(find.text('iAgree 1.0'), findsOneWidget);
    });

    testWidgets('Görünüm: Koyu seçilince ayar değişir ve satır güncellenir', (
      tester,
    ) async {
      await _launch(tester);
      await _openAccount(tester);
      await tester.tap(find.text('Görünüm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Koyu'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(_settings.themeMode, ThemeMode.dark);
      expect(find.text('Koyu'), findsOneWidget);
    });

    testWidgets('Çıkış yap: karşılamaya döner, yığın temiz', (tester) async {
      await _launch(tester);
      await _openAccount(tester);
      await tester.tap(find.text('Çıkış yap'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.byType(AccountScreen), findsNothing);
    });

    testWidgets('Hesabı sil: alert; Vazgeç hesapta bırakır', (tester) async {
      await _launch(tester);
      await _openAccount(tester);
      await tester.scrollUntilVisible(
        find.text('Hesabı sil'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Hesabı sil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Hesabın silinsin mi?'), findsOneWidget);
      await tester.tap(find.text('Vazgeç'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(AccountScreen), findsOneWidget);
    });

    testWidgets('Hesabı sil: onay karşılamaya döndürür', (tester) async {
      await _launch(tester);
      await _openAccount(tester);
      await tester.scrollUntilVisible(
        find.text('Hesabı sil'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Hesabı sil'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.text('Hesabı sil').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });

    testWidgets('Bildirimler: şimdilik bilgi toast\'ı', (tester) async {
      await _launch(tester);
      await _openAccount(tester);
      await tester.tap(find.text('Bildirimler'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Bu ekran yakında eklenecek'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
