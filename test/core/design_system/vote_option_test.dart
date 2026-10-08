import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/content/app_card.dart';
import 'package:iagree/core/design_system/components/content/app_list_group.dart';
import 'package:iagree/core/design_system/components/content/place_meta.dart';
import 'package:iagree/core/design_system/components/people/app_avatar.dart';
import 'package:iagree/core/design_system/components/people/app_avatar_group.dart';
import 'package:iagree/core/design_system/components/result/vote_option.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

final _light = AppColors.light;

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

const _sen = AppAvatarPerson(userId: 'u-sen', name: 'Sen');
const _can = AppAvatarPerson(userId: 'u-can', name: 'Can');
const _deniz = AppAvatarPerson(userId: 'u-deniz', name: 'Deniz');
const _photo = ColoredBox(key: ValueKey('photo'), color: Colors.brown);

Widget _hero({
  List<AppAvatarPerson> voters = const [_sen, _can],
  bool leading = true,
  bool mine = true,
}) => SizedBox(
  width: 350,
  child: VoteOption.hero(
    name: 'Mavi Kapı Kahve',
    photo: _photo,
    voters: voters,
    meta: const PlaceMeta(
      rating: 4.7,
      category: 'Kahve',
      priceLevel: 1,
      distanceKm: 0.65,
    ),
    isLeading: leading,
    isMine: mine,
  ),
);

Widget _compact({
  String name = 'Bar',
  List<AppAvatarPerson> voters = const [_deniz],
  bool leading = false,
  bool mine = false,
}) => SizedBox(
  width: 350,
  child: Builder(
    builder: (context) => AppListGroup(
      children: [
        VoteOption.compact(
          context: context,
          name: name,
          photo: _photo,
          voters: voters,
          isLeading: leading,
          isMine: mine,
        ),
      ],
    ),
  ),
);

void main() {
  group('hero', () {
    testWidgets('görsel 16:10; isim h3 + meta; Arc yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _hero());
      final photo = tester.getSize(find.byKey(const ValueKey('photo')));
      expect(photo.height, closeTo(350 / 1.6, 0.01));
      expect(
        tester.widget<Text>(find.text('Mavi Kapı Kahve')).style!.fontSize,
        20,
      );
      expect(find.text('4,7 · Kahve · ₺ · 650 m'), findsOneWidget);
      expect(find.textContaining('%'), findsNothing); // uyum yayı kayboldu
    });

    testWidgets(
      'sağda oy verenlerin avatarları (sm) ve sayı (title, tabular)',
      (tester) async {
        _phone(tester);
        await pumpApp(tester, _hero());
        final group = tester.widget<AppAvatarGroup>(
          find.byType(AppAvatarGroup),
        );
        expect(group.size, AppAvatarSize.sm);
        expect(group.ringColor, _light.surface);
        expect(find.byType(AppAvatar), findsNWidgets(2));
        final count = tester.widget<Text>(find.text('2'));
        expect(count.style!.fontSize, 17);
        expect(count.style!.fontWeight, FontWeight.w600);
        expect(count.style!.color, _light.textPrimary);
        expect(
          tester.getCenter(find.text('2')).dx,
          greaterThan(tester.getCenter(find.text('Mavi Kapı Kahve')).dx),
        );
      },
    );

    testWidgets('önde olan: 2px brand kenar; değilse yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _hero());
      expect(tester.widget<AppCard>(find.byType(AppCard)).selected, isTrue);
      await pumpApp(tester, _hero(leading: false));
      expect(tester.widget<AppCard>(find.byType(AppCard)).selected, isFalse);
    });

    testWidgets('kendi oyun: ✓ işareti; değilse yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _hero());
      expect(find.byIcon(AppIcons.check), findsOneWidget);
      await pumpApp(tester, _hero(mine: false));
      expect(find.byIcon(AppIcons.check), findsNothing);
    });

    testWidgets('0 oy: avatar yok, sayı textTertiary', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        _hero(voters: const [], leading: false, mine: false),
      );
      expect(find.byType(AppAvatarGroup), findsNothing);
      expect(
        tester.widget<Text>(find.text('0')).style!.color,
        _light.textTertiary,
      );
    });

    testWidgets('semantics: tek cümle; önde, oy sayısı, isimler, senin oyun', (
      tester,
    ) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _hero());
      expect(
        find.bySemanticsLabel(
          'Mavi Kapı Kahve, önde, 2 oy: Sen, Can. Senin oyun.',
        ),
        findsOneWidget,
      );
      await pumpApp(
        tester,
        _hero(voters: const [_can], leading: false, mine: false),
      );
      expect(
        find.bySemanticsLabel('Mavi Kapı Kahve, 1 oy: Can.'),
        findsOneWidget,
      );
      await pumpApp(
        tester,
        _hero(voters: const [], leading: false, mine: false),
      );
      expect(find.bySemanticsLabel('Mavi Kapı Kahve, oy yok.'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('en cümlesi', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _hero(), locale: const Locale('en'));
      expect(
        find.bySemanticsLabel(
          'Mavi Kapı Kahve, leading, 2 votes: Sen, Can. Your vote.',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('yazı 2x ve dark: taşma yok', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        SingleChildScrollView(child: _hero()),
        textScale: 2,
        dark: true,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('compact', () {
    testWidgets('satır 72, thumbnail 56, isim title; oy sayısı sağda', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _compact());
      expect(tester.getSize(find.byType(AppListRow)).height, 72);
      expect(
        tester.getSize(find.byKey(const ValueKey('photo'))),
        const Size.square(56),
      );
      expect(
        tester.widget<Text>(find.text('Bar')).style!.fontWeight,
        FontWeight.w600,
      );
      expect(find.text('1'), findsOneWidget);
      expect(find.byType(AppAvatar), findsOneWidget);
      expect(
        tester.getCenter(find.text('1')).dx,
        greaterThan(tester.getCenter(find.text('Bar')).dx),
      );
    });

    testWidgets('önde olan satır 2px brand halkalı; yerleşim aynı', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _compact());
      final plainHeight = tester.getSize(find.byType(AppListRow)).height;
      Iterable<ShapeDecoration> rings() => tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(AppListRow),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<ShapeDecoration>()
          .where(
            (d) =>
                d.shape is RoundedSuperellipseBorder &&
                (d.shape as RoundedSuperellipseBorder).side.color ==
                    _light.brand &&
                (d.shape as RoundedSuperellipseBorder).side.width == 2,
          );
      expect(rings(), isEmpty);
      await pumpApp(tester, _compact(leading: true));
      expect(rings(), hasLength(1));
      expect(tester.getSize(find.byType(AppListRow)).height, plainHeight);
    });

    testWidgets('0 oy: avatar yok, "0" textTertiary', (tester) async {
      _phone(tester);
      await pumpApp(tester, _compact(voters: const []));
      expect(find.byType(AppAvatar), findsNothing);
      expect(
        tester.widget<Text>(find.text('0')).style!.color,
        _light.textTertiary,
      );
    });

    testWidgets('çok oy: avatarlar üst üste, sayı doğru', (tester) async {
      _phone(tester);
      await pumpApp(tester, _compact(voters: const [_sen, _can, _deniz]));
      expect(find.byType(AppAvatar), findsNWidgets(3));
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('semantics: tek cümle', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _compact(leading: true, mine: true));
      expect(
        find.bySemanticsLabel('Bar, önde, 1 oy: Deniz. Senin oyun.'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('yazı 2x: taşma yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _compact(), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
