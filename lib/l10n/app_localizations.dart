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

  /// Kart üstü etiket: → Olur.
  ///
  /// In tr, this message translates to:
  /// **'Olur'**
  String get deckDecisionOk;

  /// Kart üstü etiket: ← Pas.
  ///
  /// In tr, this message translates to:
  /// **'Pas'**
  String get deckDecisionPass;

  /// Kart üstü etiket: ↑ Çok isterim.
  ///
  /// In tr, this message translates to:
  /// **'Çok isterim'**
  String get deckDecisionLove;

  /// Kart üstü etiket: ↓ Olmaz.
  ///
  /// In tr, this message translates to:
  /// **'Olmaz'**
  String get deckDecisionVeto;

  /// Deste üst barındaki geri düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Odaya dön'**
  String get deckBackSemantics;

  /// Son kartı geri alma düğmesi.
  ///
  /// In tr, this message translates to:
  /// **'Geri al'**
  String get deckUndoSemantics;

  /// Deste ilerlemesi (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'Kart {position}, toplam {total}'**
  String deckProgressSemantics(int position, int total);

  /// Görünür mesafe, 1 km'nin altında.
  ///
  /// In tr, this message translates to:
  /// **'{meters} m'**
  String placeDistanceMeters(int meters);

  /// Mesafenin VoiceOver metni, 1 km'nin altında.
  ///
  /// In tr, this message translates to:
  /// **'{meters} metre'**
  String placeDistanceMetersSemantics(int meters);

  /// Çok isteyen tek kişi.
  ///
  /// In tr, this message translates to:
  /// **'{a} çok istiyor'**
  String resultLovers1(String a);

  /// Çok isteyen iki kişi.
  ///
  /// In tr, this message translates to:
  /// **'{a} ve {b} çok istiyor'**
  String resultLovers2(String a, String b);

  /// Çok isteyen üç kişi.
  ///
  /// In tr, this message translates to:
  /// **'{a}, {b} ve {c} çok istiyor'**
  String resultLovers3(String a, String b, String c);

  /// Çok isteyen dört ya da daha fazla kişi.
  ///
  /// In tr, this message translates to:
  /// **'{a}, {b} ve {count} kişi daha çok istiyor'**
  String resultLoversMore(String a, String b, int count);

  /// Oy almış seçenek (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{name}, {count} oy: {names}'**
  String voteOptionVotes(String name, int count, String names);

  /// Önde olan seçenek (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{name}, önde, {count} oy: {names}'**
  String voteOptionVotesLeading(String name, int count, String names);

  /// Oy almamış seçenek (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'{name}, oy yok'**
  String voteOptionNoVotes(String name);

  /// Kullanıcının kendi oyunu verdiği seçenek (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'Senin oyun.'**
  String get voteOptionMine;

  /// Karar anı başlığı (oybirliği).
  ///
  /// In tr, this message translates to:
  /// **'Hepiniz anlaştınız.'**
  String get decisionUnanimous;

  /// Karar anı başlığı (çoğunluk).
  ///
  /// In tr, this message translates to:
  /// **'Karar verildi.'**
  String get decisionMajority;

  /// Karar anı birincil eylemi.
  ///
  /// In tr, this message translates to:
  /// **'Yol tarifi al'**
  String get decisionDirections;

  /// Karar anı ikincil eylemi.
  ///
  /// In tr, this message translates to:
  /// **'Gruba paylaş'**
  String get decisionShare;

  /// Çoğunluk etiketi.
  ///
  /// In tr, this message translates to:
  /// **'{votes}/{total} oyla seçildi'**
  String decisionVotes(int votes, int total);

  /// Odadaki karar kartının üst etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Karar'**
  String get decisionCardOverline;

  /// Karar kartı (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'Karar: {name}, {time}'**
  String decisionCardSemantics(String name, String time);

  /// Karar anındaki avatar kümesi (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'Katılımcılar: {names}'**
  String decisionParticipants(String names);

  /// E-posta ekranı başlığı.
  ///
  /// In tr, this message translates to:
  /// **'E-posta adresin'**
  String get authEmailTitle;

  /// E-posta ekranı açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Sana 6 haneli bir giriş kodu göndereceğiz. Şifre yok.'**
  String get authEmailSubtitle;

  /// E-posta alanı etiketi.
  ///
  /// In tr, this message translates to:
  /// **'E-posta'**
  String get authEmailLabel;

  /// E-posta ekranı birincil butonu.
  ///
  /// In tr, this message translates to:
  /// **'Kodu gönder'**
  String get authEmailSend;

  /// Geçersiz e-posta hatası.
  ///
  /// In tr, this message translates to:
  /// **'Geçerli bir e-posta adresi gir.'**
  String get authEmailInvalid;

  /// Kod ekranı başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Kodu gir'**
  String get authCodeTitle;

  /// Kod ekranı açıklaması; adres kalın yazılır.
  ///
  /// In tr, this message translates to:
  /// **'Kodu {email} adresine gönderdik.'**
  String authCodeSubtitle(String email);

  /// Kod ekranında e-posta ekranına dönüş.
  ///
  /// In tr, this message translates to:
  /// **'Adresi değiştir'**
  String get authChangeAddress;

  /// Kod ekranı yardım metni.
  ///
  /// In tr, this message translates to:
  /// **'Kod gelmedi mi? Spam klasörüne de bak.'**
  String get authCodeHint;

  /// Geri sayım sürerken pasif yeniden gönder metni.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden gönder · {time}'**
  String authResendIn(String time);

  /// Geri sayım bitince aktif yeniden gönder.
  ///
  /// In tr, this message translates to:
  /// **'Yeniden gönder'**
  String get authResend;

  /// Mail uygulamasını açma butonu.
  ///
  /// In tr, this message translates to:
  /// **'Mail\'i aç'**
  String get authOpenMail;

  /// Yanlış kod hatası.
  ///
  /// In tr, this message translates to:
  /// **'Kod doğru değil. Tekrar dene.'**
  String get authCodeWrong;

  /// Boş kod alanı (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'Kod alanı, {length} hane'**
  String authCodeEmptySemantics(int length);

  /// Kısmen dolu kod alanı (VoiceOver).
  ///
  /// In tr, this message translates to:
  /// **'Kod: {digits}, {remaining} hane kaldı'**
  String authCodeSemantics(String digits, int remaining);

  /// Profil kurulumu başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Son bir adım'**
  String get authProfileTitle;

  /// Profil kurulumu açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Arkadaşların seni odalarda bu isim ve fotoğrafla görecek.'**
  String get authProfileSubtitle;

  /// Profil fotoğrafı ekleme.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf ekle'**
  String get authAddPhoto;

  /// Fotoğrafın isteğe bağlı olduğunu söyler.
  ///
  /// In tr, this message translates to:
  /// **'İsteğe bağlı'**
  String get authOptional;

  /// İsim alanı etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Adın'**
  String get authNameLabel;

  /// Apple'dan gelen isim notu.
  ///
  /// In tr, this message translates to:
  /// **'Apple hesabından geldi. İstersen değiştir.'**
  String get authNameFromApple;

  /// Boş isim hatası.
  ///
  /// In tr, this message translates to:
  /// **'Adını yaz.'**
  String get authNameRequired;

  /// Profil kurulumu birincil butonu.
  ///
  /// In tr, this message translates to:
  /// **'Başla'**
  String get authStart;

  /// Fotoğraf seçici henüz yokken gösterilen bilgi.
  ///
  /// In tr, this message translates to:
  /// **'Fotoğraf seçimi yakında'**
  String get authPhotoSoon;

  /// Mail açma henüz yokken gösterilen bilgi.
  ///
  /// In tr, this message translates to:
  /// **'Mail uygulaması yakında açılacak'**
  String get authMailSoon;

  /// Koşullar/gizlilik bağlantıları hazır olana kadar gösterilen bilgi.
  ///
  /// In tr, this message translates to:
  /// **'Bu sayfa yakında eklenecek'**
  String get welcomeLinkSoon;

  /// Karşılama sahne 1 sloganı.
  ///
  /// In tr, this message translates to:
  /// **'“Nereye gidelim?” sorusunu birlikte, tartışmadan bitirin.'**
  String get welcomeTagline;

  /// Apple ile giriş butonu.
  ///
  /// In tr, this message translates to:
  /// **'Apple ile devam et'**
  String get welcomeApple;

  /// E-posta ile giriş butonu.
  ///
  /// In tr, this message translates to:
  /// **'E-posta ile devam et'**
  String get welcomeEmail;

  /// Koşullar metni; iki bağlantı kalın/renkli yazılır.
  ///
  /// In tr, this message translates to:
  /// **'Devam ederek {terms}’nı ve {privacy}’nı kabul etmiş olursun.'**
  String welcomeTerms(String terms, String privacy);

  /// Koşullar bağlantı metni.
  ///
  /// In tr, this message translates to:
  /// **'Kullanım Koşulları'**
  String get welcomeTermsLabel;

  /// Gizlilik bağlantı metni.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik Politikası'**
  String get welcomePrivacyLabel;

  /// Karşılama sahne 2 başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Nereye gidelim?'**
  String get welcomeSceneTwoTitle;

  /// Karşılama sahne 2 açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Kartları kaydır: Olur, Pas, Çok isterim. Gruptaki uyum anında görünür.'**
  String get welcomeSceneTwoBody;

  /// Karşılama sahne 3 başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Birlikte karar verin.'**
  String get welcomeSceneThreeTitle;

  /// Karşılama sahne 3 açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Oda kur, arkadaşlarını çağır. Herkes seçsin, iAgree ortak noktayı bulsun.'**
  String get welcomeSceneThreeBody;

  /// Geçici ana ekranda çıkış.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get homeSignOut;

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

  /// Henüz yapılmamış ekranlara gidildiğinde gösterilen bilgi.
  ///
  /// In tr, this message translates to:
  /// **'Bu ekran yakında eklenecek'**
  String get comingSoon;

  /// Ana ekran başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Odalarım'**
  String get homeTitle;

  /// Oda oluşturma butonu / ikon etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Oda oluştur'**
  String get homeCreateRoom;

  /// Profil avatarı etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Profil'**
  String get homeProfile;

  /// Kompakt oda listesi başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Diğer odalar'**
  String get homeOtherRooms;

  /// Geçmiş karar karoları başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Geçmiş kararlar'**
  String get homePastDecisions;

  /// Boş durum başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Henüz bir odan yok'**
  String get homeEmptyTitle;

  /// Boş durum açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Bir oda aç, arkadaşlarını çağır, birlikte karar verin. Bir davet aldıysan linke dokunman yeterli.'**
  String get homeEmptyBody;

  /// Yükleme hatası başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Odalar yüklenemedi'**
  String get homeLoadFailedTitle;

  /// Yükleme hatası açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Bağlantını kontrol edip tekrar dene.'**
  String get homeLoadFailedBody;

  /// Yeniden deneme butonu.
  ///
  /// In tr, this message translates to:
  /// **'Tekrar dene'**
  String get homeRetry;

  /// Hero kart etiketi: sonuçlar hazır.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçlar hazır'**
  String get homeHeroResultsLabel;

  /// Hero kart açıklaması: sonuçlar hazır.
  ///
  /// In tr, this message translates to:
  /// **'Herkes seçti. En çok uyuşan {count} mekan hazır, son kararı oylayın.'**
  String homeHeroResultsBody(int count);

  /// Hero kart butonu: oylama.
  ///
  /// In tr, this message translates to:
  /// **'Oy ver'**
  String get homeHeroVote;

  /// Hero kart etiketi: sıra sende.
  ///
  /// In tr, this message translates to:
  /// **'Şimdi senin sıran'**
  String get homeHeroTurnLabel;

  /// Hero kart açıklaması: sıra sende.
  ///
  /// In tr, this message translates to:
  /// **'{ready}/{total} kişi seçimini bitirdi. Sıra sende.'**
  String homeHeroTurnBody(int ready, int total);

  /// Hero kart butonu: seçmeye başla.
  ///
  /// In tr, this message translates to:
  /// **'Seç'**
  String get homeHeroPick;

  /// Hero kart etiketi: başkaları bekleniyor.
  ///
  /// In tr, this message translates to:
  /// **'Bekleniyor'**
  String get homeHeroWaitLabel;

  /// Hero kart açıklaması: bekleme.
  ///
  /// In tr, this message translates to:
  /// **'{ready}/{total} kişi seçti. Herkes bitirince sonuçlar açılır.'**
  String homeHeroWaitBody(int ready, int total);

  /// Hero kart butonu: odayı aç.
  ///
  /// In tr, this message translates to:
  /// **'Odaya git'**
  String get homeHeroOpen;

  /// Hero kart meta satırı.
  ///
  /// In tr, this message translates to:
  /// **'{category} · {when} · {count} kişi'**
  String homeHeroMeta(String category, String when, int count);

  /// Oda satırı meta metni.
  ///
  /// In tr, this message translates to:
  /// **'{category} · {when}'**
  String homeRoomMeta(String category, String when);

  /// Oda satırı durum etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Sıra sende'**
  String get homeTagYourTurn;

  /// Oda satırı durum etiketi.
  ///
  /// In tr, this message translates to:
  /// **'Sonuçlar hazır'**
  String get homeTagResults;

  /// Oda satırı bekleme durumu.
  ///
  /// In tr, this message translates to:
  /// **'{ready}/{total} hazır'**
  String homeReadyCount(int ready, int total);

  /// Hero önizleme uyum yüzdesi.
  ///
  /// In tr, this message translates to:
  /// **'%{percent} uyum'**
  String homeAgreement(int percent);

  /// Oda satırı VoiceOver etiketi.
  ///
  /// In tr, this message translates to:
  /// **'{name}. {meta}. {status}'**
  String homeRoomSemantics(String name, String meta, String status);

  /// Hero önizleme VoiceOver etiketi.
  ///
  /// In tr, this message translates to:
  /// **'{name}, %{percent} uyum'**
  String homePreviewSemantics(String name, int percent);

  /// Profil düzenleme butonu.
  ///
  /// In tr, this message translates to:
  /// **'Düzenle'**
  String get accountEdit;

  /// Profil listesi satırı.
  ///
  /// In tr, this message translates to:
  /// **'Bildirimler'**
  String get accountNotifications;

  /// Profil listesi satırı.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get accountAppearance;

  /// Görünüm seçeneği.
  ///
  /// In tr, this message translates to:
  /// **'Sistem'**
  String get accountThemeSystem;

  /// Görünüm seçeneği.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get accountThemeLight;

  /// Görünüm seçeneği.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get accountThemeDark;

  /// Profil listesi satırı.
  ///
  /// In tr, this message translates to:
  /// **'Gizlilik ve koşullar'**
  String get accountPrivacy;

  /// Profil listesi satırı.
  ///
  /// In tr, this message translates to:
  /// **'Bize yaz'**
  String get accountContact;

  /// Profil listesi satırı.
  ///
  /// In tr, this message translates to:
  /// **'Çıkış yap'**
  String get accountSignOut;

  /// Profil listesi satırı (yıkıcı).
  ///
  /// In tr, this message translates to:
  /// **'Hesabı sil'**
  String get accountDelete;

  /// Hesap silme alert başlığı.
  ///
  /// In tr, this message translates to:
  /// **'Hesabın silinsin mi?'**
  String get accountDeleteTitle;

  /// Hesap silme alert açıklaması.
  ///
  /// In tr, this message translates to:
  /// **'Odaların ve geçmiş kararların kalıcı olarak silinir. Bu işlem geri alınamaz.'**
  String get accountDeleteMessage;

  /// Hesap silme alert onay butonu.
  ///
  /// In tr, this message translates to:
  /// **'Hesabı sil'**
  String get accountDeleteConfirm;

  /// Sürüm etiketi.
  ///
  /// In tr, this message translates to:
  /// **'iAgree {version}'**
  String accountVersion(String version);
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
