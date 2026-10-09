# Cihazda kontrol listesi

Simülatörün veremediği şeyler: gerçek dokunma hissi, haptic, VoiceOver, sistem izin pencereleri, Reduce Motion ve Dynamic Type'ın uç boyutları. Gerçek bir iPhone'a şöyle kur:

```bash
flutter run --release -d <cihaz-adı-veya-id> --dart-define=DEMO=home
```

(`DEMO=home` oturum açık başlatır; ilk kurulumda Xcode'da `Runner` için bir geliştirici ekibi seçmen gerekir: Signing & Capabilities → Team.)

Her madde için: **geçti / sorun var + ne gördün**. Sorun olanları bana yaz.

## 1. Haptic (Ayarlar → Ses ve Dokunuş → Sistem Dokunuşları açık)
- [ ] Deste: Olur / Çok isterim / Pas / Olmaz butonları ve sürükleme eşikleri farklı hissediliyor mu.
- [ ] Geri al: hafif.
- [ ] Hata durumları (boş isim, geçersiz e-posta, yanlış kod): error titreşimi.
- [ ] Chip, toggle, slider adımı: selection/light.
- [ ] Oy ver / Kaydet / Link kopyala: success.
- [ ] Karar anı (oybirliği): kademeli titreşim animasyonla uyumlu mu. Çoğunlukta yalnızca hafif.
- [ ] Karşılama animasyonunda hiç titreşim yok.

## 2. VoiceOver (Ayarlar → Erişilebilirlik → VoiceOver)
- [ ] Karşılama: sahne başlığı okunuyor, butonlar sırayla, animasyon bitmeden de ulaşılıyor.
- [ ] Kod ekranı: kutular tek alan gibi okunuyor ("Kod: 123, 3 hane kaldı"), yanlış kodda hata duyuruluyor.
- [ ] Odalarım: hero kart, satırlar tek cümle ("Doğum günü planı. Aktivite · 18 Ekim. Sıra sende"); bölüm başlıkları rotor'da "Başlıklar" ile gezilebiliyor.
- [ ] Deste kartı: kart tek öğe, **rotor → Eylemler** içinde Olur / Pas / Çok isterim / Olmaz var, çalışıyor.
- [ ] Deste: kart detay sheet'i açılıyor ve odak sheet başlığına gidiyor; alttaki dört buton okunuyor.
- [ ] Bekleme: "Sen hazırsın" canlı bölge olarak duyuruluyor.
- [ ] Sonuçlar: seçili seçenek söyleniyor; oy sonrası oy verenler okunuyor. Pas/Olmaz hiçbir yerde okunmuyor.
- [ ] Eşitlik ekranı: başlık duyuruluyor, seçim satırları seçili/seçili değil diyor.
- [ ] Karar anı: animasyon sırasında içerik okunabiliyor; "Kapat" ulaşılabilir.
- [ ] Alert'ler (hesap silme, oda silme, değişiklikleri sil): odak alert içinde kalıyor.
- [ ] Profil düzenleme: ✕, fotoğraf, isim, Kaydet sırası mantıklı; Kaydet pasifken "devre dışı" deniyor.

## 3. Reduce Motion (Ayarlar → Erişilebilirlik → Hareket → Hareketi Azalt)
- [ ] Karşılama doğrudan son sahnede açılıyor.
- [ ] Deste kartı uçmak yerine kısa geçişle değişiyor, ekran tonu titremiyor.
- [ ] Karar anı animasyonsuz, içerik belirip duruyor.
- [ ] Sheet ve modal geçişleri sakin.

## 4. Dynamic Type (Ayarlar → Erişilebilirlik → Ekran ve Metin Boyutu → Daha Büyük Metin → en büyük)
- [ ] Hiçbir ekranda kesilen/üst üste binen yazı yok: karşılama, e-posta, kod, profil kurulumu, Odalarım (hero + liste), Profil, oda kurma (2 adım), oda, deste, bekleme, sonuçlar, karar anı.
- [ ] Tüm butonlar tam okunuyor, kaydırarak ulaşılabiliyor.
- [ ] Deste kartında bilgi paneli büyüyor, kart oranı bozulmuyor.

## 5. Diğer erişilebilirlik
- [ ] Koyu Tema: her ekran. Özellikle avatar tintleri, durum etiketi, kod kutuları.
- [ ] Kontrastı Artır: kartlarda/listelerde kenar çizgisi görünüyor.
- [ ] Kalın Metin.
- [ ] Sağ el / sol el: alt butonlar başparmakla rahat ulaşılıyor.

## 6. Sistem entegrasyonu
- [ ] Bekleme'de "Evet" → iOS bildirim izni penceresi (yalnızca ilk seferde). Sonra Profil → Bildirimler'de izin reddedilmişse uyarı kartı + "Ayarları aç" doğru sayfayı açıyor; Ayarlar'dan izin verip dönünce kart kayboluyor.
- [ ] Oda kurma → Konumum: konum izni penceresi, Türkçe açıklama.
- [ ] Profil fotoğrafı: galeri izin penceresi, seçilen fotoğraf avatarlarda görünüyor.
- [ ] Linki paylaş: iOS paylaşım sayfası açılıyor, Mesajlar'a gönderince metin `https://iagree.app/r/...`.
- [ ] Karar anı → Yol tarifi al: Apple Maps açılıyor, mekan adıyla.
- [ ] Mail'i aç: Mail uygulaması açılıyor.
- [ ] Uygulama arka plana atılıp dönünce deste/oy durumu bozulmuyor.
- [ ] Telefon yatay çevrilince uygulama dönmüyor (yalnızca dikey).

## 7. His / performans
- [ ] Deste sürükleme 60 fps akıcı; yön geçişleri (sağdan yukarıya) kilitlenmeden dönüyor.
- [ ] Karşılama animasyonu takılmadan oynuyor (özellikle eski cihazda).
- [ ] Sheet ve modal açılışları.
- [ ] Soğuk açılışta beyaz/boş kare görünmüyor (launch screen → ilk ekran).
