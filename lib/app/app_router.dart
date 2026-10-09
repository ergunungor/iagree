import 'package:flutter/cupertino.dart';

import '../core/data/auth_repository.dart';
import '../core/domain/room.dart';
import '../core/domain/user_profile.dart';
import '../features/auth/code_screen.dart';
import '../features/auth/email_screen.dart';
import '../features/account/account_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/rooms/create_details_screen.dart';
import '../features/rooms/create_what_screen.dart';
import '../features/rooms/room_screen.dart';
import 'app_scope.dart';

/// Uygulamanın rotaları. Paketsiz `Navigator`; rota adları ve argümanlar burada tek yerde,
/// ekranlar yalnızca bu sınıfın tipli yardımcılarını çağırır. Deep link geldiğinde (davet
/// linki) bu dosya `go_router` gibi bir çözüme taşınabilir.
///
/// Geçiş türleri (SCREENS.md): hiyerarşi → push; kendi içinde görev (oda oluşturma, karar anı)
/// → tam ekran modal; kısa bağlamsal işlem → sheet; geri alınamaz onay → alert.
abstract final class AppRoutes {
  static const String email = '/auth/email';
  static const String code = '/auth/code';
  static const String profile = '/auth/profile';
  static const String account = '/account';
  static const String createWhat = '/create/what';
  static const String createDetails = '/create/details';
  static const String room = '/room';

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case email:
        return _push(settings, (_) => const EmailScreen());
      case code:
        final email = settings.arguments! as String;
        return _push(settings, (_) => CodeScreen(email: email));
      case profile:
        final pending = settings.arguments! as NeedsProfile;
        return _push(settings, (_) => ProfileSetupScreen(pending: pending));
      case account:
        return _push(settings, (_) => const AccountScreen());
      case createWhat:
        // Kendi içinde görev: tam ekran modal (aşağıdan açılır).
        return CupertinoPageRoute<void>(
          settings: settings,
          fullscreenDialog: true,
          builder: (_) => const CreateWhatScreen(),
        );
      case createDetails:
        final args = settings.arguments! as CreateDetailsArgs;
        return _push(settings, (_) => CreateDetailsScreen(args: args));
      case room:
        final id = settings.arguments! as String;
        return _push(settings, (_) => RoomScreen(roomId: id));
    }
    return null;
  }

  static Route<T> _push<T>(RouteSettings settings, WidgetBuilder builder) =>
      CupertinoPageRoute<T>(settings: settings, builder: builder);

  static void pushEmail(BuildContext context) =>
      Navigator.of(context).pushNamed(email);

  static void pushCode(BuildContext context, {required String email}) =>
      Navigator.of(context).pushNamed(code, arguments: email);

  static void pushProfile(BuildContext context, NeedsProfile pending) =>
      Navigator.of(context).pushNamed(profile, arguments: pending);

  static void pushAccount(BuildContext context) =>
      Navigator.of(context).pushNamed(account);

  static void pushCreateWhat(BuildContext context) =>
      Navigator.of(context).pushNamed(createWhat);

  static void pushCreateDetails(BuildContext context, CreateDetailsArgs args) =>
      Navigator.of(context).pushNamed(createDetails, arguments: args);

  static void pushRoom(BuildContext context, Room target) =>
      Navigator.of(context).pushNamed(room, arguments: target.id);

  /// Oda kuruldu: oda kurma adımları yığından kalkar, oda ekranı Odalarım'ın üstüne açılır
  /// (tek geçişle; geri Odalarım'a döner).
  static void finishCreate(BuildContext context, Room created) =>
      Navigator.of(context).pushNamedAndRemoveUntil(
        room,
        (route) => route.isFirst,
        arguments: created.id,
      );

  /// Giriş akışı bitti: giriş ekranları yığından kalkar, oturum açılır ve kök ekran ana
  /// ekrana geçer.
  static void finishSignIn(BuildContext context, UserProfile user) {
    final session = AppScope.of(context).session;
    Navigator.of(context).popUntil((route) => route.isFirst);
    session.completeSignIn(user);
  }
}
