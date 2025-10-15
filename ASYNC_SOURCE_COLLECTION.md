# Asenkron Kaynak Toplama Sistemi (Async Source Collection)

## 📋 Genel Bakış

Film detay sayfasına girdiğinizde, iframe kaynakları arka planda otomatik olarak taranır ve bulunan video/altyazı URL'leri veritabanına kaydedilir. Bu sistem sayesinde:

- ✅ **Proaktif Önbellekleme**: Kaynaklar önceden toplanıp kaydedilir
- ✅ **Asenkron Çalışma**: UI engellemeden arka planda çalışır
- ✅ **Real-time Güncellemeler**: Bulunan kaynaklar anında ekranda görünür
- ✅ **Duplicate Kontrolü**: Aynı kaynak tekrar eklenmez
- ✅ **Veritabanı Entegrasyonu**: Her kaynak kalıcı olarak saklanır

## 🎯 Motivasyon

### Önceki Sistem (Reaktif)
```
Kullanıcı İzle → Hata Olursa → Iframe Player Aç → Kaynak Topla → İzle
```
**Sorun**: Her seferinde iframe yüklemek gerekiyor, yavaş ve kullanıcı deneyimi kötü.

### Yeni Sistem (Proaktif)
```
Detay Sayfası Açılır → Background Toplama Başlar → Kaynaklar Veritabanına Kaydedilir
  ↓
Kullanıcı İzle → Direkt Kayıtlı Kaynaktan İzle (Hızlı!)
```
**Avantaj**: Kaynaklar önceden hazır, iframe yükleme yok, hızlı başlama.

## 🏗️ Mimari

### 1. SourceCollectorService
**Dosya**: `/lib/services/source_collector_service.dart`

**Sorumluluklar**:
- Headless WebView ile iframe'leri yükler
- JavaScript injection ile XHR/Fetch isteklerini yakalar
- Medya URL'lerini tespit eder (12-layer detection)
- Veritabanına kaydeder (duplicate kontrolü ile)
- Stream ile UI'a real-time güncellemeler gönderir

**Key Methods**:
```dart
Future<void> startCollecting({
  required int filmId,
  required String iframeUrl,
  required String sourceTitle,
})
```

### 2. Film Detail Screen Entegrasyonu
**Dosya**: `/lib/screens/film_detail_screen.dart`

**Değişiklikler**:
- `initState()` içinde `_startBackgroundSourceCollection()` çağrılır
- Stream'ler dinlenir, `setState()` ile UI güncellenir
- Yeni section: `_buildDiscoveredSourcesSection()` bulunan kaynakları gösterir

### 3. API Service Extensions
**Dosya**: `/lib/services/api_service.dart`

**Yeni Methodlar**:
```dart
Future<Kaynak> createFilmKaynagi(int filmId, Kaynak kaynak)
Future<Altyazi> createFilmAltyazisi(int filmId, Altyazi altyazi)
```

## 🔄 İş Akışı

### 1. Kullanıcı Film Detay Sayfasına Girer
```dart
@override
void initState() {
  super.initState();
  _loadFilmDetails();
  _startBackgroundSourceCollection(); // ✨ Yeni!
}
```

### 2. Background Collection Başlar
```dart
Future<void> _startBackgroundSourceCollection() async {
  // 1. Film'in iframe kaynaklarını al
  final iframeSources = film.kaynaklar?.where((k) => k.isIframe).toList();

  // 2. Her iframe için collector başlat
  for (final source in iframeSources) {
    await _sourceCollector.startCollecting(
      filmId: film.id,
      iframeUrl: source.url,
      sourceTitle: source.baslik,
    );
  }
}
```

### 3. SourceCollector İşlem Yapar
```dart
// a) WebView oluşturur (headless)
final controller = WebViewController()
  ..setJavaScriptMode(JavaScriptMode.unrestricted)
  ..addJavaScriptChannel('SourceCollector', ...);

// b) JavaScript kodunu inject eder
await controller.loadRequest(Uri.parse(iframeUrl));
await _injectJavaScript(controller);

// c) Mesajları dinler
onMessageReceived: (message) {
  _handleSourceMessage(message.message, filmId, sourceTitle);
}
```

### 4. JavaScript Network Intercept
```javascript
// XHR intercept
XMLHttpRequest.prototype.send = function() {
  xhr.addEventListener('load', function() {
    if (isMediaContent(url, contentType)) {
      SourceCollector.postMessage(JSON.stringify({
        type: 'video',
        url: url,
        contentType: contentType
      }));
    }
  });
};

// Fetch intercept
window.fetch = function(url, options) {
  promise.then(function(response) {
    if (isMediaContent(url, contentType)) {
      SourceCollector.postMessage(...);
    }
  });
};
```

### 5. Veritabanına Kayıt
```dart
Future<void> _handleVideoSource(url, contentType, filmId, sourceTitle) async {
  // a) Duplicate kontrolü (local)
  if (_discoveredSourceUrls.contains(url)) return;

  // b) Duplicate kontrolü (veritabanı)
  final existingSources = await _apiService.getFilmKaynaklari(filmId);
  if (existingSources.any((k) => k.url == url)) return;

  // c) Veritabanına kaydet
  final savedSource = await _apiService.createFilmKaynagi(filmId, newSource);

  // d) Stream'e gönder (UI günceller)
  _currentSources.add(savedSource);
  _sourcesStreamController.add(List.from(_currentSources));
}
```

### 6. UI Real-time Güncellenir
```dart
// Stream dinleme
_sourceCollector.sourcesStream.listen((sources) {
  setState(() {
    _discoveredSources = sources;
  });
});

// UI'da gösterim
Widget _buildDiscoveredSourcesSection() {
  return ListView.builder(
    itemCount: _discoveredSources.length,
    itemBuilder: (context, index) {
      final source = _discoveredSources[index];
      return ListTile(
        title: Text(source.baslik),
        trailing: Icon(Icons.check_circle, color: AppTheme.success),
      );
    },
  );
}
```

## 📊 Veri Modelleri

### Film Kaynağı (Kaynak)
```dart
class Kaynak {
  final int id;
  final String baslik;      // "fullhdfilmizlesene - 1080p"
  final String url;         // Direkt video URL
  final int? kaynakId;
  final bool isIframe;      // false (direkt URL)
}
```

### Film Altyazısı (Altyazi)
```dart
class Altyazi {
  final int id;
  final String baslik;      // "WebVTT" veya "SRT"
  final String url;         // Altyazı dosyası URL
  final int? filmId;
}
```

## 🔌 API Entegrasyonu

### 1. Kaynak Oluşturma
```http
POST /api/film_kaynaklari:create
Content-Type: application/json

{
  "film_id": {"id": 123},
  "baslik": "fullhdfilmizlesene - 1080p",
  "url": "https://photostack.net/m9/nUyyZKMd...",
  "is_iframe": false
}
```

### 2. Altyazı Oluşturma
```http
POST /api/film_altyazilari:create
Content-Type: application/json

{
  "filmler": {"id": 123},
  "baslik": "WebVTT",
  "url": "https://example.com/subtitles.vtt"
}
```

### 3. Duplicate Kontrolü
```http
GET /api/film_kaynaklari:list?filter={"url":{"$eq":"https://..."}}
```

## 🎨 UI Özellikleri

### Discovered Sources Section
- **Header**: "Bulunan Kaynaklar" + yükleniyor spinner
- **Badges**: Video sayısı (kırmızı), Altyazı sayısı (turuncu)
- **Liste**: Her kaynak için kart
  - ✅ Kayıt durumu (yeşil check icon)
  - 🎬 Kaynak başlığı (kalite ile)
  - 🔗 URL preview (kısaltılmış)
- **Loading State**: "Kaynaklar Taranıyor..." mesajı

### Responsive Design
- **Desktop**: Geniş kartlar, sol navbar
- **Mobile**: Kompakt liste, alt navbar

## 🔍 Medya Tespit Algoritması

### 12 Katmanlı Tespit
1. **Video Formatları**: .m3u8, .mp4, .mkv, .webm, .mpd
2. **TS Segment Kontrolü**: .ts dosyaları (sadece HLS context'inde)
3. **Streaming Pattern'leri**: hls, dash, video, stream, manifest
4. **Content-Type**: video/*, application/x-mpegurl, octet-stream
5. **Response İçerik**: #EXTM3U, #EXT-X-, <MPD>
6. **CDN Domain**: photostack.net, imagehub.pics, dplayer82, streamtape, rapidvid, vidmoxy
7. **Hash Path Pattern**: 20+ karakter alphanumeric path (uzantısız)
8. **Encrypted Query**: Base64 token parametreleri (?v=cHVQ..., ?token=...)
9. **CORS Headers**: Cross-origin istekler
10. **Response Size**: Büyük yanıt = video verisi
11. **False Positive Önleme**: Resim, font, kod dosyaları hariç
12. **Subtitle Priority**: VTT/SRT varsa video sayılmaz

### Örnek URL'ler
```
✅ Vidmoxy:  photostack.net/m9/nUyyZKMdLJg0o3Oyd0zxpTuiqT9mqTSwnl5h...
✅ Rapidvid: imagehub.pics/mx/FJ50MKWmLKE2pzI1pUgipzHioJVxLzLhMF5R...
✅ DPlayer:  dplayer82.site/master.m3u8?v=cHVQSnhEcHA5...
✅ HLS:      rovideox.org/hls/480.m3u8
```

## 🧪 Test Senaryosu

### 1. Film Detay Sayfası
```
1. Uygulamayı başlat
2. Bir filme tıkla
3. Detay sayfası açılır
4. ✅ "Bulunan Kaynaklar" section görünür
5. ✅ Yükleniyor spinner aktif
6. ✅ 5 saniye içinde ilk kaynak görünür
```

### 2. Real-time Güncellemeler
```
1. Background collection devam ederken
2. ✅ Her yeni kaynak anında listeye eklenir
3. ✅ Sayaçlar güncellenir (Video: 3, Altyazı: 1)
4. ✅ Her kaynak "Kaydedildi" badge'i gösterir
```

### 3. Duplicate Kontrolü
```
1. Aynı filme 2. kez gir
2. ✅ Mevcut kaynaklar tekrar eklenmez
3. ✅ Sadece yeni kaynaklar veritabanına yazılır
```

### 4. Veritabanı Doğrulama
```
1. NocoBase admin paneline gir
2. film_kaynaklari tablosunu aç
3. ✅ Yeni kayıtlar görünür
4. ✅ film_id doğru
5. ✅ is_iframe = false
6. ✅ baslik formatı: "iframe_title - quality"
```

## 🚀 Performans

### Optimizasyonlar
- **Parallel Loading**: Her iframe ayrı thread'de yüklenir (gelecek)
- **Timeout Kontrolü**: 30 saniye sonra otomatik iptal
- **Memory Management**: WebView dispose edilir
- **Debouncing**: Aynı URL 3 saniye içinde tekrar gönderilmez

### Benchmark
- **İlk kaynak**: ~5 saniye
- **Toplam süre**: 10-30 saniye (iframe sayısına göre)
- **Memory kullanımı**: +50MB (WebView overhead)

## 🐛 Hata Yönetimi

### Graceful Degradation
```dart
try {
  await _sourceCollector.startCollecting(...);
} catch (e) {
  debugPrint('❌ SOURCE COLLECTION: Hata: $e');
  // UI engellenmesin, devam et
}
```

### Error Cases
- **Iframe yüklenemezse**: Sonrakine geç
- **JavaScript hata verirse**: Log yaz, devam et
- **API timeout**: Retry 3 kez
- **Duplicate insert**: Ignore, devam et

## 📝 Logging

### Debug Output
```
🔍 SOURCE COLLECTOR: Başlatılıyor...
🔍 Film ID: 123
🔍 Iframe URL: https://fullhdfilmizlesene...
✅ SOURCE COLLECTOR: JavaScript injected
📨 SOURCE COLLECTOR: Mesaj alındı: video - https://...
📹 SOURCE COLLECTOR: Yeni kaynak bulundu: fullhdfilmizlesene - 1080p
✅ SOURCE COLLECTOR: Kaynak veritabanına eklendi: 456
✅ SOURCE COLLECTION: Tamamlandı!
```

## 🔮 Gelecek Geliştirmeler

1. **Parallel Loading**: Tüm iframe'ler aynı anda
2. **Quality Detection**: Daha akıllı kalite tespiti (OCR, regex)
3. **CDN Whitelist**: Güvenilir CDN'ler için hızlı tespit
4. **Cache TTL**: Eski kaynakları temizle (7 gün)
5. **Priority Queue**: Popüler filmler önce
6. **Background Service**: Uygulama kapanınca da çalışsın
7. **Progress Bar**: Her iframe için ayrı ilerleme
8. **Manual Trigger**: "Kaynakları Yenile" butonu

## 📚 İlgili Dosyalar

- `/lib/services/source_collector_service.dart` - Ana service
- `/lib/screens/film_detail_screen.dart` - UI entegrasyonu
- `/lib/services/api_service.dart` - Database operations
- `/lib/models/kaynak.dart` - Kaynak modeli
- `/lib/models/altyazi.dart` - Altyazı modeli
- `/roadmap/apis.json` - API dokumentasyonu

## 🎓 Öğrenilen Dersler

1. **Stream > Callback**: Real-time UI güncellemeleri için stream kullan
2. **Duplicate Check**: Hem local hem remote kontrol gerekli
3. **Headless WebView**: UI'sız WebView performanslı
4. **JavaScript Injection**: XHR/Fetch intercept güçlü
5. **Error Handling**: Her adımda try-catch, graceful degradation

---

**Durum**: ✅ Tamamlandı
**Tarih**: 2025-01-15
**Geliştirici**: @erdoganyesil
