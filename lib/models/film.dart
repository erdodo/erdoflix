import 'tur.dart';
import 'kaynak.dart';
import 'altyazi.dart';

class Film {
  final int id;
  final String baslik;
  final String? orjinalBaslik;
  final String? poster;
  final String? arkaPlan;
  final String? detay;
  final String? yayinTarihi;
  final String? tmdbId;
  final String? imdbId;
  final List<Tur> turler;
  final List<Kaynak>? kaynaklar; // Video kaynakları
  final List<Altyazi>? altyazilar; // Altyazılar

  Film({
    required this.id,
    required this.baslik,
    this.orjinalBaslik,
    this.poster,
    this.arkaPlan,
    this.detay,
    this.yayinTarihi,
    this.tmdbId,
    this.imdbId,
    this.turler = const [],
    this.kaynaklar,
    this.altyazilar,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    // Türleri parse et
    List<Tur> turlerList = [];
    if (json['turler'] != null && json['turler'] is List) {
      turlerList = (json['turler'] as List)
          .map((turJson) => Tur.fromJson(turJson))
          .toList();
    }

    // Kaynakları parse et
    List<Kaynak>? kaynakList;
    if (json['kaynaklar_id'] != null && json['kaynaklar_id'] is List) {
      kaynakList = (json['kaynaklar_id'] as List)
          .map((kaynakJson) => Kaynak.fromJson(kaynakJson))
          .toList();
      // Kaliteye göre sırala (yüksek kalite önce)
      kaynakList.sort((a, b) => b.priority.compareTo(a.priority));
    }

    // Altyazıları parse et
    List<Altyazi>? altyaziList;
    if (json['film_altyazilari_id'] != null &&
        json['film_altyazilari_id'] is List) {
      altyaziList = (json['film_altyazilari_id'] as List)
          .map((altyaziJson) => Altyazi.fromJson(altyaziJson))
          .toList();
    }

    return Film(
      id: json['id'] ?? 0,
      baslik: json['baslik'] ?? '',
      orjinalBaslik: json['orjinal_baslik'],
      poster: json['poster'],
      arkaPlan: json['arka_plan'],
      detay: json['detay'],
      yayinTarihi: json['yayin_tarihi'],
      tmdbId: json['tmdb_id'],
      imdbId: json['imdb_id'],
      turler: turlerList,
      kaynaklar: kaynakList,
      altyazilar: altyaziList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baslik': baslik,
      'orjinal_baslik': orjinalBaslik,
      'poster': poster,
      'arka_plan': arkaPlan,
      'detay': detay,
      'yayin_tarihi': yayinTarihi,
      'tmdb_id': tmdbId,
      'imdb_id': imdbId,
      'turler': turler.map((tur) => tur.toJson()).toList(),
      if (kaynaklar != null)
        'kaynaklar_id': kaynaklar!.map((k) => k.toJson()).toList(),
      if (altyazilar != null)
        'film_altyazilari_id': altyazilar!.map((a) => a.toJson()).toList(),
    };
  }

  // En iyi kaliteli kaynağı döndür
  Kaynak? get defaultKaynak {
    if (kaynaklar == null || kaynaklar!.isEmpty) return null;
    return kaynaklar!.first; // Zaten priority'ye göre sıralı
  }

  // Video URL'i var mı?
  bool get hasVideo {
    return kaynaklar != null && kaynaklar!.isNotEmpty;
  }
}
