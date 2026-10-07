import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iagree/l10n/app_localizations.dart';
import 'package:iagree/main.dart';

Future<BuildContext> _pump(WidgetTester tester, Locale locale) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  await tester.pumpWidget(const IAgreeApp(home: IAgreePlaceholder()));
  await tester.pumpAndSettle();
  return tester.element(find.byType(Scaffold));
}

void main() {
  test('desteklenen diller: tr ve en', () {
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      {'tr', 'en'},
    );
  });

  testWidgets('sistem dili Türkçe: Türkçe', (tester) async {
    final c = await _pump(tester, const Locale('tr', 'TR'));
    expect(Localizations.localeOf(c).languageCode, 'tr');
    expect(MaterialLocalizations.of(c).copyButtonLabel, 'Kopyala');
  });

  testWidgets('sistem dili İngilizce: İngilizce', (tester) async {
    final c = await _pump(tester, const Locale('en', 'US'));
    expect(Localizations.localeOf(c).languageCode, 'en');
    expect(MaterialLocalizations.of(c).copyButtonLabel, 'Copy');
  });

  testWidgets('desteklenmeyen dil: Türkçeye düşer', (tester) async {
    final c = await _pump(tester, const Locale('de', 'DE'));
    expect(Localizations.localeOf(c).languageCode, 'tr');
    expect(MaterialLocalizations.of(c).copyButtonLabel, 'Kopyala');
  });

  testWidgets('marka adı iki dilde de iAgree', (tester) async {
    for (final l in AppLocalizations.supportedLocales) {
      expect(lookupAppLocalizations(l).appTitle, 'iAgree');
    }
  });
}
