import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/content/app_list_group.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

Finder get _group => find.byType(AppListGroup);
Finder get _rows => find.byType(AppListRow);

Finder get _surface => find
    .descendant(
      of: _group,
      matching: find.byWidgetPredicate((w) {
        if (w is! DecoratedBox) return false;
        final d = w.decoration;
        return d is ShapeDecoration &&
            d.color != null &&
            d.shape is RoundedSuperellipseBorder &&
            (d.shape as RoundedSuperellipseBorder).borderRadius ==
                BorderRadius.circular(20);
      }),
    )
    .first;
ShapeDecoration _groupDeco(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_surface).decoration as ShapeDecoration;

/// Satır ayırıcıları: 1px yüksekliğinde `border` renkli kutular.
Finder _dividers(Color color) => find.descendant(
  of: _group,
  matching: find.byWidgetPredicate((w) => w is ColoredBox && w.color == color),
);

Text _text(WidgetTester tester, String s) => tester.widget<Text>(find.text(s));

void main() {
  group('grup', () {
    for (final dark in [false, true]) {
      final c = dark ? AppColors.dark : AppColors.light;
      final name = dark ? 'dark' : 'light';

      testWidgets('surface, radius lg, E0 (gölge ve hairline yok) $name', (
        tester,
      ) async {
        await pumpApp(
          tester,
          const AppListGroup(
            children: [
              AppListRow(title: 'A'),
              AppListRow(title: 'B'),
            ],
          ),
          dark: dark,
        );
        expect(_groupDeco(tester).color, c.surface);
        expect(_groupDeco(tester).shadows, isNull);
        expect(
          (_groupDeco(tester).shape as OutlinedBorder).side,
          BorderSide.none,
        );
      });
    }

    testWidgets('satırlar köşelere göre kırpılır', (tester) async {
      await pumpApp(
        tester,
        const AppListGroup(
          children: [
            AppListRow(title: 'A'),
            AppListRow(title: 'B'),
          ],
        ),
      );
      final clip = tester.widget<ClipPath>(
        find.descendant(of: _group, matching: find.byType(ClipPath)).first,
      );
      expect(
        (clip.clipper! as ShapeBorderClipper)
            .getClip(tester.getSize(_group))
            .contains(const Offset(1, 1)),
        isFalse,
      );
    });

    testWidgets('Increase Contrast: borderControl kenarı', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(highContrast: true),
          child: MaterialApp(
            theme: ThemeData(extensions: [AppColors.light]),
            home: const Scaffold(
              body: AppListGroup(children: [AppListRow(title: 'A')]),
            ),
          ),
        ),
      );
      expect(
        (_groupDeco(tester).shape as OutlinedBorder).side.color,
        AppColors.lightHighContrast.borderControl,
      );
    });
  });

  group('satır', () {
    testWidgets('tek satır yükseklik 52 (ayırıcı hariç), yatay padding 16', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppListGroup(children: [AppListRow(title: 'Bildirimler')]),
      );
      expect(tester.getSize(_rows).height, 52);
      expect(
        tester.getTopLeft(find.text('Bildirimler')).dx -
            tester.getTopLeft(_group).dx,
        16,
      );
    });

    testWidgets(
      'metin stilleri: body, emphasized title (600), meta caption textSecondary',
      (tester) async {
        await pumpApp(
          tester,
          const AppListGroup(
            children: [
              AppListRow(title: 'Düz'),
              AppListRow(
                title: 'Güçlü',
                emphasized: true,
                subtitle: '★ 4,6 · ₺₺ · 1,2 km',
              ),
            ],
          ),
        );
        expect(_text(tester, 'Düz').style!.fontSize, 17);
        expect(_text(tester, 'Düz').style!.fontWeight, FontWeight.w400);
        expect(_text(tester, 'Güçlü').style!.fontWeight, FontWeight.w600);
        final meta = _text(tester, '★ 4,6 · ₺₺ · 1,2 km').style!;
        expect(meta.fontSize, 13);
        expect(meta.color, AppColors.light.textSecondary);
        expect(meta.fontFeatures, contains(const FontFeature.tabularFigures()));
      },
    );

    testWidgets('destructive: ana metin error', (tester) async {
      await pumpApp(
        tester,
        const AppListGroup(
          children: [AppListRow(title: 'Hesabı sil', destructive: true)],
        ),
      );
      expect(_text(tester, 'Hesabı sil').style!.color, AppColors.light.error);
    });

    testWidgets('chevron sağda: 20, textTertiary', (tester) async {
      await pumpApp(
        tester,
        const AppListGroup(
          children: [AppListRow(title: 'Profil', showsChevron: true)],
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(AppIcons.chevronRight));
      expect(icon.size, 20);
      expect(icon.color, AppColors.light.textTertiary);
      expect(
        tester.getCenter(find.byIcon(AppIcons.chevronRight)).dx,
        greaterThan(tester.getCenter(_group).dx),
      );
    });

    testWidgets('leading ve trailing yerleşir; leadingExtent olmadan assert', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppListGroup(
          children: [
            AppListRow(
              leading: Icon(Icons.home, size: 20),
              leadingExtent: 20,
              title: 'Ev',
              trailing: Text('Aç'),
            ),
          ],
        ),
      );
      expect(
        tester.getCenter(find.byIcon(Icons.home)).dx,
        lessThan(tester.getCenter(find.text('Ev')).dx),
      );
      expect(
        tester.getCenter(find.text('Aç')).dx,
        greaterThan(tester.getCenter(find.text('Ev')).dx),
      );
      expect(
        () => AppListRow(leading: const Icon(Icons.home), title: 'x'),
        throwsAssertionError,
      );
    });
  });

  group('ayırıcı', () {
    testWidgets('son satırda yok; n-1 tane, 1px, border renkli', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppListGroup(
          children: [
            AppListRow(title: 'A'),
            AppListRow(title: 'B'),
            AppListRow(title: 'C'),
          ],
        ),
      );
      final d = _dividers(AppColors.light.border);
      expect(d, findsNWidgets(2));
      expect(tester.getSize(d.first).height, 1);
    });

    testWidgets(
      'metnin başladığı yerden başlar: leading yoksa 16, varsa 16 + extent + 12',
      (tester) async {
        await pumpApp(
          tester,
          const AppListGroup(
            children: [
              AppListRow(title: 'Düz'),
              AppListRow(
                leading: SizedBox(width: 56, height: 56),
                leadingExtent: 56,
                title: 'Thumbnail',
              ),
              AppListRow(title: 'Son'),
            ],
          ),
        );
        final dividers = _dividers(AppColors.light.border);
        final groupLeft = tester.getTopLeft(_group).dx;
        final groupRight = tester.getTopRight(_group).dx;
        expect(
          tester.getTopLeft(dividers.at(0)).dx - groupLeft,
          16,
          reason: 'leading yok',
        );
        // Thumbnail satırının ayırıcısı, thumbnail satırı üçüncü sırada son değil → 2. ayırıcı.
        expect(
          tester.getTopLeft(dividers.at(1)).dx - groupLeft,
          16 + 56 + 12,
          reason: 'leading var',
        );
        expect(
          tester.getTopLeft(dividers.at(1)).dx,
          tester.getTopLeft(find.text('Thumbnail')).dx,
        );
        expect(
          tester.getTopRight(dividers.at(0)).dx,
          groupRight,
          reason: 'sağ kenara kadar',
        );
      },
    );

    testWidgets('grup dışındaki satırda ayırıcı yok', (tester) async {
      await pumpApp(tester, const AppListRow(title: 'Tek'));
      expect(
        find
            .byType(ColoredBox)
            .evaluate()
            .where(
              (e) => (e.widget as ColoredBox).color == AppColors.light.border,
            ),
        isEmpty,
      );
    });
  });

  group('etkileşim', () {
    testWidgets('onPressed: dokununca çağrılır; basılıyken surfacePressed', (
      tester,
    ) async {
      var taps = 0;
      await pumpApp(
        tester,
        AppListGroup(
          children: [AppListRow(title: 'Profil', onPressed: () => taps++)],
        ),
      );
      Color? bg() {
        final box = tester.widget<AnimatedContainer>(
          find
              .descendant(of: _rows, matching: find.byType(AnimatedContainer))
              .first,
        );
        return (box.decoration as BoxDecoration?)?.color;
      }

      expect(bg(), Colors.transparent);
      final g = await tester.startGesture(tester.getCenter(_rows));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(bg(), AppColors.light.surfacePressed);
      await g.up();
      await tester.pumpAndSettle();
      expect(taps, 1);
      expect(bg(), Colors.transparent);
    });

    testWidgets('satır ölçeklenmez (yalnızca arka plan)', (tester) async {
      await pumpApp(
        tester,
        AppListGroup(
          children: [AppListRow(title: 'Profil', onPressed: () {})],
        ),
      );
      final g = await tester.startGesture(tester.getCenter(_rows));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        find.descendant(of: _rows, matching: find.byType(Transform)),
        findsNothing,
      );
      await g.up();
    });

    testWidgets('dokunulamayan satırda (toggle trailing) satır tıklaması yok', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppListGroup(
          children: [AppListRow(title: 'Bildirimler', trailing: Text('Açık'))],
        ),
      );
      expect(
        find.descendant(of: _rows, matching: find.byType(GestureDetector)),
        findsNothing,
      );
    });
  });

  group('tekli seçim', () {
    testWidgets('seçili satırda sağda brand ✓ (20); diğerlerinde yok', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppListGroup(
          children: [
            AppListRow(title: 'Uyuma göre', selected: true),
            AppListRow(title: 'Mesafeye göre', selected: false),
          ],
        ),
      );
      expect(find.byIcon(AppIcons.check), findsOneWidget);
      final icon = tester.widget<Icon>(find.byIcon(AppIcons.check));
      expect(icon.size, 20);
      expect(icon.color, AppColors.light.brand);
      expect(
        tester.getCenter(find.byIcon(AppIcons.check)).dx,
        greaterThan(tester.getCenter(_group).dx),
      );
    });

    testWidgets('seçim değişince metin kaymaz (✓ yeri ayrılı)', (tester) async {
      Future<void> pump(bool selected) => pumpApp(
        tester,
        AppListGroup(
          children: [
            AppListRow(
              title: 'Mesafeye göre',
              selected: selected,
              onPressed: () {},
            ),
          ],
        ),
      );
      await pump(false);
      final before = tester.getTopLeft(find.text('Mesafeye göre'));
      final width = tester.getSize(find.text('Mesafeye göre')).width;
      await pump(true);
      expect(tester.getTopLeft(find.text('Mesafeye göre')), before);
      expect(tester.getSize(find.text('Mesafeye göre')).width, width);
    });

    testWidgets('semantics: buton, etiket, seçili, değer = meta', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        AppListGroup(
          children: [
            AppListRow(
              title: 'Uyuma göre',
              subtitle: 'Varsayılan',
              selected: true,
              onPressed: () {},
            ),
          ],
        ),
      );
      final node = tester.getSemantics(_rows);
      expect(node.label, 'Uyuma göre');
      expect(node.value, 'Varsayılan');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isSelected.toString(), contains('isTrue'));
      handle.dispose();
    });
  });

  testWidgets('yazı 2x: satırlar metinle büyür, taşma yok', (tester) async {
    await pumpApp(
      tester,
      AppListGroup(
        children: [
          AppListRow(
            leading: const SizedBox(width: 56, height: 56),
            leadingExtent: 56,
            emphasized: true,
            title: 'Trattoria Lume',
            subtitle: '★ 4,6 · ₺₺ · 1,2 km',
            trailing: const Text('%80'),
            onPressed: () {},
          ),
        ],
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(_rows).height, greaterThan(52));
  });

  group('sonuç satırı seçenekleri', () {
    Widget group(AppListRow row) =>
        SizedBox(width: 350, child: AppListGroup(children: [row]));

    testWidgets('verticalPadding satır yüksekliğini belirler', (tester) async {
      await pumpApp(
        tester,
        group(
          const AppListRow(
            title: 'A',
            leading: SizedBox.square(dimension: 56),
            leadingExtent: 56,
            verticalPadding: 8,
          ),
        ),
      );
      expect(tester.getSize(find.byType(AppListRow)).height, 72);
    });

    testWidgets('highlighted: 2px brand halka, yerleşimi değiştirmez', (
      tester,
    ) async {
      await pumpApp(tester, group(const AppListRow(title: 'A')));
      final h = tester.getSize(find.byType(AppListRow));
      await pumpApp(
        tester,
        group(const AppListRow(title: 'A', highlighted: true)),
      );
      expect(tester.getSize(find.byType(AppListRow)), h);
      final ring = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<ShapeDecoration>()
          .where((d) {
            final s = d.shape;
            return s is RoundedSuperellipseBorder &&
                s.side.width == 2 &&
                s.side.color == AppColors.light.brand;
          });
      expect(ring, hasLength(1));
    });

    testWidgets('semanticLabel etkileşimsiz satırı tek öğe yapar', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        group(
          const AppListRow(
            title: 'A',
            subtitle: 'B',
            semanticLabel: 'A, B, özel',
          ),
        ),
      );
      expect(find.bySemanticsLabel('A, B, özel'), findsOneWidget);
      expect(find.bySemanticsLabel('A'), findsNothing);
      handle.dispose();
    });
  });
}
