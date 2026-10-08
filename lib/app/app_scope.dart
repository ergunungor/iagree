import 'package:flutter/widgets.dart';

import '../core/data/auth_repository.dart';
import 'session_controller.dart';

/// Uygulama genelinde paylaşılan bağımlılıklar (paketsiz, `InheritedWidget`). Denetleyiciler
/// `Listenable` olduğundan ekranlar `ListenableBuilder` ile dinler; kapsamın kendisi
/// değişmez.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.session,
    required this.auth,
    required super.child,
  });

  final SessionController session;
  final AuthRepository auth;

  static AppScope of(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope bulunamadı: IAgreeApp altında kullanın.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope old) =>
      old.session != session || old.auth != auth;
}
