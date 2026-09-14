import 'package:flutter/material.dart';
import 'welcome_screen.dart';
import 'favorites_screen.dart';

void main() {
  runApp(const MovieBrowserApp());
}

class MovieBrowserApp extends StatefulWidget {
  const MovieBrowserApp({super.key});

  @override
  State<MovieBrowserApp> createState() => _MovieBrowserAppState();
}

class _MovieBrowserAppState extends State<MovieBrowserApp> {
  ThemeMode themeMode = ThemeMode.dark;

  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      home: WelcomeScreen(toggleTheme: toggleTheme),
      routes: {'favorites': (context) => const FavoritesScreen()},
    );
  }
}
