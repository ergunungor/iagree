# iAgree Design System — Implementation Spec

Bu dosya iAgree'nin tasarım sisteminin **tek doğru kaynağıdır**. Bütün değerler onaylanmış kararlardır; kod yazarken buradan birebir alınır, yorumlanmaz, "daha iyisi" ile değiştirilmez. Değişiklik gerekiyorsa önce sorulur.

Makine okunur değerler: `docs/design-system/tokens.json`.

---

## 1. Marka

- **Ürün:** Arkadaş gruplarının "nereye gidelim / ne yapalım" kararını birlikte vermesini sağlayan sosyal karar uygulaması. iOS öncelikli Flutter uygulaması.
- **Marka özellikleri:** Warm · Decisive · Social · Effortless.
- **His:** Uygulama açıldığında rahatlama ("bu iş çözülecek"); heyecan yalnızca karar anında.
- **Görsel yön:** Warm Table + Native Calm. Sıcak kırık beyaz zemin, tek vurgu rengi Plum, SF Pro arayüz, Fraunces yalnızca büyük başlıklarda, gölge yerine ton farkı.
- **Logo: iA monogramı.** i'nin gövdesi ile A'nın sol bacağı alttaki köşede birleşip ✓ oluşturur; A'nın yatay çizgisi ✓'ya değmez. Dosyalar `assets/logo/`:
  - `iagree-mark-two-tone.svg`: marka kullanımı (i ve ✓ `brand`, kalanı `textPrimary`); yalnızca `canvas`/`surface` üzerinde.
  - `iagree-mark-ink.svg` / `iagree-mark-cream.svg` / `iagree-mark-plum-light.svg`: tek renk (açık zemin / `brand` veya `momentBg` zemin / koyu tema).
  - Wordmark = işaret + Fraunces 500 "iAgree", ayrı bir dosya değil; kodda yan yana kurulur (işaret yüksekliği ≈ metin boyutunun 1,3 katı).
  - `app-icon-1024.png` (açık) ve `app-icon-dark-1024.png` (iOS koyu ikon): kare, opak, kalın çizgili tek renk.
  - `favicon.svg`: 32 px ve altı, yatay çizgisiz (web).
  - İşaret döndürülmez, eğilmez, gölge/gradient almaz; çevresinde en az işaret yüksekliğinin %25'i boşluk.

## 2. İçerik ve dil kuralları

- Arayüz dili Türkçe, samimi ve kısa.
- Marka adı her zaman **iAgree**. Hiçbir koşulda büyük harfe çevrilmez.
- **`toUpperCase()` ve büyük harfe dönüştürme kullanılmaz** (Türkçe i → I hatası). Gerekirse metin kaynağında büyük yazılır.
- Buton metni fiille başlar, en fazla 3 kelime, cümle düzeni: "Oda oluştur", "Tercihlerimi gönder". Onay butonları işlemi tekrarlar: "Odayı sil" (asla "Tamam").
- Hata metni: ne oldu + ne yapmalı. Hata kodu yok, kullanıcı suçlanmaz.
- Arayüzde emoji yok. "AI", "akıllı öneri", ✨ yok.
- Sayılar Türkçe: `4,6`, `1,2 km`, `%80` (yüzde işareti başta), ondalıksız yüzde. Fiyat seviyesi `₺ / ₺₺ / ₺₺₺`; VoiceOver "uygun / orta / yüksek fiyat" okur.
- Deste yönleri: **Olur / Pas / Çok isterim / Olmaz**.
- Karar anı başlığı: oybirliğinde **"Hepiniz anlaştınız."**, çoğunlukta **"Karar verildi."**

## 3. Renk

### Kurallar

1. Tek vurgu rengi `brand` (Plum). Yalnızca: Primary CTA, seçili durum, focus, link, Çok isterim. Dekorasyon için kullanılmaz.
2. `brand` dolgu üzerindeki metin her zaman `onBrand` (dark'ta koyu metin). Sabit beyaz yazılmaz.
3. Info rengi yok. Bilgilendirme nötr yüzey + ikonla.
4. Durum renkleri (`success`, `warning`, `error`) her zaman ikon veya metinle birlikte; tek başına renk anlam taşımaz.
5. Ekran seviyesindeki hatalar nötr (`textSecondary`). `error` yalnızca alan hataları ve destructive aksiyonlar için.
6. Avatar tintleri yalnızca fotoğrafsız avatar zemininde ve tema kartlarında ("Bugüne özel": Yağmurlu hava, Maç akşamı…).
7. `moment*` ve `inverse*` renkleri iki temada aynıdır (`AppFixedColors`).

### Token tablosu

HEX yazımı `#RRGGBB` veya `#RRGGBBAA`. **Flutter'a çevirirken alfa başa gelir:** `#1c191766` → `Color(0x661C1917)`.

| Token (Dart adı) | Light | Dark | Kullanım |
|---|---|---|---|
| `canvas` (canvas) | `#faf7f2` | `#16131a` | Ekran zemini. Light'ta sıcak kırık beyaz, dark'ta morumsu siyah (pure black değil). |
| `surface` (surface) | `#ffffff` | `#1f1b24` | Kart, liste grubu, deste kartının bilgi paneli. canvas'tan ton farkıyla ayrılır. |
| `surface-raised` (surfaceRaised) | `#ffffff` | `#29242e` | Bottom sheet, alert modal, toast (dark), seçili segment. Dark'ta yüzey merdiveninin en üst basamağı. |
| `surface-muted` (surfaceMuted) | `#f3eee7` | `#2b2630` | Input dolgusu, seçili olmayan chip, Secondary buton, skeleton. |
| `surface-pressed` (surfacePressed) | `#eae3da` | `#37313c` | Nötr yüzeylerin basılı hâli; Agreement Arc izi. |
| `surface-input-focus` (surfaceInputFocus) | `#ffffff` | `#2b2630` | Focus'taki input'un dolgusu (light'ta beyaza döner, dark'ta aynı kalır). |
| `track-off` (trackOff) | `#eae3da` | `#3a3440` | Kapalı toggle'ın track'i. |
| `text-primary` (textPrimary) | `#1c1917` | `#f4eff2` | Başlık ve gövde metni. canvas üzerinde 16.4:1 / 16.2:1; bütün yüzeylerde 13:1 üstü. |
| `text-secondary` (textSecondary) | `#5e5650` | `#b5acb4` | Açıklama, meta bilgi, label. canvas, surface, surface-muted ve brand-soft üzerinde 6:1 üstü (iki temada). |
| `text-tertiary` (textTertiary) | `#6f665f` | `#9d949e` | Placeholder, zaman damgası. surface-muted üzerinde 4.9:1 / 5.0:1. |
| `text-disabled` (textDisabled) | `#b3aaa0` | `#5f5864` | Disabled metin ve ikon. WCAG muaf; tek başına anlam taşımaz. |
| `border` (border) | `#e5ddd3` | `#38323e` | Hairline: liste ayırıcı, dark'ta kart kenarı. Dekoratif. |
| `border-control` (borderControl) | `#8f857a` | `#7d7483` | Checkbox, Check Circle çerçevesi, davet edilmiş katılımcının kesik halkası. canvas/surface-muted üzerinde 3:1 üstü. |
| `brand` (brand) | `#6b2e63` | `#d59ad0` | Plum. Primary CTA, seçili durum, focus, link, Çok isterim. Ekranın %10'unu geçmez. canvas üzerinde 9.0:1 / 8.2:1. |
| `brand-pressed` (brandPressed) | `#58254f` | `#c487be` | Primary CTA basılı. |
| `on-brand` (onBrand) | `#ffffff` | `#16131a` | brand dolgu üzerindeki metin ve ikon (dark'ta koyu metin). 9.6:1 / 8.2:1. |
| `brand-soft` (brandSoft) | `#f4e8f1` | `#3b2338` | Soft selected zemini: seçili chip, Olur etiketi. |
| `on-brand-soft` (onBrandSoft) | `#4e1f48` | `#f2d6ee` | brand-soft üzerindeki metin. 10.9:1 / 10.5:1. |
| `brand-muted` (brandMuted) | `#b07aa8` | `#8a5a85` | Agreement Arc'ta Olur payı. Sadece grafik; metin olarak kullanılmaz. |
| `success` (success) | `#1f7a4d` | `#52c48d` | Açık durumu, onay ikonları. Metin olarak surface ve success-soft üzerinde. |
| `success-soft` (successSoft) | `#e4f2ea` | `#17301f` | Success zemini. |
| `warning` (warning) | `#8a5300` | `#edb24e` | Kapanıyor, çevrimdışı uyarısı. Metin olarak warning-soft üzerinde 5.6:1 / 7.6:1. |
| `warning-soft` (warningSoft) | `#fbf0da` | `#33280f` | Çevrimdışı banner zemini. |
| `error` (error) | `#b42a23` | `#ff7f76` | Alan hatası, destructive, Olmaz. error-soft üzerinde 5.4:1 / 6.3:1. |
| `error-soft` (errorSoft) | `#fbe8e6` | `#3b1b1b` | Destructive buton zemini. |
| `on-error` (onError) | `#ffffff` | `#16131a` | Destructive Strong buton metni. |
| `scrim` (scrim) | `#1c191766` | `#0000008c` | Modal ve sheet arkası (%40 / %55). |
| `inverse-surface` (inverseSurface) | `#29242e` | `#29242e` | Toast zemini. Light'ta ters tema, dark'ta surface-raised ile aynı. |
| `inverse-text` (inverseText) | `#f4eff2` | `#f4eff2` | Toast metni. inverse-surface üzerinde 13.3:1. |
| `inverse-action` (inverseAction) | `#d59ad0` | `#d59ad0` | Toast aksiyonu (Geri al). inverse-surface üzerinde 6.8:1. |
| `inverse-success` (inverseSuccess) | `#52c48d` | `#52c48d` | Toast success ikonu. |
| `inverse-error` (inverseError) | `#ff7f76` | `#ff7f76` | Toast error ikonu. |
| `moment-bg` (momentBg) | `#6b2e63` | `#6b2e63` | Karar anının tam ekran zemini. Uygulamada markanın tüm ekranı kapladığı tek yer. |
| `moment-ink` (momentInk) | `#faf7f2` | `#faf7f2` | Karar anında metin, Arc dolgusu ve birincil buton dolgusu. moment-bg üzerinde 9.0:1. |
| `moment-track` (momentTrack) | `#faf7f233` | `#faf7f233` | Karar anında Arc izi (%20 krem). |
| `moment-ghost` (momentGhost) | `#faf7f226` | `#faf7f226` | Karar anında Secondary buton zemini (%15 krem). |
| `avatar-sand` (avatarSand) | `#eadfd3` | `#3a332c` | Fotoğrafsız avatar zemini (Kum). Sadece avatar. |
| `avatar-sage` (avatarSage) | `#dce3d5` | `#2f362d` | Fotoğrafsız avatar zemini (Adaçayı). Sadece avatar. |
| `avatar-mist` (avatarMist) | `#d9e0e8` | `#2d333b` | Fotoğrafsız avatar zemini (Sis). Sadece avatar. |
| `avatar-rose` (avatarRose) | `#ebdce0` | `#3a2e32` | Fotoğrafsız avatar zemini (Gül). Sadece avatar. |
| `avatar-lavender` (avatarLavender) | `#e3dcea` | `#342e3d` | Fotoğrafsız avatar zemini (Lavanta). Sadece avatar. |
| `focus-ring` (focusRing) | `{brand}` | `{brand}` | Klavye/Switch Control odağı: 2px canvas boşluk + 2px brand halka. |

Bütün metin/zemin çiftleri iki temada WCAG AA (4.5:1) üstünde doğrulandı; `borderControl` 3:1 üstünde.

## 4. Tipografi

- **UI: SF Pro.** iOS'ta `fontFamily` boş bırakılır (sistem fontu). Letter spacing elle verilir (logical px).
- **Display: Fraunces**, variable TTF **asset olarak gömülü** (`google_fonts` ile indirilmez). `fontVariations: [FontVariation('SOFT', 50), FontVariation('WONK', 0), FontVariation('wght', 500)]`.
- **Fraunces yalnızca `display` ve `h1`.** Buton, liste, form, navigation bar'da serif yok.

| Stil | Font | Boyut / Satır | Ağırlık | Letter spacing | Kullanım |
|---|---|---|---|---|---|
| `display` | Fraunces | 40 / 44 | 500 | -0.6 | Karar anı, onboarding |
| `h1` | Fraunces | 32 / 38 | 500 | -0.3 | Oda adı, large title |
| `h2` | SF Pro | 24 / 30 | 700 | +0.07 | Ekran içi section başlığı |
| `h3` | SF Pro | 20 / 25 | 600 | +0.38 | Kart/sheet/empty state başlığı |
| `title` | SF Pro | 17 / 22 | 600 | -0.41 | Liste başlığı, mekan adı, inline nav başlığı |
| `body` | SF Pro | 17 / 24 | 400 | -0.41 | Ana metin |
| `bodySmall` | SF Pro | 15 / 20 | 400 | -0.24 | İkincil açıklama, gerekçe satırı |
| `label` | SF Pro | 15 / 20 | 500 | -0.24 | Chip, form label, segmented |
| `button` | SF Pro | 17 / 22 | 600 | -0.41 | Large/Medium buton (Small: 15/20 600) |
| `caption` | SF Pro | 13 / 18 | 400 | -0.08 | Meta: puan, mesafe, fiyat, zaman |
| `overline` | SF Pro | 12 / 16 | 600 | +0.5 | Seyrek; büyük harfe çevrilmez, `textSecondary` |

- Flutter'da satır yüksekliği `height = lineHeight / fontSize` (örn. body: 24/17).
- Puan, fiyat, mesafe, yüzde: `FontFeature.tabularFigures()`.
- **Dynamic Type:** bütün stiller `MediaQuery.textScaler` ile ölçeklenir. `display` ve `h1` en fazla **1.3x**, AgreementArc içindeki sayı en fazla **1.5x** (`TextScaler.clamp`). Component yükseklikleri **minimum** değerdir (`ConstrainedBox(minHeight)`), metinle büyür.

## 5. Spacing ve layout

4pt sistemi. Yalnızca bu değerler kullanılır:

| Token | px | Kullanım |
|---|---|---|
| `xxs` | 4 | Başlık + alt metin |
| `xs` | 8 | İkon ↔ metin, chip'ler arası, label → input |
| `sm` | 12 | Liste satırı dikey padding, section başlığı → içerik |
| `md` | 16 | Kart iç padding, input yatay padding |
| `lg` | 20 | Ekran yatay padding |
| `xl` | 24 | Sheet/modal padding, Large buton yatay padding |
| `xxl` | 32 | Section arası |
| `xxxl` | 40 | Büyük bloklar arası |
| `huge` | 48 | Empty state üst boşluğu |
| `giant` | 64 | Onboarding / karar anı |

Semantik: `screenPadding = 20`, `sectionGap = 32`, `cardPadding = 16`, `touchTarget = 44`.

- Tek kolon. Birincil aksiyon **alttaki sabit CTA bölgesinde** (yanlar 20, üst 12, alt safe area + 8). Floating Action Button yok.
- Minimum dokunma alanı 44×44; yan yana alanlar arası en az 8.
- **Kart yalnızca tek başına dokunulabilir bir nesnedir.** Metin gruplamak için section başlığı + 32 boşluk.

## 6. Radius

| Token | px | Kullanım |
|---|---|---|
| `xs` | 6 | Checkbox, badge |
| `sm` | 10 | Mekan thumbnail, seçili segment |
| `md` | 14 | Input, search, segmented dış kap |
| `lg` | 20 | Kart, liste grubu, alert |
| `xl` | 28 | Bottom sheet üst köşeleri, deste kartı |
| `pill` | 999 | **Bütün butonlar**, chip, toast |

- Köşeler `RoundedSuperellipseBorder` ile (iOS continuous corner; Flutter ≥ 3.32). Ekran kodunda `BorderRadius.circular()` yazılmaz.
- İç içe radius: iç radius = dış radius − padding.

## 7. Elevation

Sıra: ton farkı → hairline → gölge. Spread her zaman 0, gölge rengi `#1C1917`.

| Seviye | Light | Dark | Kullanım |
|---|---|---|---|
| E0 | yok | yok | Liste, section |
| E1 | `0 1 3 #1C1917@5%` + `0 4 12 @4%` | gölge yok, 1px `border` kenar | Kart |
| E2 | `0 8 24 @8%` + `0 2 6 @4%` | `0 8 24 #000@40%` | Toast, sürüklenen kart, scroll'daki CTA bölgesi |
| E3 | `0 -4 32 @10%` + scrim | `0 -4 32 #000@45%` + scrim | Sheet, modal |

Blur yalnızca navigation bar'da (sigma ≈ 20). Başka yerde glassmorphism yok.

## 8. İkonlar

- **Phosphor Icons** (`phosphor_flutter`). Varsayılan Regular, seçili/aktif Fill. SF Symbols kullanılmaz.
- Boyutlar: 14 (caption içi), 16 (small buton, chip ✓), 20 (buton, search, liste), 24 (nav bar), 32 (empty/error).
- İkon rengi yanındaki metni miras alır; `brand` ikon yalnızca seçili/aktif durumda. Satırda en fazla bir ikon.
- Ekranlar Phosphor'u doğrudan import etmez; `AppIcons` üzerinden kullanır.

## 9. Ortak state modeli

| State | Kural |
|---|---|
| Pressed | Dolgulu: dolgu bir ton koyulaşır (`brandPressed`, `surfacePressed`) + 0.97 scale. Dolgusuz: içerik %50 opaklık |
| Disabled | Opacity yok. Dolgu `surfaceMuted`, içerik `textDisabled` |
| Selected | Soft: `brandSoft` + `onBrandSoft` + 1.5px `brand` kenar. Strong: `brand` + `onBrand` |
| Focus | Input'ta 1.5px `brand` iç kenar |
| Loading | İçerik yerine spinner, genişlik sabit |
| Renkten bağımsızlık | Seçim ✓, hata ⚠ + metin ile |

**CTA politikası:** Primary CTA mümkün olduğunca aktif kalır; eksik alanla basılınca eksik alan işaretlenir + error haptic. Disabled CTA yalnızca kural ekranda açıkça yazılıysa.

## 10. Component'ler

### Button (`AppButton`)
- Tek sınıf + `variant` enum + named constructor'lar (`AppButton.primary(...)`). Ayrı PrimaryButton/SecondaryButton sınıfları yok.
- Boyut: Large 52 (tam genişlik CTA), Medium 44, Small 32 (dokunma alanı 44). Yatay padding 24 / 20 / 12. İkon 20 / 20 / 16, solda, 8 boşluk. Hepsi `pill`.
- Varyantlar: primary (`brand`/`onBrand`), secondary (`surfaceMuted`/`textPrimary`), tertiary (dolgusuz, `brand` metin), destructive (`errorSoft`/`error`), destructiveStrong (`error`/`onError`, sadece alert modal), moment (`momentInk`/`momentBg`), momentGhost (`momentGhost`/`momentInk`), momentText.
- Ekran başına tek Primary. İki aksiyon dikey dizilir: Primary üstte, Tertiary altta.

### IconButton (`AppIconButton`)
- `semanticLabel` zorunlu. Plain (44, nav bar, ikon 24), Soft (36 daire `surfaceMuted`, alan 44), Media (36 daire siyah %35 + beyaz ikon, fotoğraf üstü).

### TextField (`AppTextField`)
- Label üstte (`label`, `textSecondary`), 8 boşluk. Floating label yok.
- 52 min yükseklik, `radius md`, yatay padding 16, dolgu `surfaceMuted`, varsayılan kenarlık yok.
- Focused: dolgu `surfaceInputFocus` + 1.5px `brand`; doluysa sağda temizle ikonu. Error: 1.5px `error` + altta ⚠ + `error` metin (`caption`). Disabled: `textDisabled`.

### SearchField / SelectionField
- Search: 44 yükseklik, `radius md`, solda 20 büyüteç (`textTertiary`); focus'ta sağda Tertiary "Vazgeç".
- SelectionField: TextField görünümü + sağda yukarı-aşağı chevron; dokununca **bottom sheet** (dropdown yok).

### Stepper / Slider
- Stepper: `[−] değer [+]`, Soft icon button'lar, değer `title` + tabular; basılı tutunca hızlanır, her adımda selection haptic.
- Slider: iz 4px `surfaceMuted`, dolu kısım `brand`, 28 beyaz thumb (E1), değer üstte `title`; snap değerleri (örn. 1, 3, 5, 10 km), serbest değer yok.

### Selection
- **Radio yok:** tekli seçim listede sağda `brand` ✓.
- Checkbox (22, `radius xs`, 1.5px `borderControl`; seçili `brand` + `onBrand` ✓) yalnızca onay metinlerinde.
- Check Circle (24) listede çoklu seçim.
- Toggle: `CupertinoSwitch`, açık `brand`, kapalı `trackOff`.
- Segmented: kap `surfaceMuted` `radius md` padding 4; seçili segment `surfaceRaised` + E1, `radius sm`, 600 ağırlık. En fazla 4 segment.
- **Chip:** 36 min, `pill`, yatay 16, `label` stili, aralarında 8, wrap. Selected: `brandSoft` + `onBrandSoft` + 1.5px `brand` + solda 16 ✓ (genişlik değişimi springSnappy).

### Card (`AppCard`) ve ListGroup
- Card: `surface`, `radius lg`, padding 16, E1. Interactive: basınca 0.97 + `textPrimary` %4 overlay. Media: üstte 4:3 görsel. Selected: 2px `brand` kenar (boyut değişmez).
- ListGroup (iOS inset grouped): `surface`, `radius lg`, E0, satır min 52, dikey padding 12. Ayırıcı metnin başladığı yerden başlar.

### Avatar
- **İnsanlar daire, mekanlar `radius sm` kare.**
- Boyutlar: xs 20, sm 28, md 40, lg 56, xl 88.
- Fotoğrafsız: baş harfler (600) + 5 tintten biri; tint `userId`'den deterministik.
- Grup: %30 üst üste, 2px `canvas` halka, en fazla 4 + "+N" sayaç (`surfaceMuted` pill); oda sahibi ilk.
- Online noktası kullanılmaz.

### ParticipantRing
Avatar etrafında tek halka (2pt kalınlık, avatardan 2pt boşluk):

| Durum | Görünüm |
|---|---|
| invited | Kesik çizgi `borderControl`, avatar yerine boş daire, "Bekleniyor" |
| joined | Halka yok |
| choosing(progress) | `brand` yay, ilerlemeye göre dolar (canlı) |
| ready | Tam `brand` halka + sağ altta 18 ✓ rozeti (`brand`/`onBrand`, 2px `canvas` halka) |

VoiceOver: "Can, seçiyor, yüzde 60". ParticipantStrip: md halkalar + "1/4 hazır" (`caption`); dokununca katılımcılar sheet'i.

### InviteBlock ve Dürt
- Boş yerler kesik çizgili avatar daireleri. Primary "Linki paylaş" (iOS share sheet), Secondary "Kopyala" (~1 sn ✓ "Kopyalandı").
- Davet karşılama: davet edenin lg avatarı + "Ayşe seni *Cuma akşamı* odasına çağırdı".
- **Dürt:** katılımcılar listesinde seçimini bitirmemiş kişinin satırında Tertiary Small "Dürt". Odadaki herkes dürtebilir; aynı kişi en fazla 30 dakikada bir. Gönderince "Dürtüldü ✓" (`textTertiary`), light haptic.

### SwipeDeck (imza component)
- Kartlarda **yalnızca somut mekan/aktivite**. Bütçe, mesafe, zaman desteden önce ~10 sn'lik adımda Chip/Segmented/Slider ile. Deste 10–15 kart.
- Kart: genişlik ekran − 40, oran 3:4, `radius xl`, E2. Görsel üst ~%78 (metin görsele yazılmaz; en fazla 4 fotoğraf, kenarlara **dokunarak** geçiş, üstte segment göstergesi). Bilgi paneli **iki satır**: `h3` isim + `caption` meta (★ puan · kategori · fiyat · mesafe, en fazla 4 öğe). Gerekçe satırı ve "Açık" bilgisi destede gösterilmez (çerçeveyi oda sahibi belirlediği için bütün kartlar zaten uyuyor); yalnızca istisna durumunda `warning` ile "Kapanıyor · 45 dk". Panele dokununca detay sheet'i (açıkken kaydırma kapalı).
- **Kart varyantları kategoriye göre:** mekan (fotoğraf, mesafe); film/dizi (2:3 afiş `surfaceMuted` zemin üzerinde ortalı; meta: puan · tür · süre; sağda platform etiketi; mesafe yok). Afişler lisanslı kaynaktan (örn. TMDB) ve atıf kurallarıyla.
- Arkada tek kart: 0.95 ölçek, 8 aşağıda.

| Yön | Etiket | Kart üstü geri bildirim | Karar kuralı |
|---|---|---|---|
| → | Olur | `brandSoft` etiket + ✓ | %30 genişlik **veya** > 800 pt/s |
| ← | Pas | nötr etiket + ✕ | %30 genişlik **veya** > 800 pt/s |
| ↑ | Çok isterim | `brand` etiket + ♥ (Fill) | %25 yükseklik **veya** > 800 pt/s |
| ↓ | Olmaz | `surface` etiket, 1.5px `error` kenar, ⊘, üstü çizili | **Sadece** %35 mesafe (hız tek başına sayılmaz) |

- Fizik: yatayda 1:1 takip, dönme = (dx / genişlik) × 12°, en fazla ±12°, eksen alt orta. Yukarı 1:1, dönme yok. Aşağı parmağın **0.55**'i (direnç). İlk 12pt'den sonra eksen kilidi. Etiket opaklığı eşiğe kadar 0→1; renk tonu overlay'i eşikte en fazla %20. Eşik geçilince selection haptic (her girişte bir kez).
- Bırakma: kart bırakıldığı hızla (min 1000 pt/s) ~250 ms'de ekran dışına (`exit`); aynı anda arka kart 0.95→1 (springStandard). Eşik geçilmediyse springStandard ile merkeze döner.
- Ekranın alt 20pt'inde başlayan dokunuş deste hareketi sayılmaz. Deste ekranı **push** ile tam ekran açılır, sheet içinde asla.
- Üst bar: geri (odaya) + 4px progress + "8/15" (`caption`, tabular) + geri al **ikonu** (son kart, çıktığı yönden springStandard ile döner).
- Alt butonlar soldan sağa: **Pas 56 · Olmaz 44 · Çok isterim 44 · Olur 56**. Pas/Olmaz/Çok isterim `surface` + E1 (ikon `textSecondary` / `error` / `brand`); Olur `brand` dolgu + `onBrand`. Butona basınca kart ilgili yöne uçar (`emphasis`, `exit`).
- İlk kart öğretici: dört yön gösterilir, kart 24pt sağa-sola 2 döngü kıpırdar (toplam 1.2 sn), tek sefer.
- VoiceOver: kartta 4 custom action. Reduce Motion: kart uçmak yerine solar.

### AgreementArc
- 180° yay, yuvarlak uçlar. **Parametre olarak sayılar alır** (`loveCount`, `okCount`, `total`), yüzdeyi kendisi hesaplar.
- **Yüzde = (Olur + Çok isterim) / toplam kişi.** Ağırlıklı skor yok. `%100` yalnızca gerçekten herkes olumluysa (yukarı yuvarlama yok).
- Soldan sağa: `brand` (Çok isterim), 2pt boşluk, `brandMuted` (Olur); kalan iz `surfacePressed`. Veto edilen seçenek sonuçlarda hiç yer almaz.
- Altında her zaman kişi sayısı: "4/5 kişi". Yüzde "%80" biçiminde, tabular.

| Boyut | Genişlik | Çizgi | Yüzde | Kullanım |
|---|---|---|---|---|
| S | 32 | 4 | yayın sağında, `caption` 600 | Compact satır, VoteOption |
| M | 64 | 6 | yay içinde, `title` | Hero sonuç kartı |
| L | 160 | 14 | yay içinde, 34 bold | Karar anı (`momentInk` dolgu, `momentTrack` iz, tek ton) |

- İlk görünüşte 100 ms gecikmeyle `expressive` + `enter` ile dolar, sayı eşzamanlı sayar. Reduce Motion: doğrudan son değer. İbre/tick/ölçek yok.
- VoiceOver: "Uyum yüzde 80. 5 kişiden 4'ü olur dedi, 2'si çok istiyor."

### ResultCard
- Sonuçlarda **en fazla 3 seçenek**. 1. sıra Hero, 2–3 Compact.
- Hero: Media Card (16:10), `h3` isim, `caption` meta, açık durumu, sağda Arc M, gerekçe satırı (en fazla 2 öğe, " · " ile, veriden gelmiyorsa gösterilmez), sevenlerin xs avatarları ("Ayşe ve Can çok istiyor").
- Compact: ListGroup satırı, 56 thumbnail (`radius sm`), `title`, `caption`, sağda Arc S.

### VoteOption
- Oybirliği yoksa en iyi 3 arasında tek seçimli final oylaması; solda Check Circle.
- **Oy verene kadar sonuçlar gizli.** Sonra her seçenekte oy verenlerin avatarları + sayı; önde olan 2px `brand`. Eşitlikte oda sahibine "Son söz sende".

### DecisionMoment
- Uygulamadaki tek tam ekran başarı anı. Zemin `momentBg`, metin/Arc `momentInk`, iki temada aynı.
- İçerik: avatar kümesi (lg, 3px `momentBg` halka, üst üste) → Arc L → başlık `display` → mekan kartı (`surface`, `radius lg`, E2, 56 thumbnail + `title` + `caption`) → aksiyonlar: "Yol tarifi al" (moment, Apple Maps), "Gruba paylaş" (momentGhost), "Kapat" (momentText).
- Normal `brand` buton bu zeminde kullanılmaz.

| Adım (oybirliği) | Zaman | Easing |
|---|---|---|
| Zemin Plum'a geçer | 0–200 ms | move |
| Avatarlar kenarlardan merkeze | 200–800 ms | springBouncy |
| Temas: halka dalgası + **medium haptic** | ~800 ms | enter, 400 ms'de solar |
| Arc %100'e dolar → **success haptic** | 800–1400 ms | expressive, enter |
| Başlık 8pt yukarı kayarak belirir | ~1400 ms | emphasis |
| Mekan kartı alttan yükselir | 1500–1800 ms | springStandard |
| Aksiyonlar aktif | ≤ 2000 ms | — |

- Dokununca animasyon atlanır. Çoğunluk: "Karar verildi.", avatarlar baştan merkezde, halka dalgası yok, Arc gerçek oranına, yalnızca light haptic. Konfeti/rozet yok. Reduce Motion: crossfade.
- Kapanınca odanın üstüne **DecisionCard**: 56 thumbnail, "Karar" overline, `title`, saat; 2px `brand` kenar.

### Navigation
- **MVP'de tab bar yok.** Ana ekran "Odalarım", profil sağ üstte avatar. Tab bar ancak 3+ sekmede (49 + safe area, ikon 24, etiket 11/500, seçili `brand` + Fill).
- Nav bar: `CupertinoSliverNavigationBar`; large title `h1` (Fraunces), scroll'da inline `title`; içerik altından geçince blur + hairline. Geri: yalnızca chevron. Sağda en fazla 2 icon button.
- Akış ilerlemesi: bar altında 4px progress; "Adım 2/4" yazılmaz.
- Sunum: hiyerarşi → push; kendi içinde görev (oda oluşturma) → full-screen modal (sol üstte ✕); kısa bağlamsal işlem → bottom sheet; geri alınamaz onay → alert; SwipeDeck → push.

### Bottom Sheet (`AppSheet.show`)
- `surfaceRaised`, üst köşeler `radius xl`, E3 + scrim, grabber 36×5 (`textTertiary` %30, üstten 8), yanlar 24, başlık `h3` sola hizalı, CTA altta sabit.
- Detent: fit, Medium (~%50), Large (en fazla iki). Kapatma: aşağı kaydırma veya scrim; ✕ yalnızca Large'da.
- Üst üste en fazla bir sheet. İki adımdan uzun akış sheet'te yaşamaz.

### Alert (`AppAlert.show`)
- Yalnızca geri alınamaz işlemler. Genişlik ekran − 48 (max 340), `surfaceRaised`, `radius lg`, padding 24, ortalı `h3` + en fazla 2 cümle `bodySmall`. Butonlar dikey: aksiyon üstte, Tertiary "Vazgeç" altta.
- **Geri alınabilir işlemlerde modal açılmaz:** işlem yapılır + "Geri al" toast'ı.

### Toast (`AppToast`)
- Ekranın **üstünde**, safe area + 8. `pill`, `inverseSurface` + `inverseText`, E2, min 44, yatay 16.
- Solda 20 ikon (nötr / `inverseSuccess` ✓ / `inverseError` ⚠), metin `bodySmall` en fazla 2 satır, isteğe bağlı aksiyon (`inverseAction`).
- Süre 3 sn, aksiyonlu 5 sn, VoiceOver açıkken aksiyonlu 10 sn. Yukarı kaydırarak kapanır. Aynı anda tek toast. Warning toast yok.
- Çevrimdışı: nav bar altında kalıcı banner, `warningSoft` + `warning`, "Bağlantı yok. Değişikliklerin bağlanınca gönderilecek."

### States
- **Empty:** stok illüstrasyon yok. Yapısal görsel (kesik çizgili avatarlar) → `h3` → 1–2 satır `bodySmall` → tek buton. Dikey ~%40.
- **Error (ekran):** aynı yapı, nötr 32 ikon. Alan hatası inline, component hatası kart içinde "Tekrar dene", geçici hata toast.
- **Loading:** < 300 ms hiçbir şey; 300 ms–1 sn inline spinner (`CupertinoActivityIndicator`); içerik için skeleton (`surfaceMuted`, opaklık 1→0.6 nabız, shimmer yok, en fazla 3 satır); > 2 sn açıklayıcı metin ("Tercihler birleştiriliyor…", avatarlar sırayla 1.06 nabız). **Yapay bekleme yok.**
- **Success:** rutin işlem mikro (buton ~1 sn ✓ veya toast); akış sonunda ayrı başarı ekranı yok; tam ekran başarı yalnızca DecisionMoment.

## 10b. Oda kurma ve kategoriler

- Çerçeveyi (kategori/tema, konum + mesafe, zaman, bütçe) **odayı kuran** belirler. Katılımcılar doğrudan desteye girer (uygulama ve web).
- "Ne yapıyorsunuz?" ekranı iki eksen: **Bugüne özel** temalar (yatay kaydırılan tint'li kartlar, bağlama duyarlı) + **Kategoriler** (2 sütun ızgara, sonda "Fark etmez"). Seçim yapılınca doğrudan sonraki adım.
- Detaylar adımı kategoriye göre değişir (film/dizi: konum yerine platform).
- Yeni kurulan odada alt Primary "Linki paylaş"; ilk katılımcı gelince "Seçmeye başla" olur.
- Liste satırlarında tek satır metin hedeflenir; durum mümkünse görsel öğeyle anlatılır.

## 10c. Karar anı varyantları

- Oybirliği → tam ekran `momentBg` karar anı ("Hepiniz anlaştınız.").
- Oylama ile çoğunluk → `canvas` zeminli, kazanan mekanın fotoğrafı üstte, "Karar verildi."; Primary `brand`. Tam ekran Plum yalnızca oybirliğine aittir.
- Oy verildikten sonra sonuç ekranında uyum yayları yerini oy veren avatarlarına ve oy sayısına bırakır.
- Deste ekranında kart, üst bar ile butonlar arasında dikey ortalanır; butonlar altta kalır.

## 11. Sosyal ilke

- Bireysel seçimler karar verilene kadar görünmez; kaydırma sırasında yalnızca ilerleme.
- Sonuçta olumlu tepkiler isimle gösterilebilir. **Pas ve veto hiçbir zaman isimle gösterilmez.**
- Final oylamasında sonuçlar kullanıcı oy verene kadar gizli.

## 12. Motion

- Süreler: `fast` 120 ms, `standard` 200 ms, `emphasis` 300 ms, `expressive` 600 ms (yalnızca Arc ve karar anı). Çıkışlar girişten %25 kısa.
- Eğriler: `enter` = `Cubic(0.16, 1, 0.3, 1)`, `exit` = `Cubic(0.4, 0, 1, 1)`, `move` = `Cubic(0.65, 0, 0.35, 1)`.
- Spring'ler (`SpringDescription.withDampingRatio`, mass 1):

| Ad | Damping ratio | Response | Stiffness | Kullanım |
|---|---|---|---|---|
| snappy | 0.9 | 0.30 s | 439 | Basma dönüşü, chip genişliği |
| standard | 0.85 | 0.45 s | 195 | Sheet, kart dönüşü, toast |
| bouncy | 0.7 | 0.50 s | 158 | Yalnızca tamamlanma: ring ✓, karar anı |

- Push/modal geçişleri native Cupertino. Liste girişi: 8pt aşağıdan fade (`emphasis`), öğeler arası 30 ms, en fazla 6 öğe, yalnızca ilk yükleme. Toast: üstten 16pt (springStandard). Alert: 1.05→1 + fade (`standard`).
- Reduce Motion (`MediaQuery.disableAnimationsOf`): süreler 0, spring'ler overshoot'suz `move`, kart solar, karar anı crossfade, Arc doğrudan son değer, skeleton nabzı yok.

## 13. Haptics

Yalnızca kullanıcının kendi eylemi veya karar anı. Başkasının "hazır" olması, ekran açılışı, ağ hatası için titreşim yok.

| Olay | Haptic |
|---|---|
| Chip, segmented, stepper adımı, deste eşiği | selection |
| Olur, Pas, Geri al, Dürt, toggle | light |
| Çok isterim | medium |
| Olmaz | rigid |
| Desteyi bitirip gönderme | success (notification) |
| Eksik alanla CTA | error (notification) |
| Karar anı oybirliği | temas: medium, Arc %100: success |
| Karar anı çoğunluk | Arc dolunca light |

Flutter `HapticFeedback` rigid ve notification tiplerini içermez → küçük native iOS kanalı (UIImpactFeedbackGenerator `.rigid`, UINotificationFeedbackGenerator). Ekranlar yalnızca `AppHaptics`'i çağırır.

## 14. Accessibility

- Dynamic Type (bkz. Tipografi), minimum dokunma 44×44.
- VoiceOver: icon button'larda Türkçe etiket; kartlar tek öğe olarak okunur ("Trattoria Lume. İtalyan, orta fiyat, 1,2 kilometre. Açık, 23'e kadar."); deste kartında 4 custom action, katılımcı satırında "Dürt"; canlı duyurular birleştirilir; sheet açılınca odak başlığa; modal odağı hapseder.
- Renkten bağımsızlık her yerde (✓, ⚠, metin, yüzde + kişi sayısı).
- Reduce Transparency: blur yerine düz `canvas` + hairline. Increase Contrast (`MediaQuery.highContrastOf`): kartlara `borderControl` kenarı, `textSecondary` light `#4A433E` / dark `#D0C8CF`. Bold Text (`MediaQuery.boldTextOf`): ağırlıklar +100.

## 15. Flutter mapping

### Mimari
- `MaterialApp` + `ThemeExtension<AppColors>`. `splashFactory: NoSplash.splashFactory`, `highlightColor: Colors.transparent`, bütün platformlarda `CupertinoPageTransitionsBuilder`, `cupertinoOverrideTheme(primaryColor: brand)`, `scaffoldBackgroundColor: canvas`, imleç `brand`.
- Minimum Flutter 3.32.
- `BuildContext` extension'ları: `context.colors`, `context.text`, `context.motion`.

### Klasörler

```
lib/
  core/design_system/
    tokens/        app_colors.dart, app_fixed_colors.dart, app_typography.dart,
                   app_spacing.dart, app_radius.dart, app_elevation.dart, app_motion.dart
    foundations/   app_theme.dart, app_haptics.dart, app_icons.dart, context_extensions.dart
    components/
      buttons/     app_button.dart, app_icon_button.dart
      inputs/      app_text_field.dart, app_search_field.dart, app_selection_field.dart,
                   app_stepper.dart, app_slider.dart
      selection/   app_chip.dart, app_segmented_control.dart, app_toggle.dart,
                   app_checkbox.dart, app_check_circle.dart
      content/     app_card.dart, app_list_group.dart
      people/      app_avatar.dart, app_avatar_group.dart, participant_ring.dart
      feedback/    app_toast.dart, app_sheet.dart, app_alert.dart, app_empty_state.dart,
                   app_skeleton.dart, offline_banner.dart
      navigation/  app_nav_bar.dart
      decision/    agreement_arc.dart
    gallery/       design_system_gallery.dart   (yalnızca debug)
  features/
    deck/          swipe_deck.dart, deck_card.dart
    results/       result_card.dart, vote_option.dart
    decision/      decision_moment.dart, decision_card.dart
    room/          participant_strip.dart, invite_block.dart, nudge_button.dart
assets/fonts/Fraunces-Variable.ttf
```

Kural: birden fazla feature'da kullanılan design_system'da; tek feature'a ait olan feature klasöründe ama yalnızca token kullanır.

### Kodlama kuralları
1. Ekran ve feature kodunda ham değer yok: `Color(0x...)`, sayısal `EdgeInsets`, satır içi `TextStyle(...)`, `BorderRadius.circular()`, `Duration(...)` yazılmaz. Hepsi token.
2. Her component kendi `Semantics`, 44 min dokunma alanı ve metin ölçeklemesini taşır.
3. Hareket yalnızca `AppMotion`, titreşim yalnızca `AppHaptics`, ikon yalnızca `AppIcons` üzerinden.
4. Debug'da component galerisi: her component light/dark ve textScale 1.0 / 2.0'da.
5. Yeni paket eklemeden önce sorulur. Onaylı: `phosphor_flutter`.

---

## 17. Uygulama sapmaları ve ek kararlar (Faz C sonu)

Uygulama sırasında verilen, yukarıdaki metinden **bilinçli olarak ayrılan** ya da metnin boş bıraktığı kararlar. Çelişki halinde bu bölüm, ilgili ana bölümden önce gelir. Kullanıcı kararı olanlar "K" ile işaretli.

| # | Konu | Metin | Uygulama | Not |
|---|---|---|---|---|
| 1 | SwipeDeck eksen kilidi | İlk 12pt'den sonra kilit | **Kilit yok.** Baskın eksen her harekette yeniden bulunur; diğer eksen yumuşak 24pt ile sınırlı; iki eksen arası sürekli harmanlanır. 12pt yalnızca "yön/etiket belirir, hız tek başına karar sayılır" alt sınırı | K |
| 2 | Sürükleme geri bildirimi | İlgili alt buton vurgulanır, diğerleri soluklaşır | **Ekran zemini** kararın tonuna boyanır (eşikte %25); alt butonlar sabit. Kart foto tonu %20 aynen | K |
| 3 | ↓ Olmaz eşiği | %35 mesafe | Kartın **görünen** ofsetinin %35'i (parmak ≈ %64 yükseklik), hız sayılmaz | |
| 4 | Hız kuralı | > 800 pt/s | Hız, ofsetle aynı yönde olmalı; kart ≥ 12pt oynamış olmalı | |
| 5 | Uçuş süresi | ~250 ms, min 1000 pt/s | `mesafe / max(hız, 1000)`, aralık `fast` – `exitOf(emphasis)` (225 ms) | |
| 6 | Karar etiketi/tonu | Etiket renkleri tabloda | Konum: Olur/Çok isterim/Olmaz sol üst, Pas sağ üst. Ton: Olur `brandMuted`, Pas `textTertiary`, Çok isterim `brand`, Olmaz `error` | |
| 7 | Geri al | Son kart | Tek seviye; sayaç = şu anki kartın sırası | |
| 8 | İlk kullanım ipucu | Dört yön gösterilir, 24pt × 2 döngü | Kıpırdama sırasında dört yön pill'i belirir; karar etiketi/ton yok. "Bir kez" bilgisini çağıran tutar | K |
| 9 | Reduce Motion (deste) | Kart solar | Yerinde 200 ms solar (`AppMotion.regular.standard`); Geri al'da solarak gelir | |
| 10 | DeckCard | Görsel ~%78, iki satır | PROMPTS C2'deki %58 ve açık/gerekçe satırı **uygulanmadı**; yalnızca istisna "Kapanıyor · N dk" 3. satırda | |
| 11 | Mesafe biçimi | `1,2 km` | 1 km altı metre (`650 m`, en yakın 10), tam km ondalıksız (`1 km`) | mockup |
| 12 | ResultCard | Compact: 56 thumbnail | Satır 72 (dikey padding 8); compact'ta puan yazılmaz; hero seçili değilken sağ üstte boş halka rozeti | K |
| 13 | VoteOption | Önde olan 2px brand | Hero kart kenarı; compact satırda 4pt içeride 2px halka. Yalnızca "Çok isterim" diyenler isimle (API başka tür vermez) | K |
| 14 | AgreementArc | Sayı + "N/M kişi" | VoiceOver cümlesinde sayıya ek yok ("Toplam 5 kişi, olumlu 4, çok isteyen 2."); S'de "N/M kişi" yazmaz; sayılar sonradan değişirse animasyonsuz; yüzde aşağı yuvarlanır | K |
| 15 | Karar anı çoğunluk | "Arc gerçek oranına" | Çoğunlukta **Arc yok**, "3/4 oyla seçildi" etiketi (mockup + SCREENS D8); en fazla 5 avatar; avatar örtüşmesi %25 | K |
| 16 | Nav bar | Blur sigma ≈ 20 | Sigma 10 (`CupertinoSliverNavigationBar` sabit); çubuk arka planı `canvas` %85; uzun large title tek satır, sonuna "…" | |
| 17 | Skeleton nabzı | Süre yok | Her yön `emphasis` (300 ms); `expressive` yalnızca Arc ve karar anı için | |
| 18 | Bekleyen açık konular | | Slider değerinin konumu (üst/sağ), thumb gölgesi (E1/mockup), pasif toggle'ın CupertinoSwitch soluklaştırması | |
| 19 | Klasör yapısı | SwipeDeck, ResultCard, VoteOption, DecisionMoment `features/` altında | Hepsi `lib/core/design_system/components/` altında (galeri tek yerden gezer, testler tek yerde); ekran kodu `features/` altında olacak | E0'da yeniden değerlendirilebilir |
| 20 | Karşılama tipografisi | Yalnızca `display`/`h1` Fraunces | Karşılama sahne 1 için `hero` (Fraunces 80/76, -2) ve slogan için `lead` (SF 20/27) eklendi; yalnızca A2'de kullanılır, `tokens.json`'a işlenmedi | |
| 21 | Kod alanı | Metinde yok | `AppCodeField`: gizli TextField + 6 kutu; hata durumunda tüm kutular `error` kenar; yanlış kodda temizlenir | |
