import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/components/buttons/app_icon_button.dart';
import 'package:iagree/core/design_system/components/inputs/app_stepper.dart';
import 'package:iagree/core/design_system/foundations/app_icons.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/l10n/app_localizations.dart';

class _Host extends StatefulWidget {
  const _Host({
    required this.initial,
    this.min = 1,
    this.max = 12,
    this.step = 1,
    this.enabled = true,
    this.onValue,
  });
  final int initial;
  final int min;
  final int max;
  final int step;
  final bool enabled;
  final ValueChanged<int>? onValue;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late int value = widget.initial;

  @override
  Widget build(BuildContext context) => AppStepper(
    value: value,
    min: widget.min,
    max: widget.max,
    step: widget.step,
    semanticLabel: 'Kişi sayısı',
    valueFormatter: (v) => '$v kişi',
    onChanged: widget.enabled
        ? (v) {
            setState(() => value = v);
            widget.onValue?.call(v);
          }
        : null,
  );
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double textScale = 1,
  Locale locale = const Locale('tr'),
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Gerçek uygulamadaki gibi kare kare ilerler: zamanlayıcı geri çağrıları arasında
/// yeniden çizim olur (tek büyük pump bayat değerle tekrar ettirir).
Future<void> _advance(WidgetTester tester, Duration total) async {
  const frame = Duration(milliseconds: 16);
  for (var t = Duration.zero; t < total; t += frame) {
    await tester.pump(frame);
  }
}

Finder get _minus => find.byWidgetPredicate(
  (w) => w is AppIconButton && w.icon == AppIcons.minus,
);
Finder get _plus => find.byWidgetPredicate(
  (w) => w is AppIconButton && w.icon == AppIcons.plus,
);
AppIconButton _btn(WidgetTester tester, Finder f) =>
    tester.widget<AppIconButton>(f);

void main() {
  group('görünüm', () {
    testWidgets('[−] değer [+]: iki Soft ikon butonu, değer title + tabular', (
      tester,
    ) async {
      await _pump(tester, const _Host(initial: 4));
      expect(_btn(tester, _minus).style, AppIconButtonStyle.soft);
      expect(_btn(tester, _plus).style, AppIconButtonStyle.soft);
      final style = tester.widget<Text>(find.text('4 kişi')).style!;
      expect(style.fontSize, 17);
      expect(style.fontWeight, FontWeight.w600);
      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(style.color, AppColors.light.textPrimary);
      // Sıra: − değer +
      final x = [
        _minus,
        find.text('4 kişi'),
        _plus,
      ].map((f) => tester.getCenter(f).dx).toList();
      expect(x[0], lessThan(x[1]));
      expect(x[1], lessThan(x[2]));
    });

    testWidgets(
      'butonların dokunma alanı 44, değer genişliği sabit (basamak değişince kaymaz)',
      (tester) async {
        await _pump(tester, const _Host(initial: 9));
        expect(tester.getSize(_minus), const Size(44, 44));
        final plusX = tester.getCenter(_plus).dx;
        await tester.tap(_plus);
        await tester.pumpAndSettle(); // 10 (iki basamak)
        await tester.tap(_plus);
        await tester.pumpAndSettle();
        expect(tester.getCenter(_plus).dx, closeTo(plusX, 6));
      },
    );

    testWidgets('dark', (tester) async {
      await _pump(tester, const _Host(initial: 4), dark: true);
      expect(
        tester.widget<Text>(find.text('4 kişi')).style!.color,
        AppColors.dark.textPrimary,
      );
    });
  });

  group('davranış', () {
    testWidgets('+ ve − değeri step kadar değiştirir', (tester) async {
      final seen = <int>[];
      await _pump(tester, _Host(initial: 4, step: 2, onValue: seen.add));
      await tester.tap(_plus);
      await tester.pumpAndSettle();
      await tester.tap(_minus);
      await tester.pumpAndSettle();
      await tester.tap(_minus);
      await tester.pumpAndSettle();
      expect(seen, [6, 4, 2]);
    });

    testWidgets('min ve max\'ta ilgili buton pasif, aşılmaz', (tester) async {
      await _pump(tester, const _Host(initial: 1, min: 1, max: 2));
      expect(_btn(tester, _minus).onPressed, isNull);
      expect(_btn(tester, _plus).onPressed, isNotNull);
      await tester.tap(_plus);
      await tester.pumpAndSettle();
      expect(find.text('2 kişi'), findsOneWidget);
      expect(_btn(tester, _plus).onPressed, isNull);
      expect(_btn(tester, _minus).onPressed, isNotNull);
    });

    testWidgets('onChanged null: ikisi de pasif, değer textDisabled', (
      tester,
    ) async {
      await _pump(tester, const _Host(initial: 3, enabled: false));
      expect(_btn(tester, _minus).onPressed, isNull);
      expect(_btn(tester, _plus).onPressed, isNull);
      expect(
        tester.widget<Text>(find.text('3 kişi')).style!.color,
        AppColors.light.textDisabled,
      );
    });

    testWidgets('her adımda selection haptic', (tester) async {
      final calls = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              calls.add(call.arguments as String);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await _pump(tester, const _Host(initial: 4));
      await tester.tap(_plus);
      await tester.pumpAndSettle();
      await tester.tap(_minus);
      await tester.pumpAndSettle();
      expect(calls, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.selectionClick',
      ]);
    });

    testWidgets(
      'basılı tutunca hızlanarak tekrarlar; bırakınca ekstra adım yok',
      (tester) async {
        final seen = <int>[];
        await _pump(tester, _Host(initial: 1, max: 99, onValue: seen.add));
        final g = await tester.startGesture(tester.getCenter(_plus));
        await _advance(tester, const Duration(milliseconds: 350));
        expect(seen, isEmpty, reason: 'gecikme süresi dolmadan tekrar yok');
        await _advance(tester, const Duration(milliseconds: 150));
        expect(seen, [2], reason: '400 ms sonra ilk tekrar');

        await _advance(tester, const Duration(seconds: 1));
        final firstSecond = seen.length - 1;
        await _advance(tester, const Duration(seconds: 1));
        final secondSecond = seen.length - 1 - firstSecond;
        expect(secondSecond, greaterThan(firstSecond), reason: 'hızlanıyor');
        // Her adım tam bir artış: bayat değer yok.
        expect(seen, [for (var i = 0; i < seen.length; i++) i + 2]);

        final beforeRelease = seen.length;
        await g.up();
        await tester.pump();
        expect(seen.length, beforeRelease, reason: 'bırakınca tap sayılmaz');
        await _advance(tester, const Duration(seconds: 2));
        expect(seen.length, beforeRelease, reason: 'bırakınca tekrar durur');
      },
    );

    testWidgets('en hızlı tekrar aralığı sınırlı (60 ms)', (tester) async {
      final seen = <int>[];
      await _pump(tester, _Host(initial: 1, max: 999, onValue: seen.add));
      final g = await tester.startGesture(tester.getCenter(_plus));
      await _advance(tester, const Duration(seconds: 6));
      final before = seen.length;
      await _advance(tester, const Duration(seconds: 1));
      final perSecond = seen.length - before;
      expect(perSecond, lessThanOrEqualTo(17)); // 1000/60
      expect(perSecond, greaterThan(10));
      await g.up();
    });

    testWidgets('kısa dokunuş tam bir adım', (tester) async {
      final seen = <int>[];
      await _pump(tester, _Host(initial: 1, onValue: seen.add));
      await tester.tap(_plus);
      await tester.pump(const Duration(seconds: 1));
      expect(seen, [2]);
    });

    testWidgets('tutarken max\'a ulaşınca durur', (tester) async {
      final seen = <int>[];
      await _pump(tester, _Host(initial: 1, max: 3, onValue: seen.add));
      final g = await tester.startGesture(tester.getCenter(_plus));
      await _advance(tester, const Duration(seconds: 3));
      expect(seen, [2, 3]);
      await g.up();
    });
  });

  group('erişilebilirlik', () {
    testWidgets('butonlar yerelleştirilmiş etiket taşır (tr/en)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const _Host(initial: 4));
      expect(find.bySemanticsLabel('Azalt'), findsOneWidget);
      expect(find.bySemanticsLabel('Artır'), findsOneWidget);
      await _pump(tester, const _Host(initial: 4), locale: const Locale('en'));
      expect(find.bySemanticsLabel('Decrease'), findsOneWidget);
      expect(find.bySemanticsLabel('Increase'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('ayarlanabilir değer: etiket, değer, artır/azalt eylemleri', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final seen = <int>[];
      await _pump(tester, _Host(initial: 4, onValue: seen.add));
      final node = tester.getSemantics(find.bySemanticsLabel('Kişi sayısı'));
      expect(node.value, '4 kişi');
      expect(node.increasedValue, '5 kişi');
      expect(node.decreasedValue, '3 kişi');
      tester.semantics.performAction(
        find.semantics.byLabel('Kişi sayısı'),
        SemanticsAction.increase,
      );
      await tester.pumpAndSettle();
      tester.semantics.performAction(
        find.semantics.byLabel('Kişi sayısı'),
        SemanticsAction.decrease,
      );
      await tester.pumpAndSettle();
      expect(seen, [5, 4]);
      handle.dispose();
    });

    testWidgets('sınırlarda artır/azalt eylemi yok', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const _Host(initial: 12));
      final node = tester.getSemantics(find.bySemanticsLabel('Kişi sayısı'));
      expect(node.increasedValue, isEmpty);
      expect(node.decreasedValue, '11 kişi');
      handle.dispose();
    });

    testWidgets('yazı 2x: taşma yok', (tester) async {
      await _pump(tester, const _Host(initial: 12), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
