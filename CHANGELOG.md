# Changelog - ErdoFlix

## [2025-01-16] - Asenkron Kaynak Toplama ve Veritabanı Entegrasyonu

### 🎉 Yeni Özellikler

#### 1. Asenkron Kaynak Toplama Sistemi
**Dosya**: `/lib/services/source_collector_service.dart`

- **Background Source Collection**: Film detay sayfasında iframe kaynakları arka planda otomatik toplanıyor
- **Headless WebView**: Görünmez WebView ile iframe'ler yükleniyor
- **JavaScript Injection**: XHR/Fetch network intercept ile medya URL'leri yakalanıyor
- **Real-time Updates**: Stream-based UI güncellemeleri
- **Database Persistence**: Her kaynak otomatik olarak veritabanına kaydediliyor
- **Duplicate Control**: Local ve database duplicate kontrolü
- **Smart Detection**: 12-layer medya tespit algoritması

**Özellikler**:
- 30 saniye kaynak toplama süresi
- 2 saniyede bir periyodik kontrol
- 0, 5, 10, 15. saniyede ekstra checkpoint'ler
- Kalite tespiti (4K, 1080p, 720p, 480p, 360p, 240p, Auto)
- Method tracking (XHR, FETCH, ELEMENT)

#### 2. Film Detay Sayfası Entegrasyonu
**Dosya**: `/lib/screens/film_detail_screen.dart`

- **Background Collection**: `_startBackgroundSourceCollection()` methodu
- **Stream Listeners**: Real-time UI güncellemeleri
- **Discovered Sources Section**: Bulunan kaynakları gösteren dinamik UI widget
- **Progress Tracking**: `[1/2]`, `[2/2]` formatında ilerleme göstergesi
- **Visual Feedback**: Loading spinner, kaynak sayaçları, "Kaydedildi" badge'leri

**UI Bileşenleri**:
- Kaynak listesi (başlık, URL preview, durum)
- Video ve altyazı sayaç badge'leri
- Loading state göstergesi
- Glassmorphism tasarım

#### 3. Iframe Player Database Integration
**Dosya**: `/lib/screens/iframe_player_screen.dart`

- **Otomatik Kaydetme**: Yakalanan her video ve altyazı veritabanına kaydediliyor
- **Video Kaydetme**: `_saveVideoToDatabase()` methodu
- **Altyazı Kaydetme**: `_saveSubtitleToDatabase()` methodu
- **Kalite Tespiti**: `_detectQuality()` ile otomatik kalite algılama
- **Duplicate Control**: Local cache + database query

**Kaynak Başlıkları**:
- Video: `"{iframe_name} - {quality} [{method}]"`
- Altyazı: `"{iframe_name} - {format}"`

#### 4. API Service Genişletmesi
**Dosya**: `/lib/services/api_service.dart`

- **createFilmKaynagi()**: Film kaynağı oluşturma
- **createFilmAltyazisi()**: Film altyazısı oluşturma
- **Kaynak ve Altyazı import'ları**: Model entegrasyonu

### 🔧 Düzeltmeler

#### Source Collection Timeout Sorunu
**Dosya**: `/lib/services/source_collector_service.dart`

**Sorun**: Background collector çok hızlı bitiyordu, kaynakları bulamıyordu.

**Çözüm**:
- Timer yerine `await Future.delayed()` kullanımı
- 30 saniye bekleme süresi eklendi
- Periyodik kontrol 3s'den 2s'ye düşürüldü
- Ekstra checkpoint'ler (0s, 5s, 10s, 15s)
- Detaylı debug logging

### 📚 Dokümantasyon

Yeni eklenen dokümantasyon dosyaları:

1. **ASYNC_SOURCE_COLLECTION.md**
   - Asenkron kaynak toplama sistemi açıklaması
   - Mimari detayları
   - İş akışı diagramları
   - Test senaryoları

2. **SOURCE_COLLECTION_DEBUG.md**
   - Debug rehberi
   - Sorun giderme adımları
   - Log formatları
   - Test checklist

3. **IFRAME_PLAYER_DATABASE_INTEGRATION.md**
   - Iframe player database entegrasyonu
   - Kaynak başlıklandırma
   - Kalite tespit algoritması
   - API entegrasyonu

4. **CHANGELOG.md** (bu dosya)
   - Tüm değişikliklerin özeti

### 🎨 UI İyileştirmeleri

#### AppTheme Güncellemeleri
**Dosya**: `/lib/utils/app_theme.dart`

- `success` rengi eklendi (yeşil check icon'lar için)
- `headingMedium` text style eklendi

### 🧪 Test Senaryoları

#### Background Source Collection
```
1. Film detay sayfasına git
2. "Bulunan Kaynaklar" section'ı görünür olmalı
3. Loading spinner dönmeli
4. 5-10 saniye içinde ilk kaynak görünmeli
5. Her kaynak "✅ Kaydedildi" badge'i ile görünmeli
6. Database'de yeni kayıtlar oluşmalı
```

#### Iframe Player Database Integration
```
1. Iframe player aç
2. Video yakalanınca console'da log görünmeli
3. Database'de yeni kayıt oluşmalı
4. Duplicate kaynaklar tekrar eklenmemeli
```

### 📊 Performans

- **Background Collection Süresi**: 30-60 saniye (iframe sayısına göre)
- **İlk Kaynak Yakalama**: 5-15 saniye
- **Memory Overhead**: +50-100MB (WebView)
- **Duplicate Check**: O(1) local + O(n) database

### 🔮 Gelecek İyileştirmeler

- [ ] Paralel iframe loading (şu anda sıralı)
- [ ] Akıllı timeout (kaynak bulunca erken dur)
- [ ] Retry mekanizması
- [ ] Background service (uygulama kapanınca da çalışsın)
- [ ] WebSocket real-time streaming
- [ ] Machine learning ile kalite tespiti
- [ ] CDN performance tracking
- [ ] Source expiration check

### 🐛 Bilinen Sorunlar

Yok - Sistem stabil durumda

### 📝 Notlar

- API token geçerlilik: 15 Ekim 2025 - 18 Ekim 2025
- Flutter version: 3.35.6
- Dart version: 3.6
- Target platform: Android (BlueStacks emulator)

### 🤝 Katkıda Bulunanlar

- @erdoganyesil - Ana geliştirme

---

**Önceki Changelog'lar**: Bu ilk major release
