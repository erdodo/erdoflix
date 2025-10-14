import 'package:flutter/material.dart';
import '../models/film.dart';

class FilmCard extends StatefulWidget {
  final Film film;
  final VoidCallback? onTap;
  final bool isFocused;

  const FilmCard({
    super.key,
    required this.film,
    this.onTap,
    this.isFocused = false,
  });

  @override
  State<FilmCard> createState() => _FilmCardState();
}

class _FilmCardState extends State<FilmCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Transform.scale(
        scale: widget.isFocused ? 1.15 : 1.0, // 1.1'den 1.15'e çıkardık
        alignment: Alignment.center,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: widget.isFocused
                ? Border.all(
                    color: Colors.white,
                    width: 1,
                  ) // 3'ten 4'e çıkardık
                : null,
            boxShadow: widget.isFocused
                ? [
                    // Glow efekti - daha yumuşak
                    BoxShadow(
                      color: Colors.white.withOpacity(
                        0.1,
                      ), // 0.8'den 0.5'e azaltıldı
                      blurRadius: 15, // 20'den 15'e azaltıldı
                      spreadRadius: 3, // 5'ten 3'e azaltıldı
                    ),
                    // İkinci katman glow - daha az yoğun
                    BoxShadow(
                      color: Colors.white.withOpacity(
                        0.2,
                      ), // 0.4'ten 0.2'ye azaltıldı
                      blurRadius: 20, // 30'dan 20'ye azaltıldı
                      spreadRadius: 5, // 10'dan 5'e azaltıldı
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 2 / 3, // Film poster oranı (genişlik/yükseklik)
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Placeholder veya gerçek poster
                  widget.film.poster != null
                      ? Image.network(
                          widget.film.poster!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholder();
                          },
                        )
                      : _buildPlaceholder(),
                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Text(
                        widget.film.baslik,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[900],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie, color: Colors.white54, size: 48),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                widget.film.baslik,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
