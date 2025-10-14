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

class _FilmCardState extends State<FilmCard> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scale(widget.isFocused ? 1.15 : 1.0)
          ..rotateZ(widget.isFocused ? 0.01 : 0.0), // Hafif 3D tilt
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            // Gradient border effect
            gradient: widget.isFocused
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.red.withValues(alpha: 0.8),
                      Colors.orange.withValues(alpha: 0.8),
                      Colors.red.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            boxShadow: widget.isFocused
                ? [
                    // Neon glow - kırmızı
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.5),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                    // Outer glow - turuncu
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.3),
                      blurRadius: 35,
                      spreadRadius: 8,
                    ),
                    // Soft white glow
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ]
                : [
                    // Subtle shadow when not focused
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          // Inner container for content
          child: Container(
            margin: widget.isFocused ? const EdgeInsets.all(2) : EdgeInsets.zero,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.isFocused ? 10 : 12),
              color: Colors.black,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.isFocused ? 10 : 12),
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
                  // Play icon overlay (focused olduğunda)
                  if (widget.isFocused)
                    Center(
                      child: AnimatedOpacity(
                        opacity: widget.isFocused ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red.withValues(alpha: 0.9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withValues(alpha: 0.5),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Rating badge (top-right)
                  // TODO: Film modeline imdbPuani alanı eklendiğinde açılacak
                  // if (widget.film.imdbPuani != null)
                  //   Positioned(
                  //     top: 8,
                  //     right: 8,
                  //     child: Container(
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 8,
                  //         vertical: 4,
                  //       ),
                  //       decoration: BoxDecoration(
                  //         color: Colors.black.withValues(alpha: 0.7),
                  //         borderRadius: BorderRadius.circular(4),
                  //         border: Border.all(
                  //           color: Colors.yellow.withValues(alpha: 0.5),
                  //           width: 1,
                  //         ),
                  //       ),
                  //       child: Row(
                  //         mainAxisSize: MainAxisSize.min,
                  //         children: [
                  //           const Icon(
                  //             Icons.star,
                  //             size: 14,
                  //             color: Colors.yellow,
                  //           ),
                  //           const SizedBox(width: 4),
                  //           Text(
                  //             widget.film.imdbPuani!.toStringAsFixed(1),
                  //             style: const TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 12,
                  //               fontWeight: FontWeight.bold,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),

                  // Year badge (top-left)
                  // TODO: Film modeline yil alanı eklendiğinde açılacak
                  // if (widget.film.yil != null)
                  //   Positioned(
                  //     top: 8,
                  //     left: 8,
                  //     child: Container(
                  //       padding: const EdgeInsets.symmetric(
                  //         horizontal: 8,
                  //         vertical: 4,
                  //       ),
                  //       decoration: BoxDecoration(
                  //         color: Colors.black.withValues(alpha: 0.7),
                  //         borderRadius: BorderRadius.circular(4),
                  //       ),
                  //       child: Text(
                  //         widget.film.yil.toString(),
                  //         style: const TextStyle(
                  //           color: Colors.white70,
                  //           fontSize: 11,
                  //           fontWeight: FontWeight.w500,
                  //         ),
                  //       ),
                  //     ),
                  //   ),

                  // Gradient overlay with title
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
                            Colors.black.withValues(alpha: 0.9),
                            Colors.black.withValues(alpha: 0.5),
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
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              blurRadius: 4,
                            ),
                          ],
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
