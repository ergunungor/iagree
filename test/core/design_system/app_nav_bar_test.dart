import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/buttons/app_icon_button.dart';
import 'package:iagree/core/design_system/components/navigation/app_flow_progress.dart';
import 'package:iagree/core/design_system/components/navigation/app_nav_bar.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/l10n/app_localizations.dart';

import '../../support/pump_app.dart';

const _fraunces = 'Fraunces';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

final _list = SliverList.builder(
  itemCount: 40,
  itemBuilder: (_, i) => SizedBox(height: 60, child: Text('Satır $i')),
);

Widget _scroller({
  String title = 'Odalarım',
  VoidCallback? onBack,
  VoidCallback? onClose,
  List<AppNavBarAction> actions = const [],
  double? progress,
  ScrollController? controller,
}) => SizedBox(
  width: 350,
  height: 700,
  child: CustomScrollView(
    controller: controller,
    slivers: [
      AppNavBar(
        title: title,
        onBack: onBack,
        onClose: onClose,
        actions: actions,
        progress: progress,
      ),
      _list,
    ],
  ),
);

AppNavBarAction _action(String label, [IconData? icon]) => AppNavBarAction(
  icon: icon ?? AppIcons.plus,
  semanticLabel: label,
  onPressed: () {},
);

Finder get _blur => find.byWidgetPredicate(
  (w) =>
      w is BackdropFilter &&
      w.filter == ImageFilter.blur(sigmaX: 10, sigmaY: 10),
);

Iterable<BoxDecoration> _barDecorations(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(
      find.descendant(
        of: find.byType(CupertinoSliverNavigationBar),
        matching: find.byType(DecoratedBox),
      ),
    )
    .map((d) => d.decoration)
    .whereType<BoxDecoration>();

void main() {
  group('AppNavBar (kaydırılan)', () {
    testWidgets('large title h1 (Fraunces), inline başlık title (SF Pro)', (
      tester,
    ) async {
      _phone(tester);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpApp(tester, _scroller(controller: controller));
      final large = tester.widget<Text>(find.text('Odalarım').first);
      expect(large.style!.fontFamily, _fraunces);
      expect(large.style!.fontSize, 32);

      controller.jumpTo(200);
      await tester.pumpAndSettle();
      final inline = tester
          .widgetList<Text>(find.text('Odalarım'))
          .where((t) => t.style!.fontFamily != _fraunces);
      expect(inline, isNotEmpty);
    });

    testWidgets('en üstte hairline yok, içerik altından geçince belirir', (
      tester,
    ) async {
      _phone(tester);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpApp(tester, _scroller(controller: controller));

      Border border() =>
          _barDecorations(tester)
              .map((d) => d.border)
              .whereType<Border>()
              .first;

      expect(border().bottom.color.a, 0);
      controller.jumpTo(300);
      await tester.pumpAndSettle();
      expect(border().bottom.color, AppColors.light.border);
      expect(_blur, findsWidgets);
    });

    testWidgets('geri chevron: 44pt, "Geri" etiketi, dokununca çalışır', (
      tester,
    ) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      var back = 0;
      await pumpApp(tester, _scroller(onBack: () => back++));
      final btn = find.widgetWithIcon(AppIconButton, AppIcons.back);
      expect(tester.getSize(btn).width, greaterThanOrEqualTo(44));
      expect(tester.getSize(btn).height, greaterThanOrEqualTo(44));
      expect(find.bySemanticsLabel('Geri'), findsOneWidget);
      await tester.tap(btn);
      expect(back, 1);
      handle.dispose();
    });

    testWidgets('✕ modal için; geri ile birlikte olmaz', (tester) async {
      _phone(tester);
      await pumpApp(tester, _scroller(onClose: () {}));
      expect(find.byIcon(AppIcons.close), findsOneWidget);
      expect(find.byIcon(AppIcons.back), findsNothing);
      expect(
        () => AppNavBar(title: 'x', onBack: () {}, onClose: () {}),
        throwsAssertionError,
      );
    });

    testWidgets('en fazla 2 aksiyon; ikon 24, etiketler VoiceOver\'da', (
      tester,
    ) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        _scroller(actions: [_action('Oda oluştur'), _action('Profil')]),
      );
      expect(find.byType(AppIconButton), findsNWidgets(2));
      expect(tester.widget<Icon>(find.byIcon(AppIcons.plus).first).size, 24);
      expect(find.bySemanticsLabel('Oda oluştur'), findsOneWidget);
      expect(find.bySemanticsLabel('Profil'), findsOneWidget);
      expect(
        () => AppNavBar(
          title: 'x',
          actions: [_action('a'), _action('b'), _action('c')],
        ),
        throwsAssertionError,
      );
      handle.dispose();
    });

    testWidgets('başlık ve ikonlar çubuk kenarından screenPadding (20)', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(
        tester,
        _scroller(onBack: () {}, actions: [_action('Ekle')]),
      );
      final origin = tester.getTopLeft(find.byType(CustomScrollView));
      final icon = tester.getTopLeft(find.byIcon(AppIcons.back));
      expect(icon.dx - origin.dx, 20);
      final title = tester.getTopLeft(find.text('Odalarım').first);
      expect(title.dx - origin.dx, 20);
      final right = tester.getTopRight(find.byIcon(AppIcons.plus));
      expect(origin.dx + 350 - right.dx, 20);
    });

    testWidgets('progress: çubuk nav bar altında, kaydırınca da sabit', (
      tester,
    ) async {
      _phone(tester);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpApp(tester, _scroller(progress: 0.5, controller: controller));
      expect(find.byType(AppFlowProgress), findsOneWidget);
      controller.jumpTo(300);
      await tester.pumpAndSettle();
      expect(find.byType(AppFlowProgress), findsOneWidget);
      expect(find.textContaining('/'), findsNothing);
    });

    testWidgets('dark temada zemin dark canvas, yarı saydam', (tester) async {
      _phone(tester);
      final controller = ScrollController();
      addTearDown(controller.dispose);
      await pumpApp(tester, _scroller(controller: controller), dark: true);
      controller.jumpTo(300);
      await tester.pumpAndSettle();
      final bg = _barDecorations(tester)
          .map((d) => d.color)
          .whereType<Color>()
          .first;
      expect(bg.r, closeTo(AppColors.dark.canvas.r, 0.02));
      expect(bg.a, lessThan(1));
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets('yazı ${scale}x: taşma yok, başlık tek satır', (
        tester,
      ) async {
        _phone(tester);
        await pumpApp(
          tester,
          _scroller(
            title: 'Cuma akşamı yemek planı ve çok uzun oda adı',
            onBack: () {},
            actions: [_action('Ekle'), _action('Profil')],
          ),
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('AppInlineNavBar', () {
    Widget bar({
      VoidCallback? onBack,
      VoidCallback? onClose,
      List<AppNavBarAction> actions = const [],
      double? progress,
      bool hairline = false,
    }) => SizedBox(
      width: 350,
      child: AppInlineNavBar(
        title: 'Oda oluştur',
        onBack: onBack,
        onClose: onClose,
        actions: actions,
        progress: progress,
        hairline: hairline,
      ),
    );

    testWidgets('başlık ortalı, title stili, SF Pro', (tester) async {
      _phone(tester);
      await pumpApp(tester, bar(onClose: () {}, actions: [_action('Ekle')]));
      final t = tester.widget<Text>(find.text('Oda oluştur'));
      expect(t.style!.fontFamily, isNot(_fraunces));
      expect(t.textAlign, TextAlign.center);
      final origin = tester.getTopLeft(find.byType(AppInlineNavBar));
      expect(
        tester.getCenter(find.text('Oda oluştur')).dx - origin.dx,
        closeTo(175, 0.5),
      );
    });

    testWidgets('✕ solda; yükseklik 44 (+4 progress ile)', (tester) async {
      _phone(tester);
      await pumpApp(tester, bar(onClose: () {}));
      expect(find.byIcon(AppIcons.close), findsOneWidget);
      expect(
        tester.getSize(find.byType(AppInlineNavBar)).height,
        greaterThanOrEqualTo(44),
      );
      await pumpApp(tester, bar(onClose: () {}, progress: 0.25));
      expect(find.byType(AppFlowProgress), findsOneWidget);
      expect(
        AppInlineNavBar(title: 'x', progress: 0.25).preferredSize.height,
        48,
      );
    });

    testWidgets('Scaffold.appBar içinde taşma yok', (tester) async {
      _phone(tester);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light,
          home: Scaffold(
            appBar: AppInlineNavBar(
              title: 'Oda oluştur',
              onBack: () {},
              progress: 0.5,
              hairline: true,
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AppFlowProgress', () {
    testWidgets('4px yükseklik, iz surfaceMuted, oran value', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        const SizedBox(width: 200, child: AppFlowProgress(value: 0.5)),
      );
      expect(tester.getSize(find.byType(AppFlowProgress)).height, 4);
      expect(tester.getSize(find.byType(FractionallySizedBox)).width, 100);
      final colors = tester
          .widgetList<ColoredBox>(
            find.descendant(
              of: find.byType(AppFlowProgress),
              matching: find.byType(ColoredBox),
            ),
          )
          .map((b) => b.color);
      expect(colors, contains(AppColors.light.surfaceMuted));
    });

    testWidgets('değişince animasyonla akar; Reduce Motion\'da anında', (
      tester,
    ) async {
      _phone(tester);
      Widget p(double v) =>
          SizedBox(width: 200, child: AppFlowProgress(value: v));
      await pumpApp(tester, p(0.25));
      await pumpApp(tester, p(0.75), settle: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = tester.getSize(find.byType(FractionallySizedBox)).width;
      expect(mid, inExclusiveRange(50, 150));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(FractionallySizedBox)).width, 150);

      await pumpApp(tester, p(0.25), disableAnimations: true);
      await pumpApp(tester, p(0.75), disableAnimations: true, settle: false);
      await tester.pump();
      expect(tester.getSize(find.byType(FractionallySizedBox)).width, 150);
    });

    testWidgets('VoiceOver değeri yüzde (tr: %50, en: 50%), "Adım" yok', (
      tester,
    ) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const AppFlowProgress(value: 0.5));
      expect(tester.getSemantics(find.byType(AppFlowProgress)).value, '%50');
      await pumpApp(
        tester,
        const AppFlowProgress(value: 0.5),
        locale: const Locale('en'),
      );
      expect(tester.getSemantics(find.byType(AppFlowProgress)).value, '50%');
      handle.dispose();
    });

    test('0–1 dışı değer assert verir', () {
      expect(() => AppFlowProgress(value: 1.5), throwsAssertionError);
      expect(() => AppFlowProgress(value: -0.1), throwsAssertionError);
    });
  });
}
