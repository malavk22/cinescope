import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'home_button.dart';
import 'movie_model.dart';
import 'poster_card.dart';
import 'ratings_panel.dart';
import 'recommendations.dart';
import 'user_movie_data.dart';

class MovieDetailsScreen extends StatefulWidget {
  final String imdbID;

  const MovieDetailsScreen({super.key, required this.imdbID});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  Map<String, dynamic>? movie;
  List<MovieModel> similar = [];
  bool isFavorite = false;
  String? watchStatus;
  int personalRating = 0;
  final TextEditingController noteController = TextEditingController();
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
      Recommendations.rememberGenre(widget.imdbID, data["Genre"]);

      final prefs = await SharedPreferences.getInstance();
      final user = prefs.getString("currentUser") ?? "";
      final favorites = prefs.getStringList("${user}_favorites") ?? [];
      final watchlist = await UserMovieData.watchlist();
      final review = await UserMovieData.reviewFor(widget.imdbID);
      if (!mounted) return;
      setState(() {
        movie = data;
        isFavorite = favorites.contains(widget.imdbID);
        watchStatus = watchlist[widget.imdbID];
        personalRating = review['rating'] as int? ?? 0;
        noteController.text = review['note'] as String? ?? '';
      });

      // Suggest movies the user hasn't already favourited.
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
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  Future<void> updateWatchStatus(String? status) async {
    await UserMovieData.setWatchStatus(widget.imdbID, status);
    if (!mounted) return;
    setState(() => watchStatus = status);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status == null ? 'Removed from watchlist' : 'Added to $status',
        ),
      ),
    );
  }

  Future<void> saveReview() async {
    await UserMovieData.saveReview(
      widget.imdbID,
      rating: personalRating,
      note: noteController.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your rating and note were saved')),
    );
  }

  Future<void> watchTrailer() async {
    final title = movie!['Title'] as String? ?? '';
    final year = movie!['Year'] as String? ?? '';
    final trailer = await ApiService.findTrailerUrl(title, year);
    final url =
        trailer ??
        'https://www.youtube.com/results?search_query=${Uri.encodeComponent('$title $year official trailer')}';
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open YouTube.')));
    }
  }

  Future<void> toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final user = prefs.getString("currentUser") ?? "";
    final favorites = prefs.getStringList("${user}_favorites") ?? [];

    if (isFavorite) {
      favorites.remove(widget.imdbID);
    } else {
      favorites.add(widget.imdbID);
    }
    await prefs.setStringList("${user}_favorites", favorites);

    if (!mounted) return;
    setState(() => isFavorite = !isFavorite);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isFavorite ? "Added to favourites" : "Removed from favourites",
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        appBar: AppBar(actions: const [HomeButton()]),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(movie!['Title']),
        actions: [
          IconButton(
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.red : null,
            ),
            tooltip: isFavorite
                ? "Remove from favourites"
                : "Add to favourites",
            onPressed: toggleFavorite,
          ),
          const HomeButton(),
        ],
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

            // Ratings & awards
            RatingsPanel(movie: movie!),

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

            OutlinedButton.icon(
              onPressed: watchTrailer,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Watch trailer'),
            ),

            const SizedBox(height: 20),

            const Text(
              'My Watchlist',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: watchStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Status',
              ),
              hint: const Text('Add to watchlist'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Remove from watchlist'),
                ),
                ...UserMovieData.statuses.map(
                  (status) =>
                      DropdownMenuItem(value: status, child: Text(status)),
                ),
              ],
              onChanged: updateWatchStatus,
            ),

            const SizedBox(height: 20),

            const Text(
              'My Rating & Note',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (index) {
                final selected = index < personalRating;
                return IconButton(
                  tooltip: '${index + 1} star${index == 0 ? '' : 's'}',
                  icon: Icon(selected ? Icons.star : Icons.star_border),
                  color: Colors.amber,
                  onPressed: () => setState(() => personalRating = index + 1),
                );
              }),
            ),
            TextField(
              controller: noteController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Write a private note about this movie',
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: saveReview,
                icon: const Icon(Icons.save),
                label: const Text('Save rating & note'),
              ),
            ),

            const SizedBox(height: 20),

            // Director & Actors
            Text(
              "Director: ${movie!['Director']}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 6),

            Text("Actors: ${movie!['Actors']}"),

            const SizedBox(height: 20),

            // Plot Summary
            const Text(
              "Plot Summary",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
