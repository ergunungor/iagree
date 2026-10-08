import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/people/app_avatar.dart';
import 'package:iagree/core/design_system/components/people/app_avatar_group.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_fixed_colors.dart';

import '../../support/pump_app.dart';

List<AppAvatarPerson> _people(int n) => [
  for (var i = 0; i < n; i++) AppAvatarPerson(userId: 'u$i', name: 'Kişi $i'),
];

Finder get _group => find.byType(AppAvatarGroup);
Finder get _avatars =>
    find.descendant(of: _group, matching: find.byType(AppAvatar));

void main() {
  group('düzen', () {
    testWidgets('3 kişi: hepsi görünür, sayaç yok', (tester) async {
      await pumpApp(tester, AppAvatarGroup(people: _people(3)));
      expect(_avatars, findsNWidgets(3));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('tam 4 kişi: sayaç yok', (tester) async {
      await pumpApp(tester, AppAvatarGroup(people: _people(4)));
      expect(_avatars, findsNWidgets(4));
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('7 kişi: 4 avatar + "+3" sayacı', (tester) async {
      await pumpApp(tester, AppAvatarGroup(people: _people(7)));
      expect(_avatars, findsNWidgets(4));
      expect(find.text('+3'), findsOneWidget);
    });

    testWidgets('5 kişi: "+1"', (tester) async {
      await pumpApp(tester, AppAvatarGroup(people: _people(5)));
      expect(find.text('+1'), findsOneWidget);
    });

    testWidgets('oda sahibi (listenin ilki) en solda', (tester) async {
      await pumpApp(tester, AppAvatarGroup(people: _people(3)));
      final xs = [
        for (var i = 0; i < 3; i++) tester.getCenter(_avatars.at(i)).dx,
      ];
      expect(xs[0], lessThan(xs[1]));
      expect(xs[1], lessThan(xs[2]));
      expect(find.text('K'), findsNWidgets(3)); // sm: tek harf
    });

    testWidgets(
      '%30 üst üste: merkezler arası adım = %70 (28 + 2×2 halka = 32 → 22,4)',
      (tester) async {
        await pumpApp(tester, AppAvatarGroup(people: _people(3)));
        final step =
            tester.getCenter(_avatars.at(1)).dx -
            tester.getCenter(_avatars.at(0)).dx;
        expect(step, closeTo(32 * 0.7, 0.01));
        final step2 =
            tester.getCenter(_avatars.at(2)).dx -
            tester.getCenter(_avatars.at(1)).dx;
        expect(step2, closeTo(32 * 0.7, 0.01));
        expect(tester.getSize(_group).width, closeTo(32 * 0.7 * 2 + 32, 0.01));
      },
    );

    testWidgets('sayaç da %30 bindirir; 2 haneli sayaç genişler', (
      tester,
    ) async {
      await pumpApp(tester, AppAvatarGroup(people: _people(20)));
      final counter = find.text('+16');
      expect(counter, findsOneWidget);
      expect(
        tester
            .getSize(
              find
                  .ancestor(of: counter, matching: find.byType(ConstrainedBox))
                  .first,
            )
            .height,
        greaterThanOrEqualTo(28),
      );
    });

    testWidgets('maxVisible ve size ayarlanabilir', (tester) async {
      await pumpApp(
        tester,
        AppAvatarGroup(
          people: _people(6),
          maxVisible: 2,
          size: AppAvatarSize.md,
        ),
      );
      expect(_avatars, findsNWidgets(2));
      expect(find.text('+4'), findsOneWidget);
      expect(tester.getSize(_avatars.first), const Size.square(40));
    });
  });

  group('halka ve sayaç görünümü', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets('her avatarın çevresinde 2px canvas halka $name', (
        tester,
      ) async {
        await pumpApp(tester, AppAvatarGroup(people: _people(2)), dark: dark);
        final ringBox = find
            .ancestor(of: _avatars.first, matching: find.byType(DecoratedBox))
            .first;
        final deco =
            tester.widget<DecoratedBox>(ringBox).decoration as ShapeDecoration;
        expect(deco.color, c.canvas);
        expect(deco.shape, isA<CircleBorder>());
        expect(tester.getSize(ringBox), const Size.square(28 + 4));
      });

      testWidgets('sayaç: surfaceMuted pill, label 600 textSecondary $name', (
        tester,
      ) async {
        await pumpApp(tester, AppAvatarGroup(people: _people(6)), dark: dark);
        final counterDeco = find
            .ancestor(of: find.text('+2'), matching: find.byType(DecoratedBox))
            .first;
        final deco =
            tester.widget<DecoratedBox>(counterDeco).decoration
                as ShapeDecoration;
        expect(deco.color, c.surfaceMuted);
        expect(
          (deco.shape as RoundedSuperellipseBorder).borderRadius,
          BorderRadius.circular(999),
        );
        final style = tester.widget<Text>(find.text('+2')).style!;
        expect(style.fontWeight, FontWeight.w600);
        expect(style.color, c.textSecondary);
      });
    }

    testWidgets(
      'halka rengi ve kalınlığı özelleştirilebilir (karar anı: lg, momentBg)',
      (tester) async {
        await pumpApp(
          tester,
          AppAvatarGroup(
            people: _people(3),
            size: AppAvatarSize.lg,
            ringColor: AppFixedColors.momentBg,
            ringWidth: 3,
          ),
        );
        final ringBox = find
            .ancestor(of: _avatars.first, matching: find.byType(DecoratedBox))
            .first;
        expect(
          (tester.widget<DecoratedBox>(ringBox).decoration as ShapeDecoration)
              .color,
          AppFixedColors.momentBg,
        );
        expect(tester.getSize(ringBox), const Size.square(56 + 6));
      },
    );
  });

  group('semantics ve ölçek', () {
    testWidgets('varsayılan süs; semanticLabel ile tek öğe', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, AppAvatarGroup(people: _people(3)));
      expect(find.bySemanticsLabel(RegExp('Kişi')), findsNothing);
      await pumpApp(
        tester,
        AppAvatarGroup(
          people: _people(3),
          semanticLabel: 'Kişi 0, Kişi 1 ve Kişi 2',
        ),
      );
      expect(tester.getSemantics(_group).label, 'Kişi 0, Kişi 1 ve Kişi 2');
      handle.dispose();
    });

    testWidgets('yazı 2x: grup boyutu sabit, taşma yok', (tester) async {
      await pumpApp(tester, AppAvatarGroup(people: _people(9)));
      final size = tester.getSize(_group);
      await pumpApp(tester, AppAvatarGroup(people: _people(9)), textScale: 2);
      expect(tester.getSize(_group), size);
      expect(tester.takeException(), isNull);
    });
  });
}
