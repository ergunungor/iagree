import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/buttons/app_button.dart';
import 'package:iagree/core/design_system/components/feedback/app_empty_state.dart';
import 'package:iagree/core/design_system/components/people/participant_ring.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

void _phone(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Boş durumun yaşadığı ekran: tam yükseklik, sabit boyutlu kap.
Widget _screen(Widget child) => SizedBox(width: 390, height: 780, child: child);

void main() {
  group('boş durum (kesik çizgili avatarlar)', () {
    testWidgets('görsel → h3 → bodySmall → tek buton, ortalı', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        _screen(
          AppEmptyState.dashedAvatars(
            title: 'Henüz oda yok',
            message: 'İlk odanı kur, arkadaşlarını çağır.',
            actionLabel: 'Oda oluştur',
            onAction: () {},
          ),
        ),
      );
      final title = find.text('Henüz oda yok');
      final message = find.text('İlk odanı kur, arkadaşlarını çağır.');
      final action = find.widgetWithText(AppButton, 'Oda oluştur');
      expect(
        tester.getTopLeft(find.byType(ParticipantRing).first).dy,
        lessThan(tester.getTopLeft(title).dy),
      );
      expect(
        tester.getTopLeft(title).dy,
        lessThan(tester.getTopLeft(message).dy),
      );
      expect(
        tester.getTopLeft(message).dy,
        lessThan(tester.getTopLeft(action).dy),
      );
      final t = tester.widget<Text>(title);
      expect(t.style!.fontSize, 20);
      expect(t.textAlign, TextAlign.center);
      final m = tester.widget<Text>(message);
      expect(m.style!.fontSize, 15);
      expect(m.style!.color, AppColors.light.textSecondary);
      expect(
        tester.getCenter(title).dx,
        closeTo(tester.getCenter(message).dx, 0.5),
      );
    });

    testWidgets(
      'yapısal görsel: 3 kesik çizgili (invited) halka, stok illüstrasyon yok',
      (tester) async {
        _phone(tester);
        await pumpApp(
          tester,
          _screen(const AppEmptyState.dashedAvatars(title: 'Boş')),
        );
        final rings = tester
            .widgetList<ParticipantRing>(find.byType(ParticipantRing))
            .toList();
        expect(rings.length, 3);
        expect(
          rings.every((r) => r.status == ParticipantStatus.invited),
          isTrue,
        );
        expect(find.byType(Image), findsNothing);
      },
    );

    testWidgets('içerik dikeyde ~%40\'a yerleşir', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        _screen(const AppEmptyState.dashedAvatars(title: 'Boş', message: 'x')),
      );
      final screen = tester.getRect(find.byType(AppEmptyState));
      final content = tester.getRect(find.byType(Column).first);
      final centerRatio = (content.center.dy - screen.top) / screen.height;
      expect(centerRatio, closeTo(0.4, 0.06));
    });

    testWidgets('mesaj ve buton isteğe bağlı; buton Primary, tek', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(
        tester,
        _screen(const AppEmptyState.dashedAvatars(title: 'Boş')),
      );
      expect(find.byType(AppButton), findsNothing);
      await pumpApp(
        tester,
        _screen(
          AppEmptyState.dashedAvatars(
            title: 'Boş',
            actionLabel: 'Davet et',
            onAction: () {},
          ),
        ),
      );
      expect(find.byType(AppButton), findsOneWidget);
      expect(
        tester.widget<AppButton>(find.byType(AppButton)).variant,
        AppButtonVariant.primary,
      );
    });

    test('eylem etiketi ve geri çağrı birlikte verilmeli', () {
      expect(
        () => AppEmptyState.dashedAvatars(title: 'x', actionLabel: 'y'),
        throwsAssertionError,
      );
    });

    testWidgets('buton çalışır', (tester) async {
      _phone(tester);
      var taps = 0;
      await pumpApp(
        tester,
        _screen(
          AppEmptyState.dashedAvatars(
            title: 'Boş',
            actionLabel: 'Oda oluştur',
            onAction: () => taps++,
          ),
        ),
      );
      await tester.tap(find.widgetWithText(AppButton, 'Oda oluştur'));
      expect(taps, 1);
    });
  });

  group('hata durumu', () {
    testWidgets('nötr 32\'lik ikon (error rengi değil), aynı yapı', (
      tester,
    ) async {
      _phone(tester);
      await pumpApp(
        tester,
        _screen(
          AppEmptyState.error(
            title: 'Yüklenemedi',
            message: 'Bağlantını kontrol edip tekrar dene.',
            actionLabel: 'Tekrar dene',
            onAction: () {},
          ),
        ),
      );
      final icon = tester.widget<Icon>(find.byIcon(AppIcons.warning));
      expect(icon.size, 32);
      expect(icon.color, AppColors.light.textSecondary);
      expect(icon.color, isNot(AppColors.light.error));
      expect(find.byType(ParticipantRing), findsNothing);
      expect(find.text('Yüklenemedi'), findsOneWidget);
    });

    testWidgets('ikon değiştirilebilir', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        _screen(
          AppEmptyState.error(title: 'Çevrimdışı', icon: AppIcons.wifiOff),
        ),
      );
      expect(find.byIcon(AppIcons.wifiOff), findsOneWidget);
    });
  });

  group('dark, semantics, ölçek', () {
    testWidgets('dark temada metin renkleri', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        _screen(
          const AppEmptyState.dashedAvatars(title: 'Boş', message: 'açıklama'),
        ),
        dark: true,
      );
      expect(
        tester.widget<Text>(find.text('açıklama')).style!.color,
        AppColors.dark.textSecondary,
      );
    });

    testWidgets('başlık header; görsel süs (semantics\'siz)', (tester) async {
      _phone(tester);
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        _screen(const AppEmptyState.dashedAvatars(title: 'Henüz oda yok')),
      );
      expect(
        tester
            .getSemantics(find.text('Henüz oda yok'))
            .flagsCollection
            .isHeader,
        isTrue,
      );
      expect(find.bySemanticsLabel(RegExp('bekleniyor')), findsNothing);
      handle.dispose();
    });

    testWidgets('yazı 2x: taşma yok', (tester) async {
      _phone(tester);
      await pumpApp(
        tester,
        _screen(
          AppEmptyState.dashedAvatars(
            title: 'Henüz oda yok',
            message: 'İlk odanı kur, arkadaşlarını çağır.',
            actionLabel: 'Oda oluştur',
            onAction: () {},
          ),
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('küçük alanda büyük yazı: kaydırılır, taşmaz', (tester) async {
    _phone(tester);
    await pumpApp(
      tester,
      SizedBox(
        width: 390,
        height: 220,
        child: AppEmptyState.dashedAvatars(
          title: 'Henüz oda yok',
          message: 'İlk odanı kur, arkadaşlarını çağır.',
          actionLabel: 'Oda oluştur',
          onAction: () {},
        ),
      ),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(
      find.descendant(
        of: find.byType(AppEmptyState),
        matching: find.byType(SingleChildScrollView),
      ),
      findsOneWidget,
    );
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();
    expect(find.text('Oda oluştur'), findsOneWidget);
  });

  group('galeri kutusu', () {
    // Galeri kutuları 300 × yazı ölçeği yüksekliğinde; içerik kaydırma gerektirmemeli.
    for (final scale in [1.0, 2.0]) {
      testWidgets('hata durumu ${scale}x: 300×ölçek kutuda kesilmez', (
        tester,
      ) async {
        _phone(tester);
        await pumpApp(
          tester,
          SizedBox(
            width: 350,
            height: 300 * scale,
            child: AppEmptyState.error(
              title: 'Yüklenemedi',
              message: 'Bağlantını kontrol edip tekrar dene.',
              actionLabel: 'Tekrar dene',
              onAction: () {},
            ),
          ),
          textScale: scale,
        );
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position;
        expect(position.maxScrollExtent, 0);
      });
    }
  });
}
