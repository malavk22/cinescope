import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'movie_model.dart';
import 'poster_card.dart';
import 'recommendations.dart';

class MovieDetailsScreen extends StatefulWidget {
  final String imdbID;

  const MovieDetailsScreen({super.key, required this.imdbID});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  Map<String, dynamic>? movie;
  List<MovieModel> similar = [];
  String? error;

  @override
  void initState() {
    super.initState();
    loadMovieDetails();
  }

  Future<void> loadMovieDetails() async {
    try {
      final data = await ApiService.getMovieDetails(widget.imdbID);
      if (data["Response"] == "False") {
        throw Exception(data["Error"] ?? "Movie not found");
      }
      if (!mounted) return;
      setState(() => movie = data);

      // Suggest movies the user hasn't already favourited.
      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString("currentUser") ?? "";
      final favorites = prefs.getStringList("${user}_favorites") ?? [];
      final recs = await Recommendations.forMovie(
        data,
        exclude: favorites.toSet(),
      );
      if (mounted) setState(() => similar = recs);
    } catch (e) {
      if (mounted && movie == null) {
        setState(() => error = "$e".replaceFirst("Exception: ", ""));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off, size: 60),
                const SizedBox(height: 12),
                Text(error!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() => error = null);
                    loadMovieDetails();
                  },
                  child: const Text("Try again"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (movie == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(movie!['Title']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Centered Poster
            Center(
              child: Image.network(
                movie!['Poster'],
                height: 320,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.movie, size: 100),
              ),
            ),

            const SizedBox(height: 20),

            // IMDb Rating
            Center(
              child: Text(
                "⭐ IMDb Rating: ${movie!['imdbRating']}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Movie Info Row
            Wrap(
              spacing: 20,
              runSpacing: 8,
              children: [
                Text("Genre: ${movie!['Genre']}"),
                Text("Runtime: ${movie!['Runtime']}"),
                Text("Language: ${movie!['Language']}"),
              ],
            ),

            const SizedBox(height: 16),

            // Director & Actors
            Text(
              "Director: ${movie!['Director']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text(
              "Actors: ${movie!['Actors']}",
            ),

            const SizedBox(height: 20),

            // Plot Summary
            const Text(
              "Plot Summary",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              movie!['Plot'],
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 16),
            ),

            // Recommendations
            if (similar.isNotEmpty) ...[
              const SizedBox(height: 28),
              const Text(
                "More like this",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: similar.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => SizedBox(
                    width: 110,
                    child: PosterCard(movie: similar[i]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
