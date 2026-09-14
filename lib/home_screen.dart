import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'movie_model.dart';
import 'movie_details_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'poster_card.dart';
import 'recommendations.dart';
import 'welcome_screen.dart';
import 'watchlist_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const HomeScreen({super.key, required this.toggleTheme});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String user = "";
  List<MovieModel> movies = [];
  List<MovieModel> popular = [];
  List<MovieModel> recommended = [];
  List<String> topGenres = [];
  List<String> favorites = [];
  bool loading = false;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadUser();
    loadPopular();
  }

  // Also runs when coming back from another screen, because favourites
  // may have changed there.
  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    user = prefs.getString("currentUser") ?? "";
    favorites = prefs.getStringList("${user}_favorites") ?? [];
    if (!mounted) return;
    setState(() {});
    loadRecommended();
  }

  Future<void> loadPopular() async {
    final list = await Recommendations.popular();
    if (mounted) setState(() => popular = list);
  }

  Future<void> loadRecommended() async {
    final result = await Recommendations.forUser(favorites);
    if (!mounted) return;
    setState(() {
      recommended = result.movies;
      topGenres = result.topGenres;
    });
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
    try {
      movies = await ApiService.searchMovies(query);
      if (movies.isEmpty) showMessage('No movies found for "$query"');
    } catch (e) {
      showMessage("$e".replaceFirst("Exception: ", ""));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
    loadRecommended();
  }

  Widget sectionTitle(String title, [String? subtitle]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        // Tapping the title clears the search and shows Popular picks again.
        title: Tooltip(
          message: "Home",
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              searchController.clear();
              setState(() => movies = []);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text("CineScope"),
            ),
          ),
        ),
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
                    Icon(Icons.bookmark),
                    SizedBox(width: 10),
                    Text("Watchlist"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 3,
                child: Row(
                  children: const [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 10),
                    Text("History"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 4,
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
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                );
                loadUser();
              } else if (value == 2) {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WatchlistScreen()),
                );
              } else if (value == 3) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );

                if (result != null) {
                  searchController.text = result;
                  searchMovies(result);
                }
              } else if (value == 4) {
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
                  ? popular.isEmpty
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
                        : CustomScrollView(
                            slivers: [
                              // ---------------- RECOMMENDED FOR YOU ----------------
                              if (recommended.isNotEmpty) ...[
                                SliverToBoxAdapter(
                                  child: sectionTitle(
                                    "Recommended for you",
                                    "Because you like ${topGenres.join(" & ")}",
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: SizedBox(
                                    height: 210,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: recommended.length,
                                      separatorBuilder: (_, _) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (context, i) => SizedBox(
                                        width: 110,
                                        child: PosterCard(
                                          movie: recommended[i],
                                          onReturn: loadUser,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SliverToBoxAdapter(
                                  child: SizedBox(height: 24),
                                ),
                              ],

                              // ------------------- POPULAR PICKS -------------------
                              SliverToBoxAdapter(
                                child: sectionTitle("Popular picks"),
                              ),
                              SliverGrid.builder(
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                      maxCrossAxisExtent: 140,
                                      childAspectRatio: 0.52,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 16,
                                    ),
                                itemCount: popular.length,
                                itemBuilder: (context, i) => PosterCard(
                                  movie: popular[i],
                                  onReturn: loadUser,
                                ),
                              ),
                            ],
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
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MovieDetailsScreen(imdbID: movie.imdbID),
                                ),
                              );
                              loadUser();
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
