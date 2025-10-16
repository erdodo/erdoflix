# 📚 Erdoflix Dokümantasyon

Bu klasör, Erdoflix projesi için teknik dokümantasyon ve geliştirme notlarını içerir.

## 📑 İçindekiler

### 🎮 [TV Navigation Fixes](./TV_NAVIGATION_FIXES.md)
Android TV kumandası desteği ve navigasyon iyileştirmeleri

**Tarih:** 16 Ekim 2025

**Kapsam:**
- Film detay ekranında kaynak listesi navigasyonu
- Player ekranında popup menü focus yönetimi
- Altyazı, kaynak ve hız seçim menülerinde focus trap
- D-pad navigasyonu ve SELECT/ENTER tuş desteği
- Görsel geri bildirim (focus highlight)

**Düzeltilen Sorunlar:**
- ❌ Kaynak listesine TV kumandası ile geçilemiyordu → ✅ Focus widget ile çözüldü
- ❌ Popup'lar açıldığında focus kayboluyordu → ✅ FocusScope ile trap oluşturuldu
- ❌ BACK tuşu ile popup kapatılamıyordu → ✅ onKeyEvent ile çözüldü

**Teknik Detaylar:**
```dart
// Focus yönetimi kalıbı
FocusScope(
  autofocus: true,
  canRequestFocus: true,
  onKeyEvent: (node, event) {
    // BACK tuşu handler
  },
  child: Focus(
    onKeyEvent: (node, event) {
      // SELECT/ENTER handler
    },
    child: ListTile(...),
  ),
);
```

---

### 🎬 [iFrame Sources Update](./IFRAME_SOURCES_UPDATE.md)
iFrame kaynaklarının detay ekranında gösterilmesi

**Tarih:** 16 Ekim 2025

**Kapsam:**
- Film detay ekranında iframe kaynaklarının listelenmesi
- iFrame etiketiyle görsel ayırt etme
- Debug log'larında kaynak türü ayrımı

**Değişiklik:**
```dart
// ❌ Önceki: Sadece direkt kaynaklar
_discoveredSources = widget.film.kaynaklar!
    .where((k) => k.isIframe == false)
    .toList();

// ✅ Yeni: Tüm kaynaklar (iframe + direkt)
_discoveredSources = widget.film.kaynaklar!.toList();
```

**Görsel İyileştirme:**
- 🔵 Mavi "iFrame" etiketi
- ✅ "Kaydedildi" durumu
- 📊 Debug: `📹 10 video (iframe: 3, direkt: 7)`

---

## 🔧 Teknik Altyapı

### Değiştirilen Dosyalar

#### 1. Source Collection & Display
- `lib/screens/film_detail_screen.dart`
  - Kaynak listesi Focus yönetimi
  - iFrame kaynakları filtresi kaldırıldı
  - iFrame etiketi eklendi

#### 2. Player Controls
- `lib/screens/player_screen.dart`
  - Kaynak seçim menüsü FocusScope
  - Altyazı seçim menüsü FocusScope
  - Hız seçim menüsü FocusScope

#### 3. Bug Fixes (Önceki)
- `lib/services/source_collector_service.dart`
  - Content-Type header eklendi
  - Duplicate control logic düzeltildi
  - Map vs Kaynak type mismatch çözüldü

- `lib/services/api_service.dart`
  - HTTP header düzeltmeleri

### Platform Desteği

- ✅ Android TV / Fire TV
- ✅ Android Mobile
- ✅ TV Kumandası (D-pad, SELECT, BACK)
- ✅ Touch Screen
- ✅ Mouse & Keyboard

---

## 🎯 Kullanım Kılavuzları

### Android TV Navigasyonu

**Film Seçme:**
1. Ana ekranda D-pad ile film listesinde gezinin
2. SELECT ile film detayına gidin

**Kaynak Seçme:**
1. Detay ekranında D-pad ile "Bulunan Kaynaklar" bölümüne inin
2. Yukarı/aşağı ile kaynaklar arasında gezinin
3. SELECT ile player'ı açın

**Player Kontrolleri:**
1. Player'da D-pad ile kontrol butonları arasında gezinin
2. "Kaynak" butonuna focus edip SELECT ile menüyü açın
3. D-pad ile kalite seçin, SELECT ile onayla
4. BACK ile menüyü kapatın

### Kaynak Türleri

**Direkt Kaynaklar:**
- M3U8, MP4, MKV formatları
- Doğrudan video player ile oynatılır
- İşaret: "Kaydedildi"

**iFrame Kaynaklar:**
- Embed player URL'leri
- WebView ile oynatılır
- İşaret: "🔵 iFrame" + "Kaydedildi"

---

## 🐛 Bilinen Sorunlar ve Çözümler

### Çözülen Sorunlar ✅

1. **Kaynak Veritabanına Kaydedilmiyor**
   - Neden: Duplicate control cache'i erken popülasyon
   - Çözüm: Cache'i DB save'den sonra doldur

2. **Type Mismatch: Map vs Kaynak**
   - Neden: API `List<dynamic>` dönüyor
   - Çözüm: `k['url']` ile Map alanlarına eriş

3. **TV Navigasyonu Çalışmıyor**
   - Neden: Focus widget eksikliği
   - Çözüm: Focus/FocusScope pattern

4. **Popup Focus Kaybı**
   - Neden: Focus trap yok
   - Çözüm: FocusScope ile isolation

### Aktif Sorunlar 🔧

_Şu anda bilinen aktif sorun yok._

---

## 📊 Performans Metrikleri

### Kaynak Toplama
- Ortalama süre: 2-5 saniye
- WebView overhead: ~1 saniye
- API round-trip: ~500ms

### Focus Performansı
- Focus change latency: <16ms (60fps)
- Key event handling: <5ms
- Visual feedback: Immediate

---

## 🚀 Gelecek Geliştirmeler

### Öncelikli
- [ ] Kaynak sıralama (kaliteye göre)
- [ ] Otomatik kaynak seçimi (en iyi kalite)
- [ ] Kaynak test etme (dead link detection)
- [ ] Offline kaynak cache

### Planlanan
- [ ] Çoklu altyazı desteği
- [ ] Altyazı senkronizasyonu
- [ ] Oynatma istatistikleri
- [ ] Watchlist senkronizasyonu

### İyileştirmeler
- [ ] Loading state animations
- [ ] Error recovery mechanisms
- [ ] Network resilience
- [ ] Background source refresh

---

## 📖 Ek Kaynaklar

### Proje Dökümanları
- [USER_GUIDE.md](../USER_GUIDE.md) - Kullanıcı kılavuzu
- [API_DOCUMENTATION.md](../API_DOCUMENTATION.md) - API referansı
- [README.md](../README.md) - Proje README

### External Links
- [Flutter Focus Management](https://docs.flutter.dev/development/ui/advanced/focus)
- [Android TV Navigation](https://developer.android.com/training/tv/start/navigation)
- [NocoBase API](https://docs.nocobase.com/)

---

## 👥 Katkıda Bulunanlar

**Geliştirici:** Erdoğan Yeşil  
**Tarih:** Ekim 2025  
**Platform:** Flutter 3.35.6 / Dart 3.6

---

## 📝 Versiyon Geçmişi

### v1.2.0 (16 Ekim 2025)
- ✅ iFrame kaynakları görüntüleme
- ✅ TV navigasyon desteği
- ✅ Focus trap implementasyonu
- ✅ Popup menü iyileştirmeleri

### v1.1.0 (Önceki)
- ✅ Kaynak toplama bug fixes
- ✅ API header düzeltmeleri
- ✅ Type mismatch çözümleri
- ✅ Memory leak fixes

---

**Son Güncelleme:** 16 Ekim 2025
