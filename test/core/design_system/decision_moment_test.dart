import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/agreement/agreement_arc.dart';
import 'package:iagree/core/design_system/components/buttons/app_button.dart';
import 'package:iagree/core/design_system/components/buttons/app_icon_button.dart';
import 'package:iagree/core/design_system/components/content/place_meta.dart';
import 'package:iagree/core/design_system/components/decision/decision_card.dart';
import 'package:iagree/core/design_system/components/decision/decision_moment.dart';
import 'package:iagree/core/design_system/components/people/app_avatar.dart';
import 'package:iagree/core/design_system/components/people/app_avatar_group.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_elevation.dart';
import 'package:iagree/core/design_system/tokens/app_fixed_colors.dart';
import 'package:iagree/l10n/app_localizations.dart';

const _people = [
  AppAvatarPerson(userId: 'u-ayse', name: 'Ayşe'),
  AppAvatarPerson(userId: 'u-can', name: 'Can'),
  AppAvatarPerson(userId: 'u-deniz', name: 'Deniz'),
  AppAvatarPerson(userId: 'u-mert', name: 'Mert'),
];

final _light = AppColors.light;

class _Log {
  int directions = 0;
  int share = 0;
  int close = 0;
}

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532); // 390 × 844
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget _moment(_Log log, {bool unanimous = true, bool animate = false}) =>
    DecisionMoment(
      isUnanimous: unanimous,
      participants: _people,
      placeName: 'Trattoria Lume',
      photo: const ColoredBox(key: ValueKey('photo'), color: Colors.brown),
      meta: const PlaceMeta(
        rating: 4.6,
        category: 'İtalyan',
        priceLevel: 2,
        distanceKm: 1.2,
      ),
      loveCount: 2,
      okCount: 2,
      total: 4,
      votes: 3,
      totalVotes: 4,
      animate: animate,
      onDirections: () => log.directions++,
      onShare: () => log.share++,
      onClose: () => log.close++,
    );

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double textScale = 1,
  bool reduce = false,
  Locale locale = const Locale('tr'),
  bool settle = true,
}) async {
  await tester.pumpWidget(
    Builder(
      builder: (context) {
        final base = MediaQueryData.fromView(View.of(context));
        return MediaQuery(
          data: base.copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduce,
          ),
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: locale,
            theme: dark ? AppTheme.dark : AppTheme.light,
            home: Scaffold(body: child),
          ),
        );
      },
    ),
  );
  if (settle) await tester.pumpAndSettle();
}

Text _text(WidgetTester tester, String s) => tester.widget<Text>(find.text(s));

Finder get _directions => find.widgetWithText(AppButton, 'Yol tarifi al');
Finder get _share => find.widgetWithText(AppButton, 'Gruba paylaş');
Finder get _closeText => find.widgetWithText(AppButton, 'Kapat');

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

  group('oybirliği (son kare)', () {
    testWidgets('zemin momentBg, iki temada aynı', (tester) async {
      _phone(tester);
      for (final dark in [false, true]) {
        await _pump(tester, _moment(_Log()), dark: dark);
        final bg = tester
            .widgetList<ColoredBox>(find.byType(ColoredBox))
            .map((b) => b.color)
            .where((c) => c == AppFixedColors.momentBg);
        expect(bg, isNotEmpty, reason: 'dark: $dark');
      }
    });

    testWidgets('avatarlar lg (56), 3px momentBg halka, 4 kişi', (
      tester,
    ) async {
      _phone(tester);
      await _pump(tester, _moment(_Log()));
      final avatars = find.byType(AppAvatar);
      expect(avatars, findsNWidgets(4));
      expect(tester.getSize(avatars.first), const Size.square(56));
      final ring = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<ShapeDecoration>()
          .where(
            (d) =>
                d.color == AppFixedColors.momentBg && d.shape is CircleBorder,
          );
      expect(ring.length, greaterThanOrEqualTo(4));
      // Üst üste: bir sonrakinin sol kenarı öncekinin sağ kenarından önce.
      expect(
        tester.getTopLeft(avatars.at(1)).dx,
        lessThan(tester.getTopRight(avatars.at(0)).dx + 6),
      );
    });

    testWidgets('Arc L onMoment: %100 ve 4/4 kişi momentInk', (tester) async {
      _phone(tester);
      await _pump(tester, _moment(_Log()));
      final arc = tester.widget<AgreementArc>(find.byType(AgreementArc));
      expect(arc.size, AgreementArcSize.large);
      expect(arc.onMoment, isTrue);
      expect(find.text('%100'), findsOneWidget);
      expect(_text(tester, '%100').style!.color, AppFixedColors.momentInk);
      expect(find.text('4/4 kişi'), findsOneWidget);
    });

    testWidgets('başlık display (Fraunces 40), momentInk, ortalı', (
      tester,
    ) async {
      _phone(tester);
      await _pump(tester, _moment(_Log()));
      final t = _text(tester, 'Hepiniz anlaştınız.');
      expect(t.style!.fontFamily, 'Fraunces');
      expect(t.style!.fontSize, 40);
      expect(t.style!.color, AppFixedColors.momentInk);
      expect(t.textAlign, TextAlign.center);
    });

    testWidgets(
      'mekan kartı: surface, radius lg, E2, 56 thumbnail, title + caption',
      (tester) async {
        _phone(tester);
        await _pump(tester, _moment(_Log()));
        final card = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((d) => d.decoration)
            .whereType<ShapeDecoration>()
            .firstWhere(
              (d) =>
                  d.color == _light.surface &&
                  d.shadows != null &&
                  d.shadows!.isNotEmpty,
            );
        expect(
          (card.shape as RoundedSuperellipseBorder).borderRadius,
          BorderRadius.circular(20),
        );
        expect(card.shadows, AppElevation.light.e2.shadows);
        expect(
          tester.getSize(find.byKey(const ValueKey('photo'))),
          const Size.square(56),
        );
        expect(_text(tester, 'Trattoria Lume').style!.fontSize, 17);
        expect(find.text('İtalyan · ₺₺ · 1,2 km'), findsOneWidget); // puan yok
      },
    );

    testWidgets('sıra: avatarlar → Arc → başlık → kart → butonlar', (
      tester,
    ) async {
      _phone(tester);
      await _pump(tester, _moment(_Log()));
      final ys = [
        tester.getTopLeft(find.byType(AppAvatar).first).dy,
        tester.getTopLeft(find.byType(AgreementArc)).dy,
        tester.getTopLeft(find.text('Hepiniz anlaştınız.')).dy,
        tester.getTopLeft(find.text('Trattoria Lume')).dy,
        tester.getTopLeft(_directions).dy,
        tester.getTopLeft(_share).dy,
        tester.getTopLeft(_closeText).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
    });

    testWidgets(
      'butonlar: moment 52 · momentGhost 44 · momentText 44, tam genişlik',
      (tester) async {
        _phone(tester);
        await _pump(tester, _moment(_Log()));
        expect(
          tester.widget<AppButton>(_directions).variant,
          AppButtonVariant.moment,
        );
        expect(
          tester.widget<AppButton>(_share).variant,
          AppButtonVariant.momentGhost,
        );
        expect(
          tester.widget<AppButton>(_closeText).variant,
          AppButtonVariant.momentText,
        );
        expect(tester.getSize(_directions).height, 52);
        expect(tester.getSize(_share).height, 44);
        expect(tester.getSize(_closeText).height, 44);
        expect(tester.getSize(_directions).width, 350);
      },
    );

    testWidgets('eylemler callback çağırır', (tester) async {
      _phone(tester);
      final log = _Log();
      await _pump(tester, _moment(log));
      await tester.tap(_directions);
      await tester.tap(_share);
      await tester.tap(_closeText);
      expect([log.directions, log.share, log.close], [1, 1, 1]);
    });

    testWidgets('yazı 2x: taşma yok, kayar; eylemlere ulaşılır', (
      tester,
    ) async {
      _phone(tester);
      await _pump(tester, _moment(_Log()), textScale: 2);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(_closeText);
      await tester.pumpAndSettle();
      expect(_closeText, findsOneWidget);
    });

    testWidgets('semantics: başlık header, katılımcılar tek öğe, ek yok', (
      tester,
    ) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await _pump(tester, _moment(_Log()));
      expect(
        find.bySemanticsLabel('Katılımcılar: Ayşe, Can, Deniz, Mert'),
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(find.text('Hepiniz anlaştınız.'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      handle.dispose();
    });

    testWidgets('en: başlık ve butonlar', (tester) async {
      _phone(tester);
      await _pump(tester, _moment(_Log()), locale: const Locale('en'));
      expect(find.text('You all agree.'), findsOneWidget);
      expect(find.text('Get directions'), findsOneWidget);
    });
  });

  group('çoğunluk (son kare)', () {
    testWidgets('canvas zemin; Arc yok; başlık "Karar verildi."', (
      tester,
    ) async {
      _phone(tester);
      await _pump(tester, _moment(_Log(), unanimous: false));
      expect(find.byType(AgreementArc), findsNothing);
      expect(find.text('Karar verildi.'), findsOneWidget);
      final root = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .map((b) => b.color);
      expect(root, contains(_light.canvas));
      expect(root, isNot(contains(AppFixedColors.momentBg)));
    });

    testWidgets('fotoğraf 390:400, tam genişlik, üstte', (tester) async {
      _phone(tester);
      await _pump(tester, _moment(_Log(), unanimous: false));
      final photo = tester.getRect(find.byKey(const ValueKey('photo')));
      expect(photo.width, 390);
      expect(photo.height, closeTo(400, 0.5));
      expect(photo.top, 0);
    });

    testWidgets('✕ Media icon butonu sol üstte; kapatır', (tester) async {
      _phone(tester);
      final log = _Log();
      await _pump(tester, _moment(log, unanimous: false));
      final close = find.widgetWithIcon(AppIconButton, AppIcons.close);
      expect(
        tester.widget<AppIconButton>(close).style,
        AppIconButtonStyle.media,
      );
      expect(tester.getTopLeft(close).dx, lessThan(20));
      await tester.tap(close);
      expect(log.close, 1);
    });

    testWidgets('avatarlar fotoğrafın alt kenarına oturur, 4px canvas halka', (
      tester,
    ) async {
      _phone(tester);
      await _pump(tester, _moment(_Log(), unanimous: false));
      final photoBottom = tester
          .getBottomLeft(find.byKey(const ValueKey('photo')))
          .dy;
      final avatar = tester.getRect(find.byType(AppAvatar).first);
      expect(avatar.center.dy, closeTo(photoBottom, 0.5));
      final group = tester.widget<AppAvatarGroup>(find.byType(AppAvatarGroup));
      expect(group.ringColor, _light.canvas);
      expect(group.ringWidth, 4);
      expect(group.size, AppAvatarSize.lg);
    });

    testWidgets('isim h3, meta puansız; "3/4 oyla seçildi" etiketi brandSoft', (
      tester,
    ) async {
      _phone(tester);
      await _pump(tester, _moment(_Log(), unanimous: false));
      expect(_text(tester, 'Trattoria Lume').style!.fontSize, 20);
      expect(find.text('İtalyan · ₺₺ · 1,2 km'), findsOneWidget);
      final tag = _text(tester, '3/4 oyla seçildi');
      expect(tag.style!.color, _light.onBrandSoft);
      expect(tag.style!.fontWeight, FontWeight.w600);
      final pill = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<ShapeDecoration>()
          .where((d) => d.color == _light.brandSoft);
      expect(pill, isNotEmpty);
      expect(find.byIcon(AppIcons.check), findsOneWidget);
    });

    testWidgets('butonlar: Primary 52 + Secondary 44', (tester) async {
      _phone(tester);
      await _pump(tester, _moment(_Log(), unanimous: false));
      expect(
        tester.widget<AppButton>(_directions).variant,
        AppButtonVariant.primary,
      );
      expect(
        tester.widget<AppButton>(_share).variant,
        AppButtonVariant.secondary,
      );
      expect(tester.getSize(_directions).height, 52);
      expect(tester.getSize(_share).height, 44);
      expect(_closeText, findsNothing);
    });

    testWidgets('yazı 2x ve dark: taşma yok', (tester) async {
      _phone(tester);
      await _pump(
        tester,
        _moment(_Log(), unanimous: false),
        textScale: 2,
        dark: true,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('koreografi (oybirliği)', () {
    Future<void> start(WidgetTester tester, {bool reduce = false}) async {
      _phone(tester);
      await _pump(
        tester,
        _moment(_Log(), animate: true),
        reduce: reduce,
        settle: false,
      );
      await tester.pump();
      await tester.pump(); // post-frame: başlar
    }

    double opacityOf(WidgetTester tester, Finder f) {
      final o = find.ancestor(of: f, matching: find.byType(Opacity));
      return o.evaluate().isEmpty ? 1 : tester.widget<Opacity>(o.first).opacity;
    }

    testWidgets('başta zemin canvas; 200 ms sonunda momentBg', (tester) async {
      await start(tester);
      Color bg() => tester
          .widget<ColoredBox>(
            find
                .descendant(
                  of: find.byType(AnimatedBuilder),
                  matching: find.byType(ColoredBox),
                )
                .first,
          )
          .color;
      await tester.pump(const Duration(milliseconds: 20));
      expect(bg(), isNot(AppFixedColors.momentBg));
      await tester.pump(const Duration(milliseconds: 200));
      expect(bg(), AppFixedColors.momentBg);
    });

    testWidgets(
      'avatarlar kenarlardan gelir: ilk kare uzakta, 800 ms\'de yerinde',
      (tester) async {
        await start(tester);
        await tester.pump(const Duration(milliseconds: 250));
        final first = tester.getCenter(find.byType(AppAvatar).first).dx;
        final last = tester.getCenter(find.byType(AppAvatar).last).dx;
        expect(first, lessThan(0)); // sol kenarın dışından
        expect(last, greaterThan(390)); // sağ kenarın dışından
        await tester.pump(const Duration(milliseconds: 600)); // 850 ms
        expect(
          tester.getCenter(find.byType(AppAvatar).first).dx,
          greaterThan(60),
        );
        expect(
          tester.getCenter(find.byType(AppAvatar).first).dx,
          lessThan(200),
        );
      },
    );

    testWidgets('başlık ve kart 1400 ms\'ye kadar görünmez, sonra belirir', (
      tester,
    ) async {
      await start(tester);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(
        opacityOf(
          tester,
          find.text('Hepiniz anlaştınız.', skipOffstage: false),
        ),
        0,
      );
      await tester.pump(const Duration(milliseconds: 800)); // 1800
      expect(
        opacityOf(tester, find.text('Hepiniz anlaştınız.')),
        closeTo(1, 0.02),
      );
    });

    testWidgets('Arc 800–1400 arasında dolar, sayı artar, 1400\'te %100', (
      tester,
    ) async {
      await start(tester);
      await tester.pump(const Duration(milliseconds: 790));
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

      expect(pct(), 0);
      await tester.pump(const Duration(milliseconds: 300)); // 1090
      expect(pct(), inExclusiveRange(0, 100));
      await tester.pump(const Duration(milliseconds: 330)); // 1420
      expect(pct(), 100);
    });

    testWidgets('haptic: ~800 ms medium, ~1400 ms success; başka yok', (
      tester,
    ) async {
      await start(tester);
      await tester.pump(const Duration(milliseconds: 700));
      expect(haptics, isEmpty);
      await tester.pump(const Duration(milliseconds: 200)); // 900
      expect(haptics, ['HapticFeedbackType.mediumImpact']);
      await tester.pump(const Duration(milliseconds: 400)); // 1300
      expect(haptics.length, 1);
      await tester.pump(const Duration(milliseconds: 200)); // 1500
      expect(haptics, [
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.mediumImpact', // success → Android'de medium
      ]);
      await tester.pumpAndSettle();
      expect(haptics.length, 2);
    });

    testWidgets('eylemler 2 sn\'ye kadar pasif; sonra aktif', (tester) async {
      _phone(tester);
      final log = _Log();
      await _pump(tester, _moment(log, animate: true), settle: false);
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1900));
      await tester.tap(_directions, warnIfMissed: false);
      expect(log.directions, 0);
      await tester.pumpAndSettle();
      await tester.tap(_directions);
      expect(log.directions, 1);
    });

    testWidgets('dokununca atlanır: son kare, haptic yok', (tester) async {
      await start(tester);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tapAt(const Offset(195, 400));
      await tester.pump();
      expect(find.text('%100'), findsOneWidget);
      expect(opacityOf(tester, find.text('Hepiniz anlaştınız.')), 1);
      expect(haptics, isEmpty);
      await tester.pumpAndSettle();
      expect(haptics, isEmpty);
      await tester.tap(_directions); // artık aktif
    });

    testWidgets('animate: false: haptic yok, doğrudan son kare', (
      tester,
    ) async {
      _phone(tester);
      await _pump(tester, _moment(_Log()));
      expect(haptics, isEmpty);
      expect(find.text('%100'), findsOneWidget);
    });

    testWidgets('Reduce Motion: hareket yok, ~200 ms crossfade, tek success', (
      tester,
    ) async {
      await start(tester, reduce: true);
      // Avatarlar baştan yerinde (kayma yok).
      final x0 = tester.getCenter(find.byType(AppAvatar).first).dx;
      expect(x0, greaterThan(0));
      expect(x0, lessThan(390));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        opacityOf(tester, find.text('Hepiniz anlaştınız.')),
        inExclusiveRange(0.2, 0.8),
      );
      await tester.pumpAndSettle();
      expect(haptics, [
        'HapticFeedbackType.mediumImpact',
      ]); // success (Android: medium)
      expect(tester.takeException(), isNull);
    });
  });

  group('koreografi (çoğunluk)', () {
    testWidgets(
      'light haptic bir kez, 700 ms\'de biter, avatarlar baştan yerinde',
      (tester) async {
        _phone(tester);
        await _pump(
          tester,
          _moment(_Log(), unanimous: false, animate: true),
          settle: false,
        );
        await tester.pump();
        await tester.pump();
        expect(haptics, ['HapticFeedbackType.lightImpact']);
        final x0 = tester.getCenter(find.byType(AppAvatar).first).dx;
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.getCenter(find.byType(AppAvatar).first).dx, x0);
        await tester.pumpAndSettle();
        expect(haptics.length, 1);
        expect(find.text('Karar verildi.'), findsOneWidget);
      },
    );
  });

  group('DecisionCard', () {
    Widget card({VoidCallback? onPressed}) => SizedBox(
      width: 350,
      child: DecisionCard(
        placeName: 'Trattoria Lume',
        time: 'Cuma 20:00',
        photo: const ColoredBox(key: ValueKey('photo'), color: Colors.brown),
        onPressed: onPressed,
      ),
    );

    testWidgets(
      '56 thumbnail, Karar overline (brand), title, saat; 2px brand kenar',
      (tester) async {
        _phone(tester);
        await _pump(tester, card());
        expect(
          tester.getSize(find.byKey(const ValueKey('photo'))),
          const Size.square(56),
        );
        final over = _text(tester, 'Karar');
        expect(over.style!.color, _light.brand);
        expect(over.style!.fontSize, 12);
        expect(over.style!.fontWeight, FontWeight.w600);
        expect(_text(tester, 'Trattoria Lume').style!.fontSize, 17);
        expect(find.text('Cuma 20:00'), findsOneWidget);
        // AppCard seçili: 2px brand kenar.
        final border = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((d) => d.decoration)
            .whereType<ShapeDecoration>()
            .where((d) {
              final s = d.shape;
              return s is RoundedSuperellipseBorder &&
                  s.side.width == 2 &&
                  s.side.color == _light.brand;
            });
        expect(border, isNotEmpty);
      },
    );

    testWidgets('dokunulabilir ve tek öğe okunur', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      var taps = 0;
      await _pump(tester, card(onPressed: () => taps++));
      expect(
        find.bySemanticsLabel('Karar: Trattoria Lume, Cuma 20:00'),
        findsOneWidget,
      );
      await tester.tap(find.text('Trattoria Lume'));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('yazı 2x ve dark: taşma yok', (tester) async {
      _phone(tester);
      await _pump(tester, card(), textScale: 2, dark: true);
      expect(tester.takeException(), isNull);
    });
  });
}
