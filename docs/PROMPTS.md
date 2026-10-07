# iAgree Design System: Claude prompt sırası

## Kurulum (bir kez)

1. Bu klasördeki dosyaları Flutter projenin köküne kopyala:
   - `CLAUDE.md` → proje kökü
   - `docs/design-system/DESIGN_SYSTEM.md` ve `docs/design-system/tokens.json` → aynı yollara
2. Fraunces'ı indir: fonts.google.com/specimen/Fraunces → "Get font" → "Download all". Zip içinde adında `VariableFont` geçen, **italic olmayan** dosyayı (örn. `Fraunces-VariableFont_SOFT,WONK,opsz,wght.ttf`) `assets/fonts/Fraunces-Variable.ttf` adıyla koy.
3. Flutter sürümün en az 3.32 olmalı (`flutter --version`).

Claude Code `CLAUDE.md`'yi her oturumda otomatik okur. Başka bir araç kullanıyorsan (claude.ai, Antigravity vb.) her yeni sohbetin başına `CLAUDE.md`'nin içeriğini yapıştır ve `DESIGN_SYSTEM.md` ile `tokens.json`'u ekle.

## Nasıl kullanılır

- Prompt'ları **sırayla, birer birer** gönder. Bir adım bitip sen test etmeden sonrakine geçme.
- Claude her adımda önce analiz + plan sunacak. Planı okuyup "onay" ya da itirazını yaz.
- Bir adım uzarsa ya da bağlam dolarsa yeni bir oturum aç ve kaldığın prompt'tan devam et. CLAUDE.md sayesinde bağlam kaybolmaz.
- Her adımın sonunda commit at. Bir şey bozulursa geri dönmek kolay olur.

---

## Faz A: Foundations

### A0: Keşif

```
DESIGN_SYSTEM.md ve tokens.json'u baştan sona oku. Sonra mevcut Flutter projesini incele: pubspec.yaml, lib/ yapısı, mevcut tema veya renk dosyaları, Flutter sürümü.

Kod yazma. Bana şunları raporla:
1. Projenin mevcut durumu ve design system'la çakışan ya da yeniden kullanılabilecek bir şey var mı
2. DESIGN_SYSTEM.md'de belirsiz bulduğun ya da Flutter'da uygulanması zor gördüğün noktalar
3. "Faz A: Foundations" için numaralı uygulama planı (hangi dosyalar, hangi sırayla)

Onayımı bekle.
```

### A1: Renkler

```
DESIGN_SYSTEM.md §3 (Renk) ve §15'e göre renk token'larını oluştur:
- lib/core/design_system/tokens/app_colors.dart: ThemeExtension<AppColors>, temaya bağlı bütün renkler, light ve dark statik instance'ları, copyWith ve lerp.
- lib/core/design_system/tokens/app_fixed_colors.dart: iki temada aynı olan moment*, inverse* ve 5 avatar tinti (avatar tintlerinin light/dark değerleri farklı, bunları nasıl modelleyeceğini planında öner).

İsimler tokens.json'daki adların camelCase hâli. HEX değerleri birebir; #RRGGBBAA'yı Color(0xAARRGGBB)'ye çevirirken dikkat et.

Önce plan, onay bekle.
```

### A2: Tipografi

```
DESIGN_SYSTEM.md §4'e göre lib/core/design_system/tokens/app_typography.dart dosyasını oluştur.
- 11 stil: display, h1, h2, h3, title, body, bodySmall, label, button, caption, overline. Boyut, satır yüksekliği (height = lineHeight / fontSize), ağırlık, letter spacing birebir.
- SF Pro için fontFamily boş (iOS sistem fontu). Fraunces assets/fonts/Fraunces-Variable.ttf'den, fontVariations ile SOFT 50, WONK 0 ve wght.
- pubspec.yaml'a font asset kaydı.
- Sayısal stiller için tabular figures seçeneği.
- display ve h1 için 1.3x Dynamic Type sınırını nasıl uygulayacağını planında öner.

Renk içermesin; renk component'te verilir. Önce plan, onay bekle.
```

### A3: Spacing, radius, elevation

```
DESIGN_SYSTEM.md §5, §6, §7'ye göre:
- app_spacing.dart: xxs…giant + screenPadding, sectionGap, cardPadding, touchTarget
- app_radius.dart: xs…pill + RoundedSuperellipseBorder ve ShapeDecoration üreten yardımcılar
- app_elevation.dart: e1, e2, e3. Light'ta BoxShadow listesi, dark'ta e1 için gölge yerine 1px border. Temaya göre doğru sonucu döndüren bir API öner.

Önce plan, onay bekle.
```

### A4: Motion ve haptics

```
DESIGN_SYSTEM.md §12 ve §13'e göre:
- app_motion.dart: fast/standard/emphasis/expressive süreleri, enter/exit/move Cubic eğrileri, snappy/standard/bouncy SpringDescription'ları (tablodaki stiffness ve damping değerleriyle). Reduce Motion açıkken (MediaQuery.disableAnimationsOf) sıfır süre ve overshoot'suz eğri döndüren context tabanlı bir erişim.
- app_haptics.dart: selection, light, medium, rigid, success, error. rigid ve notification tipleri için küçük bir native iOS method channel (Swift tarafı dahil). Android'de güvenli fallback.

Paket eklemeden native kanalla çözmek istiyorum; daha iyi bir yol olduğunu düşünüyorsan gerekçesiyle söyle. Önce plan, onay bekle.
```

### A5: İkonlar

```
phosphor_flutter paketini ekle. lib/core/design_system/foundations/app_icons.dart içinde semantik isimlerle (share, undo, check, close, heart, heartFill, prohibit, search, plus, minus, back, chevron, upDown, link, copy, warning, info, star, map, userPlus, wifiOff) Phosphor ikonlarına eşleme yap. Varsayılan Regular, seçili durumlar için Fill varyantları.

Ekranlar Phosphor'u doğrudan import etmeyecek. Önce plan, onay bekle.
```

### A6: Tema ve context extension'ları

```
DESIGN_SYSTEM.md §15 "Mimari" bölümüne göre:
- app_theme.dart: AppTheme.light ve AppTheme.dark ThemeData'ları. NoSplash, transparent highlight, bütün platformlarda CupertinoPageTransitionsBuilder, cupertinoOverrideTheme primaryColor brand, scaffoldBackgroundColor canvas, imleç ve seçim rengi brand, AppColors extension.
- context_extensions.dart: context.colors, context.text, context.motion.
- MaterialApp'i bu temaya bağla (themeMode: system).

Önce plan, onay bekle.
```

### A7: Component galerisi

```
lib/core/design_system/gallery/design_system_gallery.dart: sadece debug build'de açılan bir ekran. Şimdilik renk paleti, tipografi stilleri, spacing ve radius örneklerini göstersin. Light/dark geçişi ve textScale 1.0 / 2.0 geçişi için üstte iki toggle olsun. İlerideki her component buraya bir bölüm olarak eklenecek.

Önce plan, onay bekle.
```

---

## Faz B: Temel component'ler

Her prompt'ta Claude önce planı sunacak. Her component'i bitirince galeriye ekletmeyi unutma.

### B1: AppButton

```
DESIGN_SYSTEM.md §9 (state modeli) ve §10 "Button"a göre AppButton'u oluştur.
- Tek sınıf + variant enum (primary, secondary, tertiary, destructive, destructiveStrong, moment, momentGhost, momentText) + named constructor'lar.
- Boyutlar lg/md/sm, min yükseklik (sabit değil), pill, opsiyonel ikon, fullWidth.
- Pressed: dolgu bir ton koyu + 0.97 scale (springSnappy dönüş); tertiary'de %50 opaklık. Disabled: opacity değil token. Loading: genişlik sabit, spinner.
- Semantics ve 44pt dokunma alanı.
Galeriye bütün varyant ve state'leri ekle. Önce plan, onay bekle.
```

### B2: AppIconButton

```
DESIGN_SYSTEM.md §10 "IconButton"a göre AppIconButton: plain / soft / media stilleri, semanticLabel zorunlu, 44 dokunma alanı. Galeriye ekle. Önce plan, onay bekle.
```

### B3: Input'lar

```
DESIGN_SYSTEM.md §10 "TextField", "SearchField / SelectionField", "Stepper / Slider" bölümlerine göre AppTextField, AppSearchField, AppSelectionField, AppStepper, AppSlider. Bunları tek adımda değil, planında önereceğin sırayla birer birer yapalım. İlk olarak AppTextField'ın planını sun.
```

### B4: Selection

```
DESIGN_SYSTEM.md §10 "Selection"a göre AppChip, AppSegmentedControl<T>, AppToggle, AppCheckbox, AppCheckCircle ve listede sağda ✓ ile tekli seçim. Chip'in seçilince genişliğinin springSnappy ile açılmasına dikkat. Sırayı planında öner, ilk component'in planıyla başla.
```

### B5: Card ve ListGroup

```
DESIGN_SYSTEM.md §10 "Card ve ListGroup"a göre AppCard (standard, interactive, media, selected) ve AppListGroup + AppListRow (divider metnin başladığı yerden başlar). Önce plan, onay bekle.
```

### B6: Avatar ve ParticipantRing

```
DESIGN_SYSTEM.md §10 "Avatar" ve "ParticipantRing"e göre AppAvatar (userId'den deterministik tint), AppAvatarGroup (en fazla 4 + "+N") ve ParticipantRing (invited, joined, choosing(progress), ready). Ring ilerlemesi emphasis + move ile, ready rozeti springBouncy ile animasyonlu. VoiceOver metinleri dahil. Önce plan, onay bekle.
```

### B7: Feedback ve katmanlar

```
DESIGN_SYSTEM.md §10 "Bottom Sheet", "Alert", "Toast", "States" bölümlerine göre: AppSheet.show, AppAlert.show, AppToast (overlay, ekranın üstünde, aynı anda tek, controller ile), AppEmptyState, AppSkeleton (nabız, shimmer yok), OfflineBanner. Sırayı planında öner, birer birer gidelim.
```

### B8: Navigation

```
DESIGN_SYSTEM.md §10 "Navigation"a göre AppNavBar: CupertinoSliverNavigationBar üzerine kurulu, large title Fraunces h1, inline başlık title stili, geri butonu sadece chevron, en fazla 2 sağ aksiyon. Akışlar için bar altında 4px progress. Tab bar yapma. Önce plan, onay bekle.
```

---

## Faz C: iAgree'ye özel component'ler

### C1: AgreementArc

```
DESIGN_SYSTEM.md §10 "AgreementArc"a göre AgreementArc. Parametre olarak loveCount, okCount, total alır, yüzdeyi kendi hesaplar (%100 yalnızca herkes olumluysa, yukarı yuvarlama yok). CustomPainter ile iki tonlu yay + 2pt boşluk + iz. S/M/L boyutlar, onMoment varyantı. Dolma animasyonu (expressive, enter, 100 ms gecikme) ve eşzamanlı sayan yüzde. Reduce Motion ve VoiceOver dahil.

Yüzde hesabı için birim testi de yaz. Önce plan, onay bekle.
```

### C2: SwipeDeck, statik kart

```
DESIGN_SYSTEM.md §10 "SwipeDeck"e göre önce sadece DeckCard'ı statik olarak yap: 3:4, radius xl, fotoğraf üst %58, dokunarak fotoğraf geçişi ve segment göstergesi, bilgi paneli (isim, meta, açık durumu, gerekçe). Henüz gesture yok. Önce plan, onay bekle.
```

### C3: SwipeDeck, hareket fiziği

```
SwipeDeck'in gesture katmanını ekle: dört yön, eksen kilidi (12pt), yatayda dönme (en fazla ±12°), aşağıda 0.55 direnç, eşikler ve hız kuralları (Olmaz yalnızca mesafeyle), etiket opaklığı ve renk tonu overlay'i, eşikte selection haptic, uçuş ve geri dönüş spring'leri, arka kartın öne gelmesi, alt 20pt koruması. Tablodaki değerler birebir. Önce plan, onay bekle.
```

### C4: SwipeDeck, butonlar, geri al, erişilebilirlik

```
SwipeDeck'e üst barı (sayaç, progress, Geri al), alt buton sırasını (Pas 56 · Olmaz 44 · Çok isterim 44 · Olur 56) ve butonla tetiklemeyi ekle. Geri al için bir controller. Haptic'ler (Olur/Pas light, Çok isterim medium, Olmaz rigid). VoiceOver custom action'ları, Reduce Motion'da solma, ilk kullanımda öğretici kıpırdama. Önce plan, onay bekle.
```

### C5: ResultCard ve VoteOption

```
DESIGN_SYSTEM.md §10 "ResultCard" ve "VoteOption"a göre ResultCard.hero, ResultCard.compact ve VoteOption (oy verene kadar sonuçlar gizli, sonra avatarlar + sayı, önde olan vurgulu). Pas/veto asla isimle gösterilmez. Önce plan, onay bekle.
```

### C6: DecisionMoment, statik

```
DESIGN_SYSTEM.md §10 "DecisionMoment"e göre önce son kareyi statik olarak yap: momentBg zemin, avatar kümesi, Arc L, display başlık (isUnanimous'a göre "Hepiniz anlaştınız." / "Karar verildi."), mekan kartı, moment butonları. Ayrıca DecisionCard. Önce plan, onay bekle.
```

### C7: DecisionMoment, koreografi

```
DecisionMoment'a koreografi tablosundaki zamanlamayla animasyonu ekle (tek bir AnimationController + Interval'lar mı, ayrı controller'lar mı, planında karşılaştır). Temasta medium, Arc %100'de success haptic. Dokununca atlama. Çoğunluk varyantı ve Reduce Motion crossfade. Önce plan, onay bekle.
```

---

## Faz D: Denetim

### D1: Design system denetimi

```
lib/ altındaki bütün design system ve feature kodunu DESIGN_SYSTEM.md'ye karşı denetle. Kod değiştirme, sadece raporla:
1. Ham değer kullanımı (Color(0x...), sayısal EdgeInsets, satır içi TextStyle, BorderRadius.circular, Duration) — dosya ve satırıyla
2. Spec'ten sapan değerler (renk, boyut, süre, eşik)
3. Eksik Semantics, 44pt'den küçük dokunma alanları, Dynamic Type'ta taşan yerler
4. Reduce Motion'a uymayan animasyonlar, AppHaptics dışından yapılan titreşimler
5. toUpperCase kullanımı, Türkçe olmayan arayüz metinleri
Her bulgu için önerilen düzeltmeyi yaz, önceliğe göre sırala. Hangilerini düzelteceğimize birlikte karar verelim.
```

---

## Faz E: Ekranlar

Faz A ve B bitmeden başlama: ekranlar o component'leri kullanıyor. Her ekran için Claude önce SCREENS.md'deki bölümü ve `docs/screens/light|dark/` altındaki mockup'ı okuyacak.

### E0: Navigasyon iskeleti

```
SCREENS.md'yi baştan sona oku. Kod yazmadan bana şunları öner:
1. Ekran listesi ve route yapısı (A1–A5, C1–C2, D1–D8), hangi geçişin push, hangisinin full-screen modal, hangisinin sheet olduğu
2. Bir routing yaklaşımı (mevcut projede ne varsa onu tercih et; yoksa seçenekleri gerekçesiyle karşılaştır)
3. Ekranlar için klasör yapısı (lib/features/...)
4. Ekranlar arasında taşınacak state'in (oturum, aktif oda) en sade modeli. Backend yok: şimdilik sahte veriyle (mock repository) çalışacağız.
Onayımı bekle.
```

### E1: Giriş akışı

```
SCREENS.md "A · Giriş" bölümüne ve mockup'lara (Email, Code, Profile; light ve dark) göre A3, A4 ve A5 ekranlarını yap. Gerçek auth yok: e-posta → kod (her kod kabul) → yeni kullanıcıysa profil. Kod ekranında 6. hanede otomatik gönderim ve geri sayım dahil. Ekranları birer birer yapalım; önce A3'ün planını sun.
```

### E2: Karşılama animasyonu

```
SCREENS.md A2'ye ve Main, WelcomeB, WelcomeC mockup'larına göre karşılama ekranını yap: tek ekran, üç sahne, bir kez oynayıp C'de duran animasyon. Süreler ve eğriler AppMotion'dan, sahne zamanlaması SCREENS.md tablosundan. Reduce Motion'da doğrudan son sahne. Önce animasyonu nasıl yapılandıracağını (tek controller + Interval'lar mı, başka bir yol mu) planında karşılaştır, onay bekle.
```

### E3: Odalarım ve Profil

```
SCREENS.md C1 ve C2'ye, HomeC / HomeEmpty / ProfileMain mockup'larına göre Odalarım ve Profil ekranlarını yap. Hero kartın hangi odayı göstereceği kuralı SCREENS.md'de. Sahte veride üç farklı durumdaki odaları ve boş durumu deneyebileceğim bir yol olsun. Önce plan, onay bekle.
```

### E4: Oda oluşturma ve oda ekranı

```
SCREENS.md D1 ve D2'ye, CreateWhat / CreateDetails / RoomNew mockup'larına göre oda oluşturma (full-screen modal, 2 adım) ve oda ekranını yap. Detaylar adımının kategoriye göre alan değiştirmesi (film/dizi: platform) ve oda ekranındaki Primary butonun ilk katılımcıyla "Seçmeye başla"ya dönmesi dahil. Önce plan, onay bekle.
```

### E5: Deste ekranı

```
SCREENS.md D4'e ve DeckPlace / DeckSwipe / DeckFilm mockup'larına göre deste ekranını, Faz C'de yaptığımız SwipeDeck'i kullanarak kur. Kart dikey ortada, butonlar altta. Mekan ve film kart varyantları. Deste bitince bekleme ekranına geçiş. Önce plan, onay bekle.
```

### E6: Bekleme, sonuçlar, karar anı

```
SCREENS.md D6, D7, D8'e ve Waiting / ResultsVote / ResultsVoted / DecisionA / DecisionB mockup'larına göre bu ekranları yap. Akış kuralları: herkes bitince oybirliği varsa DecisionA, yoksa sonuçlar; oy verdikten sonra yaylar yerine oy veren avatarları; herkes oy verince DecisionB. Sahte veride oybirliği ve çoğunluk senaryolarını ayrı ayrı tetikleyebileyim. Ekranları sırayla yapalım; önce D6'nın planını sun.
```

### E7: Ekran denetimi

```
Bütün ekranları SCREENS.md ve mockup'larla karşılaştır. Kod değiştirme, raporla: spec'ten sapan yerleşim/metin/davranış, eksik dark mode karşılıkları, ham değer kullanımı, eksik Semantics, Dynamic Type'ta taşan yerler. Önceliğe göre sırala, birlikte karar verelim.
```
