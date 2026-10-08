import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/core/design_system/foundations/app_theme.dart';
import 'package:iagree/l10n/app_localizations.dart';

/// Bileşeni tema, yerelleştirme ve ölçek ayarlarıyla pompalar.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  double textScale = 1,
  bool disableAnimations = false,
  Locale locale = const Locale('tr'),
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        textScaler: TextScaler.linear(textScale),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: locale,
        theme: dark ? AppTheme.dark : AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    ),
  );
  if (settle) await tester.pumpAndSettle();
}
