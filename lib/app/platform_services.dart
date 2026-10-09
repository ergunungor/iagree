import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
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

/// Bildirim izni (SCREENS D6).
abstract interface class NotificationService {
  /// Sistem iznini ister (pencere yalnızca ilk seferde çıkar).
  Future<NotificationAccess> request();

  /// Pencere göstermeden mevcut izin durumu.
  Future<NotificationAccess> status();
}

/// iOS bildirim iznini `flutter_local_notifications` ile ister. Sistem penceresi yalnızca
/// ilk istekte çıkar; kullanıcı daha önce cevap verdiyse sonuç doğrudan döner.
class SystemNotificationService implements NotificationService {
  const SystemNotificationService();

  @override
  Future<NotificationAccess> status() async {
    try {
      final ios = FlutterLocalNotificationsPlugin()
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final options = await ios?.checkPermissions();
      return options?.isEnabled == true
          ? NotificationAccess.granted
          : NotificationAccess.denied;
    } on Object {
      return NotificationAccess.denied;
    }
  }

  @override
  Future<NotificationAccess> request() async {
    try {
      final plugin = FlutterLocalNotificationsPlugin();
      await plugin.initialize(
        settings: const InitializationSettings(
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      final ios = plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final ok = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return ok == true
          ? NotificationAccess.granted
          : NotificationAccess.denied;
    } on Object {
      return NotificationAccess.denied;
    }
  }
}

/// Galeriden fotoğraf seçer; seçilen dosyanın yolunu verir, vazgeçilirse null.
abstract interface class PhotoPicker {
  Future<String?> pick();
}

class SystemPhotoPicker implements PhotoPicker {
  const SystemPhotoPicker();

  @override
  Future<String?> pick() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      return file?.path;
    } on Object {
      return null;
    }
  }
}
