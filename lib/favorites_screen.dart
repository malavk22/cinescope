import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'movie_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Map<String, dynamic>> favoriteMovies = [];
  String currentUser = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    currentUser = prefs.getString("currentUser") ?? "";

    final favIds =
        prefs.getStringList("${currentUser}_favorites") ?? [];

    List<Map<String, dynamic>> loadedMovies = [];

    for (String id in favIds) {
      final movie = await ApiService.getMovieDetails(id);
      loadedMovies.add(movie);
    }

    setState(() {
      favoriteMovies = loadedMovies;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favourites"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteMovies.isEmpty
              ? const Center(
                  child: Text("No favourite movies yet ❤️"),
                )
              : ListView.builder(
                  itemCount: favoriteMovies.length,
                  itemBuilder: (context, index) {
                    final movie = favoriteMovies[index];

                    return Card(
                      child: ListTile(
                        leading: Image.network(
                          movie['Poster'],
                          width: 50,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.movie),
                        ),
                        title: Text(movie['Title']),
                        subtitle: Text(movie['Year']),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovieDetailsScreen(
                                imdbID: movie['imdbID'],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
