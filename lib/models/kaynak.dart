class Kaynak {
  final int id;
  final String baslik; // "1080p", "720p", "4K" vs.
  final String url; // Video URL'i (M3U8, MP4 vs.)
  final int? kaynakId; // Kaynak tipi ID (Netflix, Prime vs.)

  Kaynak({
    required this.id,
    required this.baslik,
    required this.url,
    this.kaynakId,
  });

  factory Kaynak.fromJson(Map<String, dynamic> json) {
    return Kaynak(
      id: json['id'],
      baslik: json['baslik'] ?? 'Varsayılan',
      url: json['url'] ?? '',
      kaynakId: json['kaynak_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'baslik': baslik, 'url': url, 'kaynak_id': kaynakId};
  }

  // Kalite sıralama için
  int get priority {
    if (baslik.contains('4K') || baslik.contains('2160p')) return 4;
    if (baslik.contains('1080p') || baslik.contains('Full HD')) return 3;
    if (baslik.contains('720p') || baslik.contains('HD')) return 2;
    if (baslik.contains('480p')) return 1;
    return 0;
  }
}
