# iFrame Kaynakları Görüntüleme - Güncelleme

## 🎯 Yapılan Değişiklik

**Tarih:** 16 Ekim 2025

### Önceki Durum
Film detay ekranında sadece **direkt video kaynakları** (`isIframe == false`) listelenmekteydi. Bu, iframe olarak bulunan kaynakların kullanıcıya gösterilmediği anlamına geliyordu.

### Yeni Durum
Artık **hem iframe hem de direkt video kaynakları** birlikte listeleniyor. Bu sayede:
- ✅ Kullanıcılar tüm bulunan kaynakları görebilir
- ✅ iFrame kaynakları özel etiketle işaretlenir
- ✅ Kaynak türü görsel olarak ayırt edilir

## 📝 Kod Değişiklikleri

### 1. Kaynak Filtresinin Kaldırılması

**Dosya:** `lib/screens/film_detail_screen.dart`

**Önceki Kod:**
```dart
// Sadece iframe olmayan kaynakları al
_discoveredSources = widget.film.kaynaklar!
    .where((k) => k.isIframe == false)
    .toList();
debugPrint('📹 ${_discoveredSources.length} mevcut video kaynağı yüklendi');
```

**Yeni Kod:**
```dart
// Tüm kaynakları al (iframe ve direkt)
_discoveredSources = widget.film.kaynaklar!.toList();
debugPrint('📹 ${_discoveredSources.length} mevcut video kaynağı yüklendi (iframe: ${_discoveredSources.where((k) => k.isIframe == true).length}, direkt: ${_discoveredSources.where((k) => k.isIframe == false).length})');
```

### 2. iFrame Etiketi Eklenmesi

**Dosya:** `lib/screens/film_detail_screen.dart`

Kaynak listesinde her öğenin `trailing` kısmına iframe etiket eklendi:

```dart
trailing: Row(
  mainAxisSize: MainAxisSize.min,
  children: [
    // iFrame etiketi
    if (source.isIframe == true) ...[
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          border: Border.all(
            color: Colors.blue,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          'iFrame',
          style: AppTheme.labelSmall.copyWith(
            color: Colors.blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      const SizedBox(width: 8),
    ],
    Icon(
      Icons.check_circle,
      color: AppTheme.success,
      size: 20,
    ),
    const SizedBox(width: 8),
    Text(
      'Kaydedildi',
      style: AppTheme.labelSmall.copyWith(
        color: AppTheme.success,
      ),
    ),
  ],
),
```

## 🎨 Görsel Tasarım

### iFrame Etiketi Stili
- **Arka Plan:** Mavi, %20 opaklık (`Colors.blue.withOpacity(0.2)`)
- **Kenarlık:** 1px mavi kenarlık (`Colors.blue`)
- **Metin:** Kalın, mavi renkli "iFrame" yazısı
- **Padding:** Yatay 8px, dikey 4px
- **Border Radius:** 4px yuvarlatılmış köşeler

### Kaynak Listesi Görünümü

```
┌─────────────────────────────────────────────────────┐
│ 🎬 Kaynak Başlığı                                   │
│ https://example.com/video.m3u8                      │
│                              [iFrame] ✓ Kaydedildi  │
└─────────────────────────────────────────────────────┘
```

## 🔍 Debug Çıktısı

Yeni debug log formatı:
```
📹 10 mevcut video kaynağı yüklendi (iframe: 3, direkt: 7)
```

Bu, kullanıcıya şunları gösterir:
- Toplam kaynak sayısı
- iFrame kaynak sayısı
- Direkt kaynak sayısı

## 📊 Kaynak Türleri

### iFrame Kaynakları (`isIframe == true`)
- Embed player içeren kaynaklar
- Genellikle üçüncü parti video hostlarda
- WebView ile oynatılır
- **Görsel İşaret:** Mavi "iFrame" etiketi

### Direkt Kaynakları (`isIframe == false`)
- Doğrudan video URL'leri (m3u8, mp4, vb.)
- Video player ile doğrudan oynatılır
- **Görsel İşaret:** Yalnızca "Kaydedildi" durumu

## ✅ Faydaları

1. **Tam Görünürlük:** Kullanıcılar tüm kaynakları görebilir
2. **Ayırt Edici:** iFrame kaynakları kolayca tanımlanır
3. **Seçim Özgürlüğü:** Kullanıcı tercih ettiği kaynak türünü seçebilir
4. **Debug Kolaylığı:** Log'larda kaynak türü ayrımı yapılır

## 🧪 Test Senaryoları

### Senaryo 1: iFrame Kaynağı Olan Film
1. ✅ Film detay sayfasına git
2. ✅ "Bulunan Kaynaklar" bölümünü kontrol et
3. ✅ iFrame kaynaklarının mavi "iFrame" etiketi ile gösterildiğini doğrula
4. ✅ Direkt kaynakların etiket olmadan gösterildiğini doğrula

### Senaryo 2: Sadece Direkt Kaynak Olan Film
1. ✅ Film detay sayfasına git
2. ✅ Tüm kaynakların sadece "Kaydedildi" durumu ile gösterildiğini doğrula
3. ✅ Hiçbir kaynakta "iFrame" etiketi olmadığını kontrol et

### Senaryo 3: Karışık Kaynak Türleri
1. ✅ Hem iframe hem direkt kaynaklı film aç
2. ✅ Debug log'unda kaynak sayılarını kontrol et
3. ✅ UI'da her kaynak türünün doğru etiketlendiğini doğrula

## 🔧 İlgili Dosyalar

- `lib/screens/film_detail_screen.dart` - Kaynak listesi görünümü
- `lib/models/kaynak.dart` - Kaynak model tanımı (isIframe özelliği)
- `lib/services/source_collector_service.dart` - Kaynak toplama servisi

## 📚 Teknik Notlar

### isIframe Özelliği
```dart
class Kaynak {
  final int? id;
  final String url;
  final String baslik;
  final bool isIframe; // true: iframe kaynağı, false: direkt video
  
  // ...
}
```

### Filtreleme Mantığı
```dart
// Tüm kaynakları al
final allSources = widget.film.kaynaklar!.toList();

// Sadece iframe kaynakları
final iframeSources = allSources.where((k) => k.isIframe == true).toList();

// Sadece direkt kaynakları
final directSources = allSources.where((k) => k.isIframe == false).toList();
```

## 🚀 Gelecek Geliştirmeler

1. **Kaynak Sıralama:** iFrame ve direkt kaynakları ayrı bölümlerde göster
2. **Filtre Seçeneği:** Kullanıcı kaynak türüne göre filtreleme yapabilsin
3. **Öncelik Sistemi:** Bazı kaynak türlerini öncelikli olarak işaretle
4. **Kalite Etiketleri:** 1080p, 720p, 480p gibi kalite bilgileri ekle

## 📖 İlgili Dokümantasyon

- [TV Navigation Fixes](./TV_NAVIGATION_FIXES.md) - TV kumandası navigasyonu
- [API Documentation](./API_DOCUMENTATION.md) - API kaynak yapısı
- [User Guide](./USER_GUIDE.md) - Kullanım kılavuzu

---

**Not:** Bu güncelleme, önceki TV navigasyon düzeltmeleri ile uyumludur. iFrame etiketli kaynaklar da TV kumandası ile seçilebilir.
