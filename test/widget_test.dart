import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/tokens/app_colors.dart';
import 'package:iagree/main.dart';

Color? _textColor(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find
        .descendant(of: find.text('iAgree'), matching: find.byType(RichText))
        .first,
  );
  return rich.text.style?.color;
}

void main() {
  testWidgets('açılış ekranı logoyu ve marka adını Fraunces ile gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(const IAgreeApp(home: IAgreePlaceholder()));
    expect(find.text('iAgree'), findsOneWidget);
    final style = tester.widget<Text>(find.text('iAgree')).style!;
    expect(style.fontFamily, 'Fraunces');
  });

  testWidgets('light temada metin textPrimary, zemin canvas', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const IAgreeApp(home: IAgreePlaceholder()));
    expect(_textColor(tester), AppColors.light.textPrimary);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor ??
          Theme.of(tester.element(find.byType(Scaffold)))
              .scaffoldBackgroundColor,
      AppColors.light.canvas,
    );
  });

  testWidgets('dark temada wordmark plumLight (brand), zemin canvas', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(const IAgreeApp(home: IAgreePlaceholder()));
    expect(_textColor(tester), AppColors.dark.brand);
    expect(
      Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor,
      AppColors.dark.canvas,
    );
  });
}
