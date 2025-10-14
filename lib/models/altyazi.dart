class Altyazi {
  final int id;
  final String baslik; // "Türkçe", "İngilizce" vs.
  final String url; // SRT dosyası URL'i
  final int? filmId;

  Altyazi({
    required this.id,
    required this.baslik,
    required this.url,
    this.filmId,
  });

  factory Altyazi.fromJson(Map<String, dynamic> json) {
    return Altyazi(
      id: json['id'],
      baslik: json['baslik'] ?? 'Bilinmiyor',
      url: json['url'] ?? '',
      filmId: json['film_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baslik': baslik,
      'url': url,
      'film_id': filmId,
    };
  }
}
