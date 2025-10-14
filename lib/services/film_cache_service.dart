import '../models/film.dart';

/// Film objelerini geçici olarak cache'leyen singleton service
/// go_router'ın extra parametresi web'de çalışmadığı için bu workaround gerekli
class FilmCacheService {
  static final FilmCacheService _instance = FilmCacheService._internal();
  factory FilmCacheService() => _instance;
  FilmCacheService._internal();

  final Map<int, Film> _cache = {};

  /// Film'i cache'e ekle
  void setFilm(Film film) {
    _cache[film.id] = film;
  }

  /// Film'i cache'den al
  Film? getFilm(int id) {
    return _cache[id];
  }

  /// Film'i cache'den sil
  void removeFilm(int id) {
    _cache.remove(id);
  }

  /// Tüm cache'i temizle
  void clear() {
    _cache.clear();
  }
}
