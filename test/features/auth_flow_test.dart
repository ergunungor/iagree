import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/app/app.dart';
import 'package:iagree/app/app_scope.dart';
import 'package:iagree/app/platform_services.dart';
import 'package:iagree/core/data/mock/mock_auth_repository.dart';
import 'package:iagree/core/design_system/components/buttons/app_icon_button.dart';
import 'package:iagree/core/design_system/components/inputs/app_code_field.dart';
import 'package:iagree/core/design_system/components/people/app_avatar.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/features/auth/code_screen.dart';
import 'package:iagree/features/auth/email_screen.dart';
import 'package:iagree/features/auth/profile_setup_screen.dart';
import 'package:iagree/features/auth/welcome_screen.dart';
import 'package:iagree/features/home/home_screen.dart';

final List<Uri> _opened = [];
bool _openOk = true;
String? _pickedPhoto;

class _Opener implements UrlOpener {
  @override
  Future<bool> open(Uri uri) async {
    _opened.add(uri);
    return _openOk;
  }
}

class _Photos implements PhotoPicker {
  @override
  Future<String?> pick() async => _pickedPhoto;
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _launch(WidgetTester tester, {bool reduce = false}) async {
  _phone(tester);
  _opened.clear();
  _openOk = true;
  _pickedPhoto = null;
  tester.platformDispatcher.localeTestValue = const Locale('tr');
  tester.platformDispatcher.localesTestValue = const [Locale('tr')];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view)
          .copyWith(disableAnimations: reduce),
      child: IAgreeApp(
        auth: MockAuthRepository(),
        opener: _Opener(),
        photos: _Photos(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// Rota geçişini ve klavye animasyonunu bitirir.
Future<void> _nav(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _toEmail(WidgetTester tester) async {
  await tester.tap(find.text('E-posta ile devam et'));
  await _nav(tester);
}

Future<void> _sendEmail(WidgetTester tester, String email) async {
  await tester.enterText(find.byType(TextField), email);
  await tester.tap(find.text('Kodu gönder'));
  await _nav(tester);
}

Future<void> _enterCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField), code);
  await tester.pump();
  await _nav(tester);
}

void main() {
  testWidgets('açılış: oturum yok → karşılama; butonlar ilk karede aktif', (
    tester,
  ) async {
    await _launch(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Apple ile devam et'), findsOneWidget);
    expect(find.text('E-posta ile devam et'), findsOneWidget);
    await _toEmail(tester); // animasyon sürerken bile dokunulabilir
    expect(find.byType(EmailScreen), findsOneWidget);
  });

  group('e-posta', () {
    testWidgets('boş/geçersiz adres: alan hata verir, ilerlemez', (
      tester,
    ) async {
      await _launch(tester);
      await _toEmail(tester);
      await tester.tap(find.text('Kodu gönder'));
      await tester.pump();
      expect(find.text('Geçerli bir e-posta adresi gir.'), findsOneWidget);
      expect(find.byType(CodeScreen), findsNothing);
      await tester.enterText(find.byType(TextField), 'ayse@');
      await tester.pump();
      expect(
        find.text('Geçerli bir e-posta adresi gir.'),
        findsNothing,
      ); // yazınca temizlenir
      await tester.tap(find.text('Kodu gönder'));
      await tester.pump();
      expect(find.text('Geçerli bir e-posta adresi gir.'), findsOneWidget);
    });

    testWidgets('geçerli adres: kod ekranı, adres kalın yazılır', (
      tester,
    ) async {
      await _launch(tester);
      await _toEmail(tester);
      await _sendEmail(tester, 'can@ornek.com');
      expect(find.byType(CodeScreen), findsOneWidget);
      final rich = tester
          .widgetList<RichText>(find.byType(RichText))
          .map((r) => r.text)
          .firstWhere((t) => t.toPlainText().contains('can@ornek.com'));
      final bold = <String>[];
      rich.visitChildren((span) {
        if (span is TextSpan && span.style?.fontWeight == FontWeight.w600) {
          bold.add(span.text ?? '');
        }
        return true;
      });
      expect(bold, contains('can@ornek.com'));
    });

    testWidgets('geri: karşılamaya döner', (tester) async {
      await _launch(tester);
      await _toEmail(tester);
      await tester.tap(find.widgetWithIcon(AppIconButton, AppIcons.back));
      await _nav(tester);
      expect(find.byType(EmailScreen), findsNothing);
      expect(find.byType(WelcomeScreen), findsOneWidget);
    });
  });

  group('kod', () {
    Future<void> toCode(WidgetTester tester, String email) async {
      await _launch(tester);
      await _toEmail(tester);
      await _sendEmail(tester, email);
    }

    testWidgets('altıncı hane otomatik gönderilir: yeni kullanıcı → profil', (
      tester,
    ) async {
      await toCode(tester, 'can@ornek.com');
      await _enterCode(tester, '482910');
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
    });

    testWidgets('kayıtlı kullanıcı → doğrudan ana ekran, yığın temizlenir', (
      tester,
    ) async {
      await toCode(tester, MockAuthRepository.knownEmail);
      await _enterCode(tester, '482910');
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        find.text('A'),
        findsOneWidget,
      ); // profil avatarı (küçük: tek harf)
      expect(find.byType(CodeScreen), findsNothing);
      expect(
        Navigator.of(tester.element(find.byType(HomeScreen))).canPop(),
        isFalse,
      );
    });

    testWidgets(
      'yanlış kod: hata metni, kutular temizlenir, yazınca hata gider',
      (tester) async {
        await toCode(tester, 'can@ornek.com');
        await _enterCode(tester, MockAuthRepository.wrongCode);
        expect(find.text('Kod doğru değil. Tekrar dene.'), findsOneWidget);
        expect(find.byType(CodeScreen), findsOneWidget);
        expect(
          tester.widget<TextField>(find.byType(TextField)).controller!.text,
          isEmpty,
        );
        expect(
          tester.widget<AppCodeField>(find.byType(AppCodeField)).hasError,
          isTrue,
        );
        await tester.enterText(find.byType(TextField), '1');
        await tester.pump();
        expect(find.text('Kod doğru değil. Tekrar dene.'), findsNothing);
      },
    );

    testWidgets(
      'geri sayım: 0:45 → saniyede bir azalır → 0\'da yeniden gönder',
      (tester) async {
        await toCode(tester, 'can@ornek.com');
        expect(find.text('Yeniden gönder · 0:45'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('Yeniden gönder · 0:42'), findsOneWidget);
        await tester.pump(const Duration(seconds: 42));
        expect(find.textContaining('Yeniden gönder ·'), findsNothing);
        expect(find.text('Yeniden gönder'), findsOneWidget);
        await tester.tap(find.text('Yeniden gönder'));
        await tester.pump();
        expect(find.text('Yeniden gönder · 0:45'), findsOneWidget);
      },
    );

    testWidgets('Adresi değiştir e-posta ekranına döner', (tester) async {
      await toCode(tester, 'can@ornek.com');
      await tester.tap(find.text('Adresi değiştir'));
      await _nav(tester);
      expect(find.byType(CodeScreen), findsNothing);
      expect(find.byType(EmailScreen), findsOneWidget);
    });

    testWidgets('Mail\'i aç: Mail uygulamasını açar', (tester) async {
      await toCode(tester, 'can@ornek.com');
      await tester.tap(find.text('Mail\'i aç'));
      await tester.pump();
      expect(_opened.single.toString(), 'message://');
    });

    testWidgets('Mail açılamazsa bilgi toast\'ı', (tester) async {
      _openOk = false;
      await toCode(tester, 'can@ornek.com');
      _openOk = false;
      await tester.tap(find.text('Mail\'i aç'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Bağlantı açılamadı'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('profil', () {
    Future<void> toProfile(WidgetTester tester) async {
      await _launch(tester);
      await _toEmail(tester);
      await _sendEmail(tester, 'can@ornek.com');
      await _enterCode(tester, '482910');
    }

    testWidgets('e-posta ile gelen: isim boş, Apple notu yok', (tester) async {
      await toProfile(tester);
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(
        find.text('Apple hesabından geldi. İstersen değiştir.'),
        findsNothing,
      );
    });

    testWidgets('boş isimle Başla: alan işaretlenir, ilerlemez', (
      tester,
    ) async {
      await toProfile(tester);
      await tester.tap(find.text('Başla'));
      await tester.pump();
      expect(find.text('Adını yaz.'), findsOneWidget);
      expect(find.byType(HomeScreen), findsNothing);
    });

    testWidgets(
      'isim yazıp Başla: ana ekran, avatar baş harfleri güncellenir',
      (tester) async {
        await toProfile(tester);
        await tester.enterText(find.byType(TextField), 'Can Kaya');
        await tester.pump();
        expect(find.text('CK'), findsOneWidget);
        await tester.tap(find.text('Başla'));
        await _nav(tester);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('C'), findsOneWidget);
      },
    );

    testWidgets('fotoğraf ekle: seçilen yol profile işlenir', (tester) async {
      await toProfile(tester);
      _pickedPhoto = '/tmp/ornek.png';
      await tester.tap(find.text('Fotoğraf ekle'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Can Kaya');
      await tester.tap(find.text('Başla'));
      await _nav(tester);
      final session = AppScope.of(tester.element(find.byType(HomeScreen)))
          .session;
      expect(session.user!.photoPath, '/tmp/ornek.png');
    });

    testWidgets('fotoğraf seçimi iptal: profil fotoğrafsız', (tester) async {
      _pickedPhoto = null;
      await toProfile(tester);
      await tester.tap(find.text('Fotoğraf ekle'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Can Kaya');
      await tester.tap(find.text('Başla'));
      await _nav(tester);
      final session = AppScope.of(tester.element(find.byType(HomeScreen)))
          .session;
      expect(session.user!.photoPath, isNull);
    });
  });

  testWidgets('Apple ile devam: profil, isim Apple\'dan dolu + not', (
    tester,
  ) async {
    await _launch(tester);
    await tester.tap(find.text('Apple ile devam et'));
    await _nav(tester);
    expect(find.byType(ProfileSetupScreen), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Ayşe Yılmaz',
    );
    expect(
      find.text('Apple hesabından geldi. İstersen değiştir.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Başla'));
    await _nav(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('çıkış: karşılamaya döner', (tester) async {
    await _launch(tester);
    await _toEmail(tester);
    await _sendEmail(tester, MockAuthRepository.knownEmail);
    await _enterCode(tester, '482910');
    expect(find.byType(HomeScreen), findsOneWidget);
    await tester.tap(find.byType(AppAvatar));
    await _nav(tester);
    expect(find.text('Çıkış yap'), findsOneWidget);
    await tester.tap(find.text('Çıkış yap'));
    await _nav(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });
}
