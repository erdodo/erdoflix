import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/film.dart';
import '../models/tur.dart';
import '../services/api_service.dart';
import '../services/tur_service.dart';
import '../widgets/film_row.dart';
import '../widgets/navbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TurService _turService = TurService();

  // Her kategori için ayrı film listeleri ve sayfa numaraları
  List<Film> _popularFilms = [];
  List<Film> _newFilms = [];
  List<Film> _recommendedFilms = [];
  List<Tur> _turler = [];

  int _popularPage = 1;
  int _newPage = 1;
  int _recommendedPage = 1;

  bool _isLoading = true;
  bool _isLoadingPopular = false;
  bool _isLoadingNew = false;
  bool _isLoadingRecommended = false;

  // Fokus kontrolü için
  int _focusedRow =
      -1; // -1: Hero banner, -2: Kategoriler, 0-2: Film satırları, -3: Navbar
  int _focusedColumn = 0;
  int _heroBannerFocusedButton = 0; // 0: İzle, 1: Detaylar
  int _navbarFocusedIndex = 0; // Navbar içinde hangi item seçili
  bool _isNavbarFocused = false;
  final FocusNode _focusNode = FocusNode();
  final ScrollController _mainScrollController = ScrollController();

  // Her satırın key'ini tutmak için (kategoriler + 3 film satırı)
  final GlobalKey _categoryKey = GlobalKey();
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

    // İlk sayfalardaki filmleri ve kategorileri yükle
    final turlerFuture = _turService.getTurler(pageSize: 20);
    await Future.wait([
      _loadMorePopular(),
      _loadMoreNew(),
      _loadMoreRecommended(),
    ]);

    _turler = await turlerFuture;

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
      final isMobile = MediaQuery.of(context).size.width < 800;

      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_isNavbarFocused) {
          // Navbar içinde yukarı gezin (desktop için)
          if (!isMobile && _navbarFocusedIndex > 0) {
            _navbarFocusedIndex--;
          }
        } else if (_focusedRow > 0) {
          // Film satırlarından yukarı çık
          _focusedRow--;
          _focusedColumn = 0;
          _heroBannerFocusedButton = 0;
          _scrollToFocusedRow();
        } else if (_focusedRow == 0) {
          // İlk film satırından kategorilere geç
          _focusedRow = -2;
          _focusedColumn = 0;
          _scrollToFocusedRow();
        } else if (_focusedRow == -2) {
          // Kategorilerden hero banner'a geç
          _focusedRow = -1;
          _focusedColumn = 0;
          _heroBannerFocusedButton = 0;
          _scrollToFocusedRow();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_isNavbarFocused) {
          // Navbar içinde aşağı gezin
          if (!isMobile && _navbarFocusedIndex < 4) {
            _navbarFocusedIndex++; // 5 item var (0-4)
          }
          // Mobil navbar'dan aşağı çıkılamaz
        } else if (_focusedRow == -1) {
          // Hero banner'dan kategorilere geç
          _focusedRow = -2;
          _focusedColumn = 0;
          _scrollToFocusedRow();
        } else if (_focusedRow == -2) {
          // Kategorilerden ilk film satırına geç
          _focusedRow = 0;
          _focusedColumn = 0;
          _scrollToFocusedRow();
        } else if (_focusedRow == 2) {
          // Son film satırından navbar'a geç (sadece mobilde)
          if (isMobile) {
            _isNavbarFocused = true;
            _navbarFocusedIndex = 0;
          }
        } else if (_focusedRow < 2) {
          // Film satırları arasında gezin
          _focusedRow++;
          _focusedColumn = 0;
          _scrollToFocusedRow();
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_isNavbarFocused) {
          // Navbar içinde gezin (mobilde yatay)
          if (isMobile && _navbarFocusedIndex > 0) {
            _navbarFocusedIndex--;
          }
          // Desktop'ta navbar solda olduğu için sol ok navbar'dan çıkmaz
        } else if (!isMobile && _focusedColumn == 0) {
          // Desktop'ta en soldayken navbar'a geç
          _isNavbarFocused = true;
          _navbarFocusedIndex = 0;
        } else if (_focusedRow == -1) {
          // Hero banner butonları arasında gezin
          if (_heroBannerFocusedButton > 0) {
            _heroBannerFocusedButton--;
          } else if (!isMobile) {
            // En sol butondayken navbar'a geç
            _isNavbarFocused = true;
            _navbarFocusedIndex = 0;
          }
        } else if (_focusedRow == -2) {
          // Kategoriler arasında gezin
          if (_focusedColumn > 0) {
            _focusedColumn--;
          } else if (!isMobile) {
            // En sol kategorideyken navbar'a geç
            _isNavbarFocused = true;
            _navbarFocusedIndex = 0;
          }
        } else {
          // Film kartları arasında gezin
          if (_focusedColumn > 0) {
            _focusedColumn--;
          } else if (!isMobile) {
            // En sol karttayken navbar'a geç
            _isNavbarFocused = true;
            _navbarFocusedIndex = 0;
          }
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_isNavbarFocused) {
          // Navbar içinde gezin veya içerik alanına geç
          if (isMobile && _navbarFocusedIndex < 4) {
            _navbarFocusedIndex++; // 5 item var (0-4)
          } else if (!isMobile) {
            // Desktop'ta navbar'dan sağa gidince içerik alanına geç
            _isNavbarFocused = false;
            _focusedRow = 0;
            _focusedColumn = 0;
          }
        } else if (_focusedRow == -1) {
          // Hero banner butonları arasında gezin
          if (_heroBannerFocusedButton < 1)
            _heroBannerFocusedButton++; // 2 buton var
        } else if (_focusedRow == -2) {
          // Kategoriler arasında gezin
          if (_focusedColumn < _turler.length - 1) {
            _focusedColumn++;
          }
        } else {
          // Film kartları arasında gezin
          final maxColumns = _getFilmsForRow(_focusedRow).length;
          if (_focusedColumn < maxColumns - 1) {
            _focusedColumn++;
          }
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (_isNavbarFocused) {
          // Navbar item'ına tıklandı
          // Şu an hepsi anasayfaya yönlendiriyor, ileride değiştirilecek
          switch (_navbarFocusedIndex) {
            case 0: // Anasayfa
              context.go('/');
              break;
            case 1: // Filmler
              context.go('/');
              break;
            case 2: // Diziler
              context.go('/');
              break;
            case 3: // Arama
              context.go('/');
              break;
            case 4: // Profil
              context.go('/');
              break;
          }
        } else if (_focusedRow == -1) {
          // Hero banner butonu tıklandı
          if (_popularFilms.isNotEmpty) {
            _onFilmTap(_popularFilms.first);
          }
        } else if (_focusedRow == -2) {
          // Kategori tıklandı
          if (_focusedColumn < _turler.length) {
            context.go('/category/${_turler[_focusedColumn].id}');
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

      // Kategorilere geçildiğinde
      if (_focusedRow == -2) {
        // Hero banner yüksekliği + padding
        final heroHeight = 500 + 30;

        _mainScrollController.animateTo(
          heroHeight.toDouble(),
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
    // Film detay sayfasına yönlendir
    context.go('/film/${film.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          // En üstteki içeriği status bar'dan korur
          // Alt navigation bar için SafeArea kullanmayacağız, kendi padding'i var
          top: true,
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.red),
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
                        controller: _mainScrollController,
                        child: Column(
                          children: [
                            // Hero Banner
                            _buildHeroBanner(),
                            const SizedBox(height: 30),
                            // Kategoriler
                            if (_turler.isNotEmpty) _buildCategoryRow(),
                            const SizedBox(height: 30),
                            // Film satırları
                            FilmRow(
                              key: _rowKeys[0],
                              title: 'Popüler Filmler',
                              films: _getFilmsForRow(0),
                              onFilmTap: _onFilmTap,
                              isFocused: _focusedRow == 0 && !_isNavbarFocused,
                              focusedIndex:
                                  _focusedRow == 0 && !_isNavbarFocused
                                  ? _focusedColumn
                                  : -1,
                              onLoadMore: _loadMorePopular,
                            ),
                            const SizedBox(height: 20),
                            FilmRow(
                              key: _rowKeys[1],
                              title: 'Yeni Çıkanlar',
                              films: _getFilmsForRow(1),
                              onFilmTap: _onFilmTap,
                              isFocused: _focusedRow == 1 && !_isNavbarFocused,
                              focusedIndex:
                                  _focusedRow == 1 && !_isNavbarFocused
                                  ? _focusedColumn
                                  : -1,
                              onLoadMore: _loadMoreNew,
                            ),
                            const SizedBox(height: 20),
                            FilmRow(
                              key: _rowKeys[2],
                              title: 'Önerilen Filmler',
                              films: _getFilmsForRow(2),
                              onFilmTap: _onFilmTap,
                              isFocused: _focusedRow == 2 && !_isNavbarFocused,
                              focusedIndex:
                                  _focusedRow == 2 && !_isNavbarFocused
                                  ? _focusedColumn
                                  : -1,
                              onLoadMore: _loadMoreRecommended,
                            ),
                            SizedBox(height: isMobile ? 90 : 40),
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

  Widget _buildCategoryRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Kategoriler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 60,
          child: ListView.builder(
            key: _categoryKey,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _turler.length,
            itemBuilder: (context, index) {
              final tur = _turler[index];
              final isFocused = _focusedRow == -2 && _focusedColumn == index;
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isFocused ? Colors.red : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: isFocused
                        ? Border.all(color: Colors.white, width: 2)
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go('/category/${tur.id}'),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        child: Center(
                          child: Text(
                            tur.baslik,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: isFocused
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
