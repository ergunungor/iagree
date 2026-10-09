import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Linki iOS paylaşım sayfasıyla paylaşır. Arayüz ve testler bu arayüze bağlıdır; paket
/// çağrısı yalnızca [SystemLinkSharer]'da.
abstract interface class LinkSharer {
  Future<void> share(String link);
}

class SystemLinkSharer implements LinkSharer {
  const SystemLinkSharer();

  @override
  Future<void> share(String link) async {
    await SharePlus.instance.share(ShareParams(text: link));
  }
}

/// Konum izni sonucu.
enum LocationAccess { granted, denied }

/// Konum izni ve (ileride) mevcut konum. İzin yalnızca kullanıcı "Konumumu kullan"a
/// dokununca istenir (SCREENS D1).
abstract interface class LocationService {
  Future<LocationAccess> request();
}

class SystemLocationService implements LocationService {
  const SystemLocationService();

  @override
  Future<LocationAccess> request() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      final ok =
          permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      return ok ? LocationAccess.granted : LocationAccess.denied;
    } on Object {
      return LocationAccess.denied;
    }
  }
}

/// Dış bağlantıları (Apple Maps, web) açar.
abstract interface class UrlOpener {
  Future<bool> open(Uri uri);
}

class SystemUrlOpener implements UrlOpener {
  const SystemUrlOpener();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}

/// Bildirim izni sonucu.
enum NotificationAccess { granted, denied }

/// Bildirim izni (SCREENS D6). Gerçek uygulama bildirim paketi seçilince bağlanacak;
/// şimdilik [PlaceholderNotificationService] kullanılır.
abstract interface class NotificationService {
  Future<NotificationAccess> request();
}

/// Bildirim paketi henüz seçilmediği için sistem izin penceresi açmaz; her zaman "verildi"
/// döner. Paket eklenince yerini gerçek servis alır.
class PlaceholderNotificationService implements NotificationService {
  const PlaceholderNotificationService();

  @override
  Future<NotificationAccess> request() async => NotificationAccess.granted;
}
