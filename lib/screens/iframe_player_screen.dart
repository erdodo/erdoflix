import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../models/film.dart';
import '../models/kaynak.dart';

class IframePlayerScreen extends StatefulWidget {
  final Film film;
  final Kaynak kaynak;

  const IframePlayerScreen({
    super.key,
    required this.film,
    required this.kaynak,
  });

  @override
  State<IframePlayerScreen> createState() => _IframePlayerScreenState();
}

class _IframePlayerScreenState extends State<IframePlayerScreen> {
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _capturedVideoUrl;
  bool _isAnalyzing = true;
  Timer? _videoCheckTimer;

  // TV-friendly kontroller
  int _focusedControl = 0; // 0: Geri, 1: Yeniden Yükle, 2: Native Player
  final List<String> _networkLogs = [];

  @override
  void initState() {
    super.initState();
    _initializeWebView();

    // Landscape moda geç
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 30 saniye sonra analiz göstergesini kapat (arka planda dinlemeye devam eder)
    Timer(const Duration(seconds: 30), () {
      if (mounted && _capturedVideoUrl == null) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    });

    // Her 3 saniyede bir video elementlerini kontrol et
    _videoCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_capturedVideoUrl == null) {
        _checkVideoElements();
      } else {
        timer.cancel();
      }
    });
  }

  void _checkVideoElements() async {
    try {
      // Video elementlerini kontrol et
      const jsCode = '''
        (function() {
          const videos = document.querySelectorAll('video');
          const sources = [];

          videos.forEach(function(video) {
            if (video.src) sources.push(video.src);
            if (video.currentSrc) sources.push(video.currentSrc);

            // Source elementlerini kontrol et
            video.querySelectorAll('source').forEach(function(source) {
              if (source.src) sources.push(source.src);
            });
          });

          return sources.filter(function(src) {
            return src && src.length > 0;
          });
        })();
      ''';

      final result = await _webViewController.runJavaScriptReturningResult(
        jsCode,
      );
      debugPrint('🔍 Periyodik video kontrolü: $result');
    } catch (e) {
      debugPrint('❌ Video kontrol hatası: $e');
    }
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('🌐 Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('✅ Page finished loading: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            // Network isteklerini izlemeye başla
            _injectNetworkInterceptor();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ WebView Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.kaynak.url));
  }

  void _injectNetworkInterceptor() {
    // JavaScript ile network isteklerini dinle
    const jsCode = '''
      (function() {
        // XMLHttpRequest'i intercept et
        const originalOpen = XMLHttpRequest.prototype.open;
        const originalSend = XMLHttpRequest.prototype.send;

        XMLHttpRequest.prototype.open = function(method, url) {
          this._url = url;
          return originalOpen.apply(this, arguments);
        };

        XMLHttpRequest.prototype.send = function() {
          const url = this._url;
          const xhr = this;

          // Response body'yi kontrol et
          xhr.addEventListener('load', function() {
            if (xhr.status === 200 && xhr.responseText) {
              const responseText = xhr.responseText.substring(0, 200); // İlk 200 karakter

              // M3U8 playlist kontrolü (#EXTM3U ile başlıyor mu?)
              if (responseText.includes('#EXTM3U') || responseText.includes('#EXT-X-')) {
                window.flutter_network_log.postMessage(JSON.stringify({
                  type: 'video',
                  url: url,
                  method: 'XHR_M3U8_CONTENT',
                  contentType: 'application/x-mpegURL'
                }));
              }
            }
          });

          if (url) {
            // Daha geniş format desteği
            const videoFormats = ['.m3u8', '.mp4', '.ts', '.mkv', '.avi', '.webm', '.mov', '.flv', '.m4v'];
            const isVideo = videoFormats.some(format => url.toLowerCase().includes(format));

            // Video streaming pattern'leri
            const streamPatterns = ['hls', 'dash', 'video', 'stream', 'manifest', 'playlist'];
            const isStream = streamPatterns.some(pattern => url.toLowerCase().includes(pattern));

            if (isVideo || isStream) {
              window.flutter_network_log.postMessage(JSON.stringify({
                type: 'video',
                url: url,
                method: 'XHR'
              }));
            }
          }
          return originalSend.apply(this, arguments);
        };

        // Fetch API'yi intercept et
        const originalFetch = window.fetch;
        window.fetch = function(url, options) {
          const requestUrl = typeof url === 'string' ? url : url.url;

          // Response body'yi kontrol et
          const promise = originalFetch.apply(this, arguments);
          promise.then(function(response) {
            if (response.ok && response.status === 200) {
              // Response'u clone et (orijinali bozmamak için)
              const clonedResponse = response.clone();
              clonedResponse.text().then(function(text) {
                const responseText = text.substring(0, 200); // İlk 200 karakter

                // M3U8 playlist kontrolü (#EXTM3U ile başlıyor mu?)
                if (responseText.includes('#EXTM3U') || responseText.includes('#EXT-X-')) {
                  window.flutter_network_log.postMessage(JSON.stringify({
                    type: 'video',
                    url: requestUrl,
                    method: 'FETCH_M3U8_CONTENT',
                    contentType: 'application/x-mpegURL'
                  }));
                }
              }).catch(function(e) {
                // Text parse hatası
              });
            }
          }).catch(function(e) {
            // Fetch hatası
          });

          if (typeof requestUrl === 'string') {
            const videoFormats = ['.m3u8', '.mp4', '.ts', '.mkv', '.avi', '.webm', '.mov', '.flv', '.m4v'];
            const isVideo = videoFormats.some(format => requestUrl.toLowerCase().includes(format));

            const streamPatterns = ['hls', 'dash', 'video', 'stream', 'manifest', 'playlist'];
            const isStream = streamPatterns.some(pattern => requestUrl.toLowerCase().includes(pattern));

            if (isVideo || isStream) {
              window.flutter_network_log.postMessage(JSON.stringify({
                type: 'video',
                url: requestUrl,
                method: 'FETCH'
              }));
            }
          }
          return promise;
        };

        // Video elementlerini izle
        const observer = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            mutation.addedNodes.forEach(function(node) {
              if (node.tagName === 'VIDEO') {
                const src = node.src || node.currentSrc;
                if (src) {
                  window.flutter_network_log.postMessage(JSON.stringify({
                    type: 'video',
                    url: src,
                    method: 'VIDEO_ELEMENT'
                  }));
                }
              }
            });
          });
        });

        observer.observe(document.body, {
          childList: true,
          subtree: true
        });

        // Mevcut video elementlerini kontrol et
        document.querySelectorAll('video').forEach(function(video) {
          const src = video.src || video.currentSrc;
          if (src) {
            window.flutter_network_log.postMessage(JSON.stringify({
              type: 'video',
              url: src,
              method: 'EXISTING_VIDEO'
            }));
          }
        });
      })();
    ''';

    _webViewController.runJavaScript(jsCode);

    // JavaScript channel ekle
    _webViewController.addJavaScriptChannel(
      'flutter_network_log',
      onMessageReceived: (JavaScriptMessage message) {
        try {
          final data = json.decode(message.message);
          final url = data['url'] as String?;
          final method = data['method'] as String?;
          final contentType = data['contentType'] as String?;

          if (url != null && _capturedVideoUrl == null) {
            debugPrint('🎥 Video URL yakalandı: $url');
            debugPrint('🎥 Method: $method');
            if (contentType != null) {
              debugPrint('🎥 Content-Type: $contentType');
            }

            setState(() {
              _capturedVideoUrl = url;
              final logEntry = contentType != null
                  ? '$method [$contentType]: $url'
                  : '$method: $url';
              _networkLogs.add(logEntry);
            });

            // URL yakalandı, native player'a geçelim
            _showNativePlayerDialog();
          }
        } catch (e) {
          debugPrint('❌ Network log parse error: $e');
        }
      },
    );
  }

  void _showNativePlayerDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text(
              'Video URL Bulundu!',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video kaynağı başarıyla yakalandı.',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              _capturedVideoUrl ?? '',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Text(
              'Kendi playerımızla devam etmek ister misiniz?',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Hayır, İframe\'de Kal',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _switchToNativePlayer();
            },
            icon: const Icon(Icons.play_circle_fill),
            label: const Text('Native Player\'a Geç'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _switchToNativePlayer() {
    // Native player'a geç
    // Yeni bir kaynak oluştur (iframe değil, direkt URL)
    final directKaynak = Kaynak(
      id: widget.kaynak.id,
      baslik: '${widget.kaynak.baslik} (Auto)',
      url: _capturedVideoUrl!,
      kaynakId: widget.kaynak.kaynakId,
      isIframe: false,
    );

    // Filmi güncelle
    final updatedFilm = Film(
      id: widget.film.id,
      baslik: widget.film.baslik,
      detay: widget.film.detay,
      poster: widget.film.poster,
      arkaPlan: widget.film.arkaPlan,
      yayinTarihi: widget.film.yayinTarihi,
      imdbId: widget.film.imdbId,
      tmdbId: widget.film.tmdbId,
      orjinalBaslik: widget.film.orjinalBaslik,
      kaynaklar: [directKaynak],
      altyazilar: widget.film.altyazilar,
      turler: widget.film.turler,
    );

    // Player'a yönlendir
    context.go('/player/${widget.film.id}', extra: updatedFilm);
  }

  void _handleKeyEvent(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    setState(() {
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        _focusedControl = (_focusedControl - 1).clamp(0, 2);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        _focusedControl = (_focusedControl + 1).clamp(0, 2);
      } else if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _handleControlAction();
      } else if (event.logicalKey == LogicalKeyboardKey.escape ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        _handleBack();
      }
    });
  }

  void _handleControlAction() {
    switch (_focusedControl) {
      case 0: // Geri
        _handleBack();
        break;
      case 1: // Yeniden Yükle
        _reloadPage();
        break;
      case 2: // Native Player (eğer URL yakalandıysa)
        if (_capturedVideoUrl != null) {
          _switchToNativePlayer();
        }
        break;
    }
  }

  void _handleBack() {
    // Orientation'ı geri yükle
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    context.go('/film/${widget.film.id}');
  }

  void _reloadPage() {
    // Mevcut timer'ı iptal et
    _videoCheckTimer?.cancel();

    setState(() {
      _isLoading = true;
      _capturedVideoUrl = null;
      _isAnalyzing = true;
      _networkLogs.clear();
    });
    _webViewController.reload();

    // 30 saniye sonra analiz göstergesini kapat
    Timer(const Duration(seconds: 30), () {
      if (mounted && _capturedVideoUrl == null) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    });

    // Periyodik video kontrolünü yeniden başlat
    _videoCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_capturedVideoUrl == null) {
        _checkVideoElements();
      } else {
        timer.cancel();
      }
    });
  }

  Widget _buildKaynakMenu() {
    return PopupMenuButton<int>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white30, width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.video_library, color: Colors.white, size: 16),
            SizedBox(width: 4),
            Text(
              'Kaynaklar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, color: Colors.white, size: 16),
          ],
        ),
      ),
      color: Colors.grey[900],
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) {
        return widget.film.kaynaklar!.asMap().entries.map((entry) {
          final index = entry.key;
          final kaynak = entry.value;
          final isCurrent = kaynak.id == widget.kaynak.id;

          return PopupMenuItem<int>(
            value: index,
            enabled: !isCurrent,
            child: Row(
              children: [
                Icon(
                  isCurrent ? Icons.check_circle : Icons.circle_outlined,
                  color: isCurrent ? Colors.green : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        kaynak.baslik,
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.white70,
                          fontWeight: isCurrent
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (kaynak.isIframe ||
                          kaynak.url.toLowerCase().contains('iframe'))
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.blue, width: 1),
                          ),
                          child: const Text(
                            'IFRAME',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      onSelected: (index) {
        final selectedKaynak = widget.film.kaynaklar![index];

        // URL pattern kontrolü
        final urlLower = selectedKaynak.url.toLowerCase();
        final isIframeUrl =
            urlLower.contains('iframe') ||
            urlLower.contains('embed') ||
            selectedKaynak.isIframe;

        if (isIframeUrl) {
          // Başka bir iframe kaynağı, bu sayfayı yeniden yükle
          context.go('/iframe-player/${widget.film.id}/${selectedKaynak.id}');
        } else {
          // Normal kaynak, direkt player'a git
          context.go('/player/${widget.film.id}');
        }
      },
    );
  }

  @override
  void dispose() {
    _videoCheckTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: RawKeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKey: _handleKeyEvent,
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // WebView
              if (!_isLoading) WebViewWidget(controller: _webViewController),

              // Loading indicator
              if (_isLoading)
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'İframe yükleniyor...',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),

              // HEADER - Kalıcı Kontroller (üst)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.9),
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Geri butonu
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _handleBack,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _focusedControl == 0
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _focusedControl == 0
                                      ? Colors.red
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Geri',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Film bilgisi
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.film.baslik,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.blue,
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'IFRAME',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    widget.kaynak.baslik,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Analyzing indicator
                        if (_isAnalyzing && !_isLoading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.orange,
                                width: 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Analiz...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Video URL yakalandı
                        if (_capturedVideoUrl != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green, width: 1),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'URL Bulundu',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(width: 12),

                        // Yeniden yükle butonu
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _reloadPage,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _focusedControl == 1
                                    ? Colors.red.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _focusedControl == 1
                                      ? Colors.red
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.refresh,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Kaynak seçim menüsü
                        if (widget.film.kaynaklar != null &&
                            widget.film.kaynaklar!.length > 1)
                          _buildKaynakMenu(),

                        const SizedBox(width: 8),

                        // Native Player butonu (sadece URL yakalandıysa)
                        if (_capturedVideoUrl != null)
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _switchToNativePlayer,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _focusedControl == 2
                                      ? Colors.red.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _focusedControl == 2
                                        ? Colors.red
                                        : Colors.green,
                                    width: 2,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.play_circle_fill,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Player',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Network logs (debug - alt sağ köşe)
              if (_networkLogs.isNotEmpty)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 300,
                      maxHeight: 150,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.bug_report,
                              color: Colors.green,
                              size: 16,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Network Logs:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _networkLogs.map((log) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 2,
                                  ),
                                  child: Text(
                                    log,
                                    style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 9,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
