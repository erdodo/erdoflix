class Tur {
  final int id;
  final String baslik;
  final int? tmdbId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Tur({
    required this.id,
    required this.baslik,
    this.tmdbId,
    this.createdAt,
    this.updatedAt,
  });

  factory Tur.fromJson(Map<String, dynamic> json) {
    return Tur(
      id: json['id'] as int,
      baslik: json['baslik'] as String? ?? '',
      tmdbId: json['tmdb_id'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'baslik': baslik,
      'tmdb_id': tmdbId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Tur{id: $id, baslik: $baslik, tmdbId: $tmdbId}';
  }
}
