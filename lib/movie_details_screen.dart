import 'package:flutter/material.dart';
import 'api_service.dart';

class MovieDetailsScreen extends StatefulWidget {
  final String imdbID;

  const MovieDetailsScreen({super.key, required this.imdbID});

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  Map<String, dynamic>? movie;

  @override
  void initState() {
    super.initState();
    loadMovieDetails();
  }

  void loadMovieDetails() async {
    movie = await ApiService.getMovieDetails(widget.imdbID);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
  }
}
