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
    return ResumePlay(
      id: json['id'],
      filmId: json['film_id'] ?? 0,
      userId: json['user_id'] ?? 1, // Şimdilik default user
      position: json['position'] ?? 0,
      duration: json['duration'],
      durum: json['durum'],
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
