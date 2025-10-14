import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/film.dart';
import '../services/api_service.dart';
import '../widgets/film_row.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  // Her kategori için ayrı film listeleri ve sayfa numaraları
  List<Film> _popularFilms = [];
  List<Film> _newFilms = [];
  List<Film> _recommendedFilms = [];

  int _popularPage = 1;
  int _newPage = 1;
  int _recommendedPage = 1;

  bool _isLoading = true;
  bool _isLoadingPopular = false;
  bool _isLoadingNew = false;
  bool _isLoadingRecommended = false;

  // Fokus kontrolü için
  int _focusedRow = -1; // -1: Hero banner, 0-2: Film satırları
  int _focusedColumn = 0;
  int _heroBannerFocusedButton = 0; // 0: İzle, 1: Detaylar
  final FocusNode _focusNode = FocusNode();
  final ScrollController _mainScrollController = ScrollController();

  // Her satırın key'ini tutmak için
  final List<GlobalKey> _rowKeys = [GlobalKey(), GlobalKey(), GlobalKey()];

  @override
  void initState() {
    super.initState();
    _loadFilms();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadFilms() async {
    setState(() {
      _isLoading = true;
    });

    // İlk sayfalardaki filmleri yükle
    await Future.wait([
      _loadMorePopular(),
      _loadMoreNew(),
      _loadMoreRecommended(),
    ]);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadMorePopular() async {
    if (_isLoadingPopular) return;

    setState(() {
      _isLoadingPopular = true;
    });

    final films = await _apiService.getFilmler(
      page: _popularPage,
      pageSize: 20,
    );

    setState(() {
      _popularFilms.addAll(films);
      _popularPage++;
      _isLoadingPopular = false;
    });
  }

  Future<void> _loadMoreNew() async {
    if (_isLoadingNew) return;

    setState(() {
      _isLoadingNew = true;
    });

    final films = await _apiService.getFilmler(page: _newPage, pageSize: 20);

    setState(() {
      _newFilms.addAll(films);
      _newPage++;
      _isLoadingNew = false;
    });
  }

  Future<void> _loadMoreRecommended() async {
    if (_isLoadingRecommended) return;

    setState(() {
      _isLoadingRecommended = true;
    });

    final films = await _apiService.getFilmler(
      page: _recommendedPage,
      pageSize: 20,
    );

    setState(() {
      _recommendedFilms.addAll(films);
      _recommendedPage++;
      _isLoadingRecommended = false;
    });
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    setState(() {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_focusedRow > -1) {
          _focusedRow--;
          _focusedColumn = 0;
          _heroBannerFocusedButton = 0;
          _scrollToFocusedRow();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_focusedRow < 2) {
          // -1: Hero banner, 0-2: Film satırları
          _focusedRow++;
          _focusedColumn = 0;
          _scrollToFocusedRow();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_focusedRow == -1) {
          // Hero banner butonları arasında gezin
          if (_heroBannerFocusedButton > 0) _heroBannerFocusedButton--;
        } else {
          // Film kartları arasında gezin
          if (_focusedColumn > 0) _focusedColumn--;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_focusedRow == -1) {
          // Hero banner butonları arasında gezin
          if (_heroBannerFocusedButton < 1)
            _heroBannerFocusedButton++; // 2 buton var
        } else {
          // Film kartları arasında gezin
          final maxColumns = _getFilmsForRow(_focusedRow).length;
          if (_focusedColumn < maxColumns - 1) _focusedColumn++;
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (_focusedRow == -1) {
          // Hero banner butonu tıklandı
          if (_popularFilms.isNotEmpty) {
            _onFilmTap(_popularFilms.first);
          }
        } else {
          // Film kartı tıklandı
          final films = _getFilmsForRow(_focusedRow);
          if (_focusedColumn < films.length) {
            _onFilmTap(films[_focusedColumn]);
          }
        }
      }
    });
  }

  void _scrollToFocusedRow() {
    // Widget oluşturulduktan sonra scroll yap
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Hero banner'a geçildiğinde en üste scroll yap
      if (_focusedRow == -1) {
        _mainScrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        return;
      }

      if (_rowKeys[_focusedRow].currentContext != null) {
        final RenderBox renderBox =
            _rowKeys[_focusedRow].currentContext!.findRenderObject()
                as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);

        // AppBar yüksekliğini hesaba kat
        final appBarHeight =
            AppBar().preferredSize.height + MediaQuery.of(context).padding.top;

        // Hedef scroll pozisyonu
        final targetScroll =
            _mainScrollController.offset + position.dy - appBarHeight - 20;

        _mainScrollController.animateTo(
          targetScroll.clamp(
            0.0,
            _mainScrollController.position.maxScrollExtent,
          ),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  List<Film> _getFilmsForRow(int row) {
    switch (row) {
      case 0:
        return _popularFilms;
      case 1:
        return _newFilms;
      case 2:
        return _recommendedFilms;
      default:
        return [];
    }
  }

  void _onFilmTap(Film film) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(film.baslik, style: const TextStyle(color: Colors.white)),
        content: Text(
          film.detay ?? 'Detay bilgisi bulunmamaktadır.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Oynatıcıya yönlendir
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Oynatıcı açılıyor...')),
              );
            },
            child: const Text('İzle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.8),
          title: Row(
            children: [
              const Text(
                'ERDOFLIX',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Arama özelliği yakında eklenecek'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : SingleChildScrollView(
                controller: _mainScrollController,
                child: Column(
                  children: [
                    // Hero Banner
                    _buildHeroBanner(),
                    const SizedBox(height: 20),
                    // Film satırları
                    FilmRow(
                      key: _rowKeys[0],
                      title: 'Popüler Filmler',
                      films: _getFilmsForRow(0),
                      onFilmTap: _onFilmTap,
                      isFocused: _focusedRow == 0,
                      focusedIndex: _focusedRow == 0 ? _focusedColumn : -1,
                      onLoadMore: _loadMorePopular,
                    ),
                    const SizedBox(height: 20),
                    FilmRow(
                      key: _rowKeys[1],
                      title: 'Yeni Çıkanlar',
                      films: _getFilmsForRow(1),
                      onFilmTap: _onFilmTap,
                      isFocused: _focusedRow == 1,
                      focusedIndex: _focusedRow == 1 ? _focusedColumn : -1,
                      onLoadMore: _loadMoreNew,
                    ),
                    const SizedBox(height: 20),
                    FilmRow(
                      key: _rowKeys[2],
                      title: 'Önerilen Filmler',
                      films: _getFilmsForRow(2),
                      onFilmTap: _onFilmTap,
                      isFocused: _focusedRow == 2,
                      focusedIndex: _focusedRow == 2 ? _focusedColumn : -1,
                      onLoadMore: _loadMoreRecommended,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeroBanner() {
    if (_popularFilms.isEmpty) {
      return const SizedBox.shrink();
    }

    final heroFilm = _popularFilms.first;

    return Container(
      height: 500,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.3), Colors.black],
        ),
      ),
      child: Stack(
        children: [
          // Arka plan görseli
          if (heroFilm.arkaPlan != null)
            Positioned.fill(
              child: Image.network(
                heroFilm.arkaPlan!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Colors.grey[900]);
                },
              ),
            ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                    Colors.black,
                  ],
                ),
              ),
            ),
          ),
          // Film bilgileri
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heroFilm.baslik,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  heroFilm.detay ?? 'Detay bilgisi bulunmamaktadır.',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    // İzle butonu
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border:
                            _focusedRow == -1 && _heroBannerFocusedButton == 0
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow:
                            _focusedRow == -1 && _heroBannerFocusedButton == 0
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _onFilmTap(heroFilm),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('İzle'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Detaylar butonu
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border:
                            _focusedRow == -1 && _heroBannerFocusedButton == 1
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                        boxShadow:
                            _focusedRow == -1 && _heroBannerFocusedButton == 1
                            ? [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.6),
                                  blurRadius: 15,
                                  spreadRadius: 3,
                                ),
                              ]
                            : null,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _onFilmTap(heroFilm),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('Detaylar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
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
    );
  }
}
