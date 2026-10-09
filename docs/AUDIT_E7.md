# E7 · Ekran denetimi (E3–E6 sonrası)

Kapsam: A2–A5, C1, C2, D1, D2, D4, D6, D7, D8. Yöntem: kod taraması (ham değer, `toUpperCase`, hardcoded metin, doğrudan haptic, Material ripple), l10n eşlik kontrolü, test kapsamı, release derlemesi, simülatörde dark tema gezintisi. Bu raporda kod değişikliği yoktur.

Durum özeti: 925 test geçiyor, `flutter analyze` temiz, `flutter build ios --release --no-codesign` başarılı (20,3 MB).

## 1. Tasarım kuralları

| Kural | Sonuç |
|---|---|
| `toUpperCase`/`toLowerCase` yok | Temiz. Oda adındaki "yemek" gibi küçük harf biçimleri veriden (`inlineLabel`) geliyor. |
| Ham renk yok | Temiz (`Color(0x`, `Colors.*` yok). |
| Doğrudan haptic yok | Temiz, hepsi `AppHaptics`. |
| Material ripple yok | Temiz (`InkWell`, `TextButton` yok). Tek `GestureDetector` karşılamadaki debug uzun basışı. |
| Metinler l10n'de | Temiz. Tek istisna `kDebugMode` içindeki 5 debug metni (yayında ağaçtan kesilir). TR/EN anahtarları birebir eşleşiyor. |
| Ham boşluk/süre | **Kısmen.** Aşağıya bak. |

### Ham değer bulguları

- **52 `static const double`** `lib/features` içinde. Büyük çoğunluğu iki gruptan:
  - Karşılama animasyonunun çizim alanı ve zaman çizelgesi (`welcome_screen.dart`, ~35 sabit): illüstrasyon geometrisi ve ms cinsinden zaman çizelgesi. Bunlar token değil, tasarımın kendisi. Zaman çizelgesi `AppMotion` süreleriyle ilişkili değil. **Öneri:** olduğu gibi bırak, `DESIGN_SYSTEM.md` §17'ye "A2 geometrisi ekrana özel" notu ekle.
  - Mockup'a birebir ölçüler (hero önizleme 64, karo 148×96, kategori kartı min 64, tema kartı 156×124, kopyala butonu 40). Adlandırılmış ve tek yerde. **Öneri:** bırak.
- **`AppSpacing.xxs + 2`, `xs - 2`, `sm + 2`, `sm - 2`** (11 yer). Ölçekte 6 ve 10 yok ama mockup'lar bunları kullanıyor (etiket aralığı 6, kopyala dolgusu 14, satır dolgusu 10). **Karar gerekiyor:** ya `AppSpacing`'e `xxs2 = 6` ve `xs2 = 10` eklenir ya da mockup değerleri 4/8/12'ye yuvarlanır. Önerim ilki, çünkü mockup'larda tutarlı görünüyor.
- **`AppSpacing.xl + AppSpacing.xxs` (28)** 8 yerde (bölüm aralıkları). Mockup 28 kullanıyor. Aynı karar: `sectionGap`'e benzer bir 28 tokenı eklenebilir.
- `Duration(milliseconds: 8500)` karşılama süresi: yukarıdaki istisna.

## 2. Mockup farkları

| Ekran | Fark | Not |
|---|---|---|
| D1 adım 2 | "3 km" değeri slider'ın üstünde sağda; mockup'ta slider ile aynı satırda sağda | `AppSlider` bileşeninin kendi yerleşimi, §17 madde 18 (açık). |
| C2 | "Düzenle" ve "Bildirimler" toast ile geçiyor | Ekranları tasarlanmadı. |
| D2 | Debug butonu mockup'ta yok | Yalnızca debug. |
| D1 | Tema ve kategori listesi sabit (Türkçe) | Gerçek veri sunucudan, dile göre gelecek. İngilizce cihazda "Tonight yemek" gibi karışık görünür; beklenen. |
| A2 | Apple butonu yer tutucu (düz pill) | Gerçek `sign_in_with_apple` bağlanmadı. |

## 3. Erişilebilirlik

Testlerle doğrulanan: tüm ekranlarda başlıklar `header`, liste satırları tek öğe, oda satırı "ad, meta, durum" cümlesi, dokunma alanı 44 pt, 2x yazı ve dark tema için taşma testleri (her ekran için).

**Cihazda doğrulanmadı:**
- VoiceOver gezinme sırası ve okuma metinleri (özellikle deste kartının 4 özel aksiyonu, Bekleme'deki canlı bölge, Sonuçlar'da seçili durum).
- Dynamic Type'ın 2x'in ötesindeki (erişilebilirlik) boyutları.
- Reduce Motion ile karşılama ve karar anı.
- Increase Contrast.
- Haptic hissi (her yerde `AppHaptics` var ama simülatörde duyulmuyor).

## 4. İşlevsel boşluklar (mock'tan gerçeğe)

| Konu | Durum |
|---|---|
| Oturum kalıcılığı | Mock giriş her açılışta çıkış yapıyor. Gerçek giriş gelince Keychain gerekir. |
| Oda verisi kalıcılığı | Bellekte; uygulama kapanınca sıfırlanır. |
| Koşullar/gizlilik, Bize yaz, Mail'i aç | Toast. Adresler (URL, e-posta) lazım; `url_launcher` hazır. |
| Profil fotoğrafı | Toast. `image_picker` paketi ekli, bağlanmadı. |
| Bildirim izni kartı (D6) | Yok. Bildirim paketi kararı bekliyor. |
| Eşitlikte "Son söz sende" (D7) | Yok. |
| D5 detay sheet'i | Tasarım bekliyor; kart dokunuşu işlevsiz. |
| Dürt | Toast. |
| Konum | Yalnızca izin; gerçek semt adı yok. |
| Hesabı sil | Sahte; gerçek veri silme sunucu işi. |

## 5. App Store hazırlığı (yapılandırma)

Kod dışı ama yayını engelleyecek maddeler:

1. **Bundle ID** `com.example.iagree` (yer tutucu). Gerçek kimlik ve Apple Developer ekibi gerekir.
2. **Sign in with Apple** capability'si ve `Runner.entitlements` yok. Xcode'dan sizin eklemeniz gerekiyor.
3. **Yönlendirme:** Info.plist iPhone için yatay yönleri de izin veriyor. Uygulama yalnızca dikey tasarlandı. Yatay yönleri kaldırmayı öneririm (küçük ve güvenli değişiklik).
4. **Gizlilik manifesti:** `PrivacyInfo.xcprivacy` yok. `shared_preferences` (UserDefaults) için gerekçe bildirimi gerekir; çoğu eklenti kendi manifestini getirir ama uygulama düzeyinde bir dosya önerilir.
5. **Hesap silme** akışı (Apple zorunluluğu) arayüzde var; gerçek silme backend ile gelecek.
6. **Konum ve fotoğraf izin metinleri** Türkçe olarak eklendi.
7. **Launch screen ve ikon** testli (`ios_launch_screen_test`, `ios_app_icon_test`).

## 6. Küçük temizlik

- Kullanılmayan l10n anahtarları: `createUseMyLocation`, `homeSignOut`.
- `DESIGN_SYSTEM.md` §17'ye eklenecek notlar: A2 geometrisi, AppStatusTag, kategori ikonları, Home hero kuralı (Secondary yalnızca "bekleniyor"da), `RoomStage.decided`.

## 7. Önerilen sıra

1. Kararlar: 6/10/28 boşluk tokenları, yatay yönün kapatılması.
2. Cihazda VoiceOver + Reduce Motion + gerçek haptic turu (ben yapamıyorum).
3. Bildirim paketi kararı → Bekleme kartı.
4. URL'ler/e-posta → `url_launcher` bağlama; `image_picker` → profil fotoğrafı.
5. Backend başlayınca: kalıcılık, gerçek giriş, davet linki (W1–W7 web akışı için önce tasarım).
