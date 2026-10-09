import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/app/app.dart';
import 'package:iagree/app/platform_services.dart';
import 'package:iagree/core/design_system/components/agreement/agreement_arc.dart';
import 'package:iagree/core/design_system/components/people/app_avatar.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/features/auth/welcome_screen.dart';

final List<Uri> _opened = [];

class _Opener implements UrlOpener {
  @override
  Future<bool> open(Uri uri) async {
    _opened.add(uri);
    return true;
  }
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.localeTestValue = const Locale('tr');
  tester.platformDispatcher.localesTestValue = const [Locale('tr')];
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
}

Future<void> _pump(
  WidgetTester tester, {
  bool reduce = false,
  double textScale = 1,
  Brightness brightness = Brightness.light,
  bool animate = true,
}) async {
  _phone(tester);
  _opened.clear();
  tester.platformDispatcher.platformBrightnessTestValue = brightness;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData.fromView(tester.view).copyWith(
        disableAnimations: reduce,
        textScaler: TextScaler.linear(textScale),
      ),
      child: IAgreeApp(
        home: WelcomeScreen(animate: animate),
        opener: _Opener(),
      ),
    ),
  );
  await tester.pump();
}

/// Sahne metninin opaklığı; sahne yoksa/görünmüyorsa 0.
double _sceneOpacity(WidgetTester tester, String text) {
  final f = find.text(text, skipOffstage: false);
  if (f.evaluate().isEmpty) return 0;
  final o = find.ancestor(of: f, matching: find.byType(Opacity));
  if (o.evaluate().isEmpty) return 1;
  // En dıştaki (sahne) Opacity: listenin sonuncusu.
  return tester.widget<Opacity>(o.last).opacity;
}

Future<void> _at(WidgetTester tester, int ms) async {
  await tester.pump(Duration(milliseconds: ms));
}

final _bigCheck = find.byWidgetPredicate(
  (w) => w is Icon && w.icon == AppIcons.check && w.size == 32,
);

void main() {
  final haptics = <String>[];
  setUp(() {
    haptics.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') haptics.add('x');
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('sahne 1: marka', () {
    testWidgets('büyük iAgree (Fraunces 80) ve slogan; küçük marka henüz yok', (
      tester,
    ) async {
      await _pump(tester);
      final hero = tester
          .widgetList<Text>(find.text('iAgree'))
          .firstWhere((t) => t.style?.fontSize == 80);
      expect(hero.style!.fontFamily, 'Fraunces');
      expect(
        find.text('“Nereye gidelim?” sorusunu birlikte, tartışmadan bitirin.'),
        findsOneWidget,
      );
      expect(_sceneOpacity(tester, 'Nereye gidelim?'), 0);
      expect(_sceneOpacity(tester, 'Birlikte karar verin.'), 0);
    });

    testWidgets('butonlar ve koşullar ilk kareden görünür', (tester) async {
      await _pump(tester);
      expect(find.text('Apple ile devam et'), findsOneWidget);
      expect(find.text('E-posta ile devam et'), findsOneWidget);
      expect(
        find.textContaining('Kullanım Koşulları', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group('geçiş ve sahne 2', () {
    testWidgets('2,5–2,9 sn: büyük marka solar; sonra sahne 1 yok', (
      tester,
    ) async {
      await _pump(tester);
      await _at(tester, 2400);
      expect(
        find.text('“Nereye gidelim?” sorusunu birlikte, tartışmadan bitirin.'),
        findsOneWidget,
      );
      await _at(tester, 300); // 2,7 sn
      expect(
        find.text('“Nereye gidelim?” sorusunu birlikte, tartışmadan bitirin.'),
        findsOneWidget,
      );
      await _at(tester, 300); // 3,0 sn
      expect(
        find.text('“Nereye gidelim?” sorusunu birlikte, tartışmadan bitirin.'),
        findsNothing,
      );
    });

    testWidgets('sahne 2 başlığı ~3,3 sn\'de tam görünür', (tester) async {
      await _pump(tester);
      await _at(tester, 3400);
      expect(_sceneOpacity(tester, 'Nereye gidelim?'), closeTo(1, 0.02));
      expect(_sceneOpacity(tester, 'Birlikte karar verin.'), 0);
    });

    testWidgets('öndeki kart sağa kayar, Olur etiketi çıkar', (tester) async {
      await _pump(tester);
      await _at(tester, 3450);
      expect(find.text('Olur'), findsNothing);
      await _at(tester, 1000); // 4,45 sn
      expect(find.text('Olur'), findsOneWidget);
    });

    testWidgets('uyum rozeti %80\'e dolar', (tester) async {
      await _pump(tester);
      await _at(tester, 4000);
      int pct() {
        final t = tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(AgreementArc),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data!)
            .firstWhere((s) => s.startsWith('%'));
        return int.parse(t.substring(1));
      }

      expect(pct(), lessThan(80));
      await _at(tester, 1000); // 5 sn
      expect(pct(), 80);
    });
  });

  group('sahne 3', () {
    testWidgets(
      '5,9 sn sonrası: sahne 2 gider, "Birlikte karar verin." gelir',
      (tester) async {
        await _pump(tester);
        await _at(tester, 6000);
        expect(
          _sceneOpacity(tester, 'Birlikte karar verin.'),
          closeTo(1, 0.02),
        );
        expect(_sceneOpacity(tester, 'Nereye gidelim?'), 0);
      },
    );

    testWidgets(
      'avatarlar kenarlardan gelir, ✓ en son belirir, 8,5 sn\'de durur',
      (tester) async {
        await _pump(tester);
        await _at(tester, 6000);
        expect(
          find.byType(AppAvatar, skipOffstage: false),
          findsNWidgets(5 + 0),
        );
        expect(
          _sceneOpacity(tester, 'Birlikte karar verin.'),
          closeTo(1, 0.02),
        );
        await _at(tester, 2600); // 8,6 sn
        expect(tester.hasRunningAnimations, isFalse);
        expect(_bigCheck, findsOneWidget);
      },
    );

    testWidgets('animasyon döngü yapmaz: sonrası sabit', (tester) async {
      await _pump(tester);
      await _at(tester, 9000);
      expect(tester.hasRunningAnimations, isFalse);
      expect(_sceneOpacity(tester, 'Birlikte karar verin.'), closeTo(1, 0.001));
    });
  });

  group('haptic ve erişilebilirlik', () {
    testWidgets('hiç haptic yok', (tester) async {
      await _pump(tester);
      await _at(tester, 9000);
      expect(haptics, isEmpty);
    });

    testWidgets('Reduce Motion: doğrudan son sahne, animasyon yok', (
      tester,
    ) async {
      await _pump(tester, reduce: true);
      expect(tester.hasRunningAnimations, isFalse);
      expect(_sceneOpacity(tester, 'Birlikte karar verin.'), 1);
      expect(_bigCheck, findsOneWidget);
      expect(
        find.text('“Nereye gidelim?” sorusunu birlikte, tartışmadan bitirin.'),
        findsNothing,
      );
    });

    testWidgets('animate: false de son sahnedir', (tester) async {
      await _pump(tester, animate: false);
      expect(_sceneOpacity(tester, 'Birlikte karar verin.'), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('sahne başlığı header olarak okunur', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, animate: false);
      expect(
        tester
            .getSemantics(find.text('Birlikte karar verin.'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      handle.dispose();
    });
  });

  testWidgets('koşullar ve gizlilik bağlantıları adresleri açar', (
    tester,
  ) async {
    await _pump(tester, animate: false);
    await tester.tapOnText(find.textRange.ofSubstring('Kullanım Koşulları'));
    await tester.pump();
    await tester.tapOnText(find.textRange.ofSubstring('Gizlilik Politikası'));
    await tester.pump();
    expect(_opened.map((u) => u.toString()), [
      'https://iagree.app/terms',
      'https://iagree.app/privacy',
    ]);
  });

  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'taşma yok: ${dark ? 'dark' : 'light'}, yazı ${scale}x (tüm sahneler)',
        (tester) async {
          await _pump(
            tester,
            textScale: scale,
            brightness: dark ? Brightness.dark : Brightness.light,
          );
          for (final ms in [0, 1000, 1500, 1500, 1500, 1500, 3000]) {
            await _at(tester, ms);
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
}
