import '../../domain/user_profile.dart';
import '../auth_repository.dart';

/// Bellekte çalışan sahte giriş. Gerçek backend yok:
/// - Her kod kabul edilir; **`000000` yanlış kod** sayılır (hata durumunu denemek için).
/// - [knownEmail] ile giren kullanıcı kayıtlıdır, diğer adresler profil kurulumuna gider.
/// - Apple girişi yeni kullanıcı olarak, Apple'dan gelen isimle profil kurulumuna gider.
class MockAuthRepository implements AuthRepository {
  MockAuthRepository({this.startSignedIn = false});

  static const String wrongCode = '000000';
  static const String knownEmail = 'ayse@ornek.com';

  static const UserProfile known = UserProfile(
    id: 'u-ayse',
    name: 'Ayşe Yılmaz',
    email: knownEmail,
  );

  final bool startSignedIn;
  UserProfile? _user;

  @override
  Future<UserProfile?> restore() async =>
      _user ?? (startSignedIn ? known : null);

  @override
  Future<void> sendCode(String email) async {}

  @override
  Future<AuthOutcome> verifyCode(String email, String code) async {
    if (code == wrongCode) return const WrongCode();
    if (email.trim() == knownEmail) {
      _user = known;
      return const SignedIn(known);
    }
    return NeedsProfile(email: email.trim());
  }

  @override
  Future<AuthOutcome> signInWithApple() async => const NeedsProfile(
    email: 'ayse@privaterelay.appleid.com',
    suggestedName: 'Ayşe Yılmaz',
    fromApple: true,
  );

  @override
  Future<UserProfile> createProfile({
    required String email,
    required String name,
  }) async {
    final user = UserProfile(
      id: 'u-${email.hashCode.abs()}',
      name: name.trim(),
      email: email,
    );
    _user = user;
    return user;
  }

  @override
  Future<void> signOut() async => _user = null;

  @override
  Future<void> deleteAccount() async => _user = null;
}
