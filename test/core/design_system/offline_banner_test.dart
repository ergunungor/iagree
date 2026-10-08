import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/feedback/offline_banner.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Finder get _bg => find.descendant(
  of: find.byType(OfflineBanner),
  matching: find.byType(ColoredBox),
);

void main() {
  for (final dark in [false, true]) {
    final c = dark ? AppColors.dark : AppColors.light;
    final name = dark ? 'dark' : 'light';

    testWidgets('warningSoft zemin, warning içerik, wifiOff 20 $name', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(
        tester,
        const SizedBox(width: 390, child: OfflineBanner(visible: true)),
        dark: dark,
      );
      expect(tester.widget<ColoredBox>(_bg.first).color, c.warningSoft);
      final icon = tester.widget<Icon>(find.byIcon(AppIcons.wifiOff));
      expect(icon.size, 20);
      expect(icon.color, c.warning);
      final text = tester.widget<Text>(
        find.text('Bağlantı yok. Değişikliklerin bağlanınca gönderilecek.'),
      );
      expect(text.style!.color, c.warning);
      expect(text.style!.fontSize, 15);
    });
  }

  testWidgets('tam genişlik; yatay 20, dikey 12 padding', (tester) async {
    _phone(tester);
    await pumpApp(
      tester,
      const SizedBox(width: 390, child: OfflineBanner(visible: true)),
    );
    final r = tester.getRect(_bg.first);
    expect(r.width, 350); // pumpApp içeriği 20 pt içeri alır: 390 − 40
    expect(tester.getTopLeft(find.byIcon(AppIcons.wifiOff)).dx - r.left, 20);
    expect(tester.getTopLeft(find.byIcon(AppIcons.wifiOff)).dy - r.top, 12);
  });

  testWidgets('visible: false → görünmez, yer kaplamaz', (tester) async {
    _phone(tester);
    await pumpApp(
      tester,
      const SizedBox(width: 390, child: OfflineBanner(visible: false)),
    );
    expect(find.byIcon(AppIcons.wifiOff), findsNothing);
    expect(tester.getSize(find.byType(OfflineBanner)).height, 0);
  });

  testWidgets(
    'görünürlük animasyonla açılır ve kapanır (yükseklik büyür/küçülür)',
    (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        const SizedBox(width: 390, child: OfflineBanner(visible: false)),
      );
      await pumpApp(
        tester,
        const SizedBox(width: 390, child: OfflineBanner(visible: true)),
        settle: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final mid = tester.getSize(find.byType(OfflineBanner)).height;
      await tester.pumpAndSettle();
      final full = tester.getSize(find.byType(OfflineBanner)).height;
      expect(mid, lessThan(full));
      expect(full, greaterThan(40));
      await pumpApp(
        tester,
        const SizedBox(width: 390, child: OfflineBanner(visible: false)),
      );
      expect(tester.getSize(find.byType(OfflineBanner)).height, 0);
    },
  );

  testWidgets('Reduce Motion: anında, çökme yok', (tester) async {
    _phone(tester);
    await pumpApp(
      tester,
      const SizedBox(width: 390, child: OfflineBanner(visible: false)),
      disableAnimations: true,
    );
    await pumpApp(
      tester,
      const SizedBox(width: 390, child: OfflineBanner(visible: true)),
      disableAnimations: true,
      settle: false,
    );
    await tester.pump();
    expect(find.byIcon(AppIcons.wifiOff), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('canlı bölge; metin tr/en', (tester) async {
    _phone(tester);
    final handle = tester.ensureSemantics();
    await pumpApp(
      tester,
      const SizedBox(width: 390, child: OfflineBanner(visible: true)),
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel(RegExp('Bağlantı yok')))
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );
    await pumpApp(
      tester,
      const SizedBox(width: 390, child: OfflineBanner(visible: true)),
      locale: const Locale('en'),
    );
    expect(find.textContaining('No connection'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('yazı 2x: banner metinle büyür, taşma yok', (tester) async {
    _phone(tester);
    await pumpApp(
      tester,
      const SizedBox(width: 390, child: OfflineBanner(visible: true)),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
