import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/film.dart';
import '../utils/app_theme.dart';

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

class _FilmCardState extends State<FilmCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  bool _imageLoaded = false;

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
        duration: AppTheme.animationMedium,
        curve: AppTheme.animationCurve,
        transform: Matrix4.identity()
          ..scale(widget.isFocused ? 1.12 : 1.0)
          ..translate(0.0, widget.isFocused ? -8.0 : 0.0), // Yukarı hareket
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            gradient: widget.isFocused ? AppTheme.primaryGradient : null,
            boxShadow: widget.isFocused
                ? AppTheme.cardShadowFocused
                : AppTheme.cardShadow,
          ),
          // Inner container for content
          child: Container(
            margin: widget.isFocused
                ? const EdgeInsets.all(3)
                : EdgeInsets.zero,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                widget.isFocused
                    ? AppTheme.radiusMedium - 2
                    : AppTheme.radiusMedium,
              ),
              color: AppTheme.backgroundCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                widget.isFocused
                    ? AppTheme.radiusMedium - 2
                    : AppTheme.radiusMedium,
              ),
              child: AspectRatio(
                aspectRatio: 2 / 3, // Film poster oranı
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Poster image
                    widget.film.poster != null
                        ? Image.network(
                            widget.film.poster!,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                _imageLoaded = true;
                                return child;
                              }
                              return _buildPlaceholder();
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholder();
                            },
                          )
                        : _buildPlaceholder(),

                    // Gradient overlay (bottom)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Film title overlay
                    Positioned(
                      bottom: AppTheme.spacingSmall,
                      left: AppTheme.spacingSmall,
                      right: AppTheme.spacingSmall,
                      child: Text(
                        widget.film.baslik,
                        style: AppTheme.labelMedium.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Play button overlay (focused)
                    if (widget.isFocused)
                      Center(
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0.0,
                            end: widget.isFocused ? 1.0 : 0.0,
                          ),
                          duration: AppTheme.animationMedium,
                          curve: AppTheme.animationBounceCurve,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: AppTheme.primaryGradient,
                                  boxShadow: AppTheme.glowShadow,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  size: 48,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
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
                              Shadow(color: Colors.black, blurRadius: 4),
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
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.backgroundCard,
                AppTheme.backgroundMedium,
                AppTheme.backgroundCard,
              ],
              stops: [
                (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                _shimmerController.value,
                (_shimmerController.value + 0.3).clamp(0.0, 1.0),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.movie_rounded,
                  color: AppTheme.textTertiary,
                  size: 48,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                  ),
                  child: Text(
                    widget.film.baslik,
                    style: AppTheme.bodySmall.copyWith(
                      color: AppTheme.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
