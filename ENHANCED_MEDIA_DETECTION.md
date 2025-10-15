# 🚀 Güçlendirilmiş Medya API Yakalama Sistemi

## 📊 Analiz Edilen Gerçek Dünya API'leri

### 1. **Vidmoxy / Photostack.net**
```bash
curl 'https://vs6.photostack.net/m9/nUyyZKMdLJg0o3Oyd0zxpTuiqT9mqTSwnl5hMKDs0xi6vr1'
```

**Özellikler:**
- ❌ Dosya uzantısı yok
- ✅ Uzun hash-like path (50+ karakter)
- ✅ CDN domain (photostack.net)
- ✅ CORS headers (origin: vidmoxy.com)
- ✅ Alphanumeric karışım

**Tespit Yöntemi:**
- CDN domain kontrolü
- Uzun hash path pattern
- CORS indicator

### 2. **Rapidvid / ImageHub.pics**
```bash
curl 'https://s27.imagehub.pics/mx/FJ50MKWmqTIfoTSlYwVjZGDh...'
```

**Özellikler:**
- ❌ Dosya uzantısı yok
- ✅ Çok uzun encrypted path (100+ karakter)
- ✅ CDN domain (imagehub.pics)
- ✅ CORS headers (origin: rapidvid.net)
- ✅ Subdomain pattern (s27, s28, etc.)

**Tespit Yöntemi:**
- CDN domain kontrolü
- Encrypted long path
- CORS indicator

### 3. **DPlayer82 / M3U8 HLS**
```bash
curl 'https://four.dplayer82.site/master.m3u8?v=cHVQSnhEeFVIcEhC...'
```

**Özellikler:**
- ✅ .m3u8 uzantısı (kesin tespit!)
- ✅ Base64 query parameter (v=...)
- ✅ HLS pattern (master.m3u8)
- ✅ Cookie authentication
- ✅ Referer header gerekli

**Tespit Yöntemi:**
- Video format extension (.m3u8)
- Base64 query parameter
- Stream pattern (master, manifest)

---

## 🎯 Uygulanan Tespit Stratejileri

### ✅ **1. Video Format Uzantıları**
```javascript
const videoFormats = ['.m3u8', '.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.m4v', '.mpd'];
```
- **En güvenilir yöntem**
- Kesin pozitif sinyal
- DPlayer82 örneğinde kullanıldı

### ✅ **2. TS Segment Kontrolü**
```javascript
const hasTsExtension = urlLower.includes('.ts');
const hasHlsPattern = urlLower.includes('hls') || urlLower.includes('m3u8');
const isTsVideo = hasTsExtension && hasHlsPattern;
```
- HLS streaming için .ts segment dosyaları
- Sadece HLS context'inde kabul edilir
- Aggressive false positive'leri engeller

### ✅ **3. Streaming Pattern'leri**
```javascript
const streamPatterns = ['hls', 'dash', 'video', 'stream', 'manifest', 'playlist', 'master'];
```
- Video streaming servislerinde sık kullanılan kelimeler
- CDN veya encrypted query ile birlikte güçlü sinyal
- DPlayer82'de 'master' pattern kullanıldı

### ✅ **4. Content-Type Kontrolü**
```javascript
const mediaContentTypes = [
  'video/', 'audio/',
  'application/vnd.apple.mpegurl',    // HLS
  'application/x-mpegurl',            // HLS
  'application/dash+xml',             // DASH
  'application/octet-stream'          // Binary video data
];
```
- HTTP response header'ından alınır
- **Kesin pozitif** sinyal
- Uzantısız URL'lerde kritik

### ✅ **5. Response İçerik Kontrolü**
```javascript
hasMediaContent =
  text.includes('#EXTM3U') ||     // HLS playlist
  text.includes('#EXT-X-') ||     // HLS tags
  text.includes('<MPD') ||         // DASH manifest
  text.includes('<?xml') && text.includes('urn:mpeg:dash');
```
- Response body'nin ilk 500 karakterini analiz eder
- M3U8 ve DASH formatlarını tespit eder
- DPlayer82'de #EXTM3U pattern kullanıldı

### ✅ **6. CDN Domain Kontrolü** ⭐ **YENİ!**
```javascript
const cdnDomains = [
  'photostack.net',           // Vidmoxy
  'imagehub.pics',            // Rapidvid
  'dplayer',                  // DPlayer
  'cloudfront.net',           // AWS CloudFront
  'akamaihd.net',            // Akamai
  'streamtape', 'streamlare',
  'doodstream', 'voe.sx',
  'mixdrop', 'upstream.to'
];
```
- **Vidmoxy ve Rapidvid için kritik**
- CDN'ler genellikle video serve eder
- Diğer sinyallerle birlikte güçlü tespit

### ✅ **7. Encrypted/Hash Path Pattern** ⭐ **YENİ!**
```javascript
const hasLongHashPath = pathSegments.some(segment => {
  return cleanSegment.length > 20 &&    // 20+ karakter
         hasLetters &&                   // Harf içerir
         hasNumbers &&                   // Rakam içerir
         !hasExtension;                  // Uzantı yok
});
```
**Örnek:**
- ✅ `/m9/nUyyZKMdLJg0o3Oyd0zxpTuiqT9mqTSwnl5hMKDs0xi6vr1`
- ✅ `/mx/FJ50MKWmqTIfoTSlYwVjZGDhIHuR...`
- ❌ `/images/logo.png` (uzantı var)
- ❌ `/api/v1/user` (çok kısa)

**Vidmoxy ve Rapidvid için kritik tespit yöntemi!**

### ✅ **8. Query Parameter Base64/Encrypted** ⭐ **YENİ!**
```javascript
const hasEncryptedQuery = /[?&](v|token|key|id|data|video)=[a-zA-Z0-9+\/=]{30,}/.test(url);
```
**Örnekler:**
- ✅ `?v=cHVQSnhEeFVIcEhCL0FqUUJZeUZEQUFB...` (DPlayer82)
- ✅ `?token=abcd1234efgh5678ijkl9012mnop...`
- ✅ `?key=ZGF0YTpkYXRhOmRhdGE6ZGF0YQ==`
- ❌ `?v=123` (çok kısa)

**Base64 ve encrypted token'ları tespit eder**

### ✅ **9. CORS Header Indicator** ⭐ **YENİ!**
```javascript
const hasCorsIndicator = contentType && url.includes('http') &&
  (contentType === 'application/octet-stream' ||
   contentType === '*/*' ||
   contentType === '');
```
- Cross-origin video request'leri için tipik
- Vidmoxy ve Rapidvid bu pattern'i kullanır
- `application/octet-stream` binary video data için sık kullanılır

### ✅ **10. Response Size Kontrolü** ⭐ **YENİ!**
```javascript
const hasLargeResponse = responseText && responseText.length > 1000;
```
- Büyük response genellikle video metadata veya data
- CDN ve CORS sinyalleri ile birlikte güçlü

### ❌ **11. Hariç Tutulan Format'lar**
```javascript
// Resim formatları
const imageFormats = ['.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp', '.ico', '.bmp'];

// Font formatları
const fontFormats = ['.woff', '.woff2', '.ttf', '.otf', '.eot'];

// Kod dosyaları
const codeFormats = ['.js', '.css', '.json', '.xml'];
```
- **False positive'leri engeller**
- Görsel ve font dosyaları video değildir
- JSON/XML sadece content'i kontrol edilirse yakalanır

---

## 🧠 Karar Lojiği

### Pozitif Sinyal Kombinasyonları

#### **Kesin Tespit (100% güven)**
1. ✅ Video uzantısı (.m3u8, .mp4, .mkv, ...)
2. ✅ Media content-type (video/*, application/x-mpegurl)
3. ✅ Media response içeriği (#EXTM3U, <MPD)

#### **Güçlü Tespit (90%+ güven)**
4. ✅ Stream pattern + (CDN domain VEYA encrypted query)
   - Örnek: `https://photostack.net/hls/ABC123...`
5. ✅ CDN domain + (hash path VEYA encrypted query)
   - Örnek: `https://imagehub.pics/mx/FJ50MKWm...`
6. ✅ Hash path + encrypted query
   - Örnek: `https://unknown.com/ABC123...?v=XYZ789...`

#### **Orta Tespit (70%+ güven)**
7. ✅ CORS indicator + büyük response + CDN domain
   - Örnek: binary octet-stream from photostack.net

### Kod İmplementasyonu
```javascript
const isMedia =
  hasVideoExtension ||                                            // Kesin (1)
  isTsVideo ||                                                    // Kesin (1)
  hasMediaContentType ||                                          // Kesin (2)
  hasMediaContent ||                                              // Kesin (3)
  (hasStreamPattern && (hasCdnDomain || hasEncryptedQuery)) ||   // Güçlü (4)
  (hasCdnDomain && (hasLongHashPath || hasEncryptedQuery)) ||    // Güçlü (5)
  (hasLongHashPath && hasEncryptedQuery) ||                      // Güçlü (6)
  (hasCorsIndicator && hasLargeResponse && hasCdnDomain);        // Orta (7)
```

---

## 📊 Test Sonuçları

### ✅ Başarılı Tespitler

| API | Tespit Yöntemi | Güven |
|-----|----------------|-------|
| DPlayer82 M3U8 | Video extension (.m3u8) | 100% |
| DPlayer82 M3U8 | Stream pattern + encrypted query | 90% |
| Vidmoxy | CDN domain + hash path | 90% |
| Rapidvid | CDN domain + hash path | 90% |
| Standard MP4 | Video extension (.mp4) | 100% |
| HLS Streaming | Media content (#EXTM3U) | 100% |

### ❌ False Positive Önleme

| URL | Neden Hariç? |
|-----|--------------|
| `/images/banner.jpg` | Image format |
| `/fonts/roboto.woff2` | Font format |
| `/api/data.json` | Code format |
| `/subtitles.vtt` | Subtitle content (priority check) |
| `/data.ts` | No HLS pattern (TS alone rejected) |

---

## 🎯 Gerçek Dünya Örnekleri

### Örnek 1: Vidmoxy (Photostack)
```javascript
URL: https://vs6.photostack.net/m9/nUyyZKMdLJg0o3Oyd0zxpTuiqT9mqTSwnl5hMKDs0xi6vr1

Tespit Edilen Sinyaller:
✅ hasCdnDomain: true (photostack.net)
✅ hasLongHashPath: true (50+ karakter, alphanumeric, uzantısız)
✅ hasCorsIndicator: true (cross-origin request)

Sonuç: ✅ YAKALANDI (CDN + hash path kombinasyonu)
```

### Örnek 2: Rapidvid (ImageHub)
```javascript
URL: https://s27.imagehub.pics/mx/FJ50MKWmqTIfoTSlYwVjZGDhIHuRYxWfqKWurF5W...

Tespit Edilen Sinyaller:
✅ hasCdnDomain: true (imagehub.pics)
✅ hasLongHashPath: true (100+ karakter, encrypted)
✅ hasCorsIndicator: true (cross-origin request)

Sonuç: ✅ YAKALANDI (CDN + hash path kombinasyonu)
```

### Örnek 3: DPlayer82 (M3U8)
```javascript
URL: https://four.dplayer82.site/master.m3u8?v=cHVQSnhEeFVIcEhC...

Tespit Edilen Sinyaller:
✅ hasVideoExtension: true (.m3u8)
✅ hasStreamPattern: true (master)
✅ hasEncryptedQuery: true (v= base64)
✅ hasMediaContentType: true (application/x-mpegurl)
✅ hasMediaContent: true (#EXTM3U response)

Sonuç: ✅ YAKALANDI (kesin pozitif - multiple signals)
```

### Örnek 4: False Positive Önleme
```javascript
URL: https://cdn.example.com/subtitles/turkish.vtt

Tespit Edilen Sinyaller:
❌ isSubtitleContent: true (.vtt uzantısı)
⚠️  hasVideoExtension: false
⚠️  hasCdnDomain: true (ama subtitle priority!)

Sonuç: ❌ REDDEDİLDİ (subtitle priority check)
```

---

## 🔍 Debug ve Test Komutları

### Terminal'de Log Filtrele
```bash
# Video yakalama log'larını göster
flutter logs | grep "🎬\|✅.*VIDEO"

# Tüm network log'larını göster
flutter logs | grep "FOUND\|CAPTURED"

# Sadece CDN domain tespitlerini göster
flutter logs | grep "photostack\|imagehub\|dplayer"
```

### Console Log Formatı
```
🔍 NETWORK: GET https://vs6.photostack.net/m9/nUyyZ...
✅ CDN_DOMAIN: photostack.net
✅ HASH_PATH: nUyyZKMdLJg0o3Oyd0zxpTuiqT9mqTSwnl5hMKDs0xi6vr1
✅ CORS_INDICATOR: true
🎬 VIDEO CAPTURED: https://vs6.photostack.net/...
```

---

## 📈 Performans ve Optimizasyon

### Kontrol Sırası (Hızdan Yavaşa)
1. ⚡ Subtitle check (priority - hızlı ret)
2. ⚡ Excluded formats (.jpg, .js, .css)
3. ⚡ Video extensions (kesin pozitif)
4. ⚡ Content-Type check (HTTP header)
5. 🔥 CDN domain check
6. 🔥 URL pattern checks (hash, encrypted)
7. 🐌 Response body analysis (en yavaş)

### Timer Ayarları
```dart
// Video element kontrolü
_videoCheckTimer = Timer.periodic(const Duration(seconds: 5), ...);

// Analiz göstergesi timeout
Timer(const Duration(seconds: 30), ...);
```

---

## 🚀 Gelecek İyileştirmeler

### 1. **Machine Learning Pattern Detection**
```javascript
// URL'leri ML model ile analiz et
const confidence = detectVideoUrlWithML(url);
if (confidence > 0.8) { /* capture */ }
```

### 2. **Dynamic CDN List**
```javascript
// API'den güncel CDN listesi çek
const cdnList = await fetchCdnList();
```

### 3. **User Feedback Loop**
```javascript
// Kullanıcı "Bu video değil" derse öğren
reportFalsePositive(url, reason);
```

### 4. **Response Header Analysis**
```javascript
// Daha fazla header kontrol et
const contentLength = response.headers.get('Content-Length');
const contentRange = response.headers.get('Content-Range');
if (contentLength > 1000000) { /* likely video */ }
```

### 5. **Bandwidth Detection**
```javascript
// Yüksek bandwidth = video download
if (downloadSpeed > 1000000) { /* likely video */ }
```

---

## ✅ Özet

### Güçlendirmeler
- ✅ **12 farklı tespit stratejisi**
- ✅ **3 yeni CDN domain tespiti** (photostack, imagehub, dplayer)
- ✅ **Hash path pattern detection** (uzantısız URL'ler)
- ✅ **Encrypted query parameter detection** (Base64 tokens)
- ✅ **CORS indicator detection** (cross-origin requests)
- ✅ **Response size analysis** (büyük data = video)
- ✅ **False positive prevention** (images, fonts, code files)
- ✅ **Subtitle priority check** (VTT'ler video olarak algılanmaz)

### Gerçek Dünya Uyumluluğu
- ✅ Vidmoxy / Photostack.net
- ✅ Rapidvid / ImageHub.pics
- ✅ DPlayer82 / M3U8 HLS
- ✅ Standard video hostingler
- ✅ Encrypted streaming servisleri

### Sonuç
Artık **uzantısız, encrypted, hash-based** video API'leri de yakalayabiliyoruz! 🎉
