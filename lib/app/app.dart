import 'package:flutter/material.dart';

import '../core/data/auth_repository.dart';
import '../core/data/mock/mock_auth_repository.dart';
import '../core/data/mock/mock_rooms_repository.dart';
import '../core/design_system/foundations/app_theme.dart';
import '../core/design_system/foundations/context_extensions.dart';
import '../core/design_system/gallery/design_system_gallery.dart';
import '../features/auth/welcome_screen.dart';
import '../features/home/home_screen.dart';
import '../l10n/app_localizations.dart';
import 'app_router.dart';
import 'app_scope.dart';
import 'platform_services.dart';
import 'rooms_controller.dart';
import 'session_controller.dart';
import 'settings_controller.dart';

/// Uygulamanın kökü: tema, yerelleştirme, bağımlılıklar ([AppScope]) ve rotalar.
///
/// [home] verilirse (test) kök ekran olarak o gösterilir. [auth] ve [session] test için
/// değiştirilebilir; varsayılan sahte giriş ([MockAuthRepository]).
class IAgreeApp extends StatefulWidget {
  const IAgreeApp({
    super.key,
    this.home,
    this.auth,
    this.session,
    this.rooms,
    this.settings,
    this.sharer,
    this.location,
    this.opener,
    this.notifications,
    this.photos,
  });

  final Widget? home;
  final AuthRepository? auth;
  final SessionController? session;
  final RoomsController? rooms;
  final SettingsController? settings;
  final LinkSharer? sharer;
  final LocationService? location;
  final UrlOpener? opener;
  final NotificationService? notifications;
  final PhotoPicker? photos;

  /// Geliştirme kısayolu: `--dart-define=DEMO=home` oturum açık başlar; başka bir değer
  /// verilirse tasarım galerisi (ve demo sayfaları) açılır.
  static const String demo = String.fromEnvironment('DEMO');

  @override
  State<IAgreeApp> createState() => _IAgreeAppState();
}

class _IAgreeAppState extends State<IAgreeApp> {
  late final AuthRepository _auth =
      widget.auth ??
      MockAuthRepository(startSignedIn: IAgreeApp.demo == 'home');
  late final SessionController _session =
      widget.session ?? (SessionController(auth: _auth)..restore());
  late final SettingsController _settings =
      widget.settings ?? (SettingsController()..load());
  late final RoomsController _rooms =
      widget.rooms ?? RoomsController(repository: MockRoomsRepository());

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: _session,
      auth: _auth,
      rooms: _rooms,
      settings: _settings,
      sharer: widget.sharer ?? const SystemLinkSharer(),
      location: widget.location ?? const SystemLocationService(),
      opener: widget.opener ?? const SystemUrlOpener(),
      notifications: widget.notifications ?? const SystemNotificationService(),
      photos: widget.photos ?? const SystemPhotoPicker(),
      child: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: resolveLocale,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _settings.themeMode,
          locale: _settings.locale,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          home:
              widget.home ??
              (IAgreeApp.demo.isNotEmpty && IAgreeApp.demo != 'home'
                  ? const DesignSystemGallery()
                  : const RootGate()),
        ),
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
