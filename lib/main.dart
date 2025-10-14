import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ErdoflixApp());
}

class ErdoflixApp extends StatelessWidget {
  const ErdoflixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      home: const HomeScreen(),
    );
  }
}
