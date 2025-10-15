import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tur.dart';
import '../models/film.dart';

class TurService {
  static const String baseUrl = 'https://app.erdoganyesil.org/api';
  // Token updated: 15 Ekim 2025
  // Expires: 18 Ekim 2025 (3 gün geçerli)
  static const String apiToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInRlbXAiOnRydWUsImlhdCI6MTc2MDU1NDg3Miwic2lnbkluVGltZSI6MTc2MDU1NDg3MjE4NSwiZXhwIjoxNzYwODE0MDcyLCJqdGkiOiIwYzExYTJlNC03NjQ0LTQ4MjUtYjU0NC1kN2JmNmRhMWM5MjUifQ.DMKZ8cWtBC1zCebB13zmu9G6krXb3Dq0fZT3CtwxAcs';

  static Map<String, String> _getHeaders() {
    return {
      'accept': 'application/json',
      'X-Locale': 'tr-TR',
      'X-Role': 'root',
      'X-Authenticator': 'basic',
      'Authorization': 'Bearer $apiToken',
      'X-App': 'erdoFlix',
      'X-Timezone': '+03:00',
      'X-Hostname': 'app.erdoganyesil.org',
    };
  }

  /// Tüm türleri (kategorileri) getirir
  Future<List<Tur>> getTurler({int page = 1, int pageSize = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/turler:list?page=$page&pageSize=$pageSize'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'] ?? [];
        return data.map((item) => Tur.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load turler: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching turler: $e');
      return [];
    }
  }

  /// Belirli bir türü ID ile getirir
  Future<Tur?> getTur(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/turler:get?filterByTk=$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = jsonData['data'];
        if (data != null) {
          return Tur.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching tur: $e');
      return null;
    }
  }

  /// Belirli bir türe ait filmleri getirir
  Future<List<Film>> getFilmlerByTur(
    int turId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      // Filter parametresi: Türe ait VE kaynağı olan filmler
      final filter = jsonEncode({
        "\$and": [
          {
            "turler": {
              "id": {"\$eq": turId},
            },
          },
          {
            "kaynaklar_id": {
              "id": {"\$notEmpty": true},
            },
          },
        ],
      });

      final response = await http.get(
        Uri.parse(
          '$baseUrl/filmler:list?pageSize=$pageSize&page=$page&filter=$filter&appends[]=turler&appends[]=kaynaklar_id&appends[]=film_altyazilari_id',
        ),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'] ?? [];
        return data.map((item) => Film.fromJson(item)).toList();
      } else {
        print('Failed to load films by tur: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to load films by tur: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching films by tur: $e');
      return [];
    }
  }

  /// Metadata ile birlikte türleri getirir (toplam sayı vs.)
  Future<Map<String, dynamic>> getTurlerWithMeta({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/turler:list?page=$page&pageSize=$pageSize'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return {
          'data':
              (jsonData['data'] as List<dynamic>?)
                  ?.map((item) => Tur.fromJson(item))
                  .toList() ??
              [],
          'meta': jsonData['meta'] ?? {},
        };
      } else {
        throw Exception(
          'Failed to load turler with meta: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching turler with meta: $e');
      return {'data': [], 'meta': {}};
    }
  }
}
