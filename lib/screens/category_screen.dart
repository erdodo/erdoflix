import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/tur.dart';
import '../models/film.dart';
import '../services/tur_service.dart';
import '../widgets/film_card.dart';
import '../widgets/navbar.dart';

class CategoryScreen extends StatefulWidget {
  final Tur tur;

  const CategoryScreen({Key? key, required this.tur}) : super(key: key);

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TurService _turService = TurService();
  List<Film> _films = [];
  bool _isLoading = true;
  int _currentPage = 1;
  int _focusedIndex = 0;
  final int _itemsPerPage = 20;
  bool _hasMore = true;
  int _navbarFocusedIndex = 0;
  bool _isNavbarFocused = false;

  @override
  void initState() {
    super.initState();
    _loadFilms();
  }

  Future<void> _loadFilms({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
      });
    }

    final films = await _turService.getFilmlerByTur(
      widget.tur.id,
      page: _currentPage,
      pageSize: _itemsPerPage,
    );

    setState(() {
      if (loadMore) {
        _films.addAll(films);
      } else {
        _films = films;
      }
      _isLoading = false;
      _hasMore = films.length == _itemsPerPage;
    });
  }

  void _loadMoreFilms() {
    if (_hasMore && !_isLoading) {
      setState(() {
        _currentPage++;
      });
      _loadFilms(loadMore: true);
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      // Escape veya Backspace ile geri git
      if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        context.go('/');
        return;
      }

      final int columns = (MediaQuery.of(context).size.width / 220).floor();

      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (_focusedIndex < _films.length - 1) {
          setState(() {
            _focusedIndex++;
            // Son satırdaysak ve hala film varsa daha fazla yükle
            if (_focusedIndex >= _films.length - columns && _hasMore) {
              _loadMoreFilms();
            }
          });
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (_focusedIndex == 0 || (_focusedIndex % columns == 0)) {
          // En soldaysak navbar'a geç
          setState(() {
            _isNavbarFocused = true;
            _navbarFocusedIndex = 0;
          });
        } else if (_focusedIndex > 0) {
          setState(() {
            _focusedIndex--;
          });
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (_focusedIndex + columns < _films.length) {
          setState(() {
            _focusedIndex += columns;
            // Son satıra yaklaşıyorsak daha fazla yükle
            if (_focusedIndex >= _films.length - columns * 2 && _hasMore) {
              _loadMoreFilms();
            }
          });
        }
      } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (_focusedIndex - columns >= 0) {
          setState(() {
            _focusedIndex -= columns;
          });
        }
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        if (_focusedIndex < _films.length) {
          _onFilmTap(_films[_focusedIndex]);
        }
      }
    }
  }

  void _onFilmTap(Film film) {
    // Film detay sayfasına yönlendirme (henüz oluşturulmadı)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(film.baslik, style: const TextStyle(color: Colors.white)),
        content: Text(
          film.detay ?? 'Detay bilgisi yok',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return RawKeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKey: (event) => _handleKeyEvent(event),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Row(
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
              child: Column(
                children: [
                  // Üst başlık
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.go('/'),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.tur.baslik,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Film grid
                  Expanded(
                    child: _isLoading && _films.isEmpty
            ? const Center(child: CircularProgressIndicator(color: Colors.red))
            : _films.isEmpty
            ? const Center(
                child: Text(
                  'Bu kategoride film bulunamadı',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Grid layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: List.generate(_films.length, (index) {
                            final isFocused = _focusedIndex == index;
                            return SizedBox(
                              width: 200,
                              child: FilmCard(
                                film: _films[index],
                                isFocused: isFocused,
                                onTap: () => _onFilmTap(_films[index]),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                    // Loading indicator for more items
                    if (_isLoading && _films.isNotEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
                  ),
                ],
              ),
            ),
          ],
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
