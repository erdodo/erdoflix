# 🔧 VTT Altyazı Filtresi ve Sürekli İzleme Düzeltmeleri

## 🐛 Düzeltilen Sorunlar

### 1. **VTT Altyazıları Video Kaynağı Olarak Sayılıyordu**

#### Sorun:
- `.vtt` uzantılı altyazı dosyaları `_capturedVideoUrls` listesine ekleniyordu
- "X Kaynak" badge'inde altyazılar da sayılıyordu
- Kaynak seçim dialog'unda VTT dosyaları video olarak listeleniyordu

#### Çözüm:
JavaScript'te `isMediaContent()` fonksiyonunda **öncelik kontrolü** eklendi:

```javascript
function isMediaContent(url, responseText, contentType) {
  // ÖNEMLİ: Önce altyazı kontrolü yap - eğer altyazıysa video değildir!
  if (isSubtitleContent(url, responseText, contentType)) {
    return false; // Altyazıları hemen reddet
  }

  // Video kontrolleri...
}
```

#### Sonuç:
- ✅ VTT dosyaları sadece `_capturedSubtitles` listesine ekleniyor
- ✅ Video kaynakları ile karışmıyor
- ✅ Kaynak sayısı doğru gösteriliyor
- ✅ Altyazılar arka planda toplanmaya devam ediyor (player için)

---

### 2. **Aynı İframe İçinde 2. Video Yakalanmıyordu**

#### Sorun:
- Kullanıcı iframe içinde farklı bir videoya geçtiğinde
- `_checkVideoElements()` duruyordu (ilk URL yakalandıktan sonra)
- Timer iptal ediliyordu
- Yeni video kaynakları tespit edilmiyordu

#### Çözüm:

##### A) Timer Sürekli Çalışsın
```dart
// ÖNCE:
_videoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
  if (_capturedVideoUrl == null && !_showingDialog) {
    _checkVideoElements();
  } else if (_capturedVideoUrl != null) {
    timer.cancel(); // ❌ Duruyordu!
  }
});

// SONRA:
_videoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
  _checkVideoElements(); // ✅ Sürekli çalışıyor
});
```

##### B) `_checkVideoElements()` Concurrent Check Dışında Her Zaman Çalışsın
```dart
// ÖNCE:
void _checkVideoElements() async {
  if (_capturedVideoUrl != null || _showingDialog || _isCheckingVideo) {
    return; // ❌ İlk URL'den sonra duruyordu
  }
}

// SONRA:
void _checkVideoElements() async {
  if (_isCheckingVideo) {
    return; // ✅ Sadece concurrent çağrıları engelle
  }
}
```

##### C) Tüm URL'leri Topla, Dialog Sadece İlk Seferde Açılsın
```dart
if (urls.isNotEmpty) {
  // Tüm URL'leri listeye ekle
  for (final url in urls) {
    if (!_capturedVideoUrls.contains(trimmedUrl)) {
      setState(() {
        _capturedVideoUrls.add(trimmedUrl); // ✅ Hepsini topla
      });
    }
  }

  // Dialog sadece ilk seferde ve kullanıcı iptal etmediyse
  if (_capturedVideoUrl == null && !_userDismissedDialog) {
    // İlk dialog
  }
}
```

#### Sonuç:
- ✅ İframe içinde video değişse bile tespit ediliyor
- ✅ Tüm kaynaklar `_capturedVideoUrls` listesine ekleniyor
- ✅ Header badge gerçek zamanlı güncelleniyor
- ✅ Kullanıcı istediği zaman kaynak değiştirebiliyor

---

## 🎯 TS Segment Filtresi (Bonus Düzeltme)

### Sorun:
`.ts` uzantılı dosyalar (TypeScript, Transport Stream, vb.) çok agresif yakalanıyordu.

### Çözüm:
TS dosyaları **sadece HLS context'inde** kabul ediliyor:

```javascript
// TS sadece HLS pattern'i varsa kabul et
const hasTsExtension = urlLower.includes('.ts');
const hasHlsPattern = urlLower.includes('hls') ||
                      urlLower.includes('m3u8') ||
                      urlLower.includes('segment');
const isTsVideo = hasTsExtension && hasHlsPattern;

// Return'de kullan
return hasVideoExtension || isTsVideo || hasStreamPattern || ...;
```

### Sonuç:
- ✅ TypeScript dosyaları video olarak algılanmıyor
- ✅ Sadece gerçek HLS segment'leri yakalanıyor
- ✅ False positive'ler azaldı

---

## 📊 Davranış Akışı (Güncellenmiş)

### İframe Açıldığında:
```
1. ⏱️  Timer başlatılır (5 saniye periyot)
2. 🔍 JavaScript network interceptor aktif
3. 🔍 Periyodik video element kontrolü aktif
```

### Video/Altyazı Yakalandığında:
```
📹 Video URL yakalandı
   ├─ ✅ _capturedVideoUrls listesine ekle
   ├─ 📊 Header badge'i güncelle (X Kaynak)
   └─ 🔔 İlk seferde ve iptal edilmediyse → Dialog aç

📝 Altyazı URL yakalandı
   ├─ ✅ _capturedSubtitles listesine ekle
   ├─ ❌ Video listesine EKLEME (isMediaContent = false)
   └─ ❌ Dialog gösterme (altyazı için popup yok)
```

### İframe İçinde Video Değiştiğinde:
```
1. 🔄 Periyodik kontrol yeni video element'i bulur
2. ➕ _capturedVideoUrls listesine ekler
3. 📊 Header badge: "3 Kaynak" → "4 Kaynak"
4. 🔕 Yeni popup açılmaz (kullanıcı zaten bilgilendirildi)
5. 👆 Kullanıcı isterse badge'e tıklayıp seçer
```

### Kullanıcı Dialog İptal Ederse:
```
1. ❌ _userDismissedDialog = true
2. 🔄 Arka plan dinleme DEVAM EDER
3. 📊 Yeni kaynaklar badge'e eklenir
4. 🔕 Otomatik popup artık açılmaz
5. 👆 Manuel seçim için badge her zaman tıklanabilir
```

---

## 🔬 Test Senaryoları

### Test 1: VTT Filtresi
1. ✅ İframe'de VTT altyazılı video aç
2. ✅ Header'da kaynak sayısına bak
3. ✅ VTT dosyası sayılmamalı
4. ✅ Badge'e tıkla, VTT listede olmamalı
5. ✅ Player'da altyazılar mevcut olmalı

### Test 2: İframe İçinde Video Değiştirme
1. ✅ İframe player aç, ilk video başlasın
2. ✅ "İframe'de Kal" butonuna bas
3. ✅ İframe içinde başka videoya geç
4. ✅ 5-10 saniye bekle
5. ✅ Header badge'inin "2 Kaynak" gösterdiğini kontrol et
6. ✅ Badge'e tıkla, her iki kaynağı da görmeli

### Test 3: Çoklu Video Toplama
1. ✅ Playlist veya çoklu video içeren iframe aç
2. ✅ 30 saniye bekle (periyodik kontroller çalışsın)
3. ✅ Header badge sayısını kontrol et
4. ✅ Badge'e tıkla, tüm kaynakları gör
5. ✅ Farklı kaynakları dene (format göstergelerine bak)

### Test 4: TS Segment Filtresi
1. ✅ HLS stream içeren video aç
2. ✅ `.ts` segment'ler yakalanmalı
3. ✅ TypeScript dosyaları yakalanmamalı
4. ✅ Badge'de sadece geçerli video kaynakları

---

## 📝 Debug Logları

### Normal İşleyiş:
```
🔍 Media request detected: FETCH [video/mp2t]: https://example.com/segment1.ts
🎥 Toplam 1 video URL yakalandı

📝 Altyazı URL yakalandı: https://example.com/subtitle.vtt
(VTT video listesine EKLENMEDİ)

🎥 Video element bulundu: https://example.com/video2.m3u8
🎥 Toplam 2 video kaynağı
```

### VTT Filtresi:
```
🔍 Checking: https://example.com/subtitle.vtt
📝 isSubtitleContent = true
🎬 isMediaContent = false (rejected by subtitle check)
📝 Altyazı URL yakalandı: https://example.com/subtitle.vtt
```

### İframe İçinde Video Değişimi:
```
🎥 Video element bulundu: https://example.com/video1.m3u8
🎥 Toplam 1 video kaynağı

(5 saniye sonra)

🎥 Video element bulundu: https://example.com/video2.m3u8
🎥 Toplam 2 video kaynağı
```

---

## ✅ Tamamlanan İyileştirmeler

1. ✅ VTT altyazıları artık video kaynağı olarak sayılmıyor
2. ✅ İframe içinde video değişince tespit ediliyor
3. ✅ Periyodik kontrol sürekli çalışıyor (iptal edilmiyor)
4. ✅ Tüm kaynaklar arka planda toplanıyor
5. ✅ TS segment filtresi eklendi (HLS context kontrolü)
6. ✅ Altyazılar sessizce toplanıyor (popup açılmıyor)
7. ✅ Kaynak sayısı header'da doğru gösteriliyor
8. ✅ Manuel kaynak seçimi her zaman mevcut

---

## 🚀 Kullanım Önerileri

### Kullanıcı İçin:
1. **İlk popup'ı iptal edin** → Arka plan dinlemeye devam eder
2. **Video değiştirin** → Yeni kaynaklar otomatik toplanır
3. **Header badge'ine tıklayın** → Tüm kaynakları görün
4. **En iyi kaynağı seçin** → Format ve URL'e bakarak

### Geliştirici İçin:
1. **Debug log'larını izleyin** → `🎥`, `📝`, `🔍` emoji'leri
2. **Timer'ı iptal etmeyin** → Sürekli dinleme önemli
3. **Subtitle check'i önce yapın** → VTT filtresi kritik
4. **State management'a dikkat** → `_userDismissedDialog` flag'i
