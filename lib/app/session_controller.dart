import 'package:flutter/foundation.dart';

import '../core/data/auth_repository.dart';
import '../core/domain/user_profile.dart';

enum SessionStatus {
  /// Açılışta kayıtlı oturum aranıyor (launch screen ile aynı `canvas`).
  unknown,
  signedOut,
  signedIn,
}

/// Oturum durumu. Kök ekran bunu dinleyerek karşılama ya da ana ekranı seçer.
class SessionController extends ChangeNotifier {
  SessionController({required this.auth});

  final AuthRepository auth;

  SessionStatus _status = SessionStatus.unknown;
  UserProfile? _user;

  SessionStatus get status => _status;
  UserProfile? get user => _user;

  /// Açılışta kayıtlı oturumu yükler.
  Future<void> restore() async {
    _user = await auth.restore();
    _status = _user == null ? SessionStatus.signedOut : SessionStatus.signedIn;
    notifyListeners();
  }

  /// Giriş akışı bitti. Çağıran önce yığını temizlemiş olmalı.
  void completeSignIn(UserProfile user) {
    _user = user;
    _status = SessionStatus.signedIn;
    notifyListeners();
  }

  /// Hesabı siler; sonuç çıkış yapmakla aynıdır (karşılamaya döner).
  Future<void> deleteAccount() async {
    await auth.deleteAccount();
    _user = null;
    _status = SessionStatus.signedOut;
    notifyListeners();
  }

  Future<void> signOut() async {
    await auth.signOut();
    _user = null;
    _status = SessionStatus.signedOut;
    notifyListeners();
  }
}
