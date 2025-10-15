# 🎬 ErdoFlix

**Netflix tarzı modern film platformu** - Flutter Web ile geliştirilmiştir.

[![Flutter](https://img.shields.io/badge/Flutter-3.35.6-blue.svg)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.6-blue.svg)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## 📖 İçindekiler

- [Özellikler](#-özellikler)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Klavye Kontrolleri](#-klavye-kontrolleri)
- [Proje Yapısı](#-proje-yapısı)
- [Teknolojiler](#-teknolojiler)
- [Dokümantasyon](#-dokümantasyon)
- [Roadmap](#-roadmap)
- [Katkıda Bulunma](#-katkıda-bulunma)

## ✨ Özellikler

### Phase 1 ✅ (Tamamlandı)

- 🎥 **Hero Banner**: Öne çıkan film gösterimi
- 🎬 **Film Kategorileri**: Aksiyon, Komedi, Drama, Korku vb.
- 🔄 **Infinity Scroll**: Sınırsız film keşfi
- 📱 **Responsive Tasarım**: Desktop ve mobile uyumlu
- ⌨️ **Tam Klavye Kontrolü**: TV remote benzeri navigasyon
- 🎨 **Focus Efektleri**: Netflix-style hover ve focus
- 🧭 **Navbar**: Kolay menü navigasyonu (desktop sol, mobile alt)
- 📄 **Film Detay**: Kapsamlı film bilgileri ve benzer filmler
- 🔗 **API Entegrasyonu**: NocoBase backend ile senkronizasyon
- ⚡ **Performans**: Cache, lazy loading, optimize edilmiş rendering
- 🎬 **Iframe Player**: Gelişmiş medya API yakalama ve otomatik yönlendirme
- 🔄 **Asenkron Kaynak Toplama**: Background'da iframe kaynakları toplanır ve veritabanına kaydedilir
- 📦 **Smart Caching**: Kaynaklar önceden toplanıp önbelleklenir, hızlı oynatma
- 🎯 **12-Layer Detection**: CDN, hash path, encrypted query ile akıllı medya tespiti

### Phase 2 ⏳ (Planlanan)

- 🎮 Video oynatıcı
- 🔍 Arama fonksiyonu
- 👤 Kullanıcı girişi/kayıt
- ❤️ Favori listesi
- 📝 İzleme geçmişi
- 🔊 Altyazı seçimi
- 🎚️ Kalite ayarları

## 🚀 Kurulum

### Gereksinimler

- Flutter SDK 3.35.6 veya üzeri
- Dart SDK 3.6 veya üzeri
- Web browser (Chrome, Safari, Edge önerilir)

### Adımlar

1. **Repoyu klonlayın:**
```bash
git clone https://github.com/erdodo/erdoflix.git
cd erdoflix
```

2. **Bağımlılıkları yükleyin:**
```bash
flutter pub get
```

3. **Uygulamayı çalıştırın:**
```bash
flutter run -d web-server --web-port=8080
```

4. **Tarayıcıda açın:**
```
http://localhost:8080
```

## 💻 Kullanım

### Geliştirme

```bash
# Web sunucusu başlat
flutter run -d web-server --web-port=8080

# Hot reload
# Terminal'de 'r' tuşuna bas

# Hot restart
# Terminal'de 'R' tuşuna bas
```

### Production Build

```bash
flutter build web --release
```

Build dosyaları `build/web/` klasöründe oluşturulur.

## ⌨️ Klavye Kontrolleri

### Genel Navigasyon

| Tuş | Aksiyon |
|-----|---------|
| `→` | Sağa git |
| `←` | Sola git / Navbar'a geç |
| `↑` | Yukarı git |
| `↓` | Aşağı git |
| `Enter` / `Space` | Seç / Aktifleştir |
| `Escape` / `Backspace` | Ana sayfaya dön |

### Özel Kontroller

- **Hero → Kategoriler**: `↓` tuşu
- **Kategoriler → Hero**: `↑` tuşu
- **Film → Navbar**: En solda `←` tuşu
- **Navbar → Film**: `→` tuşu

Detaylı bilgi için: [USER_GUIDE.md](USER_GUIDE.md)

## 📁 Proje Yapısı

```
erdoflix/
├── lib/
│   ├── main.dart              # Uygulama giriş noktası
│   ├── models/                # Data modelleri
│   │   ├── film.dart          # Film model
│   │   └── tur.dart           # Tür/Kategori model
│   ├── screens/               # Sayfa ekranları
│   │   ├── home_screen.dart   # Ana sayfa
│   │   ├── film_detail_screen.dart  # Film detay
│   │   └── category_screen.dart     # Kategori sayfası
│   ├── services/              # API servisleri
│   │   ├── film_service.dart  # Film API
│   │   └── tur_service.dart   # Kategori API
│   └── widgets/               # Yeniden kullanılabilir bileşenler
│       ├── film_card.dart     # Film kartı
│       ├── hero_banner.dart   # Hero banner
│       └── navbar.dart        # Navigation bar
├── roadmap/                   # Proje yol haritası
│   ├── yapilacaklar.md       # Todo listesi
│   ├── hatalar.md            # Bug tracker
│   └── apis.json             # API şeması
├── TEST_REPORT.md            # Test raporu
├── API_DOCUMENTATION.md      # API dökümanları
├── USER_GUIDE.md             # Kullanıcı kılavuzu
└── README.md                 # Bu dosya
```

## 🛠️ Teknolojiler

### Frontend
- **Flutter** 3.35.6 - UI framework
- **Dart** 3.6 - Programming language
- **go_router** 14.8.1 - Routing
- **provider** 6.1.1 - State management
- **cached_network_image** 3.3.1 - Image caching
- **flutter_hooks** 0.20.5 - Lifecycle hooks

### Backend
- **NocoBase** - Headless CMS
- **REST API** - HTTP communication

### Styling
- **Material Design** - Base components
- **Custom Theme** - Netflix-inspired dark theme

## 📚 Dokümantasyon

- [API Dokümantasyonu](API_DOCUMENTATION.md) - Backend API referansı
- [Kullanıcı Kılavuzu](USER_GUIDE.md) - Son kullanıcı rehberi
- [Test Raporu](TEST_REPORT.md) - Kapsamlı test sonuçları
- [Iframe Player Dokümantasyonu](IFRAME_PLAYER_DOCS.md) - Medya yakalama sistemi
- [Iframe Player İyileştirmeleri](IFRAME_IMPROVEMENTS.md) - Son güncellemeler (16 Ekim 2025)
- [Roadmap](roadmap/yapilacaklar.md) - Özellik planlaması
- [Bug Tracker](roadmap/hatalar.md) - Hata takibi (24 bug düzeltildi ✅)

## 🗺️ Roadmap

### ✅ Phase 1 - Tamamlandı (14 Ekim 2025)
- [x] Ana sayfa UI
- [x] Film detay sayfası
- [x] Kategori sayfası
- [x] Navbar implementasyonu
- [x] Klavye kontrolleri
- [x] API entegrasyonu
- [x] Responsive tasarım
- [x] 24 bug fix

### 🚧 Phase 2 - Devam Ediyor
- [ ] Video oynatıcı
- [ ] Arama fonksiyonu
- [ ] Kullanıcı sistemi
- [ ] Favori/liste özellikleri
- [ ] İzleme geçmişi
- [ ] Altyazı sistemi

### 📅 Phase 3 - Planlanıyor
- [ ] Multi-language support
- [ ] Dark/Light theme
- [ ] PWA support
- [ ] Offline mode
- [ ] Mobile app (iOS/Android)

## 🤝 Katkıda Bulunma

Katkılarınızı bekliyoruz! Lütfen şu adımları izleyin:

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'feat: add amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request açın

### Commit Mesaj Formatı

```
<type>: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: Yeni özellik
- `fix`: Bug düzeltme
- `docs`: Dokümantasyon
- `style`: Code formatting
- `refactor`: Code refactoring
- `test`: Test ekleme
- `chore`: Build/tool değişiklikleri

## 📄 Lisans

Bu proje [MIT Lisansı](LICENSE) ile lisanslanmıştır.

## 👤 Geliştirici

**Erdoğan Yeşil**

- GitHub: [@erdodo](https://github.com/erdodo)
- Email: erdoganyesil@gmail.com (varsayılan)

## 🙏 Teşekkürler

- [Flutter Team](https://flutter.dev) - Amazing framework
- [NocoBase](https://www.nocobase.com/) - Powerful backend
- [Netflix](https://netflix.com) - Design inspiration
- AI Assistant (GitHub Copilot) - Development support

## 📊 Durum

![GitHub commit activity](https://img.shields.io/github/commit-activity/m/erdodo/erdoflix)
![GitHub last commit](https://img.shields.io/github/last-commit/erdodo/erdoflix)
![GitHub issues](https://img.shields.io/github/issues/erdodo/erdoflix)

---

**🍿 İyi seyirler!**

Made with ❤️ by [Erdoğan Yeşil](https://github.com/erdodo)
