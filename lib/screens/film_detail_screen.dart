import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/film.dart';
import '../services/api_service.dart';

class FilmDetailScreen extends StatefulWidget {
  final Film film;

  const FilmDetailScreen({
    Key? key,
    required this.film,
  }) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _loadFilmDetails();
  }

  Future<void> _loadFilmDetails() async {
    setState(() {
      _isLoading = true;
    });

    // Film detaylarını çek (turler ile birlikte)
    final detailedFilm = await _apiService.getFilm(widget.film.id);
    
    // Benzer filmleri çek (aynı türdeki filmler)
    if (detailedFilm != null && detailedFilm.turler.isNotEmpty) {
      // İlk türe göre benzer filmler
      // Not: API'de benzer filmler endpoint'i yoksa, aynı türdeki filmleri getiriyor
      final allFilms = await _apiService.getFilmler(page: 1, pageSize: 10);
      _similarFilms = allFilms
          .where((f) => f.id != widget.film.id)
          .take(6)
          .toList();
    }

    setState(() {
      _detailedFilm = detailedFilm;
      _isLoading = false;
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (_focusedButton < 2) {
        // Butonlarda gezinme
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          setState(() {
            _focusedButton = (_focusedButton + 1).clamp(0, 1);
          });
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          setState(() {
            _focusedButton = (_focusedButton - 1).clamp(0, 1);
          });
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (_similarFilms.isNotEmpty) {
            setState(() {
              _focusedButton = 2; // Benzer filmlere geç
              _focusedSimilarFilm = 0;
            });
          }
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          _handleButtonPress(_focusedButton);
        }
      } else {
        // Benzer filmlerde gezinme
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          setState(() {
            _focusedSimilarFilm = 
                (_focusedSimilarFilm + 1).clamp(0, _similarFilms.length - 1);
          });
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          setState(() {
            _focusedSimilarFilm = (_focusedSimilarFilm - 1).clamp(0, _similarFilms.length - 1);
          });
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          setState(() {
            _focusedButton = 0; // Butonlara geri dön
          });
        } else if (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) {
          // Benzer filme git
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FilmDetailScreen(
                film: _similarFilms[_focusedSimilarFilm],
              ),
            ),
          );
        }
      }
    }
  }

  void _handleButtonPress(int buttonIndex) {
    switch (buttonIndex) {
      case 0:
        // İzle butonu
        _showComingSoon('Video oynatıcı yakında eklenecek');
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
        backgroundColor: Colors.grey[900],
        title: const Text('Yakında', style: TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final film = _detailedFilm ?? widget.film;

    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (event) => _handleKeyEvent(event),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : SingleChildScrollView(
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
                              placeholder: (context, url) => Container(
                                color: Colors.grey[900],
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[900],
                              ),
                            ),
                          ),
                        // Gradient Overlay
                        Container(
                          width: double.infinity,
                          height: 500,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                                Colors.black,
                              ],
                            ),
                          ),
                        ),
                        // Back Button
                        Positioned(
                          top: 40,
                          left: 20,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white, size: 30),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        // Film Info
                        Positioned(
                          bottom: 40,
                          left: 40,
                          right: 40,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                film.baslik,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Metadata
                              Row(
                                children: [
                                  if (film.yayinTarihi != null)
                                    Text(
                                      film.yayinTarihi!,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 16,
                                      ),
                                    ),
                                  if (film.turler.isNotEmpty) ...[
                                    const SizedBox(width: 16),
                                    Text(
                                      film.turler.map((t) => t.baslik).join(', '),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Action Buttons
                              Row(
                                children: [
                                  // İzle Button
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: _focusedButton == 0
                                          ? Colors.white
                                          : Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(4),
                                      border: _focusedButton == 0
                                          ? Border.all(color: Colors.red, width: 3)
                                          : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _handleButtonPress(0),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.play_arrow,
                                                  color: Colors.black, size: 30),
                                              SizedBox(width: 8),
                                              Text(
                                                'İzle',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // Listeye Ekle Button
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[800]!.withOpacity(
                                        _focusedButton == 1 ? 1.0 : 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      border: _focusedButton == 1
                                          ? Border.all(color: Colors.white, width: 3)
                                          : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _handleButtonPress(1),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Icon(Icons.add, color: Colors.white, size: 30),
                                              SizedBox(width: 8),
                                              Text(
                                                'Listeye Ekle',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Açıklama',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            film.detay ?? 'Açıklama bilgisi bulunmuyor.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Similar Films
                          if (_similarFilms.isNotEmpty) ...[
                            const Text(
                              'Benzer Filmler',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 300,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _similarFilms.length,
                                itemBuilder: (context, index) {
                                  final similarFilm = _similarFilms[index];
                                  final isFocused = _focusedButton == 2 && 
                                      _focusedSimilarFilm == index;
                                  return Container(
                                    width: 200,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Transform.scale(
                                      scale: isFocused ? 1.1 : 1.0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: isFocused
                                              ? Border.all(
                                                  color: Colors.white, width: 3)
                                              : null,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Poster
                                              AspectRatio(
                                                aspectRatio: 2 / 3,
                                                child: similarFilm.poster != null
                                                    ? CachedNetworkImage(
                                                        imageUrl:
                                                            similarFilm.poster!,
                                                        fit: BoxFit.cover,
                                                        placeholder: (context, url) =>
                                                            Container(
                                                          color: Colors.grey[800],
                                                        ),
                                                        errorWidget: (context, url,
                                                                error) =>
                                                            Container(
                                                          color: Colors.grey[800],
                                                          child: const Icon(
                                                              Icons.movie,
                                                              color: Colors.white54,
                                                              size: 50),
                                                        ),
                                                      )
                                                    : Container(
                                                        color: Colors.grey[800],
                                                        child: const Icon(Icons.movie,
                                                            color: Colors.white54,
                                                            size: 50),
                                                      ),
                                              ),
                                              // Title
                                              Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Text(
                                                  similarFilm.baslik,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
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
    );
  }
}
