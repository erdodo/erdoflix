import 'package:flutter/material.dart';
import '../models/film.dart';
import '../utils/app_theme.dart';
import 'film_card.dart';

class FilmRow extends StatefulWidget {
  final String title;
  final List<Film> films;
  final Function(Film) onFilmTap;
  final bool isFocused;
  final int focusedIndex;
  final VoidCallback? onLoadMore; // Daha fazla film yüklemek için callback

  const FilmRow({
    super.key,
    required this.title,
    required this.films,
    required this.onFilmTap,
    this.isFocused = false,
    this.focusedIndex = 0,
    this.onLoadMore,
  });

  @override
  State<FilmRow> createState() => _FilmRowState();
}

class _FilmRowState extends State<FilmRow> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(FilmRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFocused && widget.focusedIndex != oldWidget.focusedIndex) {
      _scrollToFocusedItem();
      _checkAndLoadMore();
    }
  }

  void _onScroll() {
    // Scroll pozisyonunu kontrol et ve gerekirse daha fazla yükle
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _checkAndLoadMore();
    }
  }

  void _checkAndLoadMore() {
    if (!_isLoadingMore && widget.onLoadMore != null) {
      // Son 5 filme yaklaştıysak yeni sayfa yükle
      if (widget.focusedIndex >= widget.films.length - 5) {
        setState(() {
          _isLoadingMore = true;
        });
        widget.onLoadMore!();
        // Loading state'i parent tarafından sıfırlanacak
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  void _scrollToFocusedItem() {
    if (widget.focusedIndex >= 0 && widget.focusedIndex < widget.films.length) {
      final itemWidth = 200.0; // Film kartı genişliği
      final spacing = 12.0;
      final padding = 16.0;

      // Ekran genişliğini al
      final screenWidth = MediaQuery.of(context).size.width;
      final visibleWidth = screenWidth - (padding * 2);

      // Hedef öğenin konumunu hesapla
      final itemPosition = (itemWidth + spacing) * widget.focusedIndex;

      // Öğeyi ekranın ortasına hizala
      final centerOffset = itemPosition - (visibleWidth / 2) + (itemWidth / 2);

      // Scroll pozisyonunu sınırlandır
      final maxScroll = _scrollController.position.maxScrollExtent;
      final targetScroll = centerOffset.clamp(0.0, maxScroll);

      _scrollController.animateTo(
        targetScroll,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingMedium,
            vertical: AppTheme.spacingSmall,
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(widget.title, style: AppTheme.headlineMedium),
            ],
          ),
        ),
        SizedBox(
          height: 380, // Scale ve glow için daha fazla alan (330'dan 380'e)
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Normal ListView (focus olmayan kartlar)
              ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 25,
                ), // Üst-alt padding eklendi
                itemCount: widget.films.length,
                itemBuilder: (context, index) {
                  final isFocused =
                      widget.isFocused && widget.focusedIndex == index;

                  // Focus olan kartı burada gösterme, sadece placeholder
                  if (isFocused) {
                    return Container(
                      width: 200,
                      margin: const EdgeInsets.only(right: 12),
                      color: Colors.transparent,
                    );
                  }

                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 12),
                    child: FilmCard(
                      film: widget.films[index],
                      isFocused: false,
                      onTap: () => widget.onFilmTap(widget.films[index]),
                    ),
                  );
                },
              ),
              // Focus olan kartı en üstte göster
              if (widget.isFocused &&
                  widget.focusedIndex >= 0 &&
                  widget.focusedIndex < widget.films.length)
                Positioned(
                  left:
                      16 +
                      (widget.focusedIndex * 212.0) -
                      _scrollController.offset,
                  top: 25,
                  child: Container(
                    width: 200,
                    child: FilmCard(
                      film: widget.films[widget.focusedIndex],
                      isFocused: true,
                      onTap: () =>
                          widget.onFilmTap(widget.films[widget.focusedIndex]),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
