# 🎬 VTT Altyazı Desteği ve Gelişmiş Hata Ayıklama

## 🐛 Sorun: Web'den Yakalanan Altyazılar Çalışmıyordu

### Orijinal Sorun:
Kullanıcı iframe'den yakalanan VTT altyazılarını video player'da kullanamıyordu.

### Kök Neden:
Player'daki `_parseSrtFile()` fonksiyonu **sadece SRT formatını** destekliyordu, ancak web'den çoğunlukla **VTT formatında** altyazılar yakalanıyor.

---

## 📋 SRT vs VTT Format Farklılıkları

### SRT (SubRip) Format:
```srt
1
00:00:10,500 --> 00:00:13,000
Bu bir SRT altyazısıdır

2
00:00:13,000 --> 00:00:16,000
İkinci satır
```

**Özellikler:**
- ✅ Satır numarası var (1, 2, 3...)
- ✅ Virgül kullanır (`,`) millisaniye ayırıcı olarak
- ✅ Çift newline ile ayrılır
- ❌ Başlık satırı yok

### VTT (WebVTT) Format:
```vtt
WEBVTT

00:00:10.500 --> 00:00:13.000
Bu bir VTT altyazısıdır

00:00:13.000 --> 00:00:16.000
İkinci satır
```

**Özellikler:**
- ✅ `WEBVTT` başlık satırı var
- ✅ Nokta kullanır (`.`) millisaniye ayırıcı olarak
- ✅ Satır numarası opsiyonel
- ✅ HTML-benzeri tag'ler desteklenir (`<i>`, `<b>`, `<c>`)
- ✅ Çift newline ile ayrılır

---

## ✨ Uygulanan Çözümler

### 1. **Çift Format Desteği**

#### A) Format Tespiti
```dart
// URL'den format tespiti
final isVtt = urlLower.contains('.vtt');
final isSrt = urlLower.contains('.srt');

// İçerikten format tespiti (daha güvenilir)
final contentHasWebVtt = content.trim().startsWith('WEBVTT');
final isVttFormat = isVtt || contentHasWebVtt;
```

#### B) Dinamik Parser Seçimi
```dart
if (isVttFormat) {
  return _parseVttContent(content);
} else {
  return _parseSrtContent(content);
}
```

### 2. **VTT Parser (`_parseVttContent`)**

#### Özellikler:
- ✅ `WEBVTT` başlığını ve metadata'yı atlar
- ✅ Hem nokta (`.`) hem virgül (`,`) formatlarını destekler
- ✅ Satır numarası olmadan çalışır
- ✅ HTML tag'lerini temizler (`<c>`, `<v>`, `<i>`, `<b>`)
- ✅ HTML entity'leri dönüştürür (`&nbsp;`, `&amp;`)
- ✅ Timestamp satırını otomatik bulur

#### Regex Pattern:
```dart
r'(\d{2}):(\d{2}):(\d{2})[\.,](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[\.,](\d{3})'
```
- `[\.,]` → Hem nokta hem virgülü kabul eder

### 3. **SRT Parser (`_parseSrtContent`)**

Orijinal parser ayrı fonksiyon olarak taşındı:
- ✅ Satır numaralı SRT formatını destekler
- ✅ Virgül (`,`) ayırıcıyı kullanır
- ✅ Mevcut kod ile uyumlu

### 4. **VTT Tag Temizleyici (`_cleanVttTags`)**

VTT'ye özel HTML-benzeri tag'leri kaldırır:

```dart
String _cleanVttTags(String text) {
  // <c.yellow>, <v Speaker>, <i>, <b>, <u> gibi tag'leri kaldır
  var cleaned = text.replaceAll(RegExp(r'<[^>]+>'), '');

  // HTML entity'leri temizle
  cleaned = cleaned
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"');

  return cleaned.trim();
}
```

**Örnek:**
```
Giriş: "<c.yellow>Merhaba</c> &amp; <i>dünya</i>"
Çıkış: "Merhaba & dünya"
```

### 5. **Gelişmiş Hata Ayıklama**

#### A) Detaylı Debug Logları
```dart
debugPrint('📥 Alt yazı indiriliyor: $url');
debugPrint('🎬 Format: ${isVtt ? "VTT" : isSrt ? "SRT" : "UNKNOWN"}');
debugPrint('✅ Alt yazı indirildi: ${response.body.length} byte');
debugPrint('🎬 İçerik format: ${isVttFormat ? "VTT" : "SRT"}');
debugPrint('✅ ${subtitles.length} VTT alt yazı parse edildi');
```

#### B) HTTP Status Kontrolü
```dart
if (response.statusCode != 200) {
  debugPrint('❌ Alt yazı indirilemedi: HTTP ${response.statusCode}');
  debugPrint('❌ URL: $url');
  return [];
}
```

#### C) İçerik Boşluk Kontrolü
```dart
if (content.isEmpty) {
  debugPrint('❌ Alt yazı içeriği boş');
  return [];
}
```

#### D) Stack Trace
```dart
catch (e, stackTrace) {
  debugPrint('❌ Alt yazı parse hatası: $e');
  debugPrint('❌ Stack trace: $stackTrace');
  return [];
}
```

### 6. **Kullanıcı Bildirimleri İyileştirildi**

#### Başarısız Yükleme:
```dart
SnackBar(
  content: Column(
    children: [
      Text('❌ Alt yazı yüklenemedi'),
      Text('Olası nedenler: CORS, format hatası, veya dosya bulunamadı'),
      Text(altyaziUrl), // URL gösterilir
    ],
  ),
  backgroundColor: Colors.red,
  duration: Duration(seconds: 4), // Daha uzun süre
)
```

#### Başarılı Yükleme:
```dart
SnackBar(
  content: Text('✅ ${subtitles.length} alt yazı yüklendi: ${altyazi.baslik}'),
  backgroundColor: Colors.green,
)
```

---

## 🔍 Olası Hata Nedenleri ve Çözümleri

### 1. **CORS (Cross-Origin Resource Sharing) Hatası**

#### Neden:
Web tarayıcıları ve HTTP istemcileri, güvenlik nedeniyle farklı domain'lerden kaynak indirmeyi engelleyebilir.

#### Belirti:
- HTTP 403 (Forbidden) veya 0 (Network Error)
- Console'da CORS hatası

#### Çözüm:
```dart
// http paketinde CORS bypass (sınırlı)
final response = await http.get(
  Uri.parse(url),
  headers: {
    'User-Agent': 'Mozilla/5.0',
    'Origin': 'https://example.com',
  },
);
```

**Not:** Mobil uygulamalarda CORS genellikle sorun olmaz.

### 2. **Format Hatası**

#### Neden:
- Bozuk VTT/SRT dosyası
- Beklenmeyen karakter encoding (UTF-8, Latin1, CP1254)
- Yanlış timestamp formatı

#### Belirti:
```
❌ VTT parse hatası: FormatException
✅ 0 alt yazı parse edildi
```

#### Çözüm:
Parser artık esnek regex kullanıyor (`[\.,]`), farklı formatları destekliyor.

### 3. **Encoding Sorunu (Türkçe Karakterler)**

#### Neden:
Altyazı dosyası Latin1 veya CP1254 encoding'de ama UTF-8 olarak okunuyor.

#### Belirti:
- Türkçe karakterler bozuk (Ã¼ → ü)
- ş, ğ, ı harfleri yanlış

#### Çözüm:
```dart
// http paketinde encoding belirt
final response = await http.get(
  Uri.parse(url),
  headers: {'Accept-Charset': 'utf-8, iso-8859-9'},
);

// Veya manuel decode:
import 'dart:convert';
final content = latin1.decode(response.bodyBytes);
```

### 4. **404 - Dosya Bulunamadı**

#### Neden:
URL geçersiz veya dosya silinmiş.

#### Belirti:
```
❌ Alt yazı indirilemedi: HTTP 404
```

#### Çözüm:
- URL'yi kontrol edin
- Log'larda gösterilen URL'yi tarayıcıda açıp test edin

### 5. **Timeout**

#### Neden:
Sunucu yavaş veya network bağlantısı zayıf.

#### Çözüm:
```dart
final response = await http.get(
  Uri.parse(url),
).timeout(Duration(seconds: 10));
```

---

## 📊 Test Senaryoları

### Test 1: VTT Altyazı
1. ✅ İframe'den VTT altyazılı video aç
2. ✅ "X Kaynak" badge'ine tıkla
3. ✅ Kaynağı seç ve "Oynat"a bas
4. ✅ Player'da altyazı menüsünü aç
5. ✅ Yakalanan VTT altyazısını seç
6. ✅ Debug log'larını kontrol et:
   ```
   📥 Alt yazı indiriliyor: https://...subtitle.vtt
   🎬 Format: VTT
   ✅ Alt yazı indirildi: 52480 byte
   🎬 İçerik format: VTT
   ✅ 324 VTT alt yazı parse edildi
   ```
7. ✅ Videoda altyazıların göründüğünü doğrula

### Test 2: SRT Altyazı
1. ✅ API'den gelen SRT altyazılı film aç
2. ✅ Player'da altyazı menüsünü aç
3. ✅ SRT altyazısını seç
4. ✅ Debug log'larını kontrol et:
   ```
   📥 Alt yazı indiriliyor: https://...subtitle.srt
   🎬 Format: SRT
   ✅ 256 SRT alt yazı parse edildi
   ```

### Test 3: Hatalı Altyazı
1. ✅ Geçersiz URL ile altyazı seç
2. ✅ Kırmızı SnackBar görmeli:
   ```
   ❌ Alt yazı yüklenemedi
   Olası nedenler: CORS, format hatası, veya dosya bulunamadı
   https://...invalid-url.vtt
   ```
3. ✅ Debug log'larında hata detayını gör

### Test 4: Çoklu Format Karışımı
1. ✅ Hem VTT hem SRT altyazıları olan film
2. ✅ Her ikisini de dene
3. ✅ İkisi de çalışmalı

---

## 🎯 Desteklenen VTT Özellikleri

### ✅ Destekleniyor:
- [x] `WEBVTT` başlığı
- [x] Nokta (`.`) ve virgül (`,`) ayırıcılar
- [x] Satır numarasız format
- [x] HTML tag'leri (`<c>`, `<v>`, `<i>`, `<b>`, `<u>`)
- [x] HTML entity'ler (`&nbsp;`, `&amp;`, etc.)
- [x] Çift newline ayırıcılar
- [x] Metadata satırları (atlanır)

### ❌ Desteklenmiyor (Şimdilik):
- [ ] VTT styling (`::cue`, `color`, `position`)
- [ ] VTT cue settings (line, position, size, align)
- [ ] VTT chapters ve metadata
- [ ] VTT NOTE blokları

**Not:** Temel altyazı gösterimi için mevcut destek yeterlidir.

---

## 🔧 Gelecek İyileştirmeler

1. **Encoding Desteği:**
   ```dart
   // Latin1, CP1254, UTF-8 otomatik tespiti
   final encoding = detectEncoding(response.bodyBytes);
   final content = encoding.decode(response.bodyBytes);
   ```

2. **CORS Proxy:**
   ```dart
   // CORS sorunu yaşanan URL'ler için proxy
   final proxyUrl = 'https://cors-proxy.com/?url=$originalUrl';
   ```

3. **Cache Sistemi:**
   ```dart
   // İndirilen altyazıları cache'le
   final cached = await _subtitleCache.get(url);
   if (cached != null) return cached;
   ```

4. **VTT Styling:**
   ```dart
   // VTT cue settings'i destekle
   final cueSettings = _parseCueSettings(timelineLine);
   ```

5. **Hata Raporlama:**
   ```dart
   // Kullanıcıya hatalı altyazıları raporlama seçeneği sun
   if (subtitles.isEmpty) {
     showErrorReportDialog(url, response.statusCode);
   }
   ```

---

## 📝 Debug Komutları

### Terminal'de Log Filtrele:
```bash
# Sadece altyazı log'larını göster
flutter logs | grep "📥\|🎬\|✅.*alt"

# Hataları göster
flutter logs | grep "❌.*alt"
```

### Log Çıktısı Örneği:
```
I/flutter (12345): 📥 Alt yazı indiriliyor: https://example.com/subtitle.vtt
I/flutter (12345): 🎬 Format: VTT
I/flutter (12345): ✅ Alt yazı indirildi: 52480 byte
I/flutter (12345): 🎬 İçerik format: VTT
I/flutter (12345): ✅ 324 VTT alt yazı parse edildi
I/flutter (12345): 📝 Altyazı yükleniyor: WebVTT 1
I/flutter (12345): 📝 URL: https://example.com/subtitle.vtt
I/flutter (12345): ✅ Altyazı değiştirildi: WebVTT 1
```

---

## ✅ Özet

### Sorun:
Web'den yakalanan VTT altyazılar player'da çalışmıyordu.

### Neden:
Parser sadece SRT formatını destekliyordu.

### Çözüm:
1. ✅ VTT parser eklendi
2. ✅ Format otomatik tespit ediliyor (URL + içerik)
3. ✅ VTT tag'leri temizleniyor
4. ✅ Detaylı hata ayıklama eklendi
5. ✅ Kullanıcı bildirimleri iyileştirildi

### Sonuç:
Artık hem VTT hem SRT altyazılar sorunsuz çalışıyor! 🎉
