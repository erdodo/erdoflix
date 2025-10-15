# Iframe Player Database Integration

## 📋 Özellik

Iframe Player'da yakalanan video kaynakları ve altyazılar artık **otomatik olarak veritabanına kaydediliyor**.

## 🎯 Motivasyon

### Önceki Durum
```
Iframe Player → Video/Altyazı Yakala → Kullanıcıya Göster → ❌ Kaybolur
```
Kullanıcı iframe player'ı kapattığında bulunan kaynaklar kayboluyordu.

### Yeni Durum
```
Iframe Player → Video/Altyazı Yakala → ✅ Veritabanına Kaydet → Kalıcı Olarak Saklanır
```
Her bulunan kaynak otomatik olarak veritabanına kaydediliyor ve sonraki ziyaretlerde kullanılabiliyor.

## 🔄 Nasıl Çalışır?

### 1. Video Yakalandığında
```dart
// JavaScript mesajından veya video element'inden
if (mounted && !_capturedVideoUrls.contains(url)) {
  setState(() {
    _capturedVideoUrls.add(url);
  });

  // ✨ YENİ: Veritabanına kaydet
  _saveVideoToDatabase(url, method);
}
```

### 2. Altyazı Yakalandığında
```dart
if (type == 'subtitle') {
  if (mounted && !_capturedSubtitles.contains(url)) {
    setState(() {
      _capturedSubtitles.add(url);
    });

    // ✨ YENİ: Veritabanına kaydet
    _saveSubtitleToDatabase(url);
  }
}
```

### 3. Video Kaydetme İşlemi
```dart
Future<void> _saveVideoToDatabase(String url, String method) async {
  // 1. Local duplicate kontrolü
  if (_savedVideoUrls.contains(url)) return;

  // 2. Database duplicate kontrolü
  final existingSources = await _apiService.getFilmKaynaklari(widget.film.id);
  if (existingSources.any((k) => k.url == url)) {
    _savedVideoUrls.add(url);
    return;
  }

  // 3. Kalite tespiti
  final quality = _detectQuality(url); // "1080p", "720p", "4K", etc.

  // 4. Başlık oluştur
  final title = '${widget.kaynak.baslik}${quality.isNotEmpty ? " - $quality" : ""} [$method]';
  // Örnek: "fullhdfilmizlesene - 1080p [XHR]"

  // 5. Kaynak oluştur
  final newSource = Kaynak(
    id: 0,
    url: url,
    baslik: title,
    isIframe: false, // Direkt video URL
  );

  // 6. API'ye kaydet
  final savedSource = await _apiService.createFilmKaynagi(widget.film.id, newSource);

  // 7. Local cache'e ekle
  _savedVideoUrls.add(url);

  debugPrint('✅ IFRAME PLAYER: Video kaydedildi: ${savedSource.baslik}');
}
```

### 4. Altyazı Kaydetme İşlemi
```dart
Future<void> _saveSubtitleToDatabase(String url) async {
  // 1. Local duplicate kontrolü
  if (_savedSubtitleUrls.contains(url)) return;

  // 2. Database duplicate kontrolü
  final existingSubtitles = await _apiService.getFilmAltyazilari(widget.film.id);
  if (existingSubtitles.any((a) => a.url == url)) {
    _savedSubtitleUrls.add(url);
    return;
  }

  // 3. Format tespiti
  String title = '${widget.kaynak.baslik} - Altyazı';
  if (url.toLowerCase().contains('.vtt')) {
    title = '${widget.kaynak.baslik} - WebVTT';
  } else if (url.toLowerCase().contains('.srt')) {
    title = '${widget.kaynak.baslik} - SRT';
  }

  // 4. Altyazı oluştur
  final newSubtitle = Altyazi(
    id: 0,
    url: url,
    baslik: title,
    filmId: widget.film.id,
  );

  // 5. API'ye kaydet
  final savedSubtitle = await _apiService.createFilmAltyazisi(widget.film.id, newSubtitle);

  // 6. Local cache'e ekle
  _savedSubtitleUrls.add(url);

  debugPrint('✅ IFRAME PLAYER: Altyazı kaydedildi: ${savedSubtitle.baslik}');
}
```

## 🎨 Kaynak Başlıklandırma

### Video Başlıkları
```
Format: "{iframe_name} - {quality} [{method}]"

Örnekler:
✅ "fullhdfilmizlesene - 1080p [XHR]"
✅ "hdfilmcehennemi - 720p [FETCH]"
✅ "dizipal - 4K [ELEMENT]"
✅ "vidmoxy - Auto [XHR]" (kalite tespit edilemezse)
```

### Altyazı Başlıkları
```
Format: "{iframe_name} - {format}"

Örnekler:
✅ "fullhdfilmizlesene - WebVTT"
✅ "hdfilmcehennemi - SRT"
✅ "dizipal - Altyazı" (format tespit edilemezse)
```

## 🔍 Kalite Tespit Algoritması

### Pattern Matching
```dart
String _detectQuality(String url) {
  final urlLower = url.toLowerCase();

  // Keyword kontrolü
  if (urlLower.contains('4k') || urlLower.contains('2160p')) return '4K';
  if (urlLower.contains('1440p')) return '1440p';
  if (urlLower.contains('1080p') || urlLower.contains('fullhd')) return '1080p';
  if (urlLower.contains('720p') || urlLower.contains('hd')) return '720p';
  if (urlLower.contains('480p')) return '480p';
  if (urlLower.contains('360p')) return '360p';
  if (urlLower.contains('240p')) return '240p';

  // Path segment analizi
  // Örnek: /hls/1080/master.m3u8 → "1080"
  final segments = url.split('/');
  for (final segment in segments.reversed) {
    if (RegExp(r'\d{3,4}p?').hasMatch(segment)) {
      return segment;
    }
  }

  return 'Auto'; // Tespit edilemezse
}
```

### Örnek URL'ler
```
✅ https://cdn.com/video_1080p.m3u8        → "1080p"
✅ https://cdn.com/hls/720/master.m3u8     → "720p"
✅ https://cdn.com/4k/stream.mpd           → "4K"
✅ https://cdn.com/fullhd/video.mp4        → "1080p"
✅ https://cdn.com/encrypted/abc123.m3u8   → "Auto"
```

## 📊 Duplicate Kontrolü

### İki Katmanlı Sistem

#### 1. Local Cache (Hızlı)
```dart
final Set<String> _savedVideoUrls = {};
final Set<String> _savedSubtitleUrls = {};

// İlk kontrol: Memory'de var mı?
if (_savedVideoUrls.contains(url)) {
  debugPrint('⏭️  IFRAME PLAYER: Video zaten kaydedildi');
  return;
}
```

#### 2. Database Query (Kesin)
```dart
// İkinci kontrol: Database'de var mı?
final existingSources = await _apiService.getFilmKaynaklari(filmId);
final alreadyExists = existingSources.any((k) => k.url == url);

if (alreadyExists) {
  _savedVideoUrls.add(url); // Cache'e ekle
  return;
}
```

### Neden İki Katman?
- **Performance**: Local cache çok hızlı (O(1))
- **Accuracy**: Database kesin sonuç verir
- **Efficiency**: Gereksiz API call'ları önler

## 🧪 Test Senaryoları

### Senaryo 1: İlk Kaynak Yakalama
```
1. Iframe player aç
2. Video yakalandığında console'da:
   🎥 Video element bulundu: https://...
   ✅ IFRAME PLAYER: Video kaydedildi: fullhdfilmizlesene - 1080p [ELEMENT]
3. Database'i kontrol et
   ✅ Yeni kayıt oluştu
```

### Senaryo 2: Duplicate Kaynak
```
1. Aynı iframe player'ı tekrar aç
2. Aynı video yakalanır
3. Console'da:
   ⏭️  IFRAME PLAYER: Video zaten kaydedildi: https://...
4. Database'e yeni kayıt EKLENMEZ
```

### Senaryo 3: Multiple Video Sources
```
1. Iframe player birden fazla kalite sunar
2. Her biri ayrı ayrı yakalanır:
   ✅ fullhdfilmizlesene - 1080p [XHR]
   ✅ fullhdfilmizlesene - 720p [XHR]
   ✅ fullhdfilmizlesene - 480p [XHR]
3. Database'de 3 ayrı kayıt
```

### Senaryo 4: Subtitle Capture
```
1. Iframe player altyazı yükler
2. Console'da:
   📝 Altyazı URL yakalandı: https://.../subtitle.vtt
   ✅ IFRAME PLAYER: Altyazı kaydedildi: fullhdfilmizlesene - WebVTT
3. film_altyazilari tablosunda yeni kayıt
```

## 🔗 API Entegrasyonu

### Video Kaydetme
```http
POST /api/film_kaynaklari:create
Content-Type: application/json
Authorization: Bearer {token}

{
  "film_id": {"id": 123},
  "baslik": "fullhdfilmizlesene - 1080p [XHR]",
  "url": "https://photostack.net/m9/nUyyZKMd...",
  "is_iframe": false
}
```

### Altyazı Kaydetme
```http
POST /api/film_altyazilari:create
Content-Type: application/json
Authorization: Bearer {token}

{
  "filmler": {"id": 123},
  "baslik": "fullhdfilmizlesene - WebVTT",
  "url": "https://example.com/subtitles.vtt"
}
```

## 📝 Debug Logları

### Başarılı Kaydetme
```
🎥 Video element bulundu: https://photostack.net/m9/nUyyZKMd...
✅ IFRAME PLAYER: Video kaydedildi: fullhdfilmizlesene - 1080p [ELEMENT]
✅ IFRAME PLAYER: Video ID: 456

📝 Altyazı URL yakalandı: https://example.com/subtitle.vtt
✅ IFRAME PLAYER: Altyazı kaydedildi: fullhdfilmizlesene - WebVTT
✅ IFRAME PLAYER: Altyazı ID: 789
```

### Duplicate Kontrolü
```
⏭️  IFRAME PLAYER: Video zaten kaydedildi: https://...
⏭️  IFRAME PLAYER: Video veritabanında zaten var

⏭️  IFRAME PLAYER: Altyazı zaten kaydedildi: https://...
⏭️  IFRAME PLAYER: Altyazı veritabanında zaten var
```

### Hata Durumu
```
❌ IFRAME PLAYER: Video kaydetme hatası: Exception: Failed to create kaynak
❌ IFRAME PLAYER: Altyazı kaydetme hatası: Exception: Failed to create altyazi
```

## 🚀 Faydaları

### 1. Kalıcı Kaynak Havuzu
- Her film için zengin kaynak koleksiyonu
- Kullanıcı iframe'i kapattıktan sonra bile kaynaklar kalıyor
- Sonraki ziyaretlerde hemen kullanılabilir

### 2. Otomatik Cache
- Background source collector + Iframe player = Kapsamlı toplama
- Tüm olası kaynaklar otomatik toplanıyor
- Manuel ekleme gereksiz

### 3. Kullanıcı Deneyimi
- Daha fazla kaynak seçeneği
- Daha hızlı başlama (cached sources)
- Daha az iframe loading

### 4. Veri Zenginliği
- Her kaynak için method bilgisi (XHR, FETCH, ELEMENT)
- Kalite bilgisi (1080p, 720p, 4K)
- Format bilgisi (WebVTT, SRT)

## 🔮 Gelecek İyileştirmeler

- [ ] Kaynak güvenilirlik skoru (hangi method daha stabil?)
- [ ] Otomatik kalite tespiti (video header'larından)
- [ ] Subtitle language detection (Türkçe, İngilizce)
- [ ] CDN performance tracking
- [ ] Source expiration check (eski kaynakları temizle)

## 📚 İlgili Dosyalar

- `/lib/screens/iframe_player_screen.dart` - Ana implementasyon
- `/lib/services/api_service.dart` - API calls
- `/lib/models/kaynak.dart` - Kaynak modeli
- `/lib/models/altyazi.dart` - Altyazı modeli

---

**Durum**: ✅ Tamamlandı
**Tarih**: 16 Ekim 2025
**Geliştirici**: @erdoganyesil
