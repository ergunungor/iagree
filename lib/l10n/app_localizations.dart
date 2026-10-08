import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// Uygulama adı. Marka adı çevrilmez ve büyük harfe çevrilmez.
  ///
  /// In tr, this message translates to:
  /// **'iAgree'**
  String get appTitle;

  /// Yüklenirken butonun VoiceOver değeri.
  ///
  /// In tr, this message translates to:
  /// **'Yükleniyor'**
  String get commonLoading;

  /// Metin alanındaki temizle ikonunun VoiceOver etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Temizle'**
  String get commonClear;

  /// Vazgeç butonu (arama alanı gibi geri alınabilir işlemler).
  ///
  /// In tr, this message translates to:
  /// **'Vazgeç'**
  String get commonCancel;

  /// Stepper + butonunun VoiceOver etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Artır'**
  String get commonIncrease;

  /// Stepper − butonunun VoiceOver etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Azalt'**
  String get commonDecrease;

  /// Davet edilmiş ama henüz katılmamış katılımcı (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{name}, bekleniyor'**
  String participantInvited(String name);

  /// Katılmış katılımcı (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{name}, katıldı'**
  String participantJoined(String name);

  /// Seçim yapan katılımcı ve ilerlemesi (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{name}, seçiyor, yüzde {percent}'**
  String participantChoosing(String name, int percent);

  /// Seçimini bitiren katılımcı (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{name}, hazır'**
  String participantReady(String name);

  /// AgreementArc altındaki kişi sayısı: olumlu / toplam.
  ///
  /// In tr, this message translates to:
  /// **'{positive}/{total} kişi'**
  String agreementArcPeople(int positive, int total);

  /// AgreementArc VoiceOver cümlesi (çok isteyen yoksa). Sayıya ek getirilmez: Türkçe ünlü uyumu sayıya göre değişir.
  ///
  /// In tr, this message translates to:
  /// **'Uyum yüzde {percent}. Toplam {total} kişi, olumlu {positive}.'**
  String agreementArcSemantics(int percent, int total, int positive);

  /// AgreementArc VoiceOver cümlesi (çok isteyen varsa).
  ///
  /// In tr, this message translates to:
  /// **'Uyum yüzde {percent}. Toplam {total} kişi, olumlu {positive}, çok isteyen {love}.'**
  String agreementArcSemanticsLove(
    int percent,
    int total,
    int positive,
    int love,
  );

  /// Görünür 'Kapanıyor' satırı (istisna).
  ///
  /// In tr, this message translates to:
  /// **'Kapanıyor · {minutes} dk'**
  String deckClosing(int minutes);

  /// 'Kapanıyor' satırının VoiceOver metni.
  ///
  /// In tr, this message translates to:
  /// **'Kapanıyor, {minutes} dakika sonra'**
  String deckClosingSemantics(int minutes);

  /// Puanın VoiceOver metni.
  ///
  /// In tr, this message translates to:
  /// **'{rating} puan'**
  String deckRatingSemantics(String rating);

  /// Fiyat seviyesi 1 (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'uygun fiyat'**
  String get deckPriceLow;

  /// Fiyat seviyesi 2 (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'orta fiyat'**
  String get deckPriceMid;

  /// Fiyat seviyesi 3 (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'yüksek fiyat'**
  String get deckPriceHigh;

  /// Görünür mesafe.
  ///
  /// In tr, this message translates to:
  /// **'{distance} km'**
  String deckDistance(String distance);

  /// Mesafenin VoiceOver metni.
  ///
  /// In tr, this message translates to:
  /// **'{distance} kilometre'**
  String deckDistanceSemantics(String distance);

  /// Süre: saat ve dakika.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa {minutes} dk'**
  String deckDurationHM(int hours, int minutes);

  /// Süre: tam saat.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa'**
  String deckDurationH(int hours);

  /// Süre: yalnızca dakika.
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dk'**
  String deckDurationM(int minutes);

  /// Süre (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{hours} saat {minutes} dakika'**
  String deckDurationHMSemantics(int hours, int minutes);

  /// Süre (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{hours} saat'**
  String deckDurationHSemantics(int hours);

  /// Süre (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{minutes} dakika'**
  String deckDurationMSemantics(int minutes);

  /// Kartın fotoğraf alanı (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf {index}/{total}'**
  String deckPhotoSemantics(int index, int total);

  /// Film afişi (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{name} afişi'**
  String deckPosterSemantics(String name);

  /// Kart bilgi panelinin eylem ipucu.
  ///
  /// In tr, this message translates to:
  /// **'Ayrıntılar'**
  String get deckDetails;

  /// Navigasyon çubuğundaki geri chevron'unun VoiceOver etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Geri'**
  String get commonBack;

  /// Sheet kapatma ✕ ikonunun ve scrim'in VoiceOver etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Kapat'**
  String get commonClose;

  /// Çevrimdışı banner metni (nav bar altında kalıcı).
  ///
  /// In tr, this message translates to:
  /// **'Bağlantı yok. Değişikliklerin bağlanınca gönderilecek.'**
  String get offlineBannerMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
