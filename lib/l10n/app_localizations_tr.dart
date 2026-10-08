// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'iAgree';

  @override
  String get commonLoading => 'Yükleniyor';

  @override
  String get commonClear => 'Temizle';

  @override
  String get commonCancel => 'Vazgeç';

  @override
  String get commonIncrease => 'Artır';

  @override
  String get commonDecrease => 'Azalt';

  @override
  String participantInvited(String name) {
    return '$name, bekleniyor';
  }

  @override
  String participantJoined(String name) {
    return '$name, katıldı';
  }

  @override
  String participantChoosing(String name, int percent) {
    return '$name, seçiyor, yüzde $percent';
  }

  @override
  String participantReady(String name) {
    return '$name, hazır';
  }

  @override
  String get commonClose => 'Kapat';

  @override
  String get offlineBannerMessage =>
      'Bağlantı yok. Değişikliklerin bağlanınca gönderilecek.';
}
