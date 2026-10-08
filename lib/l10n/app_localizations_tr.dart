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
  String agreementArcPeople(int positive, int total) {
    return '$positive/$total kişi';
  }

  @override
  String agreementArcSemantics(int percent, int total, int positive) {
    return 'Uyum yüzde $percent. Toplam $total kişi, olumlu $positive.';
  }

  @override
  String agreementArcSemanticsLove(
    int percent,
    int total,
    int positive,
    int love,
  ) {
    return 'Uyum yüzde $percent. Toplam $total kişi, olumlu $positive, çok isteyen $love.';
  }

  @override
  String deckClosing(int minutes) {
    return 'Kapanıyor · $minutes dk';
  }

  @override
  String deckClosingSemantics(int minutes) {
    return 'Kapanıyor, $minutes dakika sonra';
  }

  @override
  String deckRatingSemantics(String rating) {
    return '$rating puan';
  }

  @override
  String get deckPriceLow => 'uygun fiyat';

  @override
  String get deckPriceMid => 'orta fiyat';

  @override
  String get deckPriceHigh => 'yüksek fiyat';

  @override
  String deckDistance(String distance) {
    return '$distance km';
  }

  @override
  String deckDistanceSemantics(String distance) {
    return '$distance kilometre';
  }

  @override
  String deckDurationHM(int hours, int minutes) {
    return '$hours sa $minutes dk';
  }

  @override
  String deckDurationH(int hours) {
    return '$hours sa';
  }

  @override
  String deckDurationM(int minutes) {
    return '$minutes dk';
  }

  @override
  String deckDurationHMSemantics(int hours, int minutes) {
    return '$hours saat $minutes dakika';
  }

  @override
  String deckDurationHSemantics(int hours) {
    return '$hours saat';
  }

  @override
  String deckDurationMSemantics(int minutes) {
    return '$minutes dakika';
  }

  @override
  String deckPhotoSemantics(int index, int total) {
    return 'Fotoğraf $index/$total';
  }

  @override
  String deckPosterSemantics(String name) {
    return '$name afişi';
  }

  @override
  String get deckDetails => 'Ayrıntılar';

  @override
  String get deckDecisionOk => 'Olur';

  @override
  String get deckDecisionPass => 'Pas';

  @override
  String get deckDecisionLove => 'Çok isterim';

  @override
  String get deckDecisionVeto => 'Olmaz';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonClose => 'Kapat';

  @override
  String get offlineBannerMessage =>
      'Bağlantı yok. Değişikliklerin bağlanınca gönderilecek.';
}
