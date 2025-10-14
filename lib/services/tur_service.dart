import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/tur.dart';
import '../models/film.dart';

class TurService {
  static const String baseUrl = 'https://app.erdoganyesil.org/api';
  static const String apiToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInRlbXAiOnRydWUsImlhdCI6MTc2MDQ1NjAyNiwic2lnbkluVGltZSI6MTc2MDQ1NjAyNjM0MiwiZXhwIjoxNzYwNzE1MjI2LCJqdGkiOiIxMzgwNGIwNy00MzIyLTRiNzAtOTRiNC0yYWVlN2EyY2RhN2MifQ.JUhj1jllAOxx_IFOr0bQXo0qZvg7n8nIFhhlexB8kZo';

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
      // Türe ait filmleri çekmek için turler/{turId}/film_id:list endpoint'i kullan
      final response = await http.get(
        Uri.parse(
          '$baseUrl/turler/$turId/film_id:list?page=$page&pageSize=$pageSize&appends=turler',
        ),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['data'] ?? [];
        return data.map((item) => Film.fromJson(item)).toList();
      } else {
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
