import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/film.dart';
import '../services/api_service.dart';
import '../services/film_cache_service.dart';
import '../utils/app_theme.dart';
import '../widgets/navbar.dart';

class FilmDetailScreen extends StatefulWidget {
  final Film film;

  const FilmDetailScreen({Key? key, required this.film}) : super(key: key);

  @override
  State<FilmDetailScreen> createState() => _FilmDetailScreenState();
}

class _FilmDetailScreenState extends State<FilmDetailScreen> {
  final ApiService _apiService = ApiService();
  Film? _detailedFilm;
  List<Film> _similarFilms = [];
  bool _isLoading = true;
  int _focusedButton = 0; // 0: İzle, 1: Listeye Ekle, 2: Benzer Filmler
  int _focusedSimilarFilm = 0;
  int _navbarFocusedIndex = 0;
  bool _isNavbarFocused = false;

  @override
  void initState() {
    super.initState();
    _loadFilmDetails();
  }

  Future<void> _loadFilmDetails() async {
    setState(() {
      _isLoading = true;
    });

    // widget.film zaten kaynaklar ve altyazılarla geliyor (main.dart'tan)
    // Sadece benzer filmleri yükle
    debugPrint('🎬 Detail Page: Film bilgileri:');
    debugPrint('🎬 Detail Page: Film: ${widget.film.baslik}');
    debugPrint('🎬 Detail Page: hasVideo: ${widget.film.hasVideo}');
    debugPrint('🎬 Detail Page: kaynaklar: ${widget.film.kaynaklar?.length}');
    debugPrint('🎬 Detail Page: turler: ${widget.film.turler.length}');

    // Benzer filmleri çek (aynı türdeki filmler)
    if (widget.film.turler.isNotEmpty) {
      // İlk türe göre benzer filmler
      // Not: API'de benzer filmler endpoint'i yoksa, aynı türdeki filmleri getiriyor
      final allFilms = await _apiService.getFilmler(page: 1, pageSize: 10);
      _similarFilms = allFilms
          .where((f) => f.id != widget.film.id)
          .take(6)
          .toList();
    }

    setState(() {
      // widget.film'i kullan (zaten detaylı)
      _detailedFilm = widget.film;
      _isLoading = false;
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Escape veya Backspace ile geri git
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        context.go('/');
        return;
      }

      if (_focusedButton < 2) {
        // Butonlarda gezinme
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          setState(() {
            _focusedButton = (_focusedButton + 1).clamp(0, 1);
          });
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (_focusedButton == 0) {
            // En sol buttondayken navbar'a geç
            setState(() {
              _isNavbarFocused = true;
              _navbarFocusedIndex = 0;
            });
          } else {
            setState(() {
              _focusedButton = (_focusedButton - 1).clamp(0, 1);
            });
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (_similarFilms.isNotEmpty) {
            setState(() {
              _focusedButton = 2; // Benzer filmlere geç
              _focusedSimilarFilm = 0;
            });
          }
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          if (!_isNavbarFocused) {
            _handleButtonPress(_focusedButton);
          }
        }
      } else {
        // Benzer filmlerde gezinme
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          setState(() {
            _focusedSimilarFilm = (_focusedSimilarFilm + 1).clamp(
              0,
              _similarFilms.length - 1,
            );
          });
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          setState(() {
            _focusedSimilarFilm = (_focusedSimilarFilm - 1).clamp(
              0,
              _similarFilms.length - 1,
            );
          });
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            _focusedButton = 0; // Butonlara geri dön
          });
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          if (!_isNavbarFocused) {
            // Benzer filme git
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FilmDetailScreen(film: _similarFilms[_focusedSimilarFilm]),
              ),
            );
          }
        }
      }
    }
  }

  void _handleButtonPress(int buttonIndex) {
    switch (buttonIndex) {
      case 0:
        // İzle butonu - Player'a git
        final film = _detailedFilm ?? widget.film;
        debugPrint('🎬 Film Detail -> Player');
        debugPrint('🎬 Film: ${film.baslik}');
        debugPrint('🎬 hasVideo: ${film.hasVideo}');
        debugPrint('🎬 kaynaklar: ${film.kaynaklar?.length}');

        if (film.hasVideo) {
          // Film'i cache'e kaydet
          FilmCacheService().setFilm(film);
          debugPrint('🎬 Film cache\'e kaydedildi: ${film.id}');

          context.go('/player/${film.id}', extra: film);
        } else {
          _showComingSoon('Bu film için video kaynağı bulunamadı');
        }
        break;
      case 1:
        // Listeye Ekle butonu
        _showComingSoon('Liste özelliği yakında eklenecek');
        break;
    }
  }

  void _showComingSoon(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text('Yakında', style: AppTheme.headlineSmall),
        content: Text(message, style: AppTheme.bodyMedium),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.primary,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    required bool isFocused,
  }) {
    return TweenAnimationBuilder<double>(
      duration: AppTheme.animationMedium,
      curve: AppTheme.animationCurve,
      tween: Tween(begin: 1.0, end: isFocused ? 1.05 : 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: isFocused && isPrimary
                  ? AppTheme.primaryGradient
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              boxShadow: isFocused ? AppTheme.glowShadow : null,
            ),
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 24),
              label: Text(label, style: AppTheme.labelLarge),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrimary
                    ? (isFocused ? Colors.transparent : AppTheme.primary)
                    : AppTheme.backgroundCard.withOpacity(0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                  vertical: AppTheme.spacingMedium,
                ),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  side: isFocused && !isPrimary
                      ? BorderSide(color: AppTheme.primary, width: 2)
                      : BorderSide.none,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final film = _detailedFilm ?? widget.film;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (event) => _handleKeyEvent(event),
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          top: true,
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 3,
                  ),
                )
              : Row(
                  children: [
                    // Desktop navbar (solda)
                    if (!isMobile)
                      NavBar(
                        focusedIndex: _navbarFocusedIndex,
                        onFocusChanged: (index) {
                          setState(() {
                            _navbarFocusedIndex = index;
                            _isNavbarFocused = true;
                          });
                        },
                        isFocused: _isNavbarFocused,
                      ),
                    // Ana içerik
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hero Banner with Backdrop
                            Stack(
                              children: [
                                // Backdrop Image
                                if (film.arkaPlan != null)
                                  SizedBox(
                                    width: double.infinity,
                                    height: 500,
                                    child: CachedNetworkImage(
                                      imageUrl: film.arkaPlan!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Container(color: Colors.grey[900]),
                                      errorWidget: (context, url, error) =>
                                          Container(color: Colors.grey[900]),
                                    ),
                                  ),
                                // Gradient Overlay
                                Container(
                                  width: double.infinity,
                                  height: 500,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.heroGradient,
                                  ),
                                ),
                                // Back Button with glassmorphism
                                Positioned(
                                  top: 40,
                                  left: 20,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.arrow_back,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          onPressed: () => context.go('/'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Film Info
                                Positioned(
                                  bottom: 40,
                                  left: 40,
                                  right: 40,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Title
                                      Text(
                                        film.baslik,
                                        style: isMobile
                                            ? AppTheme.displaySmall
                                            : AppTheme.displayLarge,
                                      ),
                                      SizedBox(height: AppTheme.spacingSmall),
                                      // Metadata
                                      Wrap(
                                        spacing: AppTheme.spacingSmall,
                                        runSpacing: AppTheme.spacingXSmall,
                                        children: [
                                          if (film.yayinTarihi != null)
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: AppTheme.spacingSmall,
                                                vertical: AppTheme.spacingXSmall,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppTheme.backgroundCard.withOpacity(0.6),
                                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                                border: Border.all(
                                                  color: AppTheme.primary.withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                film.yayinTarihi!,
                                                style: AppTheme.labelMedium,
                                              ),
                                            ),
                                          ...film.turler.map((tur) => Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: AppTheme.spacingSmall,
                                                  vertical: AppTheme.spacingXSmall,
                                                ),
                                                decoration: BoxDecoration(
                                                  gradient: AppTheme.primaryGradient,
                                                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                                ),
                                                child: Text(
                                                  tur.baslik,
                                                  style: AppTheme.labelSmall.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              )),
                                        ],
                                      ),
                                      SizedBox(height: AppTheme.spacingLarge),
                                      // Action Buttons
                                      Row(
                                        children: [
                                          // İzle Button
                                          Expanded(
                                            flex: isMobile ? 1 : 0,
                                            child: _buildActionButton(
                                              icon: Icons.play_arrow,
                                              label: 'İzle',
                                              onTap: () => _handleButtonPress(0),
                                              isPrimary: true,
                                              isFocused: _focusedButton == 0,
                                            ),
                                          ),
                                          SizedBox(width: AppTheme.spacingSmall),
                                          // Listeye Ekle Button
                                          Expanded(
                                            flex: isMobile ? 1 : 0,
                                            child: _buildActionButton(
                                              icon: Icons.add,
                                              label: 'Listeye Ekle',
                                              onTap: () => _handleButtonPress(1),
                                              isPrimary: false,
                                              isFocused: _focusedButton == 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            // Film Description
                            Padding(
                              padding: EdgeInsets.all(isMobile ? AppTheme.spacingLarge : AppTheme.spacingXLarge),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          gradient: AppTheme.primaryGradient,
                                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                        ),
                                      ),
                                      SizedBox(width: AppTheme.spacingSmall),
                                      Text(
                                        'Açıklama',
                                        style: AppTheme.headlineMedium,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppTheme.spacingMedium),
                                  Container(
                                    padding: const EdgeInsets.all(AppTheme.spacingLarge),
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundCard.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                      border: Border.all(
                                        color: AppTheme.backgroundMedium,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      film.detay ?? 'Açıklama bilgisi bulunmuyor.',
                                      style: AppTheme.bodyLarge,
                                    ),
                                  ),
                                  SizedBox(height: AppTheme.spacingXLarge),
                                  // Similar Films
                                  if (_similarFilms.isNotEmpty) ...[
                                    Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.primaryGradient,
                                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                          ),
                                        ),
                                        SizedBox(width: AppTheme.spacingSmall),
                                        Text(
                                          'Benzer Filmler',
                                          style: AppTheme.headlineMedium,
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: AppTheme.spacingMedium),
                                    SizedBox(
                                      height: 300,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _similarFilms.length,
                                        itemBuilder: (context, index) {
                                          final similarFilm =
                                              _similarFilms[index];
                                          final isFocused =
                                              _focusedButton == 2 &&
                                              _focusedSimilarFilm == index;
                                          return Container(
                                            width: 200,
                                            margin: const EdgeInsets.only(
                                              right: 12,
                                            ),
                                            child: Transform.scale(
                                              scale: isFocused ? 1.1 : 1.0,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: isFocused
                                                      ? Border.all(
                                                          color: Colors.white,
                                                          width: 3,
                                                        )
                                                      : null,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Poster
                                                      AspectRatio(
                                                        aspectRatio: 2 / 3,
                                                        child:
                                                            similarFilm
                                                                    .poster !=
                                                                null
                                                            ? CachedNetworkImage(
                                                                imageUrl:
                                                                    similarFilm
                                                                        .poster!,
                                                                fit: BoxFit
                                                                    .cover,
                                                                placeholder:
                                                                    (
                                                                      context,
                                                                      url,
                                                                    ) => Container(
                                                                      color: Colors
                                                                          .grey[800],
                                                                    ),
                                                                errorWidget:
                                                                    (
                                                                      context,
                                                                      url,
                                                                      error,
                                                                    ) => Container(
                                                                      color: Colors
                                                                          .grey[800],
                                                                      child: const Icon(
                                                                        Icons
                                                                            .movie,
                                                                        color: Colors
                                                                            .white54,
                                                                        size:
                                                                            50,
                                                                      ),
                                                                    ),
                                                              )
                                                            : Container(
                                                                color: Colors
                                                                    .grey[800],
                                                                child: const Icon(
                                                                  Icons.movie,
                                                                  color: Colors
                                                                      .white54,
                                                                  size: 50,
                                                                ),
                                                              ),
                                                      ),
                                                      // Title
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              8.0,
                                                            ),
                                                        child: Text(
                                                          similarFilm.baslik,
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        // Mobil navbar (altta)
        bottomNavigationBar: isMobile
            ? NavBar(
                focusedIndex: _navbarFocusedIndex,
                onFocusChanged: (index) {
                  setState(() {
                    _navbarFocusedIndex = index;
                    _isNavbarFocused = true;
                  });
                },
                isFocused: _isNavbarFocused,
              )
            : null,
      ),
    );
  }
}
