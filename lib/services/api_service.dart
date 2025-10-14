import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/film.dart';

class ApiService {
  static const String baseUrl = 'https://app.erdoganyesil.org';
  static const String apiToken =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInRlbXAiOnRydWUsImlhdCI6MTc2MDQ1NjAyNiwic2lnbkluVGltZSI6MTc2MDQ1NjAyNjM0MiwiZXhwIjoxNzYwNzE1MjI2LCJqdGkiOiIxMzgwNGIwNy00MzIyLTRiNzAtOTRiNC0yYWVlN2EyY2RhN2MifQ.JUhj1jllAOxx_IFOr0bQXo0qZvg7n8nIFhhlexB8kZo';

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
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/filmler:list?filter=%7B%7D&page=$page&pageSize=$pageSize',
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> filmlerData = data['data'] ?? [];
        return filmlerData.map((json) => Film.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load films');
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
      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/filmler:list?filter=%7B%7D&page=$page&pageSize=$pageSize',
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
}
