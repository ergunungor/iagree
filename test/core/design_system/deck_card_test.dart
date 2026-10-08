import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/deck/deck_card.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/core/design_system/tokens/app_elevation.dart';
import 'package:iagree/core/design_system/tokens/app_fixed_colors.dart';
import 'package:iagree/core/design_system/tokens/app_radius.dart';

import '../../support/pump_app.dart';

final _light = AppColors.light;

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget _photo(int i, {Color? color}) =>
    ColoredBox(key: ValueKey('photo$i'), color: color ?? Colors.primaries[i]);

Widget _card({
  List<Widget>? photos,
  String name = 'Trattoria Lume',
  double? rating = 4.6,
  String? category = 'İtalyan',
  int? price = 2,
  double? distance = 1.2,
  int? closing,
  VoidCallback? onTap,
}) => SizedBox(
  width: 350,
  child: DeckCard.place(
    name: name,
    photos: photos ?? [for (var i = 0; i < 4; i++) _photo(i)],
    rating: rating,
    category: category,
    priceLevel: price,
    distanceKm: distance,
    closingInMinutes: closing,
    onDetailsTap: onTap,
  ),
);

Widget _film({int? minutes = 130}) => SizedBox(
  width: 350,
  child: DeckCard.film(
    name: 'Son Kış',
    poster: const ColoredBox(color: Colors.blueGrey),
    rating: 7.8,
    genre: 'Dram',
    durationMinutes: minutes,
    platform: 'Netflix',
  ),
);

Finder get _cardFinder => find.byType(DeckCard);

Text _text(WidgetTester tester, String s) => tester.widget<Text>(find.text(s));

String _meta(WidgetTester tester) {
  final rich = tester
      .widgetList<Text>(find.byType(Text))
      .where((t) => t.textSpan != null)
      .first;
  return rich.textSpan!.toPlainText(includePlaceholders: false);
}

void main() {
  group('geometri', () {
    testWidgets('3:4 oran, genişliği ebeveynden alır', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card());
      final size = tester.getSize(_cardFinder);
      expect(size.width, 350);
      expect(size.height, closeTo(350 * 4 / 3, 0.01));
    });

    testWidgets('görsel alanı ~%78, panel %22', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card());
      final card = tester.getSize(_cardFinder);
      final photo = tester.getSize(find.byKey(const ValueKey('photo0')));
      expect(photo.height / card.height, closeTo(0.78, 0.01));
    });

    testWidgets('radius xl, surface, E2', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card());
      final deco = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: _cardFinder,
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<ShapeDecoration>()
          .first;
      expect(deco.color, _light.surface);
      expect(
        (deco.shape as RoundedSuperellipseBorder).borderRadius,
        BorderRadius.circular(AppRadius.xl),
      );
      expect(deco.shadows, AppElevation.light.e2.shadows);
    });

    testWidgets('dark temada surface dark', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card(), dark: true);
      final deco = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: _cardFinder,
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<ShapeDecoration>()
          .first;
      expect(deco.color, AppColors.dark.surface);
    });
  });

  group('fotoğraflar', () {
    testWidgets('en fazla 4 fotoğraf', (tester) async {
      expect(
        () => DeckCard.place(
          name: 'x',
          photos: [for (var i = 0; i < 5; i++) _photo(i)],
        ),
        throwsAssertionError,
      );
    });

    testWidgets('sağ yarı sonraki, sol yarı önceki; uçlarda sabit', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _card());
      final rect = tester.getRect(find.byKey(const ValueKey('photo0')));
      final left = Offset(rect.left + 40, rect.center.dy);
      final right = Offset(rect.right - 40, rect.center.dy);

      expect(find.byKey(const ValueKey('photo0')), findsOneWidget);
      await tester.tapAt(left); // ilkte önceki: sabit
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo0')), findsOneWidget);

      await tester.tapAt(right);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo1')), findsOneWidget);
      await tester.tapAt(right);
      await tester.tapAt(right);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo3')), findsOneWidget);
      await tester.tapAt(right); // sonda sonraki: sabit
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo3')), findsOneWidget);
      await tester.tapAt(left);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo2')), findsOneWidget);
    });

    testWidgets('segment göstergesi: 4 parça, aktif beyaz, diğerleri %45', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _card());
      final segs = find.byWidgetPredicate(
        (w) => w is SizedBox && w.height == 3 && w.child is DecoratedBox,
      );
      expect(segs, findsNWidgets(4));
      Color colorOf(int i) =>
          ((tester.widget<SizedBox>(segs.at(i)).child! as DecoratedBox)
                      .decoration
                  as ShapeDecoration)
              .color!;
      expect(colorOf(0), AppFixedColors.onMedia);
      for (var i = 1; i < 4; i++) {
        expect(colorOf(i).a, closeTo(0.45, 0.01));
      }
      final cardRect = tester.getRect(_cardFinder);
      final first = tester.getRect(segs.at(0));
      expect(first.top - cardRect.top, 10);
      expect(first.left - cardRect.left, 14);
      expect(tester.getRect(segs.at(1)).left - first.right, 4);
      await tester.tapAt(Offset(cardRect.right - 20, cardRect.top + 100));
      await tester.pumpAndSettle();
      expect(colorOf(0).a, closeTo(0.45, 0.01));
      expect(colorOf(1), AppFixedColors.onMedia);
    });

    testWidgets('tek fotoğrafta segment ve geçiş yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card(photos: [_photo(0)]));
      expect(
        find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 3 && w.child is DecoratedBox,
        ),
        findsNothing,
      );
      final rect = tester.getRect(find.byKey(const ValueKey('photo0')));
      await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('photo0')), findsOneWidget);
    });

    testWidgets('fotoğraf yoksa surfaceMuted + harita ikonu', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card(photos: const []));
      expect(find.byIcon(AppIcons.map), findsOneWidget);
    });

    testWidgets('Reduce Motion: geçiş anında, çökme yok', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card(), disableAnimations: true);
      final rect = tester.getRect(find.byKey(const ValueKey('photo0')));
      await tester.tapAt(Offset(rect.right - 20, rect.center.dy));
      await tester.pump();
      expect(find.byKey(const ValueKey('photo1')), findsOneWidget);
      expect(find.byKey(const ValueKey('photo0')), findsNothing);
    });
  });

  group('bilgi paneli', () {
    testWidgets('h3 isim, caption meta; iki satır, açık/gerekçe yok', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _card());
      final name = _text(tester, 'Trattoria Lume');
      expect(name.style!.fontSize, 20);
      expect(name.style!.fontWeight, FontWeight.w600);
      expect(_meta(tester), contains('4,6 · İtalyan · ₺₺ · 1,2 km'));
      final meta = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => t.textSpan != null);
      expect(meta.style!.fontSize, 13);
      expect(meta.style!.color, _light.textSecondary);
      expect(
        meta.style!.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
      expect(find.textContaining('Kapanıyor'), findsNothing);
      expect(find.textContaining('Açık'), findsNothing);
    });

    testWidgets('yıldız 14 pt', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card());
      final star = tester.widget<Icon>(find.byIcon(AppIcons.starFill));
      expect(star.size, 14);
      expect(star.color, _light.textSecondary);
    });

    testWidgets('boş öğeler atlanır, ayırıcı bozulmaz', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        _card(rating: null, category: 'Kafe', price: null, distance: 0.8),
      );
      expect(_meta(tester), 'Kafe · 0,8 km');
      await pumpApp(
        tester,
        _card(rating: 4.2, category: null, price: 1, distance: null),
      );
      expect(_meta(tester), contains('4,2 · ₺'));
      expect(_meta(tester), isNot(contains('· ·')));
    });

    testWidgets('en: ondalık nokta', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card(), locale: const Locale('en'));
      expect(_meta(tester), contains('4.6 · İtalyan · ₺₺ · 1.2 km'));
    });

    testWidgets('istisna: Kapanıyor · 45 dk, warning, panelin 3. satırı', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _card(closing: 45));
      final t = _text(tester, 'Kapanıyor · 45 dk');
      expect(t.style!.color, _light.warning);
      expect(t.style!.fontSize, 13);
      expect(
        tester.getTopLeft(find.text('Kapanıyor · 45 dk')).dy,
        greaterThan(tester.getBottomLeft(find.text('Trattoria Lume')).dy),
      );
    });

    testWidgets('panelin sol kenarı 20 içeride', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card());
      final card = tester.getRect(_cardFinder);
      expect(tester.getTopLeft(find.text('Trattoria Lume')).dx - card.left, 20);
    });

    testWidgets('onDetailsTap panele dokununca çağrılır', (tester) async {
      _phone(tester);
      var taps = 0;
      await pumpApp(tester, _card(onTap: () => taps++));
      await tester.tap(find.text('Trattoria Lume'));
      expect(taps, 1);
      final cardRect = tester.getRect(_cardFinder);
      await tester.tapAt(Offset(cardRect.center.dx, cardRect.top + 100));
      expect(taps, 1);
    });
  });

  group('yazı 2x', () {
    testWidgets('taşma yok, oran 3:4 korunur, görsel küçülür', (tester) async {
      _phone(tester);
      await pumpApp(tester, _card(closing: 45));
      final normalPhoto = tester.getSize(find.byKey(const ValueKey('photo0')));
      await pumpApp(tester, _card(closing: 45), textScale: 2);
      expect(tester.takeException(), isNull);
      final size = tester.getSize(_cardFinder);
      expect(size.height, closeTo(350 * 4 / 3, 0.01));
      expect(
        tester.getSize(find.byKey(const ValueKey('photo0'))).height,
        lessThan(normalPhoto.height),
      );
    });

    testWidgets('uzun isim 2 satırda kısalır', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        _card(name: 'Çok uzun bir mekan adı ve onun uzun açıklaması burada'),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('film', () {
    testWidgets('afiş 2:3, surfaceMuted zemin, ortalı', (tester) async {
      _phone(tester);
      await pumpApp(tester, _film());
      final area = tester.getRect(
        find
            .descendant(of: _cardFinder, matching: find.byType(ColoredBox))
            .first,
      );
      final poster = tester.getRect(find.byType(AspectRatio).last);
      expect(poster.height / poster.width, closeTo(1.5, 0.01));
      expect((poster.center.dx - area.center.dx).abs(), lessThan(0.5));
      expect(poster.height, closeTo(area.height - 32, 0.5));
    });

    testWidgets('meta: puan · tür · süre; mesafe yok; platform etiketi sağda', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(tester, _film());
      expect(_meta(tester), contains('7,8 · Dram · 2 sa 10 dk'));
      expect(find.textContaining('km'), findsNothing);
      final tag = tester.getRect(find.text('Netflix'));
      final name = tester.getRect(find.text('Son Kış'));
      expect(tag.left, greaterThan(name.right));
      final style = _text(tester, 'Netflix').style!;
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w600);
    });

    testWidgets('süre biçimleri', (tester) async {
      _phone(tester);
      await pumpApp(tester, _film(minutes: 120));
      expect(_meta(tester), contains('2 sa'));
      expect(_meta(tester), isNot(contains('dk')));
      await pumpApp(tester, _film(minutes: 45));
      expect(_meta(tester), contains('45 dk'));
    });
  });

  group('semantics', () {
    testWidgets(
      'panel tek düğüm: isim, puan, kategori, fiyat, mesafe (ek yok)',
      (tester) async {
        _phone(tester);
        final handle = tester.ensureSemantics();
        await pumpApp(tester, _card(onTap: () {}));
        final node = tester.getSemantics(
          find.bySemanticsLabel(RegExp('Trattoria Lume, 4,6 puan')),
        );
        expect(
          node.label,
          'Trattoria Lume, 4,6 puan, İtalyan, orta fiyat, 1,2 kilometre',
        );
        expect(node.hint, 'Ayrıntılar');
        handle.dispose();
      },
    );

    testWidgets('kapanıyor VoiceOver cümlesine eklenir', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _card(closing: 45, onTap: () {}));
      expect(
        find.bySemanticsLabel(RegExp(r'Kapanıyor, 45 dakika sonra$')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets(
      'fotoğraf alanı ayarlanabilir: artır/azalt fotoğraf değiştirir',
      (tester) async {
        _phone(tester);
        final handle = tester.ensureSemantics();
        await pumpApp(tester, _card());
        final finder = find.semantics.byLabel('Fotoğraf 1/4');
        expect(finder, findsOneWidget);
        tester.semantics.increase(finder);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('photo1')), findsOneWidget);
        expect(find.bySemanticsLabel('Fotoğraf 2/4'), findsOneWidget);
        tester.semantics.decrease(find.semantics.byLabel('Fotoğraf 2/4'));
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('photo0')), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets('film: afiş etiketi ve platform okunur', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _film());
      expect(find.bySemanticsLabel('Son Kış afişi'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          RegExp('Son Kış, Netflix, 7,8 puan, Dram, 2 saat 10 dakika'),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });
}
