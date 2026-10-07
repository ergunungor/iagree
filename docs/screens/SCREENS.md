# iAgree ekran spec'i

Bu dosya, `docs/screens/` altındaki mockup'ların nasıl okunacağını ve mockup'ta görünmeyen davranış kurallarını anlatır. Tasarım değerleri için tek kaynak hâlâ `docs/design-system/DESIGN_SYSTEM.md`.

## Mockup dosyalarını okuma

- `light/` açık tema, `dark/` koyu tema. Her ekranın iki temada birer dosyası var. İstisna: `DecisionA` (oybirliği karar anı) iki temada aynı göründüğü için sadece `light/` içinde.
- Dosyalar bir tasarım aracının `.dc.html` biçiminde: `<x-dc>`, `<helmet>`, `support.js` ve en alttaki `<script type="text/x-dc">` aracın kendi parçalarıdır, uygulamaya taşınmaz. Sadece görsel yapıya (sıra, boşluk, metin, renk, boyut) bak.
- Mockup'lardaki renkler hex olarak yazılı; kodda **her zaman token** kullanılır (`#6b2e63` → `context.colors.brand`). Hex → token karşılığı DESIGN_SYSTEM.md §3'teki tabloda.
- İkonlar elle çizilmiş yer tutucular; kodda `AppIcons` (Phosphor) kullanılır. Mekan fotoğrafları ve film afişi örnek çizimlerdir.
- Ekran 390×844 (iPhone 14/15). Üstteki 47–59 px status bar + safe area, alttaki 34–42 px home indicator alanıdır; kodda `SafeArea` ile çözülür, sabit değer yazılmaz.
- Örnek kişiler (Ayşe, Can, Deniz, Mert, Zeynep), mekanlar ve sayılar uydurmadır.

## Genel kurallar

- Ekran başına tek Primary buton.
- Liste satırlarında mümkün olduğunca tek satır metin; durum görsel öğeyle (ring, nokta, etiket) anlatılır, VoiceOver etiketi metni taşır.
- Fraunces sadece ekran başlığı (`h1`) ve `display` stillerinde.
- Pas ve veto hiçbir yerde isimle gösterilmez.

---

## A · Giriş

### A1 · Launch screen
Statik, sadece `canvas` rengi (iOS native launch screen). Logo veya metin yok. Oturum kontrolü arka planda; oturum varsa C1, yoksa A2.

### A2 · Karşılama — `Main`, `WelcomeB`, `WelcomeC`
Üç dosya **tek bir ekranın üç sahnesi**: tek ekranda, bir kez oynayan bir animasyon olarak birleşir ve C'de (`WelcomeC`) durur.

| Sahne | Dosya | Süre | Başlık |
|---|---|---|---|
| 1. Marka | `Main` | 0–2,5 sn | "Nereye gidelim?" sorusunu birlikte, tartışmadan bitirin. |
| Geçiş | — | ~0,4 sn | Büyük "iAgree" küçülüp sol üstteki başlığa dönüşür |
| 2. Mekanizma | `WelcomeB` | 2,5–5,5 sn | Nereye gidelim? (öndeki kart kendi kendine sağa kayar, "Olur" etiketi çıkar, uyum rozeti %80'e dolar) |
| 3. Sosyal | `WelcomeC` | 5,5–8,5 sn | Birlikte karar verin. (avatarlar kenarlardan gelir, kesik çizgiler çizilir, ortadaki ✓ springBouncy ile belirir) |

- Butonlar ilk kareden itibaren görünür ve tıklanabilir. Döngü yok, "Atla" yok, haptic yok.
- Reduce Motion: doğrudan `WelcomeC` statik.
- "Apple ile devam et": resmi Sign in with Apple butonu (`sign_in_with_apple`), light'ta siyah, dark'ta beyaz, pill. Mockup'taki buton logosuz bir yer tutucu.
- Altta Kullanım Koşulları / Gizlilik Politikası linkleri.

### A3 · E-posta — `Email`
Tek alan, `autofillHints: email`, e-posta klavyesi. "Kodu gönder" klavyenin hemen üstünde durur. Geçersiz adres: alan altında hata metni.

### A4 · Doğrulama kodu — `Code`
- 6 kutu; altıncı hane girilince **otomatik gönderilir** (ayrı onay butonu yok). `autofillHints: oneTimeCode`.
- "Adresi değiştir" → A3. "Yeniden gönder · 0:42" geri sayım bitince aktif olur. "Mail'i aç" mail uygulamasını açar.
- Yanlış kod: kutular `error` kenar + kısa titreşim (error haptic) + kutular temizlenir.

### A5 · Profil kurulumu — `Profile`
Sadece yeni kullanıcı. İsim Apple'dan geldiyse dolu ve altında "Apple hesabından geldi" notu. Fotoğraf isteğe bağlı (avatara dokununca fotoğraf seçici). "Başla" → C1 (davetle geldiyse doğrudan o oda).

## C · Ana kabuk

### C1 · Odalarım — `HomeC`, ilk kullanım `HomeEmpty`
- Sağ üst: "+" (oda oluştur → D1) ve profil avatarı (→ C2). Tab bar yok.
- **Hero kart:** aksiyon bekleyen en acil oda. Öncelik sırası: sonuçlar hazır (oy ver) → sıra sende (seç) → başkaları bekleniyor. Hero'nun aksiyonu ekranın tek Primary'si.
- "Diğer odalar": kompakt liste, durum etiketi ("Sıra sende" soft seçili stil; "3/5 hazır" metin).
- "Geçmiş kararlar": yatay kaydırılan fotoğraf karoları → karar detayı.
- Hiç aksiyon bekleyen oda yoksa hero gösterilmez, liste en üste çıkar.
- `HomeEmpty`: hiç odası olmayan kullanıcı. Altta tek Primary "Oda oluştur"; empty state'in kendi butonu yok.

### C2 · Profil — `ProfileMain`
Avatar, isim (Fraunces), e-posta, sağ üstte "Düzenle". Gruplar: Bildirimler, Görünüm (Sistem/Açık/Koyu) · Gizlilik ve koşullar, Bize yaz · Çıkış yap, **Hesabı sil** (`error` metin, alert modal ile onay; App Store zorunluluğu). Altta sürüm.

## D · Karar döngüsü

### D1 · Oda oluştur (full-screen modal)
**1. Ne yapıyorsunuz? — `CreateWhat`**
- "Bugüne özel": tema kartları, yatay kaydırılır, avatar tintleriyle renklenir. Bağlama duyarlı (yağmur varsa "Yağmurlu hava" gibi); veri gelene kadar sabit liste.
- "Kategoriler": 2 sütun ızgara, sonda "Fark etmez". Kategori listesi veriden gelir, UI sayıya bağımlı olmamalı.
- Bir seçeneğe dokununca doğrudan 2. adıma geçilir (Devam butonu yok). Üstte ✕ ve %50 progress.

**2. Nerede, ne zaman? — `CreateDetails`**
- Alanlar kategoriye göre değişir. Mekan kategorileri: Nerede (konum seçici sheet + mesafe slider'ı, snap 1/3/5/10 km), Ne zaman (chip'ler), Bütçe (çoklu chip), Oda adı (önceki seçimlerden önerilir).
- Film ve dizi: "Nerede" ve mesafe yerine "Hangi platform?" (çoklu chip). Bütçe yok.
- Konum izni bu ekranda, "Nerede" alanına dokununca istenir; reddedilirse semt elle seçilir.
- "Odayı kur" → D2.

### D2 · Oda — `RoomNew`
- Başlık oda adı (Fraunces), altında çerçeve etiketleri (kategori, zaman, bütçe, yer/platform).
- Katılımcı yoksa: kullanıcının avatarı + 3 boş kesik daire, "Arkadaşlarını çağır", link + "Kopyala".
- Alt bölge: Primary **"Linki paylaş"** (iOS share sheet) + Tertiary "Önce ben seçeyim" (→ D4).
- **İlk katılımcı geldiği an** Primary "Seçmeye başla" olur, davet alanı ikinci plana iner (link satırı kalır).
- Sağ üstte "…": oda ayarları (oda adını değiştir, odayı sil — alert ile).

### D3 · (kaldırıldı)
Katılımcılar çerçeve seçmez; çerçeveyi oda sahibi belirler. Linkten gelen herkes doğrudan D4'e gider.

### D4 · Deste — `DeckPlace`, `DeckSwipe`, `DeckFilm`
- Push ile tam ekran. Üst bar: geri (odaya) · progress · "8/15" · geri al ikonu.
- **Kart, üst bar ile butonlar arasındaki alanın dikey ortasında.** Butonlar altta, başparmak bölgesinde.
- Kart bilgisi iki satır: isim + meta. Gerekçe ve "Açık" bilgisi yok; sadece istisna olarak "Kapanıyor · 45 dk" (`warning`).
- `DeckSwipe`: yukarı kaydırma anı. Etiket + %20 renk tonu, ilgili buton vurgulanır, diğerleri soluklaşır. Diğer yönlerin görsel kuralları DESIGN_SYSTEM.md §10 SwipeDeck tablosunda.
- `DeckFilm`: 2:3 afiş `surfaceMuted` zemin üzerinde ortalı, meta: puan · tür · süre, sağda platform etiketi.
- Panele dokununca detay sheet'i (D5). Deste bitince → D6.

### D5 · Detay sheet'i (tasarım bekliyor)
Bottom sheet, Large detent. Mekan: fotoğraflar, adres + harita bağlantısı, saatler, menü/web bağlantısı. Film: özet, oyuncular, platform. Altta destenin dört aksiyonu sheet içinden de verilebilir.

### D6 · Bekleme — `Waiting`
- "Sen hazırsın" + "N kişi daha seçiyor"; katılımcıların ParticipantRing'leri canlı dolar.
- Bildirim izni burada istenir (kart + "Evet" → sistem izni). Kart bir kez gösterilir; reddedilirse bir daha çıkmaz.
- Primary yok. "Odaya dön" Tertiary.
- Herkes bitince: oybirliği varsa doğrudan D8 oybirliği, yoksa D7.

### D7 · Sonuçlar — `ResultsVote`, `ResultsVoted`
- En fazla 3 seçenek. 1. sıra hero (Media Card 16:10 + AgreementArc M + sevenler), 2–3 kompakt satır (AgreementArc S).
- **Oy vermeden önce:** tek seçim (hero'da sağ üst ✓ / satırlarda Check Circle), Primary "Oyumu ver". Diğerlerinin oyları gizli.
- **Oy verdikten sonra:** uyum yayları kaybolur, her seçenekte oy verenlerin avatarları + oy sayısı; önde olan 2px `brand`. Altta bekleyen kişi + "Dürt" (Secondary).
- Eşitlik: oda sahibine "Son söz sende" seçimi.
- Herkes oy verince → D8 çoğunluk.

### D8 · Karar anı — `DecisionA` (oybirliği), `DecisionB` (çoğunluk)
- **Oybirliği (`DecisionA`):** tam ekran `momentBg`, avatar kümesi, %100 Arc L, "Hepiniz anlaştınız.", mekan kartı, "Yol tarifi al" (moment), "Gruba paylaş" (momentGhost), "Kapat". Koreografi ve haptic: DESIGN_SYSTEM.md §10 DecisionMoment tablosu.
- **Çoğunluk (`DecisionB`):** `canvas` zemin, üstte kazanan mekanın fotoğrafı, avatarlar fotoğraf kenarına oturur, "Karar verildi.", mekan adı + meta, "3/4 oyla seçildi" etiketi, Primary "Yol tarifi al", Secondary "Gruba paylaş", sol üstte ✕. Avatarlar baştan yerinde, Arc animasyonu yok, sadece light haptic.
- Kapanınca odanın üstüne DecisionCard sabitlenir, oda "Geçmiş kararlar"a geçer.

## W · Web davet akışı (Next.js, tasarım bekliyor)

Uygulama ekranlarının web karşılıkları; aynı token'lar (DESIGN_SYSTEM CSS değişkenleri) ile.

| # | Ekran | Not |
|---|---|---|
| W1 | Davet önizleme | Davet edenin avatarı, oda adı, odadakiler, "Katıl". WhatsApp önizleme kartı sunucu tarafında üretilir (OG görseli). |
| W2 | Adın ne? | Sadece isim. Tarayıcı kaydı kaybolduysa "Daha önce katıldın mı? Adına dokun" listesi. |
| W3 | (yok) | Çerçeveyi oda sahibi belirler. |
| W4 | Deste | D4 ile aynı; haptic yok, `overscroll-behavior: none`, `touch-action` ile tarayıcı hareketleri kapalı. |
| W5 | Bekleme | D6 + uygulama teşviki #1: "Herkes hazır olunca haber almak için uygulamayı indir". |
| W6 | Sonuçlar ve oylama | D7 ile aynı. |
| W7 | Karar anı | D8 + teşvik #2: "Bir sonraki planı sen kur". |

- Web kullanıcısı rolünü eksiksiz oynar; indirme teşviki hiçbir zaman sonucun önünde engel değildir.
- Web kullanıcısının satırında "Dürt" yerine "Linki tekrar gönder".
- iOS Safari için Smart App Banner meta etiketi. Aynı link: uygulama yüklüyse universal link ile uygulamada açılır.
