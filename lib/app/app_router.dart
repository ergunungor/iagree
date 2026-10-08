import 'package:flutter/cupertino.dart';

import '../core/data/auth_repository.dart';
import '../core/domain/user_profile.dart';
import '../features/auth/code_screen.dart';
import '../features/auth/email_screen.dart';
import '../features/account/account_screen.dart';
import '../features/auth/profile_setup_screen.dart';
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

  /// Giriş akışı bitti: giriş ekranları yığından kalkar, oturum açılır ve kök ekran ana
  /// ekrana geçer.
  static void finishSignIn(BuildContext context, UserProfile user) {
    final session = AppScope.of(context).session;
    Navigator.of(context).popUntil((route) => route.isFirst);
    session.completeSignIn(user);
  }
}
