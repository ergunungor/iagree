import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/agreement/agreement_arc.dart';
import 'package:iagree/core/design_system/components/content/app_card.dart';
import 'package:iagree/core/design_system/components/content/app_list_group.dart';
import 'package:iagree/core/design_system/components/content/place_meta.dart';
import 'package:iagree/core/design_system/components/people/app_avatar.dart';
import 'package:iagree/core/design_system/components/people/app_avatar_group.dart';
import 'package:iagree/core/design_system/components/result/result_card.dart';
import 'package:iagree/core/design_system/components/selection/app_check_circle.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/foundations/app_pressable.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_fixed_colors.dart';

import '../../support/pump_app.dart';

final _light = AppColors.light;

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

const _photoKey = ValueKey('photo');
const _meta = PlaceMeta(
  rating: 4.7,
  category: 'Kahve',
  priceLevel: 1,
  distanceKm: 0.65,
);

const _ayse = AppAvatarPerson(userId: 'u-ayse', name: 'Ayşe');
const _can = AppAvatarPerson(userId: 'u-can', name: 'Can');
const _deniz = AppAvatarPerson(userId: 'u-deniz', name: 'Deniz');
const _mert = AppAvatarPerson(userId: 'u-mert', name: 'Mert');
const _zeynep = AppAvatarPerson(userId: 'u-zeynep', name: 'Zeynep');

Widget _hero({
  List<AppAvatarPerson> lovers = const [_ayse, _can],
  List<String> reasons = const [],
  bool selected = false,
  VoidCallback? onSelected,
  PlaceMeta meta = _meta,
}) => SizedBox(
  width: 350,
  child: ResultCard.hero(
    name: 'Mavi Kapı Kahve',
    photo: const ColoredBox(key: _photoKey, color: Colors.brown),
    loveCount: 2,
    okCount: 1,
    total: 4,
    meta: meta,
    lovers: lovers,
    reasons: reasons,
    selected: selected,
    onSelected: onSelected,
  ),
);

Widget _compact({
  String name = 'Bahçe Bistro',
  bool selected = false,
  VoidCallback? onSelected,
  PlaceMeta meta = const PlaceMeta(
    category: 'Kahvaltı',
    priceLevel: 2,
    distanceKm: 1.4,
  ),
}) => SizedBox(
  width: 350,
  child: Builder(
    builder: (context) => AppListGroup(
      children: [
        ResultCard.compact(
          context: context,
          name: name,
          photo: const ColoredBox(key: _photoKey, color: Colors.green),
          loveCount: 1,
          okCount: 2,
          total: 4,
          meta: meta,
          selected: selected,
          onSelected: onSelected,
        ),
      ],
    ),
  ),
);

void main() {
  group('hero', () {
    testWidgets('görsel 16:10, kart genişliği kadar', (tester) async {
      _phone(tester);
      await pumpApp(tester, _hero());
      final photo = tester.getSize(find.byKey(_photoKey));
      expect(photo.width, 350);
      expect(photo.height, closeTo(350 / 1.6, 0.01));
    });

    testWidgets('isim h3, meta caption tabular; yıldız yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _hero());
      final name = tester.widget<Text>(find.text('Mavi Kapı Kahve'));
      expect(name.style!.fontSize, 20);
      expect(name.style!.fontWeight, FontWeight.w600);
      final meta = tester.widget<Text>(find.text('4,7 · Kahve · ₺ · 650 m'));
      expect(meta.style!.fontSize, 13);
      expect(meta.style!.color, _light.textSecondary);
      expect(
        meta.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(find.byIcon(AppIcons.starFill), findsNothing);
    });

    testWidgets('sağda Arc M: yüzde ve kişi sayısı sayılardan hesaplanır', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _hero());
      final arc = tester.widget<AgreementArc>(find.byType(AgreementArc));
      expect(arc.size, AgreementArcSize.medium);
      await tester.pumpAndSettle();
      expect(find.text('%75'), findsOneWidget);
      expect(find.text('3/4 kişi'), findsOneWidget);
      expect(
        tester.getCenter(find.byType(AgreementArc)).dx,
        greaterThan(tester.getCenter(find.text('Mavi Kapı Kahve')).dx),
      );
    });

    group('seçim', () {
      testWidgets('seçili: 2px brand kenar, ✓ rozeti brand', (tester) async {
        _phone(tester);
        await pumpApp(tester, _hero(selected: true, onSelected: () {}));
        expect(tester.widget<AppCard>(find.byType(AppCard)).selected, isTrue);
        final check = tester.widget<Icon>(find.byIcon(AppIcons.check));
        expect(check.color, _light.onBrand);
        expect(check.size, 16);
      });

      testWidgets('seçili değil: rozet boş halka (mediaOverlay dolgu), ✓ yok', (
        tester,
      ) async {
        _phone(tester);
        await pumpApp(tester, _hero(onSelected: () {}));
        expect(find.byIcon(AppIcons.check), findsNothing);
        final badge = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((d) => d.decoration)
            .whereType<ShapeDecoration>()
            .where((d) => d.color == AppFixedColors.mediaOverlay);
        expect(badge, isNotEmpty);
      });

      testWidgets('seçili ve değil aynı boyutta (boyut değişmez)', (
        tester,
      ) async {
        _phone(tester);
        await pumpApp(tester, _hero(onSelected: () {}));
        final a = tester.getSize(find.byType(AppCard));
        await pumpApp(tester, _hero(selected: true, onSelected: () {}));
        expect(tester.getSize(find.byType(AppCard)), a);
      });

      testWidgets('onSelected karta dokununca çağrılır; null ise dokunulmaz', (
        tester,
      ) async {
        _phone(tester);
        var taps = 0;
        await pumpApp(tester, _hero(onSelected: () => taps++));
        await tester.tap(find.text('Mavi Kapı Kahve'));
        expect(taps, 1);
        await pumpApp(tester, _hero());
        expect(find.byType(AppPressable), findsNothing);
      });
    });

    group('sevenler', () {
      Future<void> pumpWith(
        WidgetTester tester,
        List<AppAvatarPerson> l,
      ) async {
        _phone(tester);
        await pumpApp(tester, _hero(lovers: l));
      }

      testWidgets('1, 2, 3 kişi', (tester) async {
        await pumpWith(tester, [_ayse]);
        expect(find.text('Ayşe çok istiyor'), findsOneWidget);
        await pumpWith(tester, [_ayse, _can]);
        expect(find.text('Ayşe ve Can çok istiyor'), findsOneWidget);
        await pumpWith(tester, [_ayse, _can, _deniz]);
        expect(find.text('Ayşe, Can ve Deniz çok istiyor'), findsOneWidget);
      });

      testWidgets('4+ kişi: iki isim ve "N kişi daha"', (tester) async {
        await pumpWith(tester, [_ayse, _can, _deniz, _mert, _zeynep]);
        expect(
          find.text('Ayşe, Can ve 3 kişi daha çok istiyor'),
          findsOneWidget,
        );
      });

      testWidgets('xs avatarlar, halka kart yüzeyi renginde', (tester) async {
        await pumpWith(tester, [_ayse, _can]);
        final group = tester.widget<AppAvatarGroup>(
          find.byType(AppAvatarGroup),
        );
        expect(group.size, AppAvatarSize.xs);
        expect(group.ringColor, _light.surface);
        expect(find.byType(AppAvatar), findsNWidgets(2));
      });

      testWidgets('boşsa satır yok', (tester) async {
        await pumpWith(tester, const []);
        expect(find.byType(AppAvatarGroup), findsNothing);
        expect(find.textContaining('çok istiyor'), findsNothing);
      });

      testWidgets('en: loves it', (tester) async {
        _phone(tester);
        await pumpApp(tester, _hero(), locale: const Locale('en'));
        expect(find.text('Ayşe and Can love it'), findsOneWidget);
      });
    });

    group('gerekçe', () {
      testWidgets('en fazla 2 öğe, " · " ile', (tester) async {
        _phone(tester);
        await pumpApp(tester, _hero(reasons: const ['Hepinize yakın', 'Açık']));
        expect(find.text('Hepinize yakın · Açık'), findsOneWidget);
      });

      testWidgets('veri yoksa gösterilmez', (tester) async {
        _phone(tester);
        await pumpApp(tester, _hero());
        expect(find.textContaining(' · Açık'), findsNothing);
      });

      test('3 öğe assert verir', () {
        expect(
          () => ResultCard.hero(
            name: 'x',
            photo: const SizedBox(),
            loveCount: 0,
            okCount: 0,
            total: 1,
            reasons: const ['a', 'b', 'c'],
          ),
          throwsAssertionError,
        );
      });
    });

    testWidgets('semantics: tek cümle, sayıya ek yok, seçili durumu', (
      tester,
    ) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _hero(selected: true, onSelected: () {}));
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Mavi Kapı Kahve')),
      );
      expect(
        node.label,
        'Mavi Kapı Kahve. 4,7 puan, Kahve, uygun fiyat, 650 metre. '
        'Uyum yüzde 75. Toplam 4 kişi, olumlu 3, çok isteyen 2. Ayşe ve Can çok istiyor.',
      );
      expect('${node.flagsCollection.isSelected}', contains('isTrue'));
      handle.dispose();
    });

    testWidgets('yazı 2x: taşma yok; dark tema', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        SingleChildScrollView(
          child: _hero(
            reasons: const ['Hepinize yakın', 'Açık'],
            lovers: [_ayse, _can, _deniz, _mert],
          ),
        ),
        textScale: 2,
        dark: true,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('compact', () {
    testWidgets('satır yüksekliği 72, thumbnail 56 radius sm', (tester) async {
      _phone(tester);
      // Test yazı tipi (Ahem) geniştir; satırın tek satırda kalması için kısa metin.
      await pumpApp(
        tester,
        _compact(
          name: 'Bar',
          meta: const PlaceMeta(category: 'Kafe'),
        ),
      );
      expect(tester.getSize(find.byType(AppListRow)).height, 72);
      final thumb = tester.getSize(find.byKey(_photoKey));
      expect(thumb, const Size.square(56));
      final clip =
          tester
                  .widget<ClipPath>(
                    find
                        .ancestor(
                          of: find.byKey(_photoKey),
                          matching: find.byType(ClipPath),
                        )
                        .first,
                  )
                  .clipper!
              as ShapeBorderClipper;
      expect(
        (clip.shape as RoundedSuperellipseBorder).borderRadius,
        BorderRadius.circular(10),
      );
    });

    testWidgets('title (600) + caption meta, sağda Arc S (yüzde yanında)', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _compact());
      final title = tester.widget<Text>(find.text('Bahçe Bistro'));
      expect(title.style!.fontSize, 17);
      expect(title.style!.fontWeight, FontWeight.w600);
      expect(find.text('Kahvaltı · ₺₺ · 1,4 km'), findsOneWidget);
      final arc = tester.widget<AgreementArc>(find.byType(AgreementArc));
      expect(arc.size, AgreementArcSize.small);
      await tester.pumpAndSettle();
      expect(find.text('%75'), findsOneWidget);
      expect(
        tester.getCenter(find.byType(AgreementArc)).dx,
        greaterThan(tester.getCenter(find.text('Bahçe Bistro')).dx),
      );
    });

    testWidgets(
      'solda Check Circle yalnızca seçilebilirken; thumbnail ondan sonra',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, _compact());
        expect(find.byType(AppCheckCircle), findsNothing);
        await pumpApp(tester, _compact(onSelected: () {}));
        expect(find.byType(AppCheckCircle), findsOneWidget);
        expect(
          tester.getCenter(find.byType(AppCheckCircle)).dx,
          lessThan(tester.getCenter(find.byKey(_photoKey)).dx),
        );
        expect(
          tester.getTopLeft(find.byType(AppCheckCircle)).dx -
              tester.getTopLeft(find.byType(AppListRow)).dx,
          16,
        );
      },
    );

    testWidgets('seçili: Check Circle dolu; dokununca onSelected', (
      tester,
    ) async {
      _phone(tester);
      var taps = 0;
      await pumpApp(tester, _compact(selected: true, onSelected: () => taps++));
      expect(
        tester.widget<AppCheckCircle>(find.byType(AppCheckCircle)).selected,
        isTrue,
      );
      await tester.tap(find.text('Bahçe Bistro'));
      expect(taps, 1);
    });

    testWidgets('semantics: tek cümle ve seçili durumu', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _compact(selected: true, onSelected: () {}));
      final node = tester.getSemantics(
        find.bySemanticsLabel(RegExp('^Bahçe Bistro')),
      );
      expect(
        node.label,
        'Bahçe Bistro. Kahvaltı, orta fiyat, 1,4 kilometre. '
        'Uyum yüzde 75. Toplam 4 kişi, olumlu 3, çok isteyen 1.',
      );
      handle.dispose();
    });

    testWidgets('yazı 2x: taşma yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _compact(onSelected: () {}), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('hero ve compact bir arada: sıra ve boşluk', (tester) async {
    _phone(tester);
    await pumpApp(
      tester,
      SizedBox(
        width: 350,
        child: Column(
          children: [
            ResultCard.hero(
              name: 'Mavi Kapı Kahve',
              photo: const ColoredBox(color: Colors.brown),
              loveCount: 2,
              okCount: 1,
              total: 4,
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) => AppListGroup(
                children: [
                  for (final n in ['Bahçe Bistro', 'Köşe Fırın'])
                    ResultCard.compact(
                      context: context,
                      name: n,
                      photo: const ColoredBox(color: Colors.green),
                      loveCount: 0,
                      okCount: 2,
                      total: 4,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(AgreementArc), findsNWidgets(3));
  });
}
