class ResumePlay {
  final int? id;
  final int filmId;
  final int userId;
  final int position; // Saniye cinsinden pozisyon
  final int? duration; // Toplam süre
  final String? durum; // "watching", "completed" vs.
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ResumePlay({
    this.id,
    required this.filmId,
    required this.userId,
    required this.position,
    this.duration,
    this.durum,
    this.createdAt,
    this.updatedAt,
  });

  factory ResumePlay.fromJson(Map<String, dynamic> json) {
    // Güvenli integer parsing
    int parseIntSafe(dynamic value, int defaultValue) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Güvenli string parsing
    String? parseStringSafe(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      return value.toString();
    }

    return ResumePlay(
      id: parseIntSafe(json['id'], 0),
      filmId: parseIntSafe(json['film_id'], 0),
      userId: parseIntSafe(json['user_id'], 1),
      position: parseIntSafe(json['position'], 0),
      duration: parseIntSafe(json['duration'], 0),
      durum: parseStringSafe(json['durum']),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'film_id': filmId,
      'user_id': userId,
      'position': position,
      if (duration != null) 'duration': duration,
      if (durum != null) 'durum': durum,
    };
  }

  // Progress yüzdesi
  double get progress {
    if (duration == null || duration == 0) return 0.0;
    return (position / duration!).clamp(0.0, 1.0);
  }

  // Tamamlandı mı?
  bool get isCompleted {
    return progress > 0.9 || durum == 'completed';
  }
}
