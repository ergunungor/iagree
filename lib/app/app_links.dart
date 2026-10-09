/// Dış adresler. Domain alınınca yalnızca burası güncellenir.
///
/// **Yer tutucu:** `iagree.app` henüz satın alınmadı; App Store'a göndermeden önce gerçek
/// sayfalar yayında olmalı (gizlilik politikası zorunlu).
abstract final class AppLinks {
  static const String host = 'iagree.app';

  static final Uri terms = Uri.https(host, '/terms');
  static final Uri privacy = Uri.https(host, '/privacy');

  /// Destek e-postası.
  static const String supportEmail = 'destek@iagree.app';
  static final Uri support = Uri(scheme: 'mailto', path: supportEmail);

  /// iOS Mail uygulamasını açar (kod ekranındaki "Mail'i aç").
  static final Uri mailApp = Uri.parse('message://');

  /// iOS Ayarları'nda uygulamanın sayfası.
  static final Uri appSettings = Uri.parse('app-settings:');

  /// Oda davet linki, şemasız (`iagree.app/r/<kod>`).
  static String invite(String slug) => '$host/r/$slug';
}
