import 'package:flutter/widgets.dart';

import '../core/data/auth_repository.dart';
import 'platform_services.dart';
import 'rooms_controller.dart';
import 'session_controller.dart';
import 'settings_controller.dart';

/// Uygulama genelinde paylaşılan bağımlılıklar (paketsiz, `InheritedWidget`). Denetleyiciler
/// `Listenable` olduğundan ekranlar `ListenableBuilder` ile dinler; kapsamın kendisi
/// değişmez.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.session,
    required this.auth,
    required this.rooms,
    required this.settings,
    required this.sharer,
    required this.location,
    required this.opener,
    required this.notifications,
    required super.child,
  });

  final SessionController session;
  final AuthRepository auth;
  final RoomsController rooms;
  final SettingsController settings;
  final LinkSharer sharer;
  final LocationService location;
  final UrlOpener opener;
  final NotificationService notifications;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadı: IAgreeApp altında kullanın.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      old.session != session ||
      old.auth != auth ||
      old.rooms != rooms ||
      old.settings != settings;
}
