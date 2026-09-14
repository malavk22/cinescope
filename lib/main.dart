import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  @override
  void initState() {
    super.initState();
    loadTheme();
  }

  // Remember the light/dark choice between launches.
  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool("darkMode") ?? true;
    setState(() => themeMode = dark ? ThemeMode.dark : ThemeMode.light);
  }

  void toggleTheme() {
    setState(() {
      themeMode = themeMode == ThemeMode.dark
          ? ThemeMode.light
          : ThemeMode.dark;
    });
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool("darkMode", themeMode == ThemeMode.dark),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "CineScope",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: themeMode,
      // Let horizontal lists be dragged with a mouse on web/desktop too.
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
        },
      ),
      home: WelcomeScreen(toggleTheme: toggleTheme),
      routes: {'favorites': (context) => const FavoritesScreen()},
    );
  }
}
