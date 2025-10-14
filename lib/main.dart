import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/film_detail_screen.dart';
import 'screens/category_screen.dart';
import 'screens/player_screen.dart';
import 'models/film.dart';
import 'models/tur.dart';
import 'services/api_service.dart';
import 'services/tur_service.dart';
import 'services/film_cache_service.dart';

// Web için HLS desteği - Şimdilik devre dışı (Android'de native destekliyor)
// import 'package:video_player_web_hls/video_player_web_hls.dart';
// import 'package:video_player_platform_interface/video_player_platform_interface.dart';

void main() {
  // Sistem UI yapılandırması (status bar, navigation bar)
  WidgetsFlutterBinding.ensureInitialized();
  
  // Edge-to-edge mod: Içerik ekranın tamamını kullanır
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );
  
  // Status bar ve navigation bar renklerini ayarla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Transparan status bar
      statusBarIconBrightness: Brightness.light, // Beyaz ikonlar (karanlık tema)
      statusBarBrightness: Brightness.dark, // iOS için
      systemNavigationBarColor: Colors.transparent, // Transparan navigation bar
      systemNavigationBarIconBrightness: Brightness.light, // Beyaz ikonlar
      systemNavigationBarContrastEnforced: false, // Android 10+ için kontrast zorlamasını kapat
    ),
  );
  
  // Web için HLS plugin'ini register et
  // if (kIsWeb) {
  //   VideoPlayerPlatform.instance = VideoPlayerPluginHls();
  // }

  runApp(const ErdoflixApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/film/:id',
      builder: (context, state) {
        final filmId = int.parse(state.pathParameters['id']!);
        // Film ID'den film objesini kaynak ve altyazılarla birlikte çek
        return FutureBuilder<Film?>(
          future: ApiService().getFilmWithDetails(filmId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return FilmDetailScreen(film: snapshot.data!);
            }
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Text(
                  'Film bulunamadı',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/category/:id',
      builder: (context, state) {
        final turId = int.parse(state.pathParameters['id']!);
        // Tür ID'den tür objesini çek
        return FutureBuilder<Tur?>(
          future: TurService().getTur(turId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return CategoryScreen(tur: snapshot.data!);
            }
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Text(
                  'Kategori bulunamadı',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/player/:id',
      builder: (context, state) {
        final filmId = int.parse(state.pathParameters['id']!);

        // 1. Önce extra'dan Film objesi almaya çalış
        final extraFilm = state.extra as Film?;

        if (extraFilm != null) {
          debugPrint('🎬 Player: Film extra ile geldi');
          return PlayerScreen(film: extraFilm);
        }

        // 2. Extra yoksa cache'den bak
        final cachedFilm = FilmCacheService().getFilm(filmId);

        if (cachedFilm != null) {
          debugPrint('🎬 Player: Film cache\'den alındı');
          debugPrint('🎬 Cache Film hasVideo: ${cachedFilm.hasVideo}');
          debugPrint(
            '🎬 Cache Film kaynaklar: ${cachedFilm.kaynaklar?.length}',
          );
          return PlayerScreen(film: cachedFilm);
        }

        // 3. Cache'de de yoksa, API'den çek
        debugPrint('🎬 Player: Film API\'den çekiliyor: $filmId');

        return FutureBuilder<Film?>(
          future: ApiService().getFilmWithDetails(filmId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(color: Colors.red),
                ),
              );
            }
            if (snapshot.hasData && snapshot.data != null) {
              return PlayerScreen(film: snapshot.data!);
            }
            return const Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: Text(
                  'Film bulunamadı',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            );
          },
        );
      },
    ),
  ],
);

class ErdoflixApp extends StatelessWidget {
  const ErdoflixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Erdoflix',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.red,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.dark(
          primary: Colors.red,
          secondary: Colors.redAccent,
        ),
      ),
      routerConfig: _router,
    );
  }
}
