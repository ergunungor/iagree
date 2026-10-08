import '../domain/user_profile.dart';

/// Kod doğrulama ya da Apple girişinin sonucu.
sealed class AuthOutcome {
  const AuthOutcome();
}

/// Kod yanlış.
class WrongCode extends AuthOutcome {
  const WrongCode();
}

/// Kullanıcı zaten kayıtlı: doğrudan oturum açılır.
class SignedIn extends AuthOutcome {
  const SignedIn(this.user);
  final UserProfile user;
}

/// Yeni kullanıcı: profil kurulumu gerekir.
class NeedsProfile extends AuthOutcome {
  const NeedsProfile({
    required this.email,
    this.suggestedName = '',
    this.fromApple = false,
  });

  final String email;

  /// Apple hesabından gelen isim; boş olabilir.
  final String suggestedName;
  final bool fromApple;
}

/// Kimlik doğrulama sözleşmesi. Backend gelene kadar [MockAuthRepository] kullanılır.
abstract interface class AuthRepository {
  /// Açılışta kayıtlı oturum; yoksa null.
  Future<UserProfile?> restore();

  Future<void> sendCode(String email);

  Future<AuthOutcome> verifyCode(String email, String code);

  Future<AuthOutcome> signInWithApple();

  Future<UserProfile> createProfile({
    required String email,
    required String name,
  });

  Future<void> signOut();
}
