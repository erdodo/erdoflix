import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/film.dart';

class ApiService {
  static const String baseUrl = 'https://app.erdoganyesil.org';
  // Token updated: 15 Ekim 2025
  // Expires: 18 Ekim 2025 (3 gün geçerli)
  static const String apiToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInRlbXAiOnRydWUsImlhdCI6MTc2MDU1NDg3Miwic2lnbkluVGltZSI6MTc2MDU1NDg3MjE4NSwiZXhwIjoxNzYwODE0MDcyLCJqdGkiOiIwYzExYTJlNC03NjQ0LTQ4MjUtYjU0NC1kN2JmNmRhMWM5MjUifQ.DMKZ8cWtBC1zCebB13zmu9G6krXb3Dq0fZT3CtwxAcs';

  Map<String, String> get _headers => {
    'accept': 'application/json',
    'Authorization': 'Bearer $apiToken',
    'X-Locale': 'en-US',
    'X-Role': 'root',
    'X-Authenticator': 'basic',
    'X-App': 'erdoFlix',
    'X-Timezone': '+03:00',
    'X-Hostname': 'app.erdoganyesil.org',
  };

  Future<List<Film>> getFilmler({int page = 1, int pageSize = 20}) async {
    try {
      // Filter: Sadece kaynağı olan filmler
      final filter = jsonEncode({
        "\$and": [
          {
            "kaynaklar_id": {
              "id": {"\$notEmpty": true},
            },
          },
        ],
      });

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/filmler:list?filter=$filter&page=$page&pageSize=$pageSize',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> filmlerData = data['data'] ?? [];
        return filmlerData.map((json) => Film.fromJson(json)).toList();
      } else {
        print('❌ API Error: Status ${response.statusCode}');
        print('❌ Response: ${response.body}');
        if (response.statusCode == 401) {
          print('🔑 TOKEN EXPIRED! API token süresi dolmuş.');
          print(
            '🔑 Yeni token için: https://app.erdoganyesil.org adresine giriş yapın',
          );
          print(
            '🔑 Token\'ı lib/services/api_service.dart dosyasına yapıştırın',
          );
        }
        throw Exception('Failed to load films: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching films: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getFilmlerWithMeta({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Filter: Sadece kaynağı olan filmler
      final filter = jsonEncode({
        "\$and": [
          {
            "kaynaklar_id": {
              "id": {"\$notEmpty": true},
            },
          },
        ],
      });

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/filmler:list?filter=$filter&page=$page&pageSize=$pageSize',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> filmlerData = data['data'] ?? [];
        final meta = data['meta'] ?? {};
        return {
          'films': filmlerData.map((json) => Film.fromJson(json)).toList(),
          'meta': meta,
        };
      } else {
        throw Exception('Failed to load films');
      }
    } catch (e) {
      print('Error fetching films: $e');
      return {'films': [], 'meta': {}};
    }
  }

  Future<Film?> getFilm(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/filmler:get/$id'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Film.fromJson(data['data']);
      } else {
        throw Exception('Failed to load film');
      }
    } catch (e) {
      print('Error fetching film: $e');
      return null;
    }
  }

  // Film kaynaklarını çek (ayrı tabloda)
  Future<List<dynamic>> getFilmKaynaklari(int filmId) async {
    try {
      // Filter: film_id.id = filmId ($ operatörleri ile)
      final filterParam = Uri.encodeComponent(
        '{"\$and":[{"film_id":{"id":{"\$eq":$filmId}}}]}',
      );

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/film_kaynaklari:list?pageSize=20&appends[]=film_id&page=1&filter=$filterParam',
        ),
        headers: _headers,
      );

      print('🔍 Kaynaklar API Response Status: ${response.statusCode}');
      print(
        '🔍 Kaynaklar API URL: $baseUrl/api/film_kaynaklari:list?filter=$filterParam',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 Kaynaklar Response: ${data['data']}');
        return data['data'] ?? [];
      } else {
        print('❌ Kaynaklar API Error: ${response.body}');
        throw Exception('Failed to load film kaynakları');
      }
    } catch (e) {
      print('❌ Error fetching film kaynakları: $e');
      return [];
    }
  }

  // Film altyazılarını çek (ayrı tabloda)
  Future<List<dynamic>> getFilmAltyazilari(int filmId) async {
    try {
      // Filter: filmler.id = filmId ($ operatörleri ile)
      final filterParam = Uri.encodeComponent(
        '{"\$and":[{"filmler":{"id":{"\$eq":$filmId}}}]}',
      );

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/film_altyazilari:list?pageSize=20&appends[]=filmler&page=1&filter=$filterParam',
        ),
        headers: _headers,
      );

      print('🔍 Altyazılar API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔍 Altyazılar Response: ${data['data']}');
        return data['data'] ?? [];
      } else {
        print('❌ Altyazılar API Error: ${response.body}');
        throw Exception('Failed to load film altyazıları');
      }
    } catch (e) {
      print('❌ Error fetching film altyazıları: $e');
      return [];
    }
  }

  // Film detayını kaynak ve altyazılarla birlikte çek
  Future<Film?> getFilmWithDetails(int id) async {
    try {
      // Film bilgisini çek
      final film = await getFilm(id);
      if (film == null) return null;

      // Kaynakları çek
      final kaynaklar = await getFilmKaynaklari(id);

      // Altyazıları çek
      final altyazilar = await getFilmAltyazilari(id);

      print('🎬 Film: ${film.baslik}');
      print('🎬 Kaynak sayısı: ${kaynaklar.length}');
      print('🎬 Altyazı sayısı: ${altyazilar.length}');

      if (kaynaklar.isNotEmpty) {
        print('🎬 İlk Kaynak: ${kaynaklar[0]}');
      }

      // Film objesini güncellenmiş verilerle yeniden oluştur
      // JSON'dan Film objesi oluşturmak için fromJson kullan
      final filmJson = {
        'id': film.id,
        'baslik': film.baslik,
        'orjinal_baslik': film.orjinalBaslik,
        'poster': film.poster,
        'arka_plan': film.arkaPlan,
        'detay': film.detay,
        'yayin_tarihi': film.yayinTarihi,
        'tmdb_id': film.tmdbId,
        'imdb_id': film.imdbId,
        'turler': film.turler
            .map((t) => {'id': t.id, 'baslik': t.baslik, 'tmdb_id': t.tmdbId})
            .toList(),
        'kaynaklar_id': kaynaklar,
        'film_altyazilari_id': altyazilar,
      };

      print('🎬 Film JSON kaynaklar_id: ${filmJson['kaynaklar_id']}');

      final filmWithDetails = Film.fromJson(filmJson);
      print('🎬 Film.hasVideo: ${filmWithDetails.hasVideo}');
      print('🎬 Film.kaynaklar length: ${filmWithDetails.kaynaklar?.length}');

      return filmWithDetails;
    } catch (e) {
      print('❌ Error fetching film with details: $e');
      return null;
    }
  }

  /// Filmleri arama (başlık, detay ve orijinal başlıkta arama)
  Future<List<Film>> searchFilms(
    String query, {
    int page = 1,
    int pageSize = 20,
  }) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // Filter: AND (sadece kaynağı olanlar) + OR (arama kriterleri)
      final filter = {
        '\$and': [
          {
            'kaynaklar_id': {
              'id': {'\$notEmpty': true},
            },
          },
          {
            '\$or': [
              {
                'baslik': {'\$includes': query},
              },
              {
                'detay': {'\$includes': query},
              },
              {
                'orjinal_baslik': {'\$includes': query},
              },
            ],
          },
        ],
      };

      final filterParam = Uri.encodeComponent(json.encode(filter));

      print('🔍 Search Query: $query');
      print('🔍 Filter: ${json.encode(filter)}');

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/filmler:list?filter=$filterParam&page=$page&pageSize=$pageSize',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> filmlerData = data['data'] ?? [];

        print('🔍 Search Results: ${filmlerData.length} films found');

        return filmlerData.map((json) => Film.fromJson(json)).toList();
      } else {
        print('❌ Search Error: Status ${response.statusCode}');
        print('❌ Response: ${response.body}');
        throw Exception('Failed to search films: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching films: $e');
      return [];
    }
  }
}
