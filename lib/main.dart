import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/film_detail_screen.dart';
import 'screens/category_screen.dart';
import 'models/film.dart';
import 'models/tur.dart';
import 'services/api_service.dart';
import 'services/tur_service.dart';

void main() {
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
        // Film ID'den film objesini çek
        return FutureBuilder<Film?>(
          future: ApiService().getFilm(filmId),
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
