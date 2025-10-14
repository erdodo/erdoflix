import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/resume_play.dart';

class ResumePlayService {
  static const String baseUrl = 'https://app.erdoganyesil.org/api';
  static const String apiKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOjEsInJvbGVOYW1lIjoicm9vdCIsImlhdCI6MTc2MDQ1NjI4NiwiZXhwIjozMzMxODA1NjI4Nn0.ikmX73jTYj73phAL-ZYf-HcslWjVVoNNzfPtoddvj_4';

  static Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
      'X-Role': 'root',
      'X-App': 'erdoFlix',
      'X-Authenticator': 'basic',
      'X-Locale': 'tr-TR',
      'X-Timezone': '+03:00',
    };
  }

  // Film için son izleme pozisyonunu getir
  static Future<ResumePlay?> getResumePosition(int filmId,
      {int userId = 1}) async {
    try {
      final filter = jsonEncode({
        "\$and": [
          {"film_id": {"\$eq": filmId}},
          {"user_id": {"\$eq": userId}}
        ]
      });

      final response = await http.get(
        Uri.parse('$baseUrl/resume_play:list?filter=$filter&pageSize=1'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null &&
            data['data'] is List &&
            data['data'].isNotEmpty) {
          return ResumePlay.fromJson(data['data'][0]);
        }
      }
      return null;
    } catch (e) {
      print('Resume position getirme hatası: $e');
      return null;
    }
  }

  // İzleme pozisyonunu kaydet/güncelle
  static Future<bool> saveResumePosition(ResumePlay resumePlay) async {
    try {
      // Önce mevcut kaydı kontrol et
      final existing =
          await getResumePosition(resumePlay.filmId, userId: resumePlay.userId);

      if (existing != null) {
        // Güncelle
        final response = await http.put(
          Uri.parse('$baseUrl/resume_play:update/${existing.id}'),
          headers: _getHeaders(),
          body: json.encode(resumePlay.toJson()),
        );
        return response.statusCode == 200;
      } else {
        // Yeni kayıt oluştur
        final response = await http.post(
          Uri.parse('$baseUrl/resume_play:create'),
          headers: _getHeaders(),
          body: json.encode(resumePlay.toJson()),
        );
        return response.statusCode == 200;
      }
    } catch (e) {
      print('Resume position kaydetme hatası: $e');
      return false;
    }
  }

  // İzleme pozisyonunu sil (tamamlandığında veya sıfırlamak için)
  static Future<bool> deleteResumePosition(int filmId,
      {int userId = 1}) async {
    try {
      final existing = await getResumePosition(filmId, userId: userId);
      if (existing != null) {
        final response = await http.delete(
          Uri.parse('$baseUrl/resume_play:destroy/${existing.id}'),
          headers: _getHeaders(),
        );
        return response.statusCode == 200;
      }
      return true;
    } catch (e) {
      print('Resume position silme hatası: $e');
      return false;
    }
  }
}
