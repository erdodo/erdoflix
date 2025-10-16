import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/kaynak.dart';
import '../models/altyazi.dart';
import 'api_service.dart';

/// Iframe'den kaynak toplama ve veritabanına kaydetme servisi
class SourceCollectorService {
  final ApiService _apiService = ApiService();

  // Stream controller'lar - UI'a real-time güncellemeler için
  final _sourcesStreamController = StreamController<List<Kaynak>>.broadcast();
  final _subtitlesStreamController =
      StreamController<List<Altyazi>>.broadcast();

  // Bulunan kaynaklar (duplicate kontrolü için)
  final Set<String> _discoveredSourceUrls = {};
  final Set<String> _discoveredSubtitleUrls = {};

  // Stream'ler
  Stream<List<Kaynak>> get sourcesStream => _sourcesStreamController.stream;
  Stream<List<Altyazi>> get subtitlesStream =>
      _subtitlesStreamController.stream;

  // Mevcut liste
  final List<Kaynak> _currentSources = [];
  final List<Altyazi> _currentSubtitles = [];

  /// Kaynak toplama başlat
  Future<void> startCollecting({
    required int filmId,
    required String iframeUrl,
    required String sourceTitle,
  }) async {
    debugPrint('🔍 SOURCE COLLECTOR: Başlatılıyor...');
    debugPrint('🔍 Film ID: $filmId');
    debugPrint('🔍 Iframe URL: $iframeUrl');
    debugPrint('🔍 Kaynak Başlığı: $sourceTitle');

    // Temizle
    _discoveredSourceUrls.clear();
    _discoveredSubtitleUrls.clear();
    _currentSources.clear();
    _currentSubtitles.clear();

    // WebView controller oluştur (headless)
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            debugPrint('✅ SOURCE COLLECTOR: Sayfa yüklendi: $url');
          },
        ),
      )
      ..addJavaScriptChannel(
        'SourceCollector',
        onMessageReceived: (JavaScriptMessage message) {
          _handleSourceMessage(message.message, filmId, sourceTitle);
        },
      );

    // JavaScript injection - kaynak yakalama kodu
    await controller.loadRequest(Uri.parse(iframeUrl));

    // JavaScript kodunu inject et ve bekle
    await Future.delayed(const Duration(seconds: 3));
    await _injectJavaScript(controller);

    // Kaynakların toplanması için bekle (30 saniye)
    debugPrint('⏳ SOURCE COLLECTOR: 30 saniye bekleniyor...');
    await Future.delayed(const Duration(seconds: 30));

    debugPrint('✅ SOURCE COLLECTOR: Toplama tamamlandı');
  }

  /// JavaScript kodunu inject et
  Future<void> _injectJavaScript(WebViewController controller) async {
    const jsCode = '''
      (function() {
        console.log('🔍 SOURCE COLLECTOR JS: Başlatıldı');

        // Medya tespit fonksiyonu
        function isMediaContent(url, contentType) {
          const urlLower = url.toLowerCase();

          // Video formatları
          const videoFormats = ['.m3u8', '.mp4', '.mkv', '.avi', '.webm', '.mov', '.flv', '.m4v', '.mpd'];
          const hasVideoExtension = videoFormats.some(format => urlLower.includes(format));

          // Streaming pattern'leri
          const streamPatterns = ['hls', 'dash', 'video', 'stream', 'manifest', 'playlist', 'master'];
          const hasStreamPattern = streamPatterns.some(pattern => urlLower.includes(pattern));

          // Content-Type kontrolü
          const mediaContentTypes = ['video/', 'audio/', 'application/vnd.apple.mpegurl', 'application/x-mpegurl', 'application/dash+xml'];
          const hasMediaContentType = contentType && mediaContentTypes.some(type => contentType.includes(type));

          return hasVideoExtension || hasStreamPattern || hasMediaContentType;
        }

        // Altyazı tespit fonksiyonu
        function isSubtitleContent(url, contentType) {
          const urlLower = url.toLowerCase();
          const subtitleFormats = ['.vtt', '.srt', '.ass', '.ssa', '.sub'];
          return subtitleFormats.some(format => urlLower.includes(format));
        }

        // XMLHttpRequest intercept
        const originalXHROpen = XMLHttpRequest.prototype.open;
        const originalXHRSend = XMLHttpRequest.prototype.send;

        XMLHttpRequest.prototype.open = function(method, url) {
          this._url = url;
          return originalXHROpen.apply(this, arguments);
        };

        XMLHttpRequest.prototype.send = function() {
          const xhr = this;
          const url = this._url;

          xhr.addEventListener('load', function() {
            if (xhr.status === 200) {
              const contentType = xhr.getResponseHeader('Content-Type') || '';

              if (isMediaContent(url, contentType)) {
                SourceCollector.postMessage(JSON.stringify({
                  type: 'video',
                  url: url,
                  method: 'XHR',
                  contentType: contentType
                }));
              } else if (isSubtitleContent(url, contentType)) {
                SourceCollector.postMessage(JSON.stringify({
                  type: 'subtitle',
                  url: url,
                  method: 'XHR',
                  contentType: contentType
                }));
              }
            }
          });

          return originalXHRSend.apply(this, arguments);
        };

        // Fetch API intercept
        const originalFetch = window.fetch;
        window.fetch = function(url, options) {
          const requestUrl = typeof url === 'string' ? url : url.url;
          const promise = originalFetch.apply(this, arguments);

          promise.then(function(response) {
            if (response.ok) {
              const contentType = response.headers.get('Content-Type') || '';

              if (isMediaContent(requestUrl, contentType)) {
                SourceCollector.postMessage(JSON.stringify({
                  type: 'video',
                  url: requestUrl,
                  method: 'FETCH',
                  contentType: contentType
                }));
              } else if (isSubtitleContent(requestUrl, contentType)) {
                SourceCollector.postMessage(JSON.stringify({
                  type: 'subtitle',
                  url: requestUrl,
                  method: 'FETCH',
                  contentType: contentType
                }));
              }
            }
          });

          return promise;
        };

        // Video element kontrolü
        function checkVideoElements() {
          const videos = document.querySelectorAll('video');
          videos.forEach(function(video) {
            if (video.src) {
              SourceCollector.postMessage(JSON.stringify({
                type: 'video',
                url: video.src,
                method: 'ELEMENT',
                contentType: 'video/element'
              }));
            }
            if (video.currentSrc) {
              SourceCollector.postMessage(JSON.stringify({
                type: 'video',
                url: video.currentSrc,
                method: 'ELEMENT',
                contentType: 'video/element'
              }));
            }
          });
        }

        // Periyodik kontrol - daha sık (her 2 saniyede)
        setInterval(checkVideoElements, 2000);

        // İlk kontrolü hemen yap, sonra 5 saniye, 10 saniye, 15 saniyede tekrar
        checkVideoElements();
        setTimeout(checkVideoElements, 5000);
        setTimeout(checkVideoElements, 10000);
        setTimeout(checkVideoElements, 15000);

        console.log('✅ SOURCE COLLECTOR JS: Hazır ve dinliyor...');
      })();
    ''';

    try {
      await controller.runJavaScript(jsCode);
      debugPrint('✅ SOURCE COLLECTOR: JavaScript injected');
    } catch (e) {
      debugPrint('❌ SOURCE COLLECTOR: JavaScript injection hatası: $e');
    }
  }

  /// Mesaj handle et
  Future<void> _handleSourceMessage(
    String message,
    int filmId,
    String sourceTitle,
  ) async {
    try {
      debugPrint('📬 SOURCE COLLECTOR: Raw mesaj alındı: $message');

      final data = json.decode(message);
      final type = data['type'] as String;
      final url = data['url'] as String;
      final method = data['method'] as String? ?? 'UNKNOWN';
      final contentType = data['contentType'] as String? ?? '';

      debugPrint(
        '📨 SOURCE COLLECTOR: Parse edildi - Type: $type, Method: $method',
      );
      debugPrint('📨 SOURCE COLLECTOR: URL: $url');
      debugPrint('📨 SOURCE COLLECTOR: Content-Type: $contentType');

      if (type == 'video') {
        await _handleVideoSource(url, contentType, filmId, sourceTitle);
      } else if (type == 'subtitle') {
        await _handleSubtitleSource(url, filmId);
      }
    } catch (e) {
      debugPrint('❌ SOURCE COLLECTOR: Mesaj parse hatası: $e');
      debugPrint('❌ SOURCE COLLECTOR: Mesaj içeriği: $message');
    }
  }

  /// Video kaynağı handle et
  Future<void> _handleVideoSource(
    String url,
    String contentType,
    int filmId,
    String sourceTitle,
  ) async {
    // Duplicate kontrolü - sadece local check
    if (_discoveredSourceUrls.contains(url)) {
      debugPrint('⏭️  SOURCE COLLECTOR: Kaynak local cache\'de var, atlanıyor');
      return;
    }

    // Kalite tespiti
    final quality = _detectQuality(url);
    final title = '$sourceTitle${quality.isNotEmpty ? " - $quality" : ""}';

    debugPrint('📹 SOURCE COLLECTOR: Yeni kaynak bulundu: $title');
    debugPrint('📹 URL: $url');

    // Veritabanında kontrol et
    try {
      final existingSourcesData = await _apiService.getFilmKaynaklari(filmId);
      final alreadyExists = existingSourcesData.any((k) => k['url'] == url);

      if (alreadyExists) {
        debugPrint('⏭️  SOURCE COLLECTOR: Kaynak veritabanında zaten var');
        _discoveredSourceUrls.add(url); // Cache'e ekle
        return;
      }

      // Veritabanına kaydet
      final newSource = Kaynak(
        id: 0, // API otomatik oluşturacak
        url: url,
        baslik: title,
        isIframe: false, // Direkt URL
      );

      final savedSource = await _apiService.createFilmKaynagi(
        filmId,
        newSource,
      );

      debugPrint(
        '✅ SOURCE COLLECTOR: Kaynak veritabanına eklendi: ${savedSource.id}',
      );

      // Başarılı kaydettikten sonra cache'e ekle
      _discoveredSourceUrls.add(url);

      // Listeye ekle
      _currentSources.add(savedSource);

      // Stream'e gönder (UI güncellenir)
      _sourcesStreamController.add(List.from(_currentSources));
    } catch (e) {
      debugPrint('❌ SOURCE COLLECTOR: Kaynak kaydetme hatası: $e');
    }
  }

  /// Altyazı handle et
  Future<void> _handleSubtitleSource(String url, int filmId) async {
    // Duplicate kontrolü - sadece local check
    if (_discoveredSubtitleUrls.contains(url)) {
      debugPrint('⏭️  SOURCE COLLECTOR: Altyazı local cache\'de var, atlanıyor');
      return;
    }

    // Format tespiti
    String title = 'Web Altyazı';
    if (url.toLowerCase().contains('.vtt')) {
      title = 'WebVTT';
    } else if (url.toLowerCase().contains('.srt')) {
      title = 'SRT';
    }

    debugPrint('📝 SOURCE COLLECTOR: Yeni altyazı bulundu: $title');
    debugPrint('📝 URL: $url');

    // Veritabanında kontrol et
    try {
      final existingSubtitlesData = await _apiService.getFilmAltyazilari(filmId);
      final alreadyExists = existingSubtitlesData.any((a) => a['url'] == url);

      if (alreadyExists) {
        debugPrint('⏭️  SOURCE COLLECTOR: Altyazı veritabanında zaten var');
        _discoveredSubtitleUrls.add(url); // Cache'e ekle
        return;
      }

      // Veritabanına kaydet
      final newSubtitle = Altyazi(
        id: 0,
        url: url,
        baslik: title,
        filmId: filmId,
      );

      final savedSubtitle = await _apiService.createFilmAltyazisi(
        filmId,
        newSubtitle,
      );

      debugPrint(
        '✅ SOURCE COLLECTOR: Altyazı veritabanına eklendi: ${savedSubtitle.id}',
      );

      // Başarılı kaydettikten sonra cache'e ekle
      _discoveredSubtitleUrls.add(url);

      // Listeye ekle
      _currentSubtitles.add(savedSubtitle);

      // Stream'e gönder (UI güncellenir)
      _subtitlesStreamController.add(List.from(_currentSubtitles));
    } catch (e) {
      debugPrint('❌ SOURCE COLLECTOR: Altyazı kaydetme hatası: $e');
    }
  }

  /// Kalite tespiti
  String _detectQuality(String url) {
    final urlLower = url.toLowerCase();

    // Kalite pattern'leri
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

  /// Temizle
  void dispose() {
    _sourcesStreamController.close();
    _subtitlesStreamController.close();
  }
}
