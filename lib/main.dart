import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'core/design_system/foundations/app_theme.dart';
import 'core/design_system/foundations/context_extensions.dart';
import 'core/design_system/gallery/design_system_gallery.dart';
import 'l10n/app_localizations.dart';

void main() {
  runApp(const IAgreeApp());
}

class IAgreeApp extends StatelessWidget {
  const IAgreeApp({super.key, this.home});

  /// Verilmezse debug'da design system galerisi, release'te geçici açılış ekranı.
  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveLocale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home:
          home ??
          (kDebugMode
              ? const DesignSystemGallery()
              : const IAgreePlaceholder()),
    );
  }
}

/// Sistem dili desteklenenlerden biriyse o, değilse Türkçe.
Locale resolveLocale(Locale? locale, Iterable<Locale> supported) {
  return supported.firstWhere(
    (s) => s.languageCode == locale?.languageCode,
    orElse: () => const Locale('tr'),
  );
}

/// Geçici açılış ekranı; ilk gerçek ekran gelince kalkacak.
class IAgreePlaceholder extends StatelessWidget {
  const IAgreePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          AppLocalizations.of(context).appTitle,
          style: context.text.display,
        ),
      ),
    );
  }
}
