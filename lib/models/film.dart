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
  });

  factory Film.fromJson(Map<String, dynamic> json) {
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
    };
  }
}
