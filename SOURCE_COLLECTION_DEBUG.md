# Source Collection Debug Guide

## 🐛 Yapılan Düzeltmeler

### Sorun
Background source collector çok kısa sürede tamamlanıyordu ve kaynakları bulamıyordu.

### Kök Nedenler
1. ❌ JavaScript injection'dan sonra bekleme yok
2. ❌ iframe yüklenme süresi yetersiz
3. ❌ Video element kontrolü çok seyrek (3 saniye)
4. ❌ İframeler arası bekleme çok kısa (5 saniye)

### Çözümler

#### 1. JavaScript Injection Sonrası Bekleme ✅
```dart
// ÖNCE (Hatalı)
Timer(const Duration(seconds: 2), () async {
  await _injectJavaScript(controller);
});
// Method hemen bitti, toplama olmadan döndü!

// SONRA (Doğru)
await Future.delayed(const Duration(seconds: 3));
await _injectJavaScript(controller);

// Kaynakların toplanması için bekle (30 saniye)
await Future.delayed(const Duration(seconds: 30));
```

**Neden?**: Timer async çalışır ve method hemen return eder. `await Future.delayed` kullanarak methodun beklemesini sağladık.

#### 2. Periyodik Kontrol Artırıldı ✅
```javascript
// ÖNCE
setInterval(checkVideoElements, 3000); // 3 saniyede bir
checkVideoElements();

// SONRA
setInterval(checkVideoElements, 2000); // 2 saniyede bir

// İlk kontrolü hemen, sonra 5s, 10s, 15s'de tekrar
checkVideoElements();
setTimeout(checkVideoElements, 5000);
setTimeout(checkVideoElements, 10000);
setTimeout(checkVideoElements, 15000);
```

**Neden?**: Bazı iframeler video'yu geç yüklüyor. Birden fazla checkpoint ile yakalama şansı artıyor.

#### 3. Detaylı Debug Logging ✅
```dart
// Raw mesaj
debugPrint('📬 SOURCE COLLECTOR: Raw mesaj alındı: $message');

// Parse detayları
debugPrint('📨 SOURCE COLLECTOR: Parse edildi - Type: $type, Method: $method');
debugPrint('📨 SOURCE COLLECTOR: URL: $url');
debugPrint('📨 SOURCE COLLECTOR: Content-Type: $contentType');
```

**Neden?**: Neyin çalışıp çalışmadığını anlamak için detaylı log.

#### 4. İframe Progress Tracking ✅
```dart
for (int i = 0; i < iframeSources.length; i++) {
  debugPrint('🔍 SOURCE COLLECTION: [${i + 1}/${iframeSources.length}] Toplama başlatılıyor');
  await _sourceCollector.startCollecting(...);
  debugPrint('✅ SOURCE COLLECTION: [${i + 1}/${iframeSources.length}] Tamamlandı');
}
```

**Neden?**: Hangi iframe'in ne zaman işlendiğini görmek için.

## 🧪 Test Adımları

### 1. Hot Restart
```bash
# Terminal'de
flutter run -d localhost:5555
# sonra "R" tuşuna bas (hot restart)
```

### 2. Film Detay Sayfasına Git
```
1. Ana sayfada bir filme tıkla
2. Detay sayfası açılır
3. Console loglarını izle
```

### 3. Beklenen Log Akışı
```
🔍 SOURCE COLLECTION: 2 iframe kaynağı bulundu
🔍 SOURCE COLLECTION: [1/2] Toplama başlatılıyor: fullhdfilmizlesene
🔍 SOURCE COLLECTOR: Başlatılıyor...
🔍 Film ID: 123
🔍 Iframe URL: https://fullhdfilmizlesene...
✅ SOURCE COLLECTOR: Sayfa yüklendi: https://...
✅ SOURCE COLLECTOR: JavaScript injected
⏳ SOURCE COLLECTOR: 30 saniye bekleniyor...

[5 saniye sonra]
📬 SOURCE COLLECTOR: Raw mesaj alındı: {"type":"video",...}
📨 SOURCE COLLECTOR: Parse edildi - Type: video, Method: XHR
📨 SOURCE COLLECTOR: URL: https://photostack.net/m9/nUyyZKMd...
📹 SOURCE COLLECTOR: Yeni kaynak bulundu: fullhdfilmizlesene - 1080p
📤 Creating Kaynak: {...}
✅ Kaynak created: {...}
✅ SOURCE COLLECTION: 1 video kaynağı bulundu

[30 saniye sonra]
✅ SOURCE COLLECTOR: Toplama tamamlandı
✅ SOURCE COLLECTION: [1/2] Tamamlandı: fullhdfilmizlesene

[2. iframe için tekrar]
🔍 SOURCE COLLECTION: [2/2] Toplama başlatılıyor: hdfilmcehennemi
...
🎉 SOURCE COLLECTION: TÜM İFRAMELER TAMAMLANDI!
```

### 4. UI Kontrolü
```
✅ "Bulunan Kaynaklar" section görünür olmalı
✅ Loading spinner dönmeli (30 saniye boyunca)
✅ İlk kaynak 5-10 saniye içinde görünmeli
✅ Her kaynak "✅ Kaydedildi" badge'i ile görünmeli
✅ Video sayısı artmalı (Video: 1, Video: 2, ...)
```

## 🔍 Sorun Giderme

### Hiçbir Mesaj Gelmiyor
**Semptom**: 30 saniye bekliyor ama hiç "📬 Raw mesaj" logu yok

**Çözüm**:
1. JavaScript injection çalıştı mı kontrol et
2. Console'da `✅ SOURCE COLLECTOR JS: Hazır ve dinliyor...` görünmeli
3. iframe URL'i gerçekten açılabiliyor mu test et (tarayıcıda aç)

### Mesaj Geliyor Ama Parse Hatası
**Semptom**: `❌ SOURCE COLLECTOR: Mesaj parse hatası`

**Çözüm**:
1. Raw mesaj formatını kontrol et
2. JSON valid mi?
3. `type`, `url`, `contentType` field'ları var mı?

### Kaynak Buluyor Ama Database'e Kaydedemiyor
**Semptom**: `📹 Yeni kaynak bulundu` ama `❌ Create Kaynak Error`

**Çözüm**:
1. API token geçerli mi? (15 Ekim 2025 - 18 Ekim 2025 arası)
2. NocoBase servisi çalışıyor mu?
3. `film_kaynaklari` tablosunda izinler var mı?

### Duplicate Kaynaklar Eklenmiyor
**Semptom**: `⏭️ SOURCE COLLECTOR: Kaynak zaten var`

**Çözüm**:
✅ Bu normal! Duplicate kontrolü çalışıyor demek.
- Farklı bir filme git ve test et
- Veya veritabanından kaynakları sil ve tekrar dene

## 📊 Performans Metrikleri

### Başarılı Toplama
```
Toplam Süre: 30-60 saniye (iframe sayısına göre)
İlk Kaynak: 5-15 saniye
Memory: +50-100MB (WebView overhead)
CPU: Orta yük (JavaScript execution)
```

### Başarısız Toplama
```
Toplam Süre: 30 saniye (boş geçer)
Kaynak Sayısı: 0
Log: Sadece başlangıç ve bitiş logları
```

## 🚀 İyileştirme Önerileri

### Kısa Vadede
1. ✅ 30 saniye bekleme eklendi
2. ✅ Periyodik kontrol artırıldı
3. ✅ Detaylı logging eklendi

### Orta Vadede
- [ ] Paralel iframe loading (şimdi sıralı)
- [ ] Akıllı timeout (kaynak bulunca erken dur)
- [ ] Retry mekanizması (başarısız iframe'leri tekrar dene)

### Uzun Vadede
- [ ] Background service (uygulama kapanınca da çalışsın)
- [ ] WebSocket real-time streaming
- [ ] Machine learning ile kalite tespiti
- [ ] CDN önbellekleme

## 📝 Test Checklist

- [ ] Hot restart yapıldı mı?
- [ ] Film detay sayfası açıldı mı?
- [ ] Console logları görünüyor mu?
- [ ] "⏳ 30 saniye bekleniyor" logu var mı?
- [ ] 5-10 saniye içinde mesaj geldi mi?
- [ ] UI'da kaynak görünüyor mu?
- [ ] "✅ Kaydedildi" badge'i var mı?
- [ ] Database'de kayıt oluştu mu?
- [ ] 2. iframe de işlendi mi?

---

**Tarih**: 16 Ekim 2025
**Durum**: ✅ Düzeltildi
**Test**: Bekliyor
