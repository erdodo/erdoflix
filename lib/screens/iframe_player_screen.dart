import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../models/film.dart';
import '../models/kaynak.dart';
import '../models/altyazi.dart';
import '../services/api_service.dart';

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

class _IframePlayerScreenState extends State<IframePlayerScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late WebViewController _webViewController;
  bool _isLoading = true;
  String? _capturedVideoUrl;
  List<String> _capturedVideoUrls = []; // Tüm yakalanan video URL'leri
  List<String> _capturedSubtitles = []; // Yakalanan altyazı URL'leri
  bool _isAnalyzing = true;
  Timer? _videoCheckTimer;
  Timer? _autoRedirectTimer;
  int _remainingSeconds = 5;
  bool _showingDialog = false;
  bool _userDismissedDialog = false; // Kullanıcı dialog'u iptal ettiyse

  // Veritabanına kaydedilen URL'leri takip et (duplicate önlemek için)
  final Set<String> _savedVideoUrls = {};
  final Set<String> _savedSubtitleUrls = {};

  // Animasyon kontrolcüsü
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  // TV-friendly kontroller
  int _focusedControl = 0; // 0: Geri, 1: Yeniden Yükle, 2: Native Player
  final List<String> _networkLogs = [];

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcüsünü başlat
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

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

    // Her 5 saniyede bir video elementlerini kontrol et (arka planda sürekli dinle)
    _videoCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkVideoElements();
    });
  }

  bool _isCheckingVideo = false; // Concurrent check önleme

  void _checkVideoElements() async {
    if (_isCheckingVideo) {
      return; // Kontrol devam ediyor, concurrent çağrıyı engelle
    }

    _isCheckingVideo = true;

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

      // Sonucu parse et ve ilk URL'i yakala
      final resultStr = result.toString();
      if (resultStr != '[]' && resultStr.isNotEmpty) {
        debugPrint('🔍 Video bulundu: $resultStr');

        // Liste formatından URL'leri çıkar
        final urls = resultStr
            .replaceAll('[', '')
            .replaceAll(']', '')
            .replaceAll('"', '')
            .split(',')
            .where((url) => url.trim().isNotEmpty)
            .toList();

        if (urls.isNotEmpty) {
          // Tüm URL'leri listeye ekle (yeni olanları)
          for (final url in urls) {
            final trimmedUrl = url.trim();
            if (trimmedUrl.isNotEmpty &&
                !_capturedVideoUrls.contains(trimmedUrl)) {
              if (mounted) {
                setState(() {
                  _capturedVideoUrls.add(trimmedUrl);
                  _networkLogs.add('✅ FOUND (ELEMENT): $trimmedUrl');
                });
                debugPrint('🎥 Video element bulundu: $trimmedUrl');
                debugPrint(
                  '🎥 Toplam ${_capturedVideoUrls.length} video kaynağı',
                );

                // Veritabanına kaydet
                _saveVideoToDatabase(trimmedUrl, 'ELEMENT');
              }
            }
          }

          // İlk URL'i yakala ve dialog göster (sadece kullanıcı iptal etmediyse)
          if (_capturedVideoUrl == null &&
              !_showingDialog &&
              !_userDismissedDialog) {
            final firstUrl = urls.first.trim();
            debugPrint(
              '🎥 İlk video URL yakalandı (periyodik kontrol): $firstUrl',
            );

            if (mounted) {
              setState(() {
                _capturedVideoUrl = firstUrl;
              });

              // Dialog göster
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted && !_showingDialog && !_userDismissedDialog) {
                  _showNativePlayerDialog();
                }
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Video kontrol hatası: $e');
    } finally {
      _isCheckingVideo = false;
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
        // Altyazı içeriği tespit fonksiyonu
        function isSubtitleContent(url, responseText, contentType) {
          const urlLower = url.toLowerCase();

          // Altyazı format uzantıları
          const subtitleFormats = ['.vtt', '.srt', '.ass', '.ssa', '.sub'];
          const hasSubtitleExtension = subtitleFormats.some(format => urlLower.includes(format));

          // Content-Type kontrolü
          const subtitleContentTypes = ['text/vtt', 'application/x-subrip', 'text/plain'];
          const hasSubtitleContentType = contentType && subtitleContentTypes.some(type => contentType.includes(type));

          // Response içerik kontrolü (VTT, SRT formatları)
          let hasSubtitleContent = false;
          if (responseText) {
            const text = responseText.substring(0, 200);
            hasSubtitleContent =
              text.includes('WEBVTT') ||
              text.includes('\\n1\\n') && text.includes(' --> ') || // SRT format
              /^\\d+\\s*\\n\\d{2}:\\d{2}:\\d{2}/.test(text); // SRT timestamp pattern
          }

          return hasSubtitleExtension || hasSubtitleContentType || hasSubtitleContent;
        }

        // Medya içeriği tespit fonksiyonu (GÜÇLENDİRİLMİŞ)
        function isMediaContent(url, responseText, contentType) {
          const urlLower = url.toLowerCase();

          // ÖNEMLİ: Önce altyazı kontrolü yap - eğer altyazıysa video değildir!
          if (isSubtitleContent(url, responseText, contentType)) {
            return false;
          }

          // 1. VIDEO FORMAT UZANTILARI
          const videoFormats = ['.m3u8', '.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.m4v', '.mpd'];
          const hasVideoExtension = videoFormats.some(format => urlLower.includes(format));

          // 2. TS SEGMENT KONTROLü (sadece HLS context'inde)
          const hasTsExtension = urlLower.includes('.ts');
          const hasHlsPattern = urlLower.includes('hls') || urlLower.includes('m3u8') || urlLower.includes('segment');
          const isTsVideo = hasTsExtension && hasHlsPattern;

          // 3. STREAMING PATTERN'LERİ
          const streamPatterns = ['hls', 'dash', 'video', 'stream', 'manifest', 'playlist', 'master'];
          const hasStreamPattern = streamPatterns.some(pattern => urlLower.includes(pattern));

          // 4. CONTENT-TYPE KONTROLÜ
          const mediaContentTypes = [
            'video/', 'audio/', 'application/vnd.apple.mpegurl',
            'application/x-mpegurl', 'application/dash+xml',
            'application/octet-stream'
          ];
          const hasMediaContentType = contentType && mediaContentTypes.some(type => contentType.includes(type));

          // 5. RESPONSE İÇERİK KONTROLÜ (M3U8, MPD)
          let hasMediaContent = false;
          if (responseText) {
            const text = responseText.substring(0, 500);
            hasMediaContent =
              text.includes('#EXTM3U') ||
              text.includes('#EXT-X-') ||
              text.includes('<MPD') ||
              text.includes('<?xml') && text.includes('urn:mpeg:dash');
          }

          // 6. CDN DOMAIN KONTROLü (photostack, imagehub, dplayer, vidmoxy, rapidvid, etc.)
          const cdnDomains = [
            'photostack.net', 'imagehub.pics', 'dplayer', 'vidmoxy', 'rapidvid',
            'cloudfront.net', 'akamaihd.net', 'googleusercontent.com',
            'streamtape', 'streamlare', 'doodstream', 'voe.sx', 'mixdrop',
            'upstream.to', 'gounlimited', 'fembed', 'asianload'
          ];
          const hasCdnDomain = cdnDomains.some(domain => urlLower.includes(domain));

          // 7. ENCRYPTED/HASH PATH PATTERN (uzantısız uzun path'ler)
          // Örnek: /m9/nUyyZKMdLJg0o3Oyd0zxpTuiqT9mqTSwnl5hMKDs0xi6vr1
          const pathSegments = url.split('/').filter(s => s.length > 0);
          const hasLongHashPath = pathSegments.some(segment => {
            // Query string'i temizle
            const cleanSegment = segment.split('?')[0];
            // 20+ karakter, harf+rakam karışımı, uzantısız
            const hasLetters = /[a-zA-Z]/.test(cleanSegment);
            const hasNumbers = /[0-9]/.test(cleanSegment);
            // Nokta içerip içermediğini kontrol et (basit yol)
            const lastDotIndex = cleanSegment.lastIndexOf('.');
            const hasExtension = lastDotIndex > -1 && (cleanSegment.length - lastDotIndex) <= 5;
            return cleanSegment.length > 20 && hasLetters && hasNumbers && !hasExtension;
          });

          // 8. QUERY PARAMETER BASE64/ENCRYPTED KONTROLü
          // Örnek: ?v=cHVQSnhEeFVIcEhC... veya ?token=abcd1234...
          const hasEncryptedQuery = /[?&](v|token|key|id|data|video)=[a-zA-Z0-9+\/=]{30,}/.test(url);

          // 9. CORS HEADER KONTROLü (cross-origin video requestleri)
          // Not: JavaScript'ten access-control header'ları göremeyiz ama
          // Content-Type ve response varlığı yeterli ipucu
          const hasCorsIndicator = contentType && url.includes('http') &&
                                   (contentType === 'application/octet-stream' ||
                                    contentType === '*/*' ||
                                    contentType === '');

          // 10. RESPONSE SIZE KONTROLü (büyük response = potansiyel video data)
          const hasLargeResponse = responseText && responseText.length > 1000;

          // 11. ÖNEMLİ: Resim ve font URL'lerini hariç tut
          const imageFormats = ['.jpg', '.jpeg', '.png', '.gif', '.svg', '.webp', '.ico', '.bmp'];
          const fontFormats = ['.woff', '.woff2', '.ttf', '.otf', '.eot'];
          const excludedFormats = [...imageFormats, ...fontFormats];
          const isExcludedFormat = excludedFormats.some(format => urlLower.includes(format));

          if (isExcludedFormat) {
            return false;
          }

          // 12. JAVASCRIPT ve CSS dosyalarını hariç tut
          const codeFormats = ['.js', '.css', '.json', '.xml'];
          const isCodeFile = codeFormats.some(format => urlLower.endsWith(format));

          if (isCodeFile) {
            return false;
          }

          // KARAR LOJİĞİ: Herhangi bir pozitif sinyal varsa medya içeriği olarak değerlendir
          const isMedia =
            hasVideoExtension ||          // 1. Kesin uzantı
            isTsVideo ||                  // 2. HLS segment
            hasMediaContentType ||        // 3. Kesin content-type
            hasMediaContent ||            // 4. Kesin response içeriği
            (hasStreamPattern && (hasCdnDomain || hasEncryptedQuery)) || // 5. Stream pattern + CDN/encrypted
            (hasCdnDomain && (hasLongHashPath || hasEncryptedQuery)) ||  // 6. CDN + hash/encrypted
            (hasLongHashPath && hasEncryptedQuery) ||                    // 7. Hash path + encrypted query
            (hasCorsIndicator && hasLargeResponse && hasCdnDomain);      // 8. CORS + büyük response + CDN

          return isMedia;
        }

        // XMLHttpRequest'i intercept et
        const originalOpen = XMLHttpRequest.prototype.open;
        const originalSend = XMLHttpRequest.prototype.send;

        XMLHttpRequest.prototype.open = function(method, url) {
          this._url = url;
          this._method = method;
          return originalOpen.apply(this, arguments);
        };

        XMLHttpRequest.prototype.send = function() {
          const url = this._url;
          const xhr = this;

          // Response'u dinle
          xhr.addEventListener('load', function() {
            if (xhr.status === 200) {
              const contentType = xhr.getResponseHeader('Content-Type') || '';
              let responseText = '';

              try {
                responseText = xhr.responseText || '';
              } catch(e) {
                // Binary response ise responseText alınamayabilir
              }

              if (isMediaContent(url, responseText, contentType)) {
                window.flutter_network_log.postMessage(JSON.stringify({
                  type: 'video',
                  url: url,
                  method: 'XHR',
                  contentType: contentType,
                  hasContent: !!responseText
                }));
              } else if (isSubtitleContent(url, responseText, contentType)) {
                window.flutter_network_log.postMessage(JSON.stringify({
                  type: 'subtitle',
                  url: url,
                  method: 'XHR',
                  contentType: contentType
                }));
              }
            }
          });

          return originalSend.apply(this, arguments);
        };

        // Fetch API'yi intercept et
        const originalFetch = window.fetch;
        window.fetch = function(url, options) {
          const requestUrl = typeof url === 'string' ? url : url.url;
          const promise = originalFetch.apply(this, arguments);

          promise.then(function(response) {
            if (response.ok && response.status === 200) {
              const contentType = response.headers.get('Content-Type') || '';

              // Response'u clone et (orijinali bozmamak için)
              const clonedResponse = response.clone();

              // Content-Type ile hızlı kontrol
              if (isMediaContent(requestUrl, '', contentType)) {
                window.flutter_network_log.postMessage(JSON.stringify({
                  type: 'video',
                  url: requestUrl,
                  method: 'FETCH',
                  contentType: contentType,
                  quickCheck: true
                }));
              } else if (isSubtitleContent(requestUrl, '', contentType)) {
                window.flutter_network_log.postMessage(JSON.stringify({
                  type: 'subtitle',
                  url: requestUrl,
                  method: 'FETCH',
                  contentType: contentType,
                  quickCheck: true
                }));
              }

              // İçerik kontrolü (text olarak parse edilebiliyorsa)
              clonedResponse.text().then(function(text) {
                if (isMediaContent(requestUrl, text, contentType)) {
                  window.flutter_network_log.postMessage(JSON.stringify({
                    type: 'video',
                    url: requestUrl,
                    method: 'FETCH_CONTENT',
                    contentType: contentType,
                    hasContent: true
                  }));
                } else if (isSubtitleContent(requestUrl, text, contentType)) {
                  window.flutter_network_log.postMessage(JSON.stringify({
                    type: 'subtitle',
                    url: requestUrl,
                    method: 'FETCH_CONTENT',
                    contentType: contentType
                  }));
                }
              }).catch(function(e) {
                // Binary content, text parse edilemedi
              });
            }
          }).catch(function(e) {
            // Fetch hatası
          });

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
                    method: 'VIDEO_ELEMENT',
                    contentType: 'video/element'
                  }));
                }

                // Source elementlerini de kontrol et
                node.querySelectorAll('source').forEach(function(source) {
                  if (source.src) {
                    window.flutter_network_log.postMessage(JSON.stringify({
                      type: 'video',
                      url: source.src,
                      method: 'VIDEO_SOURCE',
                      contentType: source.type || 'video/unknown'
                    }));
                  }
                });
              }
            });
          });
        });

        observer.observe(document.body, {
          childList: true,
          subtree: true
        });

        // Mevcut video elementlerini kontrol et (ilk yükleme)
        setTimeout(function() {
          document.querySelectorAll('video').forEach(function(video) {
            const src = video.src || video.currentSrc;
            if (src) {
              window.flutter_network_log.postMessage(JSON.stringify({
                type: 'video',
                url: src,
                method: 'EXISTING_VIDEO',
                contentType: 'video/element'
              }));
            }

            video.querySelectorAll('source').forEach(function(source) {
              if (source.src) {
                window.flutter_network_log.postMessage(JSON.stringify({
                  type: 'video',
                  url: source.src,
                  method: 'EXISTING_SOURCE',
                  contentType: source.type || 'video/unknown'
                }));
              }
            });
          });
        }, 1000);

        // NOT: Periyodik kontrolü Dart tarafında yapıyoruz
        // JavaScript'te setInterval ile sürekli mesaj göndermek yerine
        // Dart tarafında _checkVideoElements() ile kontrol ediyoruz
      })();
    ''';

    _webViewController.runJavaScript(jsCode);

    // JavaScript channel ekle
    _webViewController.addJavaScriptChannel(
      'flutter_network_log',
      onMessageReceived: (JavaScriptMessage message) {
        try {
          final data = json.decode(message.message);
          final type = data['type'] as String?;
          final url = data['url'] as String?;
          final method = data['method'] as String?;
          final contentType = data['contentType'] as String?;

          if (url != null && url.isNotEmpty) {
            // URL'i logla
            final logEntry = contentType != null
                ? '$method [$contentType]: $url'
                : '$method: $url';

            // Altyazı yakalandıysa
            if (type == 'subtitle') {
              debugPrint('📝 Altyazı URL yakalandı: $url');
              if (mounted && !_capturedSubtitles.contains(url)) {
                setState(() {
                  _capturedSubtitles.add(url);
                });

                // Veritabanına kaydet
                _saveSubtitleToDatabase(url);
              }
              return; // Altyazı için dialog gösterme
            }

            debugPrint('🔍 Media request detected: $logEntry');

            // Video URL'ini listeye ekle (tekrar ekleme)
            if (mounted && !_capturedVideoUrls.contains(url)) {
              setState(() {
                _capturedVideoUrls.add(url);
                _networkLogs.add(logEntry);
              });
              debugPrint(
                '🎥 Toplam ${_capturedVideoUrls.length} video URL yakalandı',
              );

              // Veritabanına kaydet
              _saveVideoToDatabase(url, method ?? 'UNKNOWN');
            }

            // İlk medya URL'ini yakala ve dialog göster (sadece kullanıcı iptal etmediyse)
            if (_capturedVideoUrl == null &&
                !_showingDialog &&
                !_userDismissedDialog) {
              debugPrint('🎥 Video URL yakalandı: $url');
              debugPrint('🎥 Method: $method');
              if (contentType != null) {
                debugPrint('🎥 Content-Type: $contentType');
              }

              // setState'i tek seferde yap
              if (mounted) {
                setState(() {
                  _capturedVideoUrl = url;
                });

                // URL yakalandı, dialog göster
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted && !_showingDialog && !_userDismissedDialog) {
                    _showNativePlayerDialog();
                  }
                });
              }
            }
          }
        } catch (e) {
          debugPrint('❌ Network log parse error: $e');
        }
      },
    );
  }

  void _showNativePlayerDialog() {
    if (_showingDialog) return; // Duplicate dialog önleme

    setState(() {
      _showingDialog = true;
      _remainingSeconds = 5;
    });

    // Animasyonu başlat
    _animationController.forward();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          // 5 saniyelik geri sayım timer'ı (sadece bir kez oluştur)
          _autoRedirectTimer ??= Timer.periodic(const Duration(seconds: 1), (
            timer,
          ) {
            if (!mounted) {
              timer.cancel();
              return;
            }

            // Hem ana state hem dialog state'i güncelle
            if (_remainingSeconds > 0) {
              setState(() {
                _remainingSeconds--;
              });

              setDialogState(() {
                // Dialog içi güncelleme tetikleme
              });
            }

            if (_remainingSeconds <= 0) {
              timer.cancel();
              if (mounted && _showingDialog) {
                Navigator.of(context, rootNavigator: true).pop();
                _switchToNativePlayer();
              }
            }
          });

          return ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: AlertDialog(
                backgroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.green, width: 2),
                ),
                title: Row(
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Transform.rotate(
                            angle: value * 2 * 3.14159,
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Video URL Bulundu!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                      child: Text(
                        _capturedVideoUrl ?? '',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Altyazı bilgisi
                    if (_capturedSubtitles.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.subtitles,
                            color: Colors.green,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_capturedSubtitles.length} altyazı bulundu',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Kendi playerımızla devam etmek ister misiniz?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Geri sayım göstergesi
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Stack(
                              children: [
                                CircularProgressIndicator(
                                  value: _remainingSeconds / 5,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.orange.withOpacity(
                                    0.3,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.orange,
                                      ),
                                ),
                                Center(
                                  child: Text(
                                    '$_remainingSeconds',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '$_remainingSeconds saniye içinde otomatik yönleneceksiniz...',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      _autoRedirectTimer?.cancel();
                      Navigator.of(context).pop();
                      setState(() {
                        _showingDialog = false;
                        _userDismissedDialog =
                            true; // Kullanıcı iptal etti, artık otomatik gösterme
                      });
                      debugPrint(
                        '❌ Kullanıcı dialog\'u iptal etti. Arka planda dinlemeye devam ediliyor...',
                      );
                    },
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('İframe\'de Kal'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      _autoRedirectTimer?.cancel();
                      Navigator.of(context).pop();
                      _switchToNativePlayer();
                    },
                    icon: const Icon(Icons.play_circle_fill, size: 20),
                    label: const Text('Hemen Geç'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 5,
                    ),
                  ),
                ],
              ), // AlertDialog
            ), // FadeTransition
          ); // ScaleTransition (return değeri)
        }, // builder closure
      ), // StatefulBuilder
    ).then((_) {
      // Dialog kapandığında timer'ı temizle
      _autoRedirectTimer?.cancel();
      if (mounted) {
        setState(() {
          _showingDialog = false;
        });
      }
    });
  }

  void _showSourceSelectionDialog() {
    if (_capturedVideoUrls.isEmpty) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.purple, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.video_library, color: Colors.purple, size: 28),
            const SizedBox(width: 12),
            Text(
              '${_capturedVideoUrls.length} Kaynak Bulundu',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 400),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _capturedVideoUrls.length,
            itemBuilder: (context, index) {
              final url = _capturedVideoUrls[index];
              final isSelected = url == _capturedVideoUrl;

              // URL'den format çıkar
              String format = 'Video';
              if (url.contains('.m3u8')) {
                format = 'HLS (M3U8)';
              } else if (url.contains('.mp4')) {
                format = 'MP4';
              } else if (url.contains('.ts')) {
                format = 'TS Segment';
              } else if (url.contains('.mpd')) {
                format = 'DASH';
              }

              return Card(
                color: isSelected
                    ? Colors.green.withOpacity(0.2)
                    : Colors.white.withOpacity(0.05),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected ? Colors.green : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  leading: Icon(
                    isSelected ? Icons.check_circle : Icons.play_circle_outline,
                    color: isSelected ? Colors.green : Colors.purple,
                    size: 32,
                  ),
                  title: Text(
                    'Kaynak ${index + 1}',
                    style: TextStyle(
                      color: isSelected ? Colors.green : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          format,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        url,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 10,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '✓ Şu anda bu kaynak oynatılıyor',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _switchToNativePlayerWithUrl(url);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text('Oynat', style: TextStyle(fontSize: 12)),
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  void _switchToNativePlayer() {
    _switchToNativePlayerWithUrl(_capturedVideoUrl!);
  }

  void _switchToNativePlayerWithUrl(String videoUrl) {
    // Native player'a geç
    // Yeni bir kaynak oluştur (iframe değil, direkt URL)
    final directKaynak = Kaynak(
      id: widget.kaynak.id,
      baslik: '${widget.kaynak.baslik} (Auto)',
      url: videoUrl,
      kaynakId: widget.kaynak.kaynakId,
      isIframe: false,
    );

    // Yakalanan altyazıları Altyazi modeline çevir
    final capturedAltyazilar = _capturedSubtitles.asMap().entries.map((entry) {
      final index = entry.key;
      final url = entry.value;

      // URL'den format çıkar (vtt, srt)
      final extension = url.toLowerCase().split('.').last.split('?').first;
      String baslik = 'Altyazı ${index + 1}';

      if (extension == 'vtt') {
        baslik = 'WebVTT ${index + 1}';
      } else if (extension == 'srt') {
        baslik = 'SRT ${index + 1}';
      }

      return Altyazi(
        id: -1 * (index + 1), // Negatif ID ile geçici altyazıları ayırt et
        baslik: baslik,
        url: url,
        filmId: widget.film.id,
      );
    }).toList();

    // Mevcut altyazılarla birleştir
    final existingAltyazilar = widget.film.altyazilar ?? [];
    final allAltyazilar = [...existingAltyazilar, ...capturedAltyazilar];

    debugPrint(
      '📝 Toplam ${allAltyazilar.length} altyazı player\'a gönderiliyor',
    );
    debugPrint(
      '📝 Yakalanan: ${capturedAltyazilar.length}, Mevcut: ${existingAltyazilar.length}',
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
      altyazilar: allAltyazilar,
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
    // Mevcut timer'ları iptal et
    _videoCheckTimer?.cancel();
    _autoRedirectTimer?.cancel();

    setState(() {
      _isLoading = true;
      _capturedVideoUrl = null;
      _isAnalyzing = true;
      _showingDialog = false;
      _remainingSeconds = 5;
      _networkLogs.clear();
    });

    // Animasyonu sıfırla
    _animationController.reset();

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
      if (_capturedVideoUrl == null && !_showingDialog) {
        _checkVideoElements();
      } else if (_capturedVideoUrl != null) {
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

  /// Video kaynağını veritabanına kaydet
  Future<void> _saveVideoToDatabase(String url, String method) async {
    // Duplicate kontrolü
    if (_savedVideoUrls.contains(url)) {
      debugPrint('⏭️  IFRAME PLAYER: Video zaten kaydedildi: $url');
      return;
    }

    try {
      // API'den mevcut kaynakları kontrol et
      final existingSources = await _apiService.getFilmKaynaklari(
        widget.film.id,
      );
      final alreadyExists = existingSources.any((k) => k.url == url);

      if (alreadyExists) {
        debugPrint('⏭️  IFRAME PLAYER: Video veritabanında zaten var');
        _savedVideoUrls.add(url);
        return;
      }

      // Kalite tespiti
      final quality = _detectQuality(url);
      final title =
          '${widget.kaynak.baslik}${quality.isNotEmpty ? " - $quality" : ""} [$method]';

      // Yeni kaynak oluştur
      final newSource = Kaynak(
        id: 0,
        url: url,
        baslik: title,
        isIframe: false, // Direkt video URL
      );

      // Veritabanına kaydet
      final savedSource = await _apiService.createFilmKaynagi(
        widget.film.id,
        newSource,
      );

      _savedVideoUrls.add(url);
      debugPrint('✅ IFRAME PLAYER: Video kaydedildi: ${savedSource.baslik}');
      debugPrint('✅ IFRAME PLAYER: Video ID: ${savedSource.id}');
    } catch (e) {
      debugPrint('❌ IFRAME PLAYER: Video kaydetme hatası: $e');
    }
  }

  /// Altyazıyı veritabanına kaydet
  Future<void> _saveSubtitleToDatabase(String url) async {
    // Duplicate kontrolü
    if (_savedSubtitleUrls.contains(url)) {
      debugPrint('⏭️  IFRAME PLAYER: Altyazı zaten kaydedildi: $url');
      return;
    }

    try {
      // API'den mevcut altyazıları kontrol et
      final existingSubtitles = await _apiService.getFilmAltyazilari(
        widget.film.id,
      );
      final alreadyExists = existingSubtitles.any((a) => a.url == url);

      if (alreadyExists) {
        debugPrint('⏭️  IFRAME PLAYER: Altyazı veritabanında zaten var');
        _savedSubtitleUrls.add(url);
        return;
      }

      // Format tespiti
      String title = '${widget.kaynak.baslik} - Altyazı';
      if (url.toLowerCase().contains('.vtt')) {
        title = '${widget.kaynak.baslik} - WebVTT';
      } else if (url.toLowerCase().contains('.srt')) {
        title = '${widget.kaynak.baslik} - SRT';
      }

      // Yeni altyazı oluştur
      final newSubtitle = Altyazi(
        id: 0,
        url: url,
        baslik: title,
        filmId: widget.film.id,
      );

      // Veritabanına kaydet
      final savedSubtitle = await _apiService.createFilmAltyazisi(
        widget.film.id,
        newSubtitle,
      );

      _savedSubtitleUrls.add(url);
      debugPrint(
        '✅ IFRAME PLAYER: Altyazı kaydedildi: ${savedSubtitle.baslik}',
      );
      debugPrint('✅ IFRAME PLAYER: Altyazı ID: ${savedSubtitle.id}');
    } catch (e) {
      debugPrint('❌ IFRAME PLAYER: Altyazı kaydetme hatası: $e');
    }
  }

  /// Kalite tespiti
  String _detectQuality(String url) {
    final urlLower = url.toLowerCase();

    if (urlLower.contains('4k') ||
        urlLower.contains('2160') ||
        urlLower.contains('2160p')) {
      return '4K';
    }
    if (urlLower.contains('1440') || urlLower.contains('1440p')) {
      return '1440p';
    }
    if (urlLower.contains('1080') ||
        urlLower.contains('1080p') ||
        urlLower.contains('fullhd') ||
        urlLower.contains('fhd')) {
      return '1080p';
    }
    if (urlLower.contains('720') ||
        urlLower.contains('720p') ||
        urlLower.contains('hd')) {
      return '720p';
    }
    if (urlLower.contains('480') || urlLower.contains('480p')) {
      return '480p';
    }
    if (urlLower.contains('360') || urlLower.contains('360p')) {
      return '360p';
    }
    if (urlLower.contains('240') || urlLower.contains('240p')) {
      return '240p';
    }

    // URL path'inden tespit et
    final segments = url.split('/');
    for (final segment in segments.reversed) {
      if (RegExp(r'\d{3,4}p?').hasMatch(segment)) {
        return segment;
      }
    }

    return 'Auto';
  }

  @override
  void dispose() {
    _videoCheckTimer?.cancel();
    _autoRedirectTimer?.cancel();
    _animationController.dispose();
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
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 500),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Container(
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
                                        'Analiz ediliyor...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                        // Kaynak sayısı butonu
                        if (_capturedVideoUrls.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showSourceSelectionDialog,
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.purple,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.video_library,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_capturedVideoUrls.length} Kaynak',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        // Video URL yakalandı
                        if (_capturedVideoUrl != null)
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: Colors.green,
                                      width: 1,
                                    ),
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
                              );
                            },
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
