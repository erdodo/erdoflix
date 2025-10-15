# 🎯 Iframe Arka Plan İzleme ve Kaynak Seçimi

## ✨ Yeni Özellikler

### 1. **Arka Plan İzleme Sistemi**
Kullanıcı ilk popup'ı iptal etse bile sistem arka planda video kaynaklarını izlemeye devam eder.

#### Davranış:
- ✅ **İlk yakalamada**: Popup otomatik açılır, 5 saniyelik countdown başlar
- ❌ **"İframe'de Kal" tıklanırsa**:
  - Popup kapanır
  - `_userDismissedDialog = true` flag'i set edilir
  - Otomatik popup artık gösterilmez
  - **Ama arka planda dinleme devam eder!**
- 📊 **Tüm kaynaklar toplanır**: `_capturedVideoUrls` listesine eklenir

### 2. **Header'da Kaynak Sayısı Badge**
Header'da yakalanan video kaynaklarının sayısını gösteren tıklanabilir bir badge.

#### Görünüm:
```
[🎬 video_library] X Kaynak
```

#### Özellikler:
- 🟣 Mor renk teması
- 📊 Gerçek zamanlı güncellenen sayı
- 👆 Tıklanabilir (kaynak seçim dialog'unu açar)
- 🎨 Diğer badge'lerle uyumlu tasarım

### 3. **Kaynak Seçim Dialog**
Yakalanan tüm video kaynaklarını listeleyen ve kullanıcının seçim yapmasını sağlayan popup.

#### Özellikler:
- 📋 **Liste Görünümü**: Tüm kaynaklar numaralı liste halinde
- 🎞️ **Format Göstergesi**: HLS (M3U8), MP4, TS Segment, DASH
- 🌐 **URL Önizleme**: İlk 2 satır, monospace font
- ✓ **Aktif Kaynak İşareti**: Şu an oynatılan kaynak yeşil highlight
- ▶️ **"Oynat" Butonu**: Her kaynak için ayrı buton
- 🎨 **Kart Tasarımı**: Her kaynak ayrı kart içinde

#### Dialog Yapısı:
```
┌─────────────────────────────────────┐
│ 🎬 X Kaynak Bulundu                 │
├─────────────────────────────────────┤
│ ┌───────────────────────────────┐   │
│ │ ▶ Kaynak 1                    │   │
│ │   [HLS (M3U8)]                │   │
│ │   https://example.com/...     │   │
│ │                      [Oynat]  │   │
│ └───────────────────────────────┘   │
│                                     │
│ ┌───────────────────────────────┐   │
│ │ ✓ Kaynak 2 (Aktif)           │   │
│ │   [MP4]                       │   │
│ │   https://example.com/...     │   │
│ │   ✓ Şu anda bu kaynak...      │   │
│ │                      [Oynat]  │   │
│ └───────────────────────────────┘   │
├─────────────────────────────────────┤
│                          [Kapat]   │
└─────────────────────────────────────┘
```

## 🔧 Teknik Detaylar

### State Variables
```dart
List<String> _capturedVideoUrls = [];     // Tüm video URL'leri
bool _userDismissedDialog = false;        // İptal flag'i
```

### Fonksiyonlar

#### `_showSourceSelectionDialog()`
Kaynak seçim dialog'unu açar.

**Özellikler:**
- ListView.builder ile dinamik liste
- Format tespiti (URL analizi)
- Aktif kaynak vurgulama
- Her kaynak için "Oynat" butonu

#### `_switchToNativePlayerWithUrl(String videoUrl)`
Belirtilen URL ile native player'a geçer.

**Parametreler:**
- `videoUrl`: Oynatılacak video URL'i

**İşleyiş:**
1. Kaynak objesi oluşturur
2. Film objesini günceller (altyazılarla birlikte)
3. Player ekranına yönlendirir

### JavaScript Channel Handler Güncellemesi

```dart
// Video URL'ini listeye ekle
if (mounted && !_capturedVideoUrls.contains(url)) {
  setState(() {
    _capturedVideoUrls.add(url);
  });
}

// Dialog sadece kullanıcı iptal etmediyse göster
if (_capturedVideoUrl == null && !_showingDialog && !_userDismissedDialog) {
  // İlk yakalamada dialog göster
}
```

## 🎨 UI/UX Tasarımı

### Renk Teması
- 🟣 **Kaynak Badge**: Mor (`Colors.purple`)
- 🟢 **Aktif Kaynak**: Yeşil (`Colors.green`)
- 🔴 **Oynat Butonu**: Kırmızı (`Colors.red`)
- 🔵 **Format Badge**: Mavi (`Colors.blue`)

### Animasyonlar
- ✨ Badge fade-in animasyonu
- 🎭 Kart hover efektleri
- 📍 Aktif kaynak yeşil border

## 📊 Kullanım Senaryoları

### Senaryo 1: İlk Kullanım
1. Kullanıcı iframe player açar
2. Video URL yakalanır
3. Popup otomatik açılır
4. Kullanıcı "Hemen Geç" der → Native player'a geçer

### Senaryo 2: İptal ve Manuel Seçim
1. Kullanıcı iframe player açar
2. Video URL yakalanır
3. Popup otomatik açılır
4. Kullanıcı **"İframe'de Kal"** der → Popup kapanır
5. Sistem arka planda dinlemeye devam eder
6. Daha fazla kaynak yakalanır
7. Header'da "3 Kaynak" badge'i görünür
8. Kullanıcı badge'e tıklar
9. **Kaynak seçim dialog açılır**
10. Kullanıcı istediği kaynağı seçer → Native player'a geçer

### Senaryo 3: Çoklu Kaynak Karşılaştırma
1. Sistem 5 farklı video URL'i yakalar
2. Header'da "5 Kaynak" gösterilir
3. Kullanıcı dialog'u açar
4. Formatları karşılaştırır (M3U8 vs MP4)
5. En uygun olanı seçer

## 🔍 Debug Logları

```dart
debugPrint('🎥 Toplam ${_capturedVideoUrls.length} video URL yakalandı');
debugPrint('❌ Kullanıcı dialog\'u iptal etti. Arka planda dinlemeye devam ediliyor...');
debugPrint('📝 Toplam ${allAltyazilar.length} altyazı player\'a gönderiliyor');
```

## ✅ Test Kontrol Listesi

- [ ] İlk popup otomatik açılıyor mu?
- [ ] "İframe'de Kal" butonu çalışıyor mu?
- [ ] İptalden sonra arka plan izleme devam ediyor mu?
- [ ] Header'da kaynak sayısı doğru gösteriliyor mu?
- [ ] Badge tıklanabilir mi?
- [ ] Kaynak seçim dialog açılıyor mu?
- [ ] Tüm kaynaklar listede görünüyor mu?
- [ ] Format göstergeleri doğru mu?
- [ ] Aktif kaynak vurgulanıyor mu?
- [ ] "Oynat" butonları çalışıyor mu?
- [ ] Native player'a geçiş başarılı mı?
- [ ] Altyazılar player'da mevcut mu?

## 🚀 Gelecek Geliştirmeler

- [ ] Kaynak kalite seçimi (480p, 720p, 1080p)
- [ ] Kaynak hız testi (ping/latency)
- [ ] Favori kaynak kaydetme
- [ ] Otomatik en iyi kaynak seçimi
- [ ] Kaynak indirme özelliği
- [ ] Kaynak paylaşma
