# ErdoFlix Kullanıcı Kılavuzu

## 📱 Hoş Geldiniz

ErdoFlix, Netflix tarzı bir film platformudur. Klavye kontrolleri ile optimize edilmiş, modern ve kullanıcı dostu bir deneyim sunar.

---

## 🎮 Klavye Kontrolleri

### Ana Sayfa

#### Hero Banner (Öne Çıkan Film)
- **→ (Sağ Ok)**: Sağdaki butona geç (İzle → Listeye Ekle)
- **← (Sol Ok)**: Soldaki butona geç
- **↓ (Aşağı Ok)**: Kategorilere geç
- **Enter / Space**: Butonu aktifleştir

#### Film Kategorileri
- **→ (Sağ Ok)**: Sağdaki filme geç
- **← (Sol Ok)**: Soldaki filme geç, en solda ise navbar'a geç
- **↑ (Yukarı Ok)**: Üstteki kategoriye/hero'ya geç
- **↓ (Aşağı Ok)**: Alttaki kategoriye geç
- **Enter / Space**: Film detayını aç

#### Navbar
- **Desktop:**
  - **↑ (Yukarı Ok)**: Üstteki menüye geç
  - **↓ (Aşağı Ok)**: Alttaki menüye geç
  - **→ (Sağ Ok)**: İçeriğe geri dön
  - **Enter**: Sayfaya git

- **Mobile:**
  - **→ (Sağ Ok)**: Sağdaki menüye geç
  - **← (Sol Ok)**: Soldaki menüye geç
  - **Enter**: Sayfaya git

---

### Film Detay Sayfası

#### Navigasyon
- **→ (Sağ Ok)**: Sağdaki butona geç
- **← (Sol Ok)**: Soldaki butona geç, en solda ise navbar'a geç
- **↓ (Aşağı Ok)**: Benzer filmlere geç
- **↑ (Yukarı Ok)**: Butonlara geri dön
- **Enter / Space**: Butonu aktifleştir / Benzer filme git
- **Escape / Backspace**: Ana sayfaya dön

#### Geri Dönüş
- Sol üst köşedeki **← (Geri)** butonuna tıklayın
- Veya **Escape** / **Backspace** tuşuna basın

---

### Kategori Sayfası

#### Navigasyon
- **→ (Sağ Ok)**: Sağdaki filme geç
- **← (Sol Ok)**: Soldaki filme geç, en solda ise navbar'a geç
- **↑ (Yukarı Ok)**: Üstteki satıra geç
- **↓ (Aşağı Ok)**: Alttaki satıra geç
- **Enter / Space**: Film detayını aç
- **Escape / Backspace**: Ana sayfaya dön

---

## 🧭 Sayfa Yapısı

### 1. Ana Sayfa
- **Hero Banner**: Öne çıkan günün filmi
- **Popüler Filmler**: En çok izlenen filmler
- **Kategoriler**: Aksiyon, Komedi, Drama, Korku, vb.
- **Navbar**: Sol kenarda (desktop) / Alt kenarda (mobile)

### 2. Film Detay Sayfası
- **Hero Banner**: Film arka planı ve genel bilgiler
- **Başlık, Yıl, Süre, IMDb Puanı**
- **Türler**: Film kategorileri
- **Açıklama**: Film konusu
- **Butonlar**: İzle, Listeye Ekle
- **Benzer Filmler**: İlgili öneri filmler

### 3. Kategori Sayfası
- **Kategori Başlığı**: Aksiyon, Komedi vb.
- **Film Grid**: Kategorideki tüm filmler
- **Scroll**: Sınırsız scroll ile tüm filmleri keşfedin

---

## 📋 Menü (Navbar)

### Desktop (Ekran > 800px)
Navbar sol kenarda sabit konumdadır.

### Mobile (Ekran < 800px)
Navbar alt kenarda sabit konumdadır.

### Menü Öğeleri
1. **🏠 Ana Sayfa**: Popüler filmler ve kategoriler
2. **🎬 Filmler**: Tüm filmler (Yakında)
3. **📺 Diziler**: Tüm diziler (Yakında)
4. **❤️ Favorilerim**: Kayıtlı filmler (Yakında)
5. **⚙️ Ayarlar**: Uygulama ayarları (Yakında)

---

## ✨ Özellikler

### ✅ Aktif Özellikler (Phase 1)
- Hero banner ile öne çıkan film
- Kategorilere göre film listesi
- Infinity scroll (sınırsız kaydırma)
- Film detay sayfası
- Benzer film önerileri
- Tam klavye kontrolü
- Responsive tasarım (desktop + mobile)
- Focus efektleri (kırmızı glow)
- Navbar ile kolay navigasyon

### ⏳ Yakında (Phase 2)
- 🎥 Video oynatıcı
- 🔍 Arama fonksiyonu
- 👤 Kullanıcı girişi/kayıt
- ❤️ Favori listesi
- 📝 İzleme geçmişi
- 🔊 Altyazı seçimi
- 🎚️ Kalite ayarları
- 📱 Touch/mouse scroll desteği

---

## 🎨 Tasarım

### Renkler
- **Arka Plan**: Siyah (#000000)
- **Kartlar**: Koyu gri (#1a1a1a)
- **Vurgu Rengi**: Kırmızı (#e50914)
- **Metin**: Beyaz (#ffffff)
- **İkincil Metin**: Açık gri (#b3b3b3)

### Focus Efektleri
- **Scale**: 1.15x büyütme
- **Border**: 2px kırmızı
- **Glow**: Kırmızı ışık efekti (blur: 10px)
- **Z-Index**: Focus'taki element en üstte

### Responsive Breakpoints
- **Desktop**: > 800px (navbar sol, 4-5 kolon)
- **Tablet**: 600px - 800px (navbar alt, 3 kolon)
- **Mobile**: < 600px (navbar alt, 1-2 kolon)

---

## 🐛 Bilinen Sorunlar

### Çözüldü ✅
- 24 bug düzeltildi (detaylar için `roadmap/hatalar.md`)

### Devam Eden
- Video oynatıcı henüz yok (Phase 2)
- Arama fonksiyonu yok (Phase 2)
- Kullanıcı sistemi yok (Phase 2)

---

## 💡 İpuçları

### Hızlı Navigasyon
1. **Escape**: Her zaman ana sayfaya döner
2. **Navbar**: Sol ok ile hızlıca erişin
3. **Scroll**: Otomatik scroll ile focus'taki film her zaman görünür

### Film Keşfi
1. Kategorileri oklar ile gezin
2. İlginizi çeken filme Enter basın
3. Film detayında benzer filmleri keşfedin
4. Escape ile hızlıca geri dönün

### Performans
1. Görseller otomatik cache'lenir
2. Infinity scroll sayesinde hızlı yükleme
3. Sadece görünür alandaki görseller yüklenir

---

## 📞 Destek

### Teknik Sorunlar
Bir hata ile karşılaştıysanız:
1. Sayfayı yenileyin (F5)
2. Browser cache'ini temizleyin
3. GitHub Issues'da bildirim yapın

### Özellik İstekleri
Yeni özellik önerileriniz için:
- GitHub Issues kullanın
- Detaylı açıklama ekleyin
- Varsa örnek görseller paylaşın

---

## 🔐 Gizlilik

- ErdoFlix şu anda kullanıcı sistemi kullanmıyor
- İzleme verileri toplanmıyor
- Cookie kullanımı yok
- Phase 2'de kullanıcı sistemi eklenecek

---

## 📱 Desteklenen Platformlar

### Web Browsers
- ✅ Chrome (141+)
- ✅ Safari (17+)
- ✅ Edge (141+)
- ✅ Firefox (test edilmedi)
- ✅ Brave (test edildi)

### Cihazlar
- ✅ Desktop (Windows, macOS, Linux)
- ✅ Tablet (iPad, Android tablets)
- ✅ Mobile (iPhone, Android phones)
- ❌ Smart TV (henüz test edilmedi)

---

## 🚀 Versiyon Geçmişi

### v1.0 (14 Ekim 2025) - Phase 1 Complete
- ✅ Ana sayfa implementasyonu
- ✅ Film detay sayfası
- ✅ Kategori sayfası
- ✅ Navbar (desktop + mobile)
- ✅ Klavye kontrolleri
- ✅ Infinity scroll
- ✅ 24 bug fix

### v2.0 (Planlanan) - Phase 2
- ⏳ Video oynatıcı
- ⏳ Arama fonksiyonu
- ⏳ Kullanıcı sistemi
- ⏳ Favori listesi

---

**İyi seyirler! 🍿🎬**

---

**Son Güncelleme:** 14 Ekim 2025  
**Versiyon:** 1.0  
**Platform:** Flutter Web
