import 'package:flutter/material.dart';

import '../core/data/auth_repository.dart';
import '../core/data/mock/mock_auth_repository.dart';
import '../core/design_system/foundations/app_theme.dart';
import '../core/design_system/foundations/context_extensions.dart';
import '../core/design_system/gallery/design_system_gallery.dart';
import '../features/auth/welcome_screen.dart';
import '../features/home/home_screen.dart';
import '../l10n/app_localizations.dart';
import 'app_router.dart';
import 'app_scope.dart';
import 'session_controller.dart';

/// Uygulamanın kökü: tema, yerelleştirme, bağımlılıklar ([AppScope]) ve rotalar.
///
/// [home] verilirse (test) kök ekran olarak o gösterilir. [auth] ve [session] test için
/// değiştirilebilir; varsayılan sahte giriş ([MockAuthRepository]).
class IAgreeApp extends StatefulWidget {
  const IAgreeApp({super.key, this.home, this.auth, this.session});

  final Widget? home;
  final AuthRepository? auth;
  final SessionController? session;

  /// Geliştirme kısayolu: `--dart-define=DEMO=...` verilirse tasarım galerisi (ve demo
  /// sayfaları) açılır.
  static const String demo = String.fromEnvironment('DEMO');

  @override
  State<IAgreeApp> createState() => _IAgreeAppState();
}

class _IAgreeAppState extends State<IAgreeApp> {
  late final AuthRepository _auth = widget.auth ?? MockAuthRepository();
  late final SessionController _session =
      widget.session ?? (SessionController(auth: _auth)..restore());

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: _session,
      auth: _auth,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        localeResolutionCallback: resolveLocale,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home:
            widget.home ??
            (IAgreeApp.demo.isNotEmpty
                ? const DesignSystemGallery()
                : const RootGate()),
      ),
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

/// Oturum durumuna göre kök ekranı seçer: açılışta `canvas` (launch screen ile aynı),
/// oturum yoksa karşılama, varsa ana ekran.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context).session;
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => switch (session.status) {
        SessionStatus.unknown => ColoredBox(color: context.colors.canvas),
        SessionStatus.signedOut => const WelcomeScreen(),
        SessionStatus.signedIn => const HomeScreen(),
      },
    );
  }
}
