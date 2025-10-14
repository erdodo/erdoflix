import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:better_player/better_player.dart';
import 'package:go_router/go_router.dart';
import '../models/film.dart';
import '../models/resume_play.dart';
import '../services/resume_play_service.dart';

class PlayerScreen extends StatefulWidget {
  final Film film;

  const PlayerScreen({super.key, required this.film});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  BetterPlayerController? _betterPlayerController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  // Player state
  int _selectedKaynakIndex = 0;
  int? _selectedAltyaziIndex;
  ResumePlay? _resumePosition;
  bool _isControlsVisible = true;
  
  // Otomatik gizleme için timer
  DateTime _lastInteraction = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    
    // Kontrolleri 3 saniye sonra gizle
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _isControlsVisible = false);
      }
    });
  }

  Future<void> _initializePlayer() async {
    try {
      // Film kaynağı var mı kontrol et
      if (!widget.film.hasVideo) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Bu film için video kaynağı bulunamadı';
          _isLoading = false;
        });
        return;
      }

      // Son izleme pozisyonunu getir
      _resumePosition =
          await ResumePlayService.getResumePosition(widget.film.id);

      // Better Player konfigürasyonu
      BetterPlayerConfiguration betterPlayerConfiguration =
          BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        fit: BoxFit.contain,
        autoPlay: true,
        looping: false,
        fullScreenByDefault: true,
        deviceOrientationsAfterFullScreen: [
          DeviceOrientation.portraitUp,
        ],
        controlsConfiguration: const BetterPlayerControlsConfiguration(
          enableSkips: true,
          enableFullscreen: true,
          enablePip: false,
          enableMute: true,
          enableSubtitles: true,
          enableQualities: true,
          enablePlayPause: true,
          enableProgressBar: true,
          enableProgressText: true,
          enableAudioTracks: false,
          showControlsOnInitialize: false,
          controlBarHeight: 60,
          progressBarPlayedColor: Colors.red,
          progressBarHandleColor: Colors.red,
        ),
        translations: [
          BetterPlayerTranslations(
            languageCode: 'tr',
            generalDefaultError: 'Video yüklenirken hata oluştu',
            generalNone: 'Yok',
            generalDefault: 'Varsayılan',
            controlsLive: 'CANLI',
            controlsNextVideoIn: 'Sonraki video:',
            overflowMenuPlaybackSpeed: 'Oynatma hızı',
            overflowMenuSubtitles: 'Altyazılar',
            overflowMenuQuality: 'Kalite',
          ),
        ],
      );

      // İlk kaynak
      final kaynak = widget.film.kaynaklar![_selectedKaynakIndex];
      
      // Altyazıları hazırla
      List<BetterPlayerSubtitlesSource>? subtitles;
      if (widget.film.altyazilar != null &&
          widget.film.altyazilar!.isNotEmpty) {
        subtitles = widget.film.altyazilar!
            .map((altyazi) => BetterPlayerSubtitlesSource(
                  type: BetterPlayerSubtitlesSourceType.network,
                  name: altyazi.baslik,
                  urls: [altyazi.url],
                ))
            .toList();
      }

      // Data source
      BetterPlayerDataSource betterPlayerDataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        kaynak.url,
        subtitles: subtitles,
        notificationConfiguration: BetterPlayerNotificationConfiguration(
          showNotification: true,
          title: widget.film.baslik,
          author: 'ErdoFlix',
          imageUrl: widget.film.poster ?? '',
        ),
      );

      _betterPlayerController = BetterPlayerController(
        betterPlayerConfiguration,
        betterPlayerDataSource: betterPlayerDataSource,
      );

      // Event listener ekle
      _betterPlayerController!.addEventsListener((event) {
        if (event.betterPlayerEventType == BetterPlayerEventType.progress) {
          // Progress güncellemesi - her 10 saniyede bir kaydet
          final position = event.parameters?['progress'] as Duration?;
          final duration = event.parameters?['duration'] as Duration?;
          
          if (position != null && duration != null) {
            _saveProgress(position.inSeconds, duration.inSeconds);
          }
        } else if (event.betterPlayerEventType ==
            BetterPlayerEventType.finished) {
          // Video tamamlandı
          _onVideoFinished();
        }
      });

      // Resume position varsa oradan başlat
      if (_resumePosition != null && _resumePosition!.position > 0) {
        await _betterPlayerController!.seekTo(
          Duration(seconds: _resumePosition!.position),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Player başlatılırken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  // Progress kaydetme (throttle ile)
  DateTime? _lastSave;
  Future<void> _saveProgress(int position, int duration) async {
    // 10 saniyede bir kaydet
    final now = DateTime.now();
    if (_lastSave != null &&
        now.difference(_lastSave!).inSeconds < 10) {
      return;
    }

    _lastSave = now;
    
    final resumePlay = ResumePlay(
      filmId: widget.film.id,
      userId: 1, // Şimdilik sabit
      position: position,
      duration: duration,
      durum: 'watching',
    );

    await ResumePlayService.saveResumePosition(resumePlay);
  }

  // Video tamamlandığında
  Future<void> _onVideoFinished() async {
    await ResumePlayService.deleteResumePosition(widget.film.id);
    if (mounted) {
      // Ana sayfaya dön
      context.go('/');
    }
  }

  // Kaynak değiştir
  void _changeSource(int index) {
    if (_betterPlayerController == null || widget.film.kaynaklar == null) {
      return;
    }

    final currentPosition = _betterPlayerController!.videoPlayerController?.value.position;
    
    setState(() {
      _selectedKaynakIndex = index;
    });

    final kaynak = widget.film.kaynaklar![index];
    
    // Yeni data source
    final newDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      kaynak.url,
      subtitles: widget.film.altyazilar != null
          ? widget.film.altyazilar!
              .map((a) => BetterPlayerSubtitlesSource(
                    type: BetterPlayerSubtitlesSourceType.network,
                    name: a.baslik,
                    urls: [a.url],
                  ))
              .toList()
          : null,
    );

    _betterPlayerController!.setupDataSource(newDataSource).then((_) {
      if (currentPosition != null) {
        _betterPlayerController!.seekTo(currentPosition);
      }
    });
  }

  // Kontrolleri göster/gizle
  void _toggleControls() {
    setState(() {
      _isControlsVisible = !_isControlsVisible;
      _lastInteraction = DateTime.now();
    });

    // 3 saniye sonra tekrar gizle
    if (_isControlsVisible) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && DateTime.now().difference(_lastInteraction).inSeconds >= 3) {
          setState(() => _isControlsVisible = false);
        }
      });
    }
  }

  // Klavye event handler
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    _toggleControls(); // Her tuşta kontrolleri göster

    final controller = _betterPlayerController;
    if (controller == null) return;

    if (event.logicalKey == LogicalKeyboardKey.space ||
        event.logicalKey == LogicalKeyboardKey.keyK) {
      // Play/Pause
      if (controller.isPlaying() ?? false) {
        controller.pause();
      } else {
        controller.play();
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      // 10 saniye ileri
      final current = controller.videoPlayerController?.value.position;
      if (current != null) {
        controller.seekTo(current + const Duration(seconds: 10));
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      // 10 saniye geri
      final current = controller.videoPlayerController?.value.position;
      if (current != null) {
        controller.seekTo(current - const Duration(seconds: 10));
      }
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // Ses artır
      final currentVolume = controller.videoPlayerController?.value.volume ?? 1.0;
      controller.setVolume((currentVolume + 0.1).clamp(0.0, 1.0));
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      // Ses azalt
      final currentVolume = controller.videoPlayerController?.value.volume ?? 1.0;
      controller.setVolume((currentVolume - 0.1).clamp(0.0, 1.0));
    } else if (event.logicalKey == LogicalKeyboardKey.keyF) {
      // Tam ekran toggle
      controller.toggleFullScreen();
    } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
      // Mute toggle
      final currentVolume = controller.videoPlayerController?.value.volume ?? 1.0;
      controller.setVolume(currentVolume > 0 ? 0 : 1.0);
    } else if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      // Geri dön
      context.go('/');
    } else if (event.logicalKey == LogicalKeyboardKey.keyC) {
      // Altyazı menüsünü göster
      _showSubtitleMenu();
    } else if (event.logicalKey == LogicalKeyboardKey.keyQ) {
      // Kalite menüsünü göster
      _showQualityMenu();
    }
  }

  // Altyazı menüsü
  void _showSubtitleMenu() {
    if (widget.film.altyazilar == null || widget.film.altyazilar!.isEmpty) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Altyazı Seç', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Altyazı Yok', style: TextStyle(color: Colors.white)),
              trailing: _selectedAltyaziIndex == null
                  ? const Icon(Icons.check, color: Colors.red)
                  : null,
              onTap: () {
                setState(() => _selectedAltyaziIndex = null);
                // Better player altyazı değişimi built-in kontroller ile yapılıyor
                Navigator.pop(context);
              },
            ),
            ...widget.film.altyazilar!.asMap().entries.map((entry) {
              return ListTile(
                title: Text(entry.value.baslik,
                    style: const TextStyle(color: Colors.white)),
                trailing: _selectedAltyaziIndex == entry.key
                    ? const Icon(Icons.check, color: Colors.red)
                    : null,
                onTap: () {
                  setState(() => _selectedAltyaziIndex = entry.key);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  // Kalite menüsü
  void _showQualityMenu() {
    if (widget.film.kaynaklar == null || widget.film.kaynaklar!.length <= 1) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Kalite Seç', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.film.kaynaklar!.asMap().entries.map((entry) {
            return ListTile(
              title: Text(entry.value.baslik,
                  style: const TextStyle(color: Colors.white)),
              trailing: _selectedKaynakIndex == entry.key
                  ? const Icon(Icons.check, color: Colors.red)
                  : null,
              onTap: () {
                _changeSource(entry.key);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _betterPlayerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.red),
              )
            : _hasError
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => context.go('/'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Ana Sayfaya Dön'),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      // Video Player
                      Center(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: BetterPlayer(
                            controller: _betterPlayerController!,
                          ),
                        ),
                      ),
                      
                      // Overlay tıklanabilir alan (kontrolleri göster/gizle)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _toggleControls,
                          behavior: HitTestBehavior.translucent,
                        ),
                      ),

                      // Klavye kısayol bilgisi (sağ üstte)
                      if (_isControlsVisible)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Space/K: Oynat/Durdur',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                Text('← →: 10sn Geri/İleri',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                Text('↑ ↓: Ses Artır/Azalt',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                Text('F: Tam Ekran',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                Text('M: Sessiz',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                Text('C: Altyazı',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                Text('Q: Kalite',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                                Text('Esc: Çıkış',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
