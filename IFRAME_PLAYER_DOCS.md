# İframe Player - Dokümantasyon

## 📝 Özet

İframe player, web-based video kaynakları için geliştirilmiş WebView tabanlı bir oynatıcıdır. Normal video player'ın açamadığı iframe/embed URL'leri için tasarlanmıştır.

## 🎯 Ne Zaman Kullanılır?

- URL'de `iframe` veya `embed` keyword'leri varsa
- API'den `is_iframe: true` gelirse
- Normal video player hata verdiğinde alternatif kaynak olarak

## 🚀 Özellikler

### 1. **Network İnterceptor**
JavaScript injection ile network isteklerini yakalar:
- XHR (XMLHttpRequest) monitoring
- Fetch API monitoring
- Video element observer (MutationObserver)

### 2. **Response Body Analizi** 🆕
URL uzantısı her zaman güvenilir değil. Örnek:
```
https://sx1.rovideox.org/v/d/tt0816692/tr/480
```
Bu URL'de `.m3u8` uzantısı yok ama response başlangıcı:
```
#EXTM3U
#EXT-X-VERSION:3
#EXT-X-TARGETDURATION:10
...
```

**Çözüm:**
- XHR: `addEventListener('load')` ile response body kontrolü
- Fetch: `response.clone().text()` ile content analizi
- M3U8 signature: `#EXTM3U`, `#EXT-X-` kontrolü

### 3. **Kalıcı Header Kontrolleri**
Positioned widget ile her zaman görünür:
- ⬅️ Geri butonu
- 📽️ Film bilgisi + iframe badge
- 🔄 Status (Analyzing/URL Bulundu)
- ↻ Yeniden Yükle
- 📂 Kaynak Menüsü (dropdown)
- ▶️ Native Player (URL yakalandıysa)

### 4. **Analiz Süresi & Periyodik Kontrol**
- **30 saniye** analiz süresi (önce 5 saniyeydi)
- **3 saniyede bir** periyodik video element kontrolü
- Arka planda dinleme devam eder

### 5. **Otomatik Native Player Geçişi**
Video URL yakalandığında:
```
[Dialog Gösterir]
┌─────────────────────────────────┐
│ ✅ Video URL Bulundu!           │
│                                 │
│ Kendi playerımızla devam        │
│ etmek ister misiniz?            │
│                                 │
│  [İframe'de Kal]  [Player'a Geç]│
└─────────────────────────────────┘
```

## 📊 Network Monitoring

### Yakalanan Format Türleri
```javascript
// Video formatları
['.m3u8', '.mp4', '.ts', '.mkv', '.avi', '.webm', '.mov', '.flv', '.m4v']

// Stream pattern'leri
['hls', 'dash', 'video', 'stream', 'manifest', 'playlist']

// M3U8 signature (BREAKTHROUGH!)
['#EXTM3U', '#EXT-X-']
```

### JavaScript Injection Kodu
```javascript
// XHR Response Body Kontrolü
xhr.addEventListener('load', function() {
  if (xhr.responseText.includes('#EXTM3U')) {
    window.flutter_network_log.postMessage({
      type: 'video',
      url: url,
      method: 'XHR_M3U8_CONTENT',
      contentType: 'application/x-mpegURL'
    });
  }
});

// Fetch Response Body Kontrolü
promise.then(function(response) {
  response.clone().text().then(function(text) {
    if (text.includes('#EXTM3U')) {
      window.flutter_network_log.postMessage({...});
    }
  });
});
```

## 🎮 TV Kumanda Kontrolleri

```
←  : Geri / Navbar / Sol film
→  : Sağ film / Kontrollere dön
↑  : Üst kontrol
↓  : Alt kontrol
OK : Seçili kontrolü etkinleştir
```

## 🔄 Route Yapısı

```dart
GoRoute(
  path: '/iframe-player/:filmId/:kaynakId',
  builder: (context, state) {
    final filmId = int.parse(state.pathParameters['filmId']!);
    final kaynakId = int.parse(state.pathParameters['kaynakId']!);
    return FutureBuilder<Film?>(
      future: ApiService().getFilmWithDetails(filmId),
      builder: (context, snapshot) {
        final kaynak = film.kaynaklar!.firstWhere((k) => k.id == kaynakId);
        return IframePlayerScreen(film: film, kaynak: kaynak);
      },
    );
  },
),
```

## 📦 Dependencies

```yaml
webview_flutter: ^4.10.0  # WebView + JavaScript injection
```

## 🐛 Debugging

Terminal'de şu logları görebilirsiniz:
```
🌐 Page started loading: https://...
✅ Page finished loading: https://...
🎥 Video URL yakalandı: https://...
🎥 Method: XHR_M3U8_CONTENT
🎥 Content-Type: application/x-mpegURL
🔍 Periyodik video kontrolü: []
```

## 📝 Network Logs (UI)

Alt sağ köşede debug paneli:
```
[🐞 Network Logs:]
XHR_M3U8_CONTENT [application/x-mpegURL]: https://...
FETCH_M3U8_CONTENT [application/x-mpegURL]: https://...
```

## 🎨 UI Components

### Header
```
┌──────────────────────────────────────────────────────┐
│ [← Geri] Film Başlığı [IFRAME] Kaynak [Analiz...] │
│          [↻] [📂 Kaynaklar ▼] [▶️ Player]          │
└──────────────────────────────────────────────────────┘
```

### Kaynak Menüsü
```
[📂 Kaynaklar ▼]
  ├─ ✅ Kaynak 1 [IFRAME] (Current)
  ├─ ○ Kaynak 2 [IFRAME]
  └─ ○ Kaynak 3
```

## 🚦 İyileştirme Süreci

### Problem 1: Header Kontrolleri Kayboluyordu
**Çözüm:** Positioned(top: 0) ile kalıcı header

### Problem 2: Analiz Çok Erken Bitiyor
**Çözüm:** 5s → 30s + periyodik kontrol (3s)

### Problem 3: URL Uzantısı Olmayan M3U8'ler
**Çözüm:** Response body analizi (#EXTM3U signature)

## 📈 Performans

- Response body'nin ilk **200 karakteri** kontrol edilir
- Error handling: `.catch()` ile hata yönetimi
- Clone kullanımı: `response.clone()` ile orijinal response bozulmaz

## 🔮 Gelecek Geliştirmeler

- [ ] DASH format desteği
- [ ] Header tampering (Referer, User-Agent)
- [ ] Cookie yönetimi
- [ ] Captcha çözme
- [ ] WebSocket monitoring

## 📚 İlgili Dosyalar

- `lib/screens/iframe_player_screen.dart` (980+ satır)
- `lib/screens/player_screen.dart` (iframe kontrolü)
- `lib/main.dart` (iframe-player route)
- `lib/models/kaynak.dart` (isIframe field)

---

**Son Güncelleme:** 15 Ekim 2025  
**Versiyon:** 1.2.0
