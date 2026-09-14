import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'movie_model.dart';
import 'movie_details_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const HomeScreen({super.key, required this.toggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String user = "";
  List<MovieModel> movies = [];
  List<String> favorites = [];
  bool loading = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    user = prefs.getString("currentUser") ?? "";
    favorites = prefs.getStringList("${user}_favorites") ?? [];
    setState(() {});
  }

  String getUserInitials() {
    if (user.isEmpty) return "?";
    if (user.length == 1) return user[0].toUpperCase();
    return user.substring(0, 2).toUpperCase();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("currentUser");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WelcomeScreen(toggleTheme: widget.toggleTheme),
      ),
    );
  }

  Future<void> searchMovies(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList("${user}_history") ?? [];

    if (!history.contains(query)) {
      history.insert(0, query);
      prefs.setStringList("${user}_history", history);
    }

    setState(() => loading = true);
    movies = await ApiService.searchMovies(query);
    setState(() => loading = false);
  }

  Future<void> toggleFavorite(String imdbID) async {
    final prefs = await SharedPreferences.getInstance();

    if (favorites.contains(imdbID)) {
      favorites.remove(imdbID);
    } else {
      favorites.add(imdbID);
    }

    await prefs.setStringList("${user}_favorites", favorites);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text("Movie Browser"),
        actions: [
          PopupMenuButton<int>(
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Row(
                  children: const [
                    Icon(Icons.favorite, size: 20),
                    SizedBox(width: 10),
                    Text("Favourites"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 2,
                child: Row(
                  children: const [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 10),
                    Text("History"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 3,
                child: Row(
                  children: const [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 10),
                    Text("Logout"),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
              } else if (value == 2) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );

                if (result != null) {
                  searchController.text = result;
                  searchMovies(result);
                }
              } else if (value == 3) {
                logout();
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 15),
              child: CircleAvatar(
                backgroundColor: Colors.blueAccent,
                child: Text(
                  getUserInitials(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.brightness_6),
            tooltip: "Theme",
            onPressed: widget.toggleTheme,
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ----------------------- SEARCH BOX ----------------------------
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: "Search movies...",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        border: InputBorder.none,
                      ),
                      onSubmitted: searchMovies,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, size: 28),
                    onPressed: () => searchMovies(searchController.text),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (loading) const CircularProgressIndicator(),

            Expanded(
              child: movies.isEmpty
                  ? Center(
                      child: Text(
                        "Search movies to see results",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(
                            0.7,
                          ),
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: movies.length,
                      itemBuilder: (context, i) {
                        final movie = movies[i];
                        final isFav = favorites.contains(movie.imdbID);

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                movie.poster,
                                width: 52,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.movie),
                              ),
                            ),
                            title: Text(movie.title),
                            trailing: IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.grey,
                              ),
                              onPressed: () => toggleFavorite(movie.imdbID),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MovieDetailsScreen(imdbID: movie.imdbID),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
