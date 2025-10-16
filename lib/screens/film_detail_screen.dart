import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/film.dart';
import '../models/kaynak.dart';
import '../models/altyazi.dart';
import '../services/api_service.dart';
import '../services/film_cache_service.dart';
import '../services/source_collector_service.dart';
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
  final SourceCollectorService _sourceCollector = SourceCollectorService();

  Film? _detailedFilm;
  List<Film> _similarFilms = [];
  bool _isLoading = true;
  int _focusedButton = 0; // 0: İzle, 1: Listeye Ekle, 2: Benzer Filmler
  int _focusedSimilarFilm = 0;
  int _navbarFocusedIndex = 0;
  bool _isNavbarFocused = false;

  // Background source collection
  List<Kaynak> _discoveredSources = [];
  List<Altyazi> _discoveredSubtitles = [];
  bool _isCollectingSources = false;
  
  // Stream subscriptions
  StreamSubscription<List<Kaynak>>? _sourcesSubscription;
  StreamSubscription<List<Altyazi>>? _subtitlesSubscription;

  @override
  void initState() {
    super.initState();
    _loadFilmDetails();
    _startBackgroundSourceCollection();
  }

  @override
  void dispose() {
    _sourcesSubscription?.cancel();
    _subtitlesSubscription?.cancel();
    _sourceCollector.dispose();
    super.dispose();
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
      
      // Filmin mevcut kaynaklarını listeye ekle (hem iframe hem direkt kaynaklar)
      if (widget.film.kaynaklar != null && widget.film.kaynaklar!.isNotEmpty) {
        // Tüm kaynakları al (iframe ve direkt)
        _discoveredSources = widget.film.kaynaklar!.toList();
        debugPrint('📹 ${_discoveredSources.length} mevcut video kaynağı yüklendi (iframe: ${_discoveredSources.where((k) => k.isIframe == true).length}, direkt: ${_discoveredSources.where((k) => k.isIframe == false).length})');
      }
      
      // Filmin mevcut altyazılarını listeye ekle
      if (widget.film.altyazilar != null && widget.film.altyazilar!.isNotEmpty) {
        _discoveredSubtitles = widget.film.altyazilar!.toList();
        debugPrint('📝 ${_discoveredSubtitles.length} mevcut altyazı yüklendi');
      }
      
      _isLoading = false;
    });
  }

  /// Background'da iframe kaynaklarını topla ve veritabanına kaydet
  Future<void> _startBackgroundSourceCollection() async {
    final film = _detailedFilm ?? widget.film;

    // Film'in iframe kaynakları varsa, arka planda topla
    final iframeSources =
        film.kaynaklar?.where((k) => k.isIframe).toList() ?? [];

    if (iframeSources.isEmpty) {
      debugPrint('🔍 SOURCE COLLECTION: Iframe kaynağı yok');
      return;
    }

    setState(() {
      _isCollectingSources = true;
    });

    debugPrint(
      '🔍 SOURCE COLLECTION: ${iframeSources.length} iframe kaynağı bulundu',
    );

    // Stream'leri dinle - UI'ı real-time güncellemek için
    _sourcesSubscription = _sourceCollector.sourcesStream.listen((sources) {
      if (mounted) {
        setState(() {
          // Yeni kaynakları mevcut kaynaklara ekle (duplicate olmadan)
          final existingUrls = _discoveredSources.map((s) => s.url).toSet();
          final newSources = sources.where((s) => !existingUrls.contains(s.url)).toList();
          _discoveredSources = [..._discoveredSources, ...newSources];
        });
        debugPrint(
          '✅ SOURCE COLLECTION: Toplam ${_discoveredSources.length} video kaynağı (${sources.length} yeni)',
        );
      }
    });

    _subtitlesSubscription = _sourceCollector.subtitlesStream.listen((subtitles) {
      if (mounted) {
        setState(() {
          // Yeni altyazıları mevcut altyazılara ekle (duplicate olmadan)
          final existingUrls = _discoveredSubtitles.map((s) => s.url).toSet();
          final newSubtitles = subtitles.where((s) => !existingUrls.contains(s.url)).toList();
          _discoveredSubtitles = [..._discoveredSubtitles, ...newSubtitles];
        });
        debugPrint('✅ SOURCE COLLECTION: Toplam ${_discoveredSubtitles.length} altyazı (${subtitles.length} yeni)');
      }
    });

    // Her iframe kaynağı için toplamayı başlat (sırayla)
    for (int i = 0; i < iframeSources.length; i++) {
      final source = iframeSources[i];
      debugPrint(
        '🔍 SOURCE COLLECTION: [${i + 1}/${iframeSources.length}] Toplama başlatılıyor: ${source.baslik}',
      );

      try {
        await _sourceCollector.startCollecting(
          filmId: film.id,
          iframeUrl: source.url,
          sourceTitle: source.baslik,
        );

        debugPrint(
          '✅ SOURCE COLLECTION: [${i + 1}/${iframeSources.length}] Tamamlandı: ${source.baslik}',
        );
      } catch (e) {
        debugPrint(
          '❌ SOURCE COLLECTION: [${i + 1}/${iframeSources.length}] Hata: $e',
        );
      }
    }

    setState(() {
      _isCollectingSources = false;
    });

    debugPrint('🎉 SOURCE COLLECTION: TÜM İFRAMELER TAMAMLANDI!');
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
            style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
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

  /// Bulunan kaynakları gösteren section
  Widget _buildDiscoveredSourcesSection(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 28,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Text('Bulunan Kaynaklar', style: AppTheme.headingMedium),
            const SizedBox(width: 12),
            if (_isCollectingSources)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppTheme.primary,
                  strokeWidth: 2,
                ),
              ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
              ),
              child: Text(
                '${_discoveredSources.length} Video',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
              ),
              child: Text(
                '${_discoveredSubtitles.length} Altyazı',
                style: AppTheme.labelMedium.copyWith(
                  color: AppTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Kaynak listesi
        if (_discoveredSources.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _discoveredSources.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.white.withOpacity(0.1)),
              itemBuilder: (context, index) {
                final source = _discoveredSources[index];
                return Focus(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.select ||
                          event.logicalKey == LogicalKeyboardKey.enter) {
                        debugPrint('🎬 Kaynak tıklandı: ${source.baslik}');
                        debugPrint('📹 URL: ${source.url}');
                        context.go('/player/${widget.film.id}', extra: widget.film);
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Builder(
                    builder: (context) {
                      final isFocused = Focus.of(context).hasFocus;
                      return ListTile(
                        tileColor: isFocused
                            ? AppTheme.primary.withOpacity(0.3)
                            : Colors.transparent,
                        onTap: () {
                          debugPrint('🎬 Kaynak tıklandı: ${source.baslik}');
                          debugPrint('📹 URL: ${source.url}');
                          // Player'a git ve kaynağı geç
                          context.go('/player/${widget.film.id}', extra: widget.film);
                        },
                        leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    source.baslik,
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    source.url.length > 50
                        ? '${source.url.substring(0, 50)}...'
                        : source.url,
                    style: AppTheme.bodySmall.copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // iFrame etiketi
                      if (source.isIframe == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            border: Border.all(
                              color: Colors.blue,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'iFrame',
                            style: AppTheme.labelSmall.copyWith(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kaydedildi',
                        style: AppTheme.labelSmall.copyWith(
                          color: AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                );
                    },
                  ),
                );
              },
            ),
          ),
        // Durum mesajı
        if (_discoveredSources.isEmpty && _isCollectingSources)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.backgroundCard.withOpacity(0.3),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kaynaklar Taranıyor...',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Iframe kaynakları arka planda taranarak video linkleri bulunuyor',
                        style: AppTheme.bodySmall.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final film = _detailedFilm ?? widget.film;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/');
        }
      },
      child: RawKeyboardListener(
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
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.radiusLarge,
                                      ),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.3,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radiusLarge,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal:
                                                          AppTheme.spacingSmall,
                                                      vertical: AppTheme
                                                          .spacingXSmall,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.backgroundCard
                                                      .withOpacity(0.6),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppTheme.radiusSmall,
                                                      ),
                                                  border: Border.all(
                                                    color: AppTheme.primary
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Text(
                                                  film.yayinTarihi!,
                                                  style: AppTheme.labelMedium,
                                                ),
                                              ),
                                            ...film.turler.map(
                                              (tur) => Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal:
                                                          AppTheme.spacingSmall,
                                                      vertical: AppTheme
                                                          .spacingXSmall,
                                                    ),
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      AppTheme.primaryGradient,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        AppTheme.radiusSmall,
                                                      ),
                                                ),
                                                child: Text(
                                                  tur.baslik,
                                                  style: AppTheme.labelSmall
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ),
                                            ),
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
                                                onTap: () =>
                                                    _handleButtonPress(0),
                                                isPrimary: true,
                                                isFocused: _focusedButton == 0,
                                              ),
                                            ),
                                            SizedBox(
                                              width: AppTheme.spacingSmall,
                                            ),
                                            // Listeye Ekle Button
                                            Expanded(
                                              flex: isMobile ? 1 : 0,
                                              child: _buildActionButton(
                                                icon: Icons.add,
                                                label: 'Listeye Ekle',
                                                onTap: () =>
                                                    _handleButtonPress(1),
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
                              // Discovered Sources Section
                              if (_discoveredSources.isNotEmpty ||
                                  _isCollectingSources)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isMobile
                                        ? AppTheme.spacingLarge
                                        : AppTheme.spacingXLarge,
                                    vertical: AppTheme.spacingMedium,
                                  ),
                                  child: _buildDiscoveredSourcesSection(
                                    isMobile,
                                  ),
                                ),
                              // Film Description
                              Padding(
                                padding: EdgeInsets.all(
                                  isMobile
                                      ? AppTheme.spacingLarge
                                      : AppTheme.spacingXLarge,
                                ),
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
                                            borderRadius: BorderRadius.circular(
                                              AppTheme.radiusSmall,
                                            ),
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
                                      padding: const EdgeInsets.all(
                                        AppTheme.spacingLarge,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.backgroundCard
                                            .withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.radiusMedium,
                                        ),
                                        border: Border.all(
                                          color: AppTheme.backgroundMedium,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        film.detay ??
                                            'Açıklama bilgisi bulunmuyor.',
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
                                              gradient:
                                                  AppTheme.primaryGradient,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    AppTheme.radiusSmall,
                                                  ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: AppTheme.spacingSmall,
                                          ),
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
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
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
                                                                          color:
                                                                              Colors.white54,
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
                                                            overflow:
                                                                TextOverflow
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
      ),
    );
  }
}
