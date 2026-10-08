import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/people/app_avatar.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';

import '../../support/pump_app.dart';

Finder get _avatar => find.byType(AppAvatar);
Finder get _clip =>
    find.descendant(of: _avatar, matching: find.byType(ClipPath)).first;
ShapeBorder _clipShape(WidgetTester tester) =>
    (tester.widget<ClipPath>(_clip).clipper! as ShapeBorderClipper).shape;
Color _background(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find.descendant(of: _avatar, matching: find.byType(ColoredBox)).first,
    )
    .color;

void main() {
  group('stableHash (FNV-1a 32 bit)', () {
    test('bilinen test vektörleri', () {
      expect(stableHash(''), 0x811C9DC5);
      expect(stableHash('a'), 0xE40C292C);
      expect(stableHash('foobar'), 0xBF9CF968);
    });

    test('her zaman 32 bit, her çağrıda aynı', () {
      for (final s in ['u-ayse', 'İlker Işık', '😀', 'x' * 1000]) {
        final h = stableHash(s);
        expect(h, inInclusiveRange(0, 0xFFFFFFFF));
        expect(stableHash(s), h);
      }
    });
  });

  group('baş harfler', () {
    test('tek sözcükte ilk harf, birden çok sözcükte ilk ve son sözcüğün ilk harfi', () {
      expect(avatarInitials('Can'), 'C');
      expect(avatarInitials('Ayşe Yılmaz'), 'AY');
      expect(avatarInitials('Ayşe Nur Yılmaz'), 'AY');
      expect(avatarInitials('  Ayşe    Yılmaz  '), 'AY');
      expect(avatarInitials(''), '');
      expect(avatarInitials('   '), '');
    });

    test('maxLetters 1: yalnızca ilk harf', () {
      expect(avatarInitials('Ayşe Yılmaz', maxLetters: 1), 'A');
    });

    test('büyük/küçük harf dönüştürülmez: Türkçe i/I korunur', () {
      expect(avatarInitials('ali veli'), 'av');
      expect(avatarInitials('İlker Işık'), 'İI');
      expect(avatarInitials('ılgaz ipek'), 'ıi');
    });

    test('yedek çift (emoji) bölünmez', () {
      expect(avatarInitials('😀 Ali'), '😀A');
      expect(avatarInitials('😀'), '😀');
    });

    test(
      'kod tabanında toUpperCase / toLowerCase çağrısı yok (DESIGN_SYSTEM §2)',
      () {
        final offenders = <String>[];
        for (final f
            in Directory('lib')
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) => f.path.endsWith('.dart'))) {
          final code = f.readAsLinesSync().where(
            (l) => !l.trimLeft().startsWith('//'),
          );
          if (code.any(
            (l) => l.contains('toUpperCase(') || l.contains('toLowerCase('),
          )) {
            offenders.add(f.path);
          }
        }
        expect(offenders, isEmpty);
      },
    );
  });

  group('tint', () {
    testWidgets(
      'userId\'den deterministik: hash % 5 indeksindeki avatar tinti',
      (tester) async {
        for (final id in ['u-ayse', 'u-can', 'u-deniz']) {
          await pumpApp(tester, AppAvatar(userId: id, name: 'X'));
          final expected = AppColors.light.avatarTints[stableHash(id) % 5];
          expect(_background(tester), expected, reason: id);
        }
      },
    );

    testWidgets('aynı userId her yeniden çizimde aynı renk', (tester) async {
      await pumpApp(tester, const AppAvatar(userId: 'u-can', name: 'Can'));
      final first = _background(tester);
      await pumpApp(
        tester,
        const AppAvatar(
          userId: 'u-can',
          name: 'Can Demir',
          size: AppAvatarSize.lg,
        ),
      );
      expect(_background(tester), first);
    });

    test('tintler 5 renge dağılır (20 kullanıcıda en az 4 farklı)', () {
      final used = {for (var i = 0; i < 20; i++) stableHash('user-$i') % 5};
      expect(used.length, greaterThanOrEqualTo(4));
    });

    testWidgets('dark temada dark tintler', (tester) async {
      await pumpApp(
        tester,
        const AppAvatar(userId: 'u-ayse', name: 'A'),
        dark: true,
      );
      expect(
        _background(tester),
        AppColors.dark.avatarTints[stableHash('u-ayse') % 5],
      );
    });
  });

  group('görünüm', () {
    testWidgets('boyutlar 20 / 28 / 40 / 56 / 88', (tester) async {
      final expected = {
        AppAvatarSize.xs: 20.0,
        AppAvatarSize.sm: 28.0,
        AppAvatarSize.md: 40.0,
        AppAvatarSize.lg: 56.0,
        AppAvatarSize.xl: 88.0,
      };
      for (final e in expected.entries) {
        await pumpApp(
          tester,
          AppAvatar(userId: 'u', name: 'Ayşe', size: e.key),
        );
        expect(
          tester.getSize(_avatar),
          Size.square(e.value),
          reason: '${e.key}',
        );
      }
    });

    testWidgets('insan: daire; mekan: radius sm kare', (tester) async {
      await pumpApp(tester, const AppAvatar(userId: 'u', name: 'Ayşe'));
      expect(_clipShape(tester), isA<CircleBorder>());
      await pumpApp(tester, const AppAvatar.place(name: 'Lume'));
      final shape = _clipShape(tester) as RoundedSuperellipseBorder;
      expect(shape.borderRadius, BorderRadius.circular(10));
    });

    testWidgets('baş harfler 600, textPrimary, boyutun %40\'ı', (tester) async {
      await pumpApp(
        tester,
        const AppAvatar(
          userId: 'u',
          name: 'Ayşe Yılmaz',
          size: AppAvatarSize.lg,
        ),
      );
      final style = tester.widget<Text>(find.text('AY')).style!;
      expect(style.fontWeight, FontWeight.w600);
      expect(style.color, AppColors.light.textPrimary);
      expect(style.fontSize, closeTo(56 * 0.4, 1e-9));
    });

    testWidgets(
      'xs ve sm\'de tek harf (üst üste binen grupta sığsın), md ve üstünde iki',
      (tester) async {
        for (final size in [AppAvatarSize.xs, AppAvatarSize.sm]) {
          await pumpApp(
            tester,
            AppAvatar(userId: 'u', name: 'Ayşe Yılmaz', size: size),
          );
          expect(find.text('A'), findsOneWidget, reason: '$size');
        }
        for (final size in [
          AppAvatarSize.md,
          AppAvatarSize.lg,
          AppAvatarSize.xl,
        ]) {
          await pumpApp(
            tester,
            AppAvatar(userId: 'u', name: 'Ayşe Yılmaz', size: size),
          );
          expect(find.text('AY'), findsOneWidget, reason: '$size');
        }
      },
    );

    testWidgets('yazı 2x: avatar ve baş harfler sabit, taşma yok', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppAvatar(
          userId: 'u',
          name: 'Ayşe Yılmaz',
          size: AppAvatarSize.md,
        ),
      );
      final size = tester.getSize(find.text('AY'));
      await pumpApp(
        tester,
        const AppAvatar(
          userId: 'u',
          name: 'Ayşe Yılmaz',
          size: AppAvatarSize.md,
        ),
        textScale: 2,
      );
      expect(tester.getSize(find.text('AY')), size);
      expect(tester.getSize(_avatar), const Size.square(40));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fotoğrafsız mekan: surfaceMuted + harita ikonu', (
      tester,
    ) async {
      await pumpApp(
        tester,
        const AppAvatar.place(name: 'Lume', size: AppAvatarSize.lg),
      );
      expect(_background(tester), AppColors.light.surfaceMuted);
      expect(
        tester.widget<Icon>(find.byIcon(AppIcons.map)).color,
        AppColors.light.textTertiary,
      );
    });

    testWidgets('online noktası/rozet yok: yalnızca kırpılmış içerik', (
      tester,
    ) async {
      await pumpApp(tester, const AppAvatar(userId: 'u', name: 'Ayşe'));
      expect(
        find.descendant(of: _avatar, matching: find.byType(Positioned)),
        findsNothing,
      );
    });
  });

  group('fotoğraf', () {
    testWidgets('fotoğraf verilirse Image gösterilir, tam boyutta kırpılır', (
      tester,
    ) async {
      await pumpApp(
        tester,
        AppAvatar(userId: 'u', name: 'Ayşe', image: MemoryImage(_pixel)),
        settle: false,
      );
      await tester.pump();
      expect(
        find.descendant(of: _avatar, matching: find.byType(Image)),
        findsOneWidget,
      );
      final image = tester.widget<Image>(
        find.descendant(of: _avatar, matching: find.byType(Image)),
      );
      expect(image.fit, BoxFit.cover);
      expect(image.width, 40);
    });

    testWidgets('yüklenemezse baş harflere düşer', (tester) async {
      await pumpApp(
        tester,
        const AppAvatar(
          userId: 'u',
          name: 'Ayşe Yılmaz',
          image: _BrokenImage(),
        ),
        settle: false,
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('AY'), findsOneWidget);
      tester.takeException();
    });
  });

  group('semantics', () {
    testWidgets('varsayılan: süs (isimle birlikte duyulmasın)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const AppAvatar(userId: 'u', name: 'Ayşe Yılmaz'));
      expect(find.bySemanticsLabel('AY'), findsNothing);
      handle.dispose();
    });

    testWidgets('semanticLabel verilirse tek görsel öğe', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const AppAvatar(
          userId: 'u',
          name: 'Ayşe Yılmaz',
          semanticLabel: 'Ayşe Yılmaz, oda sahibi',
        ),
      );
      final node = tester.getSemantics(_avatar);
      expect(node.label, 'Ayşe Yılmaz, oda sahibi');
      expect(node.flagsCollection.isImage, isTrue);
      handle.dispose();
    });
  });
}

/// 1×1 saydam PNG.
final _pixel = Uint8List.fromList(const [
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

/// Her zaman hata veren görsel sağlayıcı.
class _BrokenImage extends ImageProvider<_BrokenImage> {
  const _BrokenImage();

  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) =>
      Future.value(this);

  @override
  ImageStreamCompleter loadImage(
    _BrokenImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(
    Future<ImageInfo>.error(StateError('yüklenemedi')),
  );
}
