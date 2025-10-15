import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../models/film.dart';
import '../services/api_service.dart';
import '../utils/app_theme.dart';
import '../widgets/film_card.dart';
import '../widgets/navbar.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode();

  List<Film> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;
  Timer? _debounceTimer;

  // Focus kontrolü
  int _focusedIndex = 0;
  int _navbarFocusedIndex = 3; // Arama sekmesi
  bool _isNavbarFocused = false;
  bool _isSearchFieldFocused = true;

  @override
  void initState() {
    super.initState();

    // Focus listener ekle
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() {
          _isSearchFieldFocused = _searchFocusNode.hasFocus;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _keyboardFocusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    // Debounce: 500ms bekle, ardından ara
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final results = await _apiService.searchFilms(query, pageSize: 50);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
        _focusedIndex = 0; // Reset focus to first result
      });
    }
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    setState(() {
      final isMobile = MediaQuery.of(context).size.width < 800;
      final columns = (MediaQuery.of(context).size.width / 220).floor().clamp(
        2,
        10,
      );

      if (_isSearchFieldFocused) {
        // Search field'da gezinme
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (_searchResults.isNotEmpty) {
            _isSearchFieldFocused = false;
            _focusedIndex = 0;
            _searchFocusNode.unfocus();
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (!isMobile) {
            _isSearchFieldFocused = false;
            _isNavbarFocused = true;
            _searchFocusNode.unfocus();
          }
        }
      } else if (_isNavbarFocused) {
        // Navbar'da gezinme
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (!isMobile && _navbarFocusedIndex < 4) {
            _navbarFocusedIndex++;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (!isMobile && _navbarFocusedIndex > 0) {
            _navbarFocusedIndex--;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (!isMobile) {
            _isNavbarFocused = false;
            _isSearchFieldFocused = true;
            _searchFocusNode.requestFocus();
          }
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          _handleNavbarSelection(_navbarFocusedIndex);
        }
      } else {
        // Film grid'de gezinme
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          if (_focusedIndex < columns) {
            // Grid'in üstündeyken search field'a dön
            _isSearchFieldFocused = true;
            _searchFocusNode.requestFocus();
          } else {
            _focusedIndex = (_focusedIndex - columns).clamp(
              0,
              _searchResults.length - 1,
            );
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          if (_focusedIndex + columns < _searchResults.length) {
            _focusedIndex = (_focusedIndex + columns).clamp(
              0,
              _searchResults.length - 1,
            );
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          if (_focusedIndex % columns == 0 && !isMobile) {
            // En soldayken navbar'a geç
            _isNavbarFocused = true;
            _navbarFocusedIndex = 3;
          } else if (_focusedIndex > 0) {
            _focusedIndex--;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (_focusedIndex < _searchResults.length - 1) {
            _focusedIndex++;
          }
        } else if (event.logicalKey == LogicalKeyboardKey.enter) {
          if (_focusedIndex < _searchResults.length) {
            _onFilmTap(_searchResults[_focusedIndex]);
          }
        }
      }
    });
  }

  void _handleNavbarSelection(int index) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 3:
        // Already on search
        break;
      default:
        context.go('/');
    }
  }

  void _onFilmTap(Film film) {
    context.go('/film/${film.id}');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final columns = (MediaQuery.of(context).size.width / 220).floor().clamp(
      2,
      10,
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: RawKeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: false,
        onKey: (event) => _handleKeyEvent(event),
        child: Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            top: true,
            bottom: false,
            child: Row(
              children: [
                // Desktop navbar
                if (!isMobile)
                  NavBar(
                    focusedIndex: _navbarFocusedIndex,
                    onFocusChanged: (index) {
                      setState(() {
                        _navbarFocusedIndex = index;
                        _isNavbarFocused = true;
                        _isSearchFieldFocused = false;
                      });
                    },
                    isFocused: _isNavbarFocused,
                  ),
                // Ana içerik
                Expanded(
                  child: Column(
                    children: [
                      // Search Header
                      _buildSearchHeader(isMobile),
                      // Search Results
                      Expanded(child: _buildSearchResults(columns)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Mobil navbar
          bottomNavigationBar: isMobile
              ? NavBar(
                  focusedIndex: _navbarFocusedIndex,
                  onFocusChanged: (index) {
                    setState(() {
                      _navbarFocusedIndex = index;
                    });
                  },
                  isFocused: _isNavbarFocused,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildSearchHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.all(
        isMobile ? AppTheme.spacingMedium : AppTheme.spacingLarge,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.background, AppTheme.background.withOpacity(0.0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                width: 4,
                height: 32,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
              SizedBox(width: AppTheme.spacingSmall),
              Text('Arama', style: AppTheme.displaySmall),
            ],
          ),
          SizedBox(height: AppTheme.spacingLarge),
          // Search Field
          _buildSearchField(),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return TweenAnimationBuilder<double>(
      duration: AppTheme.animationMedium,
      curve: AppTheme.animationCurve,
      tween: Tween(begin: 1.0, end: _isSearchFieldFocused ? 1.02 : 1.0),
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            decoration: BoxDecoration(
              gradient: _isSearchFieldFocused
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary.withOpacity(0.1),
                        AppTheme.primaryLight.withOpacity(0.05),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: _isSearchFieldFocused
                    ? AppTheme.primary
                    : AppTheme.backgroundMedium,
                width: _isSearchFieldFocused ? 2 : 1,
              ),
              boxShadow: _isSearchFieldFocused ? AppTheme.glowShadow : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundCard.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    style: AppTheme.bodyLarge,
                    onChanged: _onSearchChanged,
                    onTap: () {
                      setState(() {
                        _isSearchFieldFocused = true;
                        _isNavbarFocused = false;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Film adı, açıklama veya orijinal başlık...',
                      hintStyle: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _isSearchFieldFocused
                            ? AppTheme.primary
                            : AppTheme.textSecondary,
                        size: 28,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppTheme.textSecondary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                              },
                            )
                          : _isSearching
                          ? Padding(
                              padding: const EdgeInsets.all(
                                AppTheme.spacingSmall,
                              ),
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                                strokeWidth: 2,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge,
                        vertical: AppTheme.spacingMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(int columns) {
    if (!_hasSearched) {
      return _buildEmptyState(
        icon: Icons.search,
        title: 'Film Ara',
        subtitle: 'Yukarıdaki arama çubuğunu kullanarak\nfilm arayabilirsiniz',
      );
    }

    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppTheme.primary, strokeWidth: 3),
            SizedBox(height: AppTheme.spacingMedium),
            Text('Filmler aranıyor...', style: AppTheme.bodyLarge),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(
        icon: Icons.movie_filter_outlined,
        title: 'Sonuç Bulunamadı',
        subtitle:
            'Arama kriterlerinize uygun film bulunamadı.\nFarklı kelimeler deneyebilirsiniz.',
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(
        MediaQuery.of(context).size.width < 800
            ? AppTheme.spacingMedium
            : AppTheme.spacingLarge,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Results count
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
            child: Text(
              '${_searchResults.length} film bulundu',
              style: AppTheme.headlineSmall.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          // Grid
          Wrap(
            spacing: AppTheme.spacingSmall,
            runSpacing: AppTheme.spacingSmall,
            children: List.generate(_searchResults.length, (index) {
              final isFocused =
                  _focusedIndex == index &&
                  !_isSearchFieldFocused &&
                  !_isNavbarFocused;
              return SizedBox(
                width: 200,
                child: FilmCard(
                  film: _searchResults[index],
                  isFocused: isFocused,
                  onTap: () => _onFilmTap(_searchResults[index]),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingXLarge),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withOpacity(0.1),
                  AppTheme.primaryLight.withOpacity(0.05),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.2),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(icon, size: 80, color: AppTheme.primary),
          ),
          SizedBox(height: AppTheme.spacingLarge),
          Text(
            title,
            style: AppTheme.headlineLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppTheme.spacingSmall),
          Text(
            subtitle,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
