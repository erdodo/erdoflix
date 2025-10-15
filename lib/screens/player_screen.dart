import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
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
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  int _selectedKaynakIndex = 0;
  ResumePlay? _resumePosition;
  DateTime? _lastSave;

  // Custom kontroller için
  bool _showControls = true;
  int _focusedControl = -1; // -1: video, 0: geri, 1: progress, 2: butonlar
  int _focusedButton =
      0; // Alt butonlar: 0: play/pause, 1: kaynak, 2: altyazı, 3: hız, 4: PIP
  Timer? _hideTimer;

  // Progress bar uzun basma için
  Timer? _seekTimer;
  int _seekMultiplier = 1; // 5sn × multiplier

  // Oynatma hızı seçenekleri
  final List<double> _playbackSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  int _selectedSpeedIndex = 2; // 1.0x

  // Altyazı seçimi
  int _selectedAltyaziIndex = -1; // -1: Altyazı yok
  List<Subtitle> _currentSubtitles = []; // Yüklü alt yazılar
  String _currentSubtitleText = ''; // Şu anda gösterilecek alt yazı

  // Player'a girerken mevcut orientation'ı sakla
  List<DeviceOrientation>? _previousOrientations;
  bool _orientationSaved = false;

  @override
  void initState() {
    super.initState();

    // Landscape (yatay) moda geç
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    // Tam ekran moda geç (system UI'ları gizle)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initializePlayer();
    _resetHideTimer(); // Kontrolleri 3 saniye sonra gizle
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // İlk kez çağrıldığında orientation'ı kaydet
    if (!_orientationSaved) {
      _savePreviousOrientation();
      _orientationSaved = true;
    }
  }

  // Mevcut orientation'ı kaydet
  void _savePreviousOrientation() {
    // MediaQuery'den mevcut ekran boyutunu al
    final size = MediaQuery.of(context).size;

    // Eğer width > height ise landscape (yatay), değilse portrait (dikey)
    final isLandscape = size.width > size.height;

    if (isLandscape) {
      // Yatay moddan geliyorsa, yatay modda kal
      _previousOrientations = [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ];
    } else {
      // Dikey moddan geliyorsa, dikey moda dön
      _previousOrientations = [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ];
    }

    debugPrint(
      '🔄 Previous orientation saved: ${isLandscape ? "Landscape" : "Portrait"}',
    );
  }

  // Video formatını tespit et
  String _getVideoFormat(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('.m3u8') || lowerUrl.contains('m3u8')) {
      return 'HLS (M3U8)';
    } else if (lowerUrl.contains('.mp4')) {
      return 'MP4';
    } else if (lowerUrl.contains('.webm')) {
      return 'WebM';
    } else if (lowerUrl.contains('.mkv')) {
      return 'MKV';
    } else if (lowerUrl.contains('.mpd')) {
      return 'DASH (MPD)';
    }
    return 'Bilinmeyen';
  }

  Future<void> _initializePlayer() async {
    try {
      debugPrint('🎬 Film: ${widget.film.baslik}');
      debugPrint('🎬 hasVideo: ${widget.film.hasVideo}');
      debugPrint('🎬 kaynaklar: ${widget.film.kaynaklar}');
      debugPrint('🎬 kaynaklar length: ${widget.film.kaynaklar?.length}');

      if (!widget.film.hasVideo) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Bu film için video kaynağı bulunamadı\n'
              'Film ID: ${widget.film.id}\n'
              'Kaynaklar: ${widget.film.kaynaklar?.length ?? 0}';
          _isLoading = false;
        });
        return;
      }

      _resumePosition = await ResumePlayService.getResumePosition(
        widget.film.id,
      );

      if (_resumePosition != null) {
        debugPrint('⏱️ Resume position bulundu: ${_resumePosition!.position}s');
      } else {
        debugPrint('⏱️ Resume position yok, 0\'dan başlanıyor');
      }

      debugPrint('🎬 Trying to get kaynak at index: $_selectedKaynakIndex');
      debugPrint('🎬 Total kaynaklar: ${widget.film.kaynaklar?.length}');

      if (widget.film.kaynaklar == null || widget.film.kaynaklar!.isEmpty) {
        throw Exception('Kaynaklar listesi boş!');
      }

      if (_selectedKaynakIndex >= widget.film.kaynaklar!.length) {
        throw Exception(
          'Kaynak index hatalı: $_selectedKaynakIndex >= ${widget.film.kaynaklar!.length}',
        );
      }

      final kaynak = widget.film.kaynaklar![_selectedKaynakIndex];
      debugPrint('🎬 Kaynak alındı: ${kaynak.baslik}');
      debugPrint('🎬 Kaynak URL: ${kaynak.url}');
      debugPrint('🎬 isIframe from API: ${kaynak.isIframe}');

      // iframe URL pattern kontrolü (API'den gelmese bile)
      final urlLower = kaynak.url.toLowerCase();
      final isIframeUrl =
          urlLower.contains('iframe') ||
          urlLower.contains('embed') ||
          kaynak.isIframe;

      debugPrint('🎬 isIframe (final): $isIframeUrl');

      // Eğer iframe kaynak ise, iframe player'a yönlendir
      if (isIframeUrl) {
        debugPrint(
          '🎬 İframe kaynak tespit edildi, iframe player\'a yönlendiriliyor',
        );
        if (!mounted) return;
        context.go('/iframe-player/${widget.film.id}/${kaynak.id}');
        return;
      }

      // URL'i kontrol et ve parse et
      String videoUrl = kaynak.url.trim();
      debugPrint('🎬 Video URL (raw): $videoUrl');

      if (videoUrl.isEmpty) {
        throw Exception('Video URL boş');
      }

      debugPrint('🎬 Video URL: $videoUrl');
      debugPrint('🎬 Video Format: ${_getVideoFormat(videoUrl)}');

      // Video player controller oluştur
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true,
          allowBackgroundPlayback: false,
        ),
      );

      // Initialize timeout ile
      await _videoPlayerController!.initialize().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Video yükleme zaman aşımına uğradı');
        },
      );

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
        allowFullScreen: false, // Custom kontroller kullanacağız
        allowMuting: true,
        showControls: false, // Chewie kontrollerini kapat - custom kullanacağız
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.red,
          handleColor: Colors.red,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.white70,
        ),
        autoInitialize: true,
      );

      if (_resumePosition != null && _resumePosition!.position > 0) {
        await _videoPlayerController!.seekTo(
          Duration(seconds: _resumePosition!.position),
        );
      }

      _videoPlayerController!.addListener(_progressListener);

      setState(() => _isLoading = false);
    } catch (e, stackTrace) {
      debugPrint('❌ Player Error: $e');
      debugPrint('❌ Stack Trace: $stackTrace');
      setState(() {
        _hasError = true;
        _errorMessage = _buildErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  // Hata mesajı oluştur
  String _buildErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('timeout') || errorStr.contains('zaman aşımı')) {
      return 'Video yüklenemedi: Bağlantı zaman aşımına uğradı.\nİnternet bağlantınızı kontrol edin.';
    } else if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'Video kaynağı bulunamadı.\nVideo URL\'i geçersiz veya kaldırılmış olabilir.';
    } else if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return 'Video erişim izni reddedildi.\nYetkilendirme sorunu olabilir.';
    } else if (errorStr.contains('cors')) {
      return 'CORS hatası: Video kaynağına erişim engellendi.\nSunucu CORS ayarlarını kontrol edin.';
    } else if (errorStr.contains('format') || errorStr.contains('codec')) {
      return 'Video formatı desteklenmiyor.\nFarklı bir kalite seçeneği deneyin.';
    } else if (errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'Ağ bağlantı hatası.\nİnternet bağlantınızı kontrol edin.';
    } else if (errorStr.contains('url') && errorStr.contains('boş')) {
      return 'Video URL\'i boş.\nFilm için geçerli bir video kaynağı bulunamadı.';
    }

    return 'Video oynatılamadı:\n${error.toString()}';
  }

  void _progressListener() {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized)
      return;

    final position = _videoPlayerController!.value.position;
    final duration = _videoPlayerController!.value.duration;

    if (position.inSeconds > 0 && duration.inSeconds > 0) {
      _saveProgress(position.inSeconds, duration.inSeconds);
    }

    if (position >= duration && duration.inSeconds > 0) {
      _onVideoFinished();
    }

    // Alt yazı güncelle
    _updateSubtitle(position);
  }

  // Alt yazı metnini temizle (ASS/SSA etiketlerini kaldır)
  String _cleanSubtitleText(String text) {
    // {\an8}, {\i1}, {\b1} gibi etiketleri kaldır
    String cleaned = text.replaceAll(RegExp(r'\{[^}]*\}'), '');
    // HTML etiketlerini kaldır
    cleaned = cleaned.replaceAll(RegExp(r'<[^>]*>'), '');
    return cleaned.trim();
  }

  // Şu anki pozisyona göre alt yazıyı güncelle
  void _updateSubtitle(Duration position) {
    if (_currentSubtitles.isEmpty) {
      if (_currentSubtitleText.isNotEmpty) {
        setState(() => _currentSubtitleText = '');
      }
      return;
    }

    // Şu anki pozisyona uygun alt yazıyı bul
    for (var subtitle in _currentSubtitles) {
      if (position >= subtitle.start && position <= subtitle.end) {
        final cleanedText = _cleanSubtitleText(subtitle.text);
        if (_currentSubtitleText != cleanedText) {
          setState(() => _currentSubtitleText = cleanedText);
        }
        return;
      }
    }

    // Hiçbir alt yazı bulunamadı
    if (_currentSubtitleText.isNotEmpty) {
      setState(() => _currentSubtitleText = '');
    }
  }

  Future<void> _saveProgress(int position, int duration) async {
    final now = DateTime.now();
    if (_lastSave != null && now.difference(_lastSave!).inSeconds < 10) return;

    _lastSave = now;
    final resumePlay = ResumePlay(
      filmId: widget.film.id,
      userId: 1,
      position: position,
      duration: duration,
      durum: 'watching',
    );

    await ResumePlayService.saveResumePosition(resumePlay);
  }

  Future<void> _onVideoFinished() async {
    await ResumePlayService.deleteResumePosition(widget.film.id);
    if (mounted) context.go('/');
  }

  void _handleKeyEvent(KeyEvent event) {
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) return;

    // Key up event - Seek timer'ı durdur
    if (event is KeyUpEvent) {
      if (_focusedControl == 1 &&
          (event.logicalKey == LogicalKeyboardKey.arrowRight ||
              event.logicalKey == LogicalKeyboardKey.arrowLeft)) {
        _stopSeekTimer();
      }
      return;
    }

    if (event is! KeyDownEvent) return;

    // Kontrolleri göster ve timer'ı sıfırla
    setState(() {
      _showControls = true;
    });
    _resetHideTimer();

    // Escape veya Backspace - Her zaman geri dön
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      context.go('/film/${widget.film.id}');
      return;
    }

    // Yukarı/Aşağı ok - Kontrol seviyeleri arası gezinme
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _focusedControl = (_focusedControl - 1).clamp(0, 2);
        if (_focusedControl == 2)
          _focusedButton = 0; // Butonlara geçerken ilk butonu seç
      });
      return;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _focusedControl = (_focusedControl + 1).clamp(0, 2);
        if (_focusedControl == 2)
          _focusedButton = 0; // Butonlara geçerken ilk butonu seç
      });
      return;
    }

    // Focus seviyesine göre davran
    if (_focusedControl == 0) {
      // Geri butonunda - Sadece Enter/Space
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        context.go('/film/${widget.film.id}');
      }
    } else if (_focusedControl == 1) {
      // Progress bar'da - Sağ/Sol ile seek (uzun basma destekli)
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _startSeekTimer(true); // İleri
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _startSeekTimer(false); // Geri
      }
    } else if (_focusedControl == 2) {
      // Butonlarda - Sağ/Sol ile butonlar arası gezinme
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        setState(() {
          _focusedButton = (_focusedButton + 1).clamp(0, 2);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        setState(() {
          _focusedButton = (_focusedButton - 1).clamp(0, 2);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _handleButtonPress(_focusedButton);
      }
    } else {
      // Video modunda (_focusedControl == -1) - Doğrudan kontrol
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.keyK) {
        controller.value.isPlaying ? controller.pause() : controller.play();
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        final target = controller.value.position + const Duration(seconds: 10);
        controller.seekTo(
          target < controller.value.duration
              ? target
              : controller.value.duration,
        );
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        final target = controller.value.position - const Duration(seconds: 10);
        controller.seekTo(target > Duration.zero ? target : Duration.zero);
      } else if (event.logicalKey == LogicalKeyboardKey.keyM) {
        controller.setVolume(controller.value.volume > 0 ? 0 : 1.0);
      }
    }
  }

  void _handleButtonPress(int buttonIndex) {
    final controller = _videoPlayerController;
    if (controller == null) return;

    switch (buttonIndex) {
      case 0: // Play/Pause
        setState(() {
          controller.value.isPlaying ? controller.pause() : controller.play();
        });
        break;
      case 1: // Kaynak seçimi (Kalite)
        _showKaynakMenu();
        break;
      case 2: // Altyazı seçimi
        _showAltyaziMenu();
        break;
      case 3: // Oynatma hızı
        _showHizMenu();
        break;
      case 4: // PIP (Picture-in-Picture)
        _togglePip();
        break;
    }
  }

  // Kaynak seçim menüsü
  void _showKaynakMenu() {
    if (widget.film.kaynaklar == null || widget.film.kaynaklar!.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Kalite Seçin',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.film.kaynaklar!.asMap().entries.map((entry) {
              final index = entry.key;
              final kaynak = entry.value;
              final isSelected = index == _selectedKaynakIndex;

              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.red : Colors.white70,
                ),
                title: Text(
                  kaynak.baslik,
                  style: TextStyle(
                    color: isSelected ? Colors.red : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _changeKaynak(index);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // Altyazı seçim menüsü
  void _showAltyaziMenu() {
    final altyazilar = widget.film.altyazilar ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Altyazı Seçin',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Altyazı yok seçeneği
              ListTile(
                leading: Icon(
                  _selectedAltyaziIndex == -1
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: _selectedAltyaziIndex == -1
                      ? Colors.red
                      : Colors.white70,
                ),
                title: Text(
                  'Altyazı Yok',
                  style: TextStyle(
                    color: _selectedAltyaziIndex == -1
                        ? Colors.red
                        : Colors.white,
                    fontWeight: _selectedAltyaziIndex == -1
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _changeSubtitle(-1);
                },
              ),
              // Altyazı listesi
              ...altyazilar.asMap().entries.map((entry) {
                final index = entry.key;
                final altyazi = entry.value;
                final isSelected = index == _selectedAltyaziIndex;

                return ListTile(
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? Colors.red : Colors.white70,
                  ),
                  title: Text(
                    altyazi.baslik,
                    style: TextStyle(
                      color: isSelected ? Colors.red : Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _changeSubtitle(index);
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  // SRT dosyasını parse et
  Future<List<Subtitle>> _parseSrtFile(String url) async {
    try {
      debugPrint('📥 Alt yazı indiriliyor: $url');

      // Format tespiti için URL kontrolü
      final urlLower = url.toLowerCase();
      final isVtt = urlLower.contains('.vtt');
      final isSrt = urlLower.contains('.srt');

      debugPrint(
        '🎬 Format: ${isVtt
            ? "VTT"
            : isSrt
            ? "SRT"
            : "UNKNOWN"}',
      );

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        debugPrint('❌ Alt yazı indirilemedi: HTTP ${response.statusCode}');
        debugPrint('❌ URL: $url');
        return [];
      }

      debugPrint('✅ Alt yazı indirildi: ${response.body.length} byte');

      // İçerik kontrolü
      final content = response.body;
      if (content.isEmpty) {
        debugPrint('❌ Alt yazı içeriği boş');
        return [];
      }

      // Format tespiti (içerikten)
      final contentHasWebVtt = content.trim().startsWith('WEBVTT');
      final isVttFormat = isVtt || contentHasWebVtt;

      debugPrint('🎬 İçerik format: ${isVttFormat ? "VTT" : "SRT"}');

      if (isVttFormat) {
        return _parseVttContent(content);
      } else {
        return _parseSrtContent(content);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Alt yazı parse hatası: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return [];
    }
  }

  // VTT Parser
  List<Subtitle> _parseVttContent(String content) {
    try {
      final subtitles = <Subtitle>[];

      // WEBVTT başlığını ve metadata'yı atla
      var lines = content.split('\n');
      var startIndex = 0;

      // WEBVTT ve metadata satırlarını atla
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty && i > 0) {
          startIndex = i + 1;
          break;
        }
      }

      // Bloklara ayır (çift newline ile)
      final contentWithoutHeader = lines.sublist(startIndex).join('\n');
      final blocks = contentWithoutHeader.split(RegExp(r'\n\s*\n'));

      for (var block in blocks) {
        final blockLines = block.trim().split('\n');
        if (blockLines.isEmpty) continue;

        // VTT formatında timestamp satırını bul
        String? timelineLine;
        int textStartIndex = 0;

        for (var i = 0; i < blockLines.length; i++) {
          if (blockLines[i].contains('-->')) {
            timelineLine = blockLines[i];
            textStartIndex = i + 1;
            break;
          }
        }

        if (timelineLine == null || textStartIndex >= blockLines.length)
          continue;

        // VTT zaman formatı: 00:00:10.500 --> 00:00:13.000
        final timeMatch = RegExp(
          r'(\d{2}):(\d{2}):(\d{2})[\.,](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[\.,](\d{3})',
        ).firstMatch(timelineLine);

        if (timeMatch == null) continue;

        final startHour = int.parse(timeMatch.group(1)!);
        final startMin = int.parse(timeMatch.group(2)!);
        final startSec = int.parse(timeMatch.group(3)!);
        final startMs = int.parse(timeMatch.group(4)!);

        final endHour = int.parse(timeMatch.group(5)!);
        final endMin = int.parse(timeMatch.group(6)!);
        final endSec = int.parse(timeMatch.group(7)!);
        final endMs = int.parse(timeMatch.group(8)!);

        final start = Duration(
          hours: startHour,
          minutes: startMin,
          seconds: startSec,
          milliseconds: startMs,
        );

        final end = Duration(
          hours: endHour,
          minutes: endMin,
          seconds: endSec,
          milliseconds: endMs,
        );

        // Metni al (VTT tag'lerini temizle)
        var text = blockLines.sublist(textStartIndex).join('\n').trim();
        text = _cleanVttTags(text);

        if (text.isNotEmpty) {
          subtitles.add(
            Subtitle(
              index: subtitles.length,
              start: start,
              end: end,
              text: text,
            ),
          );
        }
      }

      debugPrint('✅ ${subtitles.length} VTT alt yazı parse edildi');
      return subtitles;
    } catch (e) {
      debugPrint('❌ VTT parse hatası: $e');
      return [];
    }
  }

  // SRT Parser
  List<Subtitle> _parseSrtContent(String content) {
    try {
      final subtitles = <Subtitle>[];
      final blocks = content.split('\n\n');

      for (var block in blocks) {
        final lines = block.trim().split('\n');
        if (lines.length < 3) continue;

        // İlk satır index (atla)
        // İkinci satır zaman damgası
        final timeLine = lines[1];
        final timeMatch = RegExp(
          r'(\d{2}):(\d{2}):(\d{2}),(\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2}),(\d{3})',
        ).firstMatch(timeLine);

        if (timeMatch == null) continue;

        final startHour = int.parse(timeMatch.group(1)!);
        final startMin = int.parse(timeMatch.group(2)!);
        final startSec = int.parse(timeMatch.group(3)!);
        final startMs = int.parse(timeMatch.group(4)!);

        final endHour = int.parse(timeMatch.group(5)!);
        final endMin = int.parse(timeMatch.group(6)!);
        final endSec = int.parse(timeMatch.group(7)!);
        final endMs = int.parse(timeMatch.group(8)!);

        final start = Duration(
          hours: startHour,
          minutes: startMin,
          seconds: startSec,
          milliseconds: startMs,
        );

        final end = Duration(
          hours: endHour,
          minutes: endMin,
          seconds: endSec,
          milliseconds: endMs,
        );

        // Kalan satırlar metin
        final text = lines.sublist(2).join('\n').trim();

        if (text.isNotEmpty) {
          subtitles.add(
            Subtitle(
              index: subtitles.length,
              start: start,
              end: end,
              text: text,
            ),
          );
        }
      }

      debugPrint('✅ ${subtitles.length} SRT alt yazı parse edildi');
      return subtitles;
    } catch (e) {
      debugPrint('❌ SRT parse hatası: $e');
      return [];
    }
  }

  // VTT tag'lerini temizle
  String _cleanVttTags(String text) {
    // <c>, <v>, <i>, <b>, <u> gibi VTT tag'lerini kaldır
    var cleaned = text.replaceAll(RegExp(r'<[^>]+>'), '');
    // &nbsp;, &amp; gibi HTML entity'leri temizle
    cleaned = cleaned
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');
    return cleaned.trim();
  }

  // Altyazı değiştir
  Future<void> _changeSubtitle(int index) async {
    setState(() {
      _selectedAltyaziIndex = index;
      _currentSubtitleText = '';
    });

    // Alt yazı yükle (eğer seçilmişse)
    if (index >= 0 &&
        widget.film.altyazilar != null &&
        index < widget.film.altyazilar!.length) {
      final altyazi = widget.film.altyazilar![index];
      final altyaziUrl = altyazi.url;

      debugPrint('📝 Altyazı yükleniyor: ${altyazi.baslik}');
      debugPrint('📝 URL: $altyaziUrl');

      final subtitles = await _parseSrtFile(altyaziUrl);

      if (subtitles.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '❌ Alt yazı yüklenemedi',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Olası nedenler: CORS, format hatası, veya dosya bulunamadı',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    altyaziUrl,
                    style: const TextStyle(
                      fontSize: 9,
                      fontFamily: 'monospace',
                      color: Colors.white60,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        setState(() {
          _selectedAltyaziIndex = -1;
          _currentSubtitles = [];
        });
        return;
      }

      setState(() => _currentSubtitles = subtitles);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ ${subtitles.length} alt yazı yüklendi: ${altyazi.baslik}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Alt yazı kapatıldı
      setState(() => _currentSubtitles = []);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('❌ Alt yazı kapatıldı'),
            backgroundColor: Colors.grey[800],
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }

    debugPrint(
      '✅ Altyazı değiştirildi: ${index >= 0 ? widget.film.altyazilar![index].baslik : "Yok"}',
    );
  }

  // Oynatma hızı menüsü
  void _showHizMenu() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Oynatma Hızı',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _playbackSpeeds.asMap().entries.map((entry) {
              final index = entry.key;
              final speed = entry.value;
              final isSelected = index == _selectedSpeedIndex;

              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.red : Colors.white70,
                ),
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: isSelected ? Colors.red : Colors.white,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedSpeedIndex = index;
                    _videoPlayerController?.setPlaybackSpeed(speed);
                  });
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // PIP toggle
  void _togglePip() {
    // TODO: PIP implementation (requires platform-specific code)
    debugPrint('PIP özelliği henüz implementasyonda');
  }

  // Kaynak değiştir ve videoyu yeniden başlat
  Future<void> _changeKaynak(int newIndex) async {
    if (newIndex == _selectedKaynakIndex) return;

    final currentPosition = _videoPlayerController?.value.position;

    setState(() {
      _selectedKaynakIndex = newIndex;
      _isLoading = true;
    });

    // Eski controller'ları temizle
    _chewieController?.dispose();
    await _videoPlayerController?.dispose();

    // Yeni kaynakla tekrar başlat
    await _initializePlayer();

    // Aynı pozisyondan devam et
    if (currentPosition != null && _videoPlayerController != null) {
      await _videoPlayerController!.seekTo(currentPosition);
      _videoPlayerController!.play();
    }
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _startSeekTimer(bool forward) {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized)
      return;

    // İlk seek'i hemen yap (5 saniye)
    _seekMultiplier = 1;

    final currentPosition = _videoPlayerController!.value.position;
    final newPosition = currentPosition + Duration(seconds: forward ? 5 : -5);
    final duration = _videoPlayerController!.value.duration;

    if (newPosition < Duration.zero) {
      _videoPlayerController!.seekTo(Duration.zero);
    } else if (newPosition > duration) {
      _videoPlayerController!.seekTo(duration);
    } else {
      _videoPlayerController!.seekTo(newPosition);
    }

    // Timer'ı başlat - her 1 saniyede bir artarak seek yap
    _seekTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_videoPlayerController == null ||
          !_videoPlayerController!.value.isInitialized) {
        _stopSeekTimer();
        return;
      }

      _seekMultiplier++;
      final seekAmount = 5 * _seekMultiplier; // 5, 10, 15, 20, 25...

      final currentPosition = _videoPlayerController!.value.position;
      final newPosition =
          currentPosition +
          Duration(seconds: forward ? seekAmount : -seekAmount);
      final duration = _videoPlayerController!.value.duration;

      if (newPosition < Duration.zero) {
        _videoPlayerController!.seekTo(Duration.zero);
        _stopSeekTimer();
      } else if (newPosition > duration) {
        _videoPlayerController!.seekTo(duration);
        _stopSeekTimer();
      } else {
        _videoPlayerController!.seekTo(newPosition);
      }
    });
  }

  void _stopSeekTimer() {
    _seekTimer?.cancel();
    _seekTimer = null;
    _seekMultiplier = 1;
  }

  @override
  void dispose() {
    _seekTimer?.cancel();
    _hideTimer?.cancel();
    _videoPlayerController?.removeListener(_progressListener);
    _chewieController?.dispose();
    _videoPlayerController?.dispose();

    // Kaydedilen orientation'a geri dön (yoksa tüm orientasyonları aç)
    if (_previousOrientations != null) {
      SystemChrome.setPreferredOrientations(_previousOrientations!);
      debugPrint('🔄 Restored orientation: ${_previousOrientations!.first}');
    } else {
      // Fallback: Tüm orientasyonları aç
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    // System UI'ları geri getir
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: KeyboardListener(
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        // Debug bilgileri
                        if (widget.film.kaynaklar != null &&
                            widget.film.kaynaklar!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '🔍 Debug Bilgileri:',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Film: ${widget.film.baslik}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Kaynak Sayısı: ${widget.film.kaynaklar!.length}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Seçili Kaynak: ${widget.film.kaynaklar![_selectedKaynakIndex].baslik}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'URL: ${widget.film.kaynaklar![_selectedKaynakIndex].url}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Format: ${_getVideoFormat(widget.film.kaynaklar![_selectedKaynakIndex].url)}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 24),
                        // Kaynak seçimi (birden fazla kaynak varsa)
                        if (widget.film.kaynaklar != null &&
                            widget.film.kaynaklar!.length > 1) ...[
                          const Text(
                            'Diğer Kaynakları Deneyin:',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: List.generate(
                              widget.film.kaynaklar!.length,
                              (index) {
                                final kaynak = widget.film.kaynaklar![index];
                                final isSelected =
                                    index == _selectedKaynakIndex;
                                final isCurrent = index == _selectedKaynakIndex;

                                return ElevatedButton(
                                  onPressed: isCurrent
                                      ? null
                                      : () {
                                          _changeKaynak(index);
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected
                                        ? Colors.grey[700]
                                        : Colors.grey[800],
                                    disabledBackgroundColor: Colors.grey[700],
                                  ),
                                  child: Text(
                                    kaynak.baslik,
                                    style: TextStyle(
                                      color: isCurrent
                                          ? Colors.red
                                          : Colors.white,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _hasError = false;
                                  _isLoading = true;
                                });
                                _initializePlayer();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tekrar Dene'),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              icon: const Icon(Icons.home),
                              label: const Text('Ana Sayfa'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              : Center(
                  child: _chewieController != null
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _showControls = !_showControls;
                            });
                            if (_showControls) {
                              _resetHideTimer();
                            } else {
                              _hideTimer?.cancel();
                            }
                          },
                          child: Stack(
                            children: [
                              // Video player
                              Chewie(controller: _chewieController!),

                              // Alt yazı gösterimi
                              if (_currentSubtitleText.isNotEmpty)
                                Positioned(
                                  bottom: 100,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 40,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _currentSubtitleText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                          shadows: [
                                            Shadow(
                                              offset: Offset(1.5, 1.5),
                                              blurRadius: 3,
                                              color: Colors.black,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),

                              // Custom overlay kontroller
                              if (_showControls) _buildCustomControls(),
                            ],
                          ),
                        )
                      : const CircularProgressIndicator(color: Colors.red),
                ),
        ),
      ),
    );
  }

  Widget _buildCustomControls() {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Column(
        children: [
          // Üst bar - Geri butonu
          _buildTopBar(),

          const Spacer(),

          // Orta - Progress bar
          _buildProgressBar(),

          const SizedBox(height: 20),

          // Alt bar - Kontrol butonları
          _buildBottomBar(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final isFocused = _focusedControl == 0;
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Geri butonu
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isFocused ? Colors.red : Colors.black54,
              borderRadius: BorderRadius.circular(8),
              border: isFocused
                  ? Border.all(color: Colors.white, width: 2)
                  : null,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.go('/film/${widget.film.id}'),
            ),
          ),
          const SizedBox(width: 16),
          // Film başlığı
          Text(
            widget.film.baslik,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final controller = _videoPlayerController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final position = controller.value.position;
    final duration = controller.value.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    final isFocused = _focusedControl == 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          // Tıklanabilir Progress Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.red,
              inactiveTrackColor: Colors.grey[800],
              thumbColor: Colors.red,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0),
              overlayColor: Colors.red.withOpacity(0.3),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
              trackHeight: isFocused ? 6.0 : 4.0,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                final newPosition = duration * value;
                controller.seekTo(newPosition);
                setState(() {});
              },
              onChangeStart: (value) {
                // Kullanıcı slider'ı kullanırken kontrolleri göster
                _hideTimer?.cancel();
              },
              onChangeEnd: (value) {
                // Slider bırakıldığında timer'ı yeniden başlat
                _resetHideTimer();
              },
            ),
          ),
          // Zaman göstergesi
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(position),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(duration),
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final controller = _videoPlayerController;
    final isPlaying = controller?.value.isPlaying ?? false;
    final isFocused = _focusedControl == 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst sıra - Ana oynatma kontrolleri
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Geri 10sn
              _buildControlButton(
                icon: Icons.replay_10,
                label: '',
                isFocused: isFocused && _focusedButton == 2,
                onPressed: () {
                  if (controller != null && controller.value.isInitialized) {
                    final newPos =
                        controller.value.position - const Duration(seconds: 10);
                    controller.seekTo(
                      newPos < Duration.zero ? Duration.zero : newPos,
                    );
                  }
                },
              ),
              const SizedBox(width: 30),
              // Play/Pause
              _buildControlButton(
                icon: isPlaying ? Icons.pause : Icons.play_arrow,
                label: '',
                isFocused: isFocused && _focusedButton == 0,
                onPressed: () {
                  if (controller != null && controller.value.isInitialized) {
                    if (isPlaying) {
                      controller.pause();
                    } else {
                      controller.play();
                    }
                    setState(() {});
                  }
                },
                isLarge: true,
              ),
              const SizedBox(width: 30),
              // İleri 10sn
              _buildControlButton(
                icon: Icons.forward_10,
                label: '',
                isFocused: isFocused && _focusedButton == 1,
                onPressed: () {
                  if (controller != null && controller.value.isInitialized) {
                    final newPos =
                        controller.value.position + const Duration(seconds: 10);
                    final duration = controller.value.duration;
                    controller.seekTo(newPos > duration ? duration : newPos);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Alt sıra - Ek kontroller
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Kaynak seçimi
              _buildSmallControlButton(
                icon: Icons.video_library,
                label:
                    widget.film.kaynaklar != null &&
                        widget.film.kaynaklar!.isNotEmpty
                    ? widget.film.kaynaklar![_selectedKaynakIndex].baslik
                    : 'Kaynak',
                isFocused: isFocused && _focusedButton == 3,
                onPressed: _showKaynakMenu,
              ),
              // Altyazı seçimi
              _buildSmallControlButton(
                icon: Icons.closed_caption,
                label: _selectedAltyaziIndex == -1
                    ? 'Altyazı'
                    : (widget.film.altyazilar != null &&
                          _selectedAltyaziIndex <
                              widget.film.altyazilar!.length)
                    ? widget.film.altyazilar![_selectedAltyaziIndex].baslik
                    : 'Altyazı',
                isFocused: isFocused && _focusedButton == 4,
                onPressed: _showAltyaziMenu,
              ),
              // Hız ayarı
              _buildSmallControlButton(
                icon: Icons.speed,
                label: '${_playbackSpeeds[_selectedSpeedIndex]}x',
                isFocused: isFocused && _focusedButton == 5,
                onPressed: _showHizMenu,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isFocused,
    required VoidCallback onPressed,
    bool isLarge = false,
  }) {
    final size = isLarge ? 80.0 : 60.0;
    final iconSize = isLarge ? 40.0 : 30.0;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isFocused ? Colors.red : Colors.black54,
            shape: BoxShape.circle,
            border: isFocused
                ? Border.all(color: Colors.white, width: 3)
                : null,
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ]
                : null,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: iconSize),
            onPressed: onPressed,
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isFocused ? Colors.white : Colors.white70,
              fontSize: 12,
              fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmallControlButton({
    required IconData icon,
    required String label,
    required bool isFocused,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isFocused ? Colors.red : Colors.black54,
          borderRadius: BorderRadius.circular(8),
          border: isFocused ? Border.all(color: Colors.white, width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}
