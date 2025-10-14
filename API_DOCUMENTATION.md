# ErdoFlix API Dokümantasyonu

## Genel Bilgiler

**Base URL:** `https://app.erdoganyesil.org/api`

**Authentication:** JWT Bearer Token

**Headers:**
```
Authorization: Bearer {JWT_TOKEN}
X-Role: root
X-App: erdoFlix
X-Authenticator: basic
X-Locale: tr-TR
X-Timezone: +03:00
```

---

## 1. Film Endpoints

### 1.1 Popüler Filmler Listesi

**Endpoint:** `GET /filmler:list`

**Query Parameters:**
- `page`: Sayfa numarası (default: 1)
- `pageSize`: Sayfa başına kayıt (default: 20)
- `appends[]`: İlişkili veriler (turler, kaynaklar_id, film_altyazilari_id)

**Örnek İstek:**
```
GET /filmler:list?page=1&pageSize=20&appends[]=turler&appends[]=kaynaklar_id
```

**Başarılı Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "baslik": "Film Adı",
      "yil": 2024,
      "sure": 120,
      "detay": "Film açıklaması...",
      "imdb_puani": 8.5,
      "poster": "https://...",
      "arka_plan": "https://...",
      "turler": [
        {
          "id": 22,
          "ad": "Aksiyon"
        }
      ],
      "kaynaklar_id": [
        {
          "id": 1,
          "kaynak": "Netflix",
          "url": "https://..."
        }
      ]
    }
  ],
  "meta": {
    "count": 100,
    "page": 1,
    "pageSize": 20,
    "totalPage": 5
  }
}
```

---

### 1.2 Film Detayı

**Endpoint:** `GET /filmler:get`

**Query Parameters:**
- `filterByTk`: Film ID
- `appends[]`: İlişkili veriler

**Örnek İstek:**
```
GET /filmler:get?filterByTk=1&appends[]=turler&appends[]=kaynaklar_id&appends[]=film_altyazilari_id
```

**Başarılı Response (200):**
```json
{
  "data": {
    "id": 1,
    "baslik": "Film Adı",
    "yil": 2024,
    "sure": 120,
    "detay": "Detaylı açıklama...",
    "imdb_puani": 8.5,
    "poster": "https://...",
    "arka_plan": "https://...",
    "turler": [...],
    "kaynaklar_id": [...],
    "film_altyazilari_id": [...]
  }
}
```

---

### 1.3 Benzer Filmler

**Endpoint:** `GET /filmler/{id}/benzer_filmler_id:list`

**Path Parameters:**
- `id`: Film ID

**Query Parameters:**
- `page`: Sayfa numarası
- `pageSize`: Sayfa başına kayıt
- `appends[]`: İlişkili veriler

**Örnek İstek:**
```
GET /filmler/1/benzer_filmler_id:list?pageSize=6&appends[]=turler
```

**Başarılı Response (200):**
```json
{
  "data": [
    {
      "id": 2,
      "baslik": "Benzer Film",
      "poster": "https://...",
      "turler": [...]
    }
  ]
}
```

---

## 2. Tür (Kategori) Endpoints

### 2.1 Tüm Türler

**Endpoint:** `GET /turler:list`

**Query Parameters:**
- `pageSize`: Kayıt sayısı (100 önerilir)

**Örnek İstek:**
```
GET /turler:list?pageSize=100
```

**Başarılı Response (200):**
```json
{
  "data": [
    {
      "id": 22,
      "ad": "Aksiyon",
      "icon": "https://..."
    },
    {
      "id": 23,
      "ad": "Komedi",
      "icon": "https://..."
    }
  ]
}
```

---

### 2.2 Türe Göre Filmler

**Endpoint:** `GET /filmler:list`

**Query Parameters:**
- `filter`: JSON filter objesi (URL encoded)
- `page`: Sayfa numarası
- `pageSize`: Sayfa başına kayıt
- `appends[]`: İlişkili veriler

**Filter Formatı:**
```json
{
  "$and": [
    {
      "turler": {
        "id": {
          "$eq": 22
        }
      }
    }
  ]
}
```

**Örnek İstek:**
```
GET /filmler:list?filter=%7B%22$and%22%3A%5B%7B%22turler%22%3A%7B%22id%22%3A%7B%22$eq%22%3A22%7D%7D%7D%5D%7D&page=1&pageSize=12&appends[]=turler&appends[]=kaynaklar_id
```

**Dart Kodu:**
```dart
final filter = jsonEncode({
  "\$and": [
    {
      "turler": {
        "id": {"\$eq": turId}
      }
    }
  ]
});

final url = '$baseUrl/filmler:list?filter=$filter&page=$page&pageSize=$pageSize&appends[]=turler';
```

**Başarılı Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "baslik": "Aksiyon Film",
      "turler": [
        {
          "id": 22,
          "ad": "Aksiyon"
        }
      ]
    }
  ]
}
```

---

## 3. Error Responses

### 3.1 Unauthorized (401)

```json
{
  "error": "Unauthorized",
  "message": "Invalid or expired token"
}
```

**Çözüm:** Token'ı yenile

---

### 3.2 Not Found (404)

```json
{
  "error": "Not Found",
  "message": "Resource not found"
}
```

---

### 3.3 Internal Server Error (500)

```json
{
  "error": "Internal Server Error",
  "message": "Something went wrong"
}
```

---

## 4. Data Models

### 4.1 Film Model

```dart
class Film {
  final int id;
  final String baslik;
  final int? yil;
  final int? sure; // dakika
  final String? detay;
  final double? imdbPuani;
  final String? poster;
  final String? arkaPlan;
  final List<Tur>? turler;
  final List<Kaynak>? kaynaklar;
  final List<Altyazi>? altyazilar;
}
```

### 4.2 Tür Model

```dart
class Tur {
  final int id;
  final String ad;
  final String? icon;
}
```

### 4.3 Kaynak Model

```dart
class Kaynak {
  final int id;
  final String kaynak; // "Netflix", "Prime Video" vs.
  final String url;
  final String? kalite; // "1080p", "4K" vs.
}
```

### 4.4 Altyazı Model

```dart
class Altyazi {
  final int id;
  final String dil; // "tr-TR", "en-US" vs.
  final String url;
}
```

---

## 5. Best Practices

### 5.1 Pagination

Her zaman `page` ve `pageSize` parametrelerini kullan:

```dart
// İyi ✅
getFilms(page: 1, pageSize: 20);

// Kötü ❌
getFilms(); // Tüm kayıtları çeker
```

### 5.2 Appends

Sadece ihtiyacın olan ilişkili verileri çek:

```dart
// İyi ✅
'&appends[]=turler&appends[]=kaynaklar_id'

// Kötü ❌
'&appends[]=*' // Gereksiz data transfer
```

### 5.3 Filter Encoding

Filter objelerini her zaman JSON encode et:

```dart
// İyi ✅
final filter = jsonEncode({"turler": {"id": {"$eq": 22}}});

// Kötü ❌
final filter = '{"turler":{"id":22}}'; // Yanlış format
```

### 5.4 Error Handling

Her API çağrısını try-catch ile sarmal:

```dart
try {
  final response = await http.get(uri, headers: headers);
  if (response.statusCode == 200) {
    return json.decode(response.body);
  }
  throw Exception('HTTP ${response.statusCode}');
} catch (e) {
  print('Error: $e');
  rethrow;
}
```

---

## 6. Rate Limiting

**Limit:** Bilinmiyor (henüz test edilmedi)

**Öneriler:**
- Throttling implementasyonu
- Cache kullanımı (CachedNetworkImage gibi)
- Debounce search inputs

---

## 7. Changelog

### v1.0 (14 Ekim 2025)
- ✅ Film endpoints implementasyonu
- ✅ Tür endpoints implementasyonu
- ✅ Filter formatı düzeltildi
- ✅ Appends desteği eklendi
- ✅ Error handling implementasyonu

---

## 8. İletişim

**Backend:** NocoBase
**Admin Panel:** https://app.erdoganyesil.org/apps/erdoFlix/admin
**API Docs:** Bu döküman

---

**Son Güncelleme:** 14 Ekim 2025
**Versiyon:** 1.0
