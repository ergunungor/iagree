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
  String get deckBackSemantics => 'Odaya dön';

  @override
  String get deckUndoSemantics => 'Geri al';

  @override
  String deckProgressSemantics(int position, int total) {
    return 'Kart $position, toplam $total';
  }

  @override
  String placeDistanceMeters(int meters) {
    return '$meters m';
  }

  @override
  String placeDistanceMetersSemantics(int meters) {
    return '$meters metre';
  }

  @override
  String resultLovers1(String a) {
    return '$a çok istiyor';
  }

  @override
  String resultLovers2(String a, String b) {
    return '$a ve $b çok istiyor';
  }

  @override
  String resultLovers3(String a, String b, String c) {
    return '$a, $b ve $c çok istiyor';
  }

  @override
  String resultLoversMore(String a, String b, int count) {
    return '$a, $b ve $count kişi daha çok istiyor';
  }

  @override
  String voteOptionVotes(String name, int count, String names) {
    return '$name, $count oy: $names';
  }

  @override
  String voteOptionVotesLeading(String name, int count, String names) {
    return '$name, önde, $count oy: $names';
  }

  @override
  String voteOptionNoVotes(String name) {
    return '$name, oy yok';
  }

  @override
  String get voteOptionMine => 'Senin oyun.';

  @override
  String get decisionUnanimous => 'Hepiniz anlaştınız.';

  @override
  String get decisionMajority => 'Karar verildi.';

  @override
  String get decisionDirections => 'Yol tarifi al';

  @override
  String get decisionShare => 'Gruba paylaş';

  @override
  String decisionVotes(int votes, int total) {
    return '$votes/$total oyla seçildi';
  }

  @override
  String get decisionCardOverline => 'Karar';

  @override
  String decisionCardSemantics(String name, String time) {
    return 'Karar: $name, $time';
  }

  @override
  String decisionParticipants(String names) {
    return 'Katılımcılar: $names';
  }

  @override
  String get authEmailTitle => 'E-posta adresin';

  @override
  String get authEmailSubtitle =>
      'Sana 6 haneli bir giriş kodu göndereceğiz. Şifre yok.';

  @override
  String get authEmailLabel => 'E-posta';

  @override
  String get authEmailSend => 'Kodu gönder';

  @override
  String get authEmailInvalid => 'Geçerli bir e-posta adresi gir.';

  @override
  String get authCodeTitle => 'Kodu gir';

  @override
  String authCodeSubtitle(String email) {
    return 'Kodu $email adresine gönderdik.';
  }

  @override
  String get authChangeAddress => 'Adresi değiştir';

  @override
  String get authCodeHint => 'Kod gelmedi mi? Spam klasörüne de bak.';

  @override
  String authResendIn(String time) {
    return 'Yeniden gönder · $time';
  }

  @override
  String get authResend => 'Yeniden gönder';

  @override
  String get authOpenMail => 'Mail\'i aç';

  @override
  String get authCodeWrong => 'Kod doğru değil. Tekrar dene.';

  @override
  String authCodeEmptySemantics(int length) {
    return 'Kod alanı, $length hane';
  }

  @override
  String authCodeSemantics(String digits, int remaining) {
    return 'Kod: $digits, $remaining hane kaldı';
  }

  @override
  String get authProfileTitle => 'Son bir adım';

  @override
  String get authProfileSubtitle =>
      'Arkadaşların seni odalarda bu isim ve fotoğrafla görecek.';

  @override
  String get authAddPhoto => 'Fotoğraf ekle';

  @override
  String get authOptional => 'İsteğe bağlı';

  @override
  String get authNameLabel => 'Adın';

  @override
  String get authNameFromApple => 'Apple hesabından geldi. İstersen değiştir.';

  @override
  String get authNameRequired => 'Adını yaz.';

  @override
  String get authStart => 'Başla';

  @override
  String get welcomeTagline =>
      '“Nereye gidelim?” sorusunu birlikte, tartışmadan bitirin.';

  @override
  String get welcomeApple => 'Apple ile devam et';

  @override
  String get welcomeEmail => 'E-posta ile devam et';

  @override
  String welcomeTerms(String terms, String privacy) {
    return 'Devam ederek $terms’nı ve $privacy’nı kabul etmiş olursun.';
  }

  @override
  String get welcomeTermsLabel => 'Kullanım Koşulları';

  @override
  String get welcomePrivacyLabel => 'Gizlilik Politikası';

  @override
  String get welcomeSceneTwoTitle => 'Nereye gidelim?';

  @override
  String get welcomeSceneTwoBody =>
      'Kartları kaydır: Olur, Pas, Çok isterim. Gruptaki uyum anında görünür.';

  @override
  String get welcomeSceneThreeTitle => 'Birlikte karar verin.';

  @override
  String get welcomeSceneThreeBody =>
      'Oda kur, arkadaşlarını çağır. Herkes seçsin, iAgree ortak noktayı bulsun.';

  @override
  String get commonBack => 'Geri';

  @override
  String get commonClose => 'Kapat';

  @override
  String get offlineBannerMessage =>
      'Bağlantı yok. Değişikliklerin bağlanınca gönderilecek.';

  @override
  String get comingSoon => 'Bu ekran yakında eklenecek';

  @override
  String get homeTitle => 'Odalarım';

  @override
  String get homeCreateRoom => 'Oda oluştur';

  @override
  String get homeProfile => 'Profil';

  @override
  String get homeOtherRooms => 'Diğer odalar';

  @override
  String get homePastDecisions => 'Geçmiş kararlar';

  @override
  String get homeEmptyTitle => 'Henüz bir odan yok';

  @override
  String get homeEmptyBody =>
      'Bir oda aç, arkadaşlarını çağır, birlikte karar verin. Bir davet aldıysan linke dokunman yeterli.';

  @override
  String get homeLoadFailedTitle => 'Odalar yüklenemedi';

  @override
  String get homeLoadFailedBody => 'Bağlantını kontrol edip tekrar dene.';

  @override
  String get homeRetry => 'Tekrar dene';

  @override
  String get homeHeroResultsLabel => 'Sonuçlar hazır';

  @override
  String homeHeroResultsBody(int count) {
    return 'Herkes seçti. En çok uyuşan $count mekan hazır, son kararı oylayın.';
  }

  @override
  String get homeHeroVote => 'Oy ver';

  @override
  String get homeHeroTurnLabel => 'Şimdi senin sıran';

  @override
  String homeHeroTurnBody(int ready, int total) {
    return '$ready/$total kişi seçimini bitirdi. Sıra sende.';
  }

  @override
  String get homeHeroPick => 'Seç';

  @override
  String get homeHeroWaitLabel => 'Bekleniyor';

  @override
  String homeHeroWaitBody(int ready, int total) {
    return '$ready/$total kişi seçti. Herkes bitirince sonuçlar açılır.';
  }

  @override
  String get homeHeroOpen => 'Odaya git';

  @override
  String homeHeroMeta(String category, String when, int count) {
    return '$category · $when · $count kişi';
  }

  @override
  String homeRoomMeta(String category, String when) {
    return '$category · $when';
  }

  @override
  String get homeTagYourTurn => 'Sıra sende';

  @override
  String get homeTagResults => 'Sonuçlar hazır';

  @override
  String homeReadyCount(int ready, int total) {
    return '$ready/$total hazır';
  }

  @override
  String homeAgreement(int percent) {
    return '%$percent uyum';
  }

  @override
  String homeRoomSemantics(String name, String meta, String status) {
    return '$name. $meta. $status';
  }

  @override
  String homePreviewSemantics(String name, int percent) {
    return '$name, %$percent uyum';
  }

  @override
  String get accountEdit => 'Düzenle';

  @override
  String get accountNotifications => 'Bildirimler';

  @override
  String get accountAppearance => 'Görünüm';

  @override
  String get accountThemeSystem => 'Sistem';

  @override
  String get accountThemeLight => 'Açık';

  @override
  String get accountThemeDark => 'Koyu';

  @override
  String get accountPrivacy => 'Gizlilik ve koşullar';

  @override
  String get accountContact => 'Bize yaz';

  @override
  String get accountSignOut => 'Çıkış yap';

  @override
  String get accountDelete => 'Hesabı sil';

  @override
  String get accountDeleteTitle => 'Hesabın silinsin mi?';

  @override
  String get accountDeleteMessage =>
      'Odaların ve geçmiş kararların kalıcı olarak silinir. Bu işlem geri alınamaz.';

  @override
  String get accountDeleteConfirm => 'Hesabı sil';

  @override
  String accountVersion(String version) {
    return 'iAgree $version';
  }

  @override
  String get createWhatTitle => 'Ne yapıyorsunuz?';

  @override
  String get createThemesTitle => 'Bugüne özel';

  @override
  String get createCategoriesTitle => 'Kategoriler';

  @override
  String get createDetailsTitle => 'Nerede, ne zaman?';

  @override
  String get createWhere => 'Nerede';

  @override
  String get createWherePlaceholder => 'Konum seç';

  @override
  String get createWhereSheetTitle => 'Semt seç';

  @override
  String get createDistance => 'Mesafe';

  @override
  String createDistanceKm(int km) {
    return '$km km';
  }

  @override
  String get createWhen => 'Ne zaman';

  @override
  String get createWhenNow => 'Şimdi';

  @override
  String get createWhenTonight => 'Bu akşam';

  @override
  String get createWhenWeekend => 'Hafta sonu';

  @override
  String get createWhenPickDate => 'Tarih seç';

  @override
  String get createDateSheetTitle => 'Tarih seç';

  @override
  String get createDateConfirm => 'Seç';

  @override
  String get createBudget => 'Bütçe';

  @override
  String get createPlatform => 'Hangi platform?';

  @override
  String get createRoomName => 'Oda adı';

  @override
  String createRoomNameDefault(String when, String category) {
    return '$when $category';
  }

  @override
  String get createRoomNameRequired => 'Oda adı gir.';

  @override
  String get createLocationRequired => 'Bir konum seç.';

  @override
  String get createPlatformRequired => 'En az bir platform seç.';

  @override
  String get createSubmit => 'Odayı kur';

  @override
  String createPlaceTag(String place, int km) {
    return '$place · $km km';
  }

  @override
  String get createFailed => 'Oda kurulamadı. Tekrar dene.';

  @override
  String roomMembersSemantics(int count) {
    return 'Odada $count kişi';
  }

  @override
  String get roomOnlyYouSemantics => 'Odada sadece sen varsın';

  @override
  String get roomInviteTitle => 'Arkadaşlarını çağır';

  @override
  String roomMembersTitle(int count) {
    return '$count kişi odada';
  }

  @override
  String get roomLinkCopy => 'Kopyala';

  @override
  String get roomLinkCopied => 'Link kopyalandı';

  @override
  String roomLinkSemantics(String link) {
    return 'Davet linki: $link';
  }

  @override
  String get roomShare => 'Linki paylaş';

  @override
  String get roomPickFirst => 'Önce ben seçeyim';

  @override
  String get roomStartPicking => 'Seçmeye başla';

  @override
  String get roomSettings => 'Oda ayarları';

  @override
  String get roomRename => 'Oda adını değiştir';

  @override
  String get roomRenameSave => 'Kaydet';

  @override
  String get roomDelete => 'Odayı sil';

  @override
  String get roomDeleteTitle => 'Oda silinsin mi?';

  @override
  String get roomDeleteMessage =>
      'Oda ve içindeki seçimler herkes için silinir. Bu işlem geri alınamaz.';

  @override
  String get roomDeleteConfirm => 'Odayı sil';

  @override
  String get createMyLocation => 'Konumum';

  @override
  String get createLocationDenied => 'Konum izni verilmedi. Semt seçebilirsin.';

  @override
  String get deckSubmitFailed => 'Seçimlerin gönderilemedi. Tekrar dene.';

  @override
  String get waitingReady => 'Sen hazırsın';

  @override
  String waitingOthers(int count) {
    return '$count kişi daha seçiyor';
  }

  @override
  String get waitingBack => 'Odaya dön';

  @override
  String get resultsTitle => 'Sonuçlar';

  @override
  String get resultsHeading => 'Hangisi olsun?';

  @override
  String get resultsVote => 'Oyumu ver';

  @override
  String get resultsVoteFailed => 'Oyun gönderilemedi. Tekrar dene.';

  @override
  String resultsWaiting(int count) {
    return '$count kişi daha oy verecek';
  }

  @override
  String get resultsNudge => 'Dürt';

  @override
  String get resultsNudged => 'Hatırlatma gönderildi';

  @override
  String get resultsYou => 'Sen';

  @override
  String decisionShareText(String place, String when) {
    return '$place · $when. iAgree ile karar verdik.';
  }

  @override
  String get waitingNotifyTitle => 'Sonuçlar hazır olunca haber verelim mi?';

  @override
  String get waitingNotifyBody =>
      'Herkes seçimini bitirdiğinde sana bildirim göndeririz.';

  @override
  String get waitingNotifyYes => 'Evet';

  @override
  String get waitingNotifyNo => 'Şimdi değil';

  @override
  String get waitingNotifyOn => 'Bildirimler açıldı';

  @override
  String get linkOpenFailed => 'Bağlantı açılamadı';

  @override
  String get accountTerms => 'Kullanım koşulları';

  @override
  String get accountPrivacyPolicy => 'Gizlilik politikası';

  @override
  String get editTitle => 'Profili düzenle';

  @override
  String get editSave => 'Kaydet';

  @override
  String get editEmailHelper => 'E-posta adresi değiştirilemez.';

  @override
  String get editChangePhoto => 'Fotoğrafı değiştir';

  @override
  String get editRemovePhoto => 'Fotoğrafı kaldır';

  @override
  String get editSaveFailed => 'Kaydedilemedi. Tekrar dene.';

  @override
  String get editDiscardTitle => 'Değişiklikler silinsin mi?';

  @override
  String get editDiscardMessage => 'Kaydetmediğin değişiklikler kaybolacak.';

  @override
  String get editDiscardConfirm => 'Değişiklikleri sil';

  @override
  String get editKeepEditing => 'Düzenlemeye devam';
}
