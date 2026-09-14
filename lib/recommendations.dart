import 'dart:convert';
import 'package:flutter/services.dart';
import 'api_service.dart';
import 'movie_model.dart';

// OMDb has no "similar movies" endpoint, so recommendations combine:
//  1. related titles (sequels / same franchise) found by searching the title
//  2. a built-in catalog of popular movies ranked by shared genres, then rating
class Recommendations {
  static List<Map<String, dynamic>>? _catalog;

  static Future<List<Map<String, dynamic>>> _loadCatalog() async =>
      _catalog ??= List<Map<String, dynamic>>.from(
        jsonDecode(await rootBundle.loadString("assets/catalog.json")),
      );

  // Highest-rated catalog movies, shown on the home screen before a search.
  static Future<List<MovieModel>> popular() async {
    final all = [...await _loadCatalog()]
      ..sort((a, b) => _rating(b).compareTo(_rating(a)));
    return all.map(MovieModel.fromJson).toList();
  }

  static Future<List<MovieModel>> forMovie(
    Map<String, dynamic> movie, {
    Set<String> exclude = const {},
  }) async {
    final catalog = await _loadCatalog();
    final skip = {movie["imdbID"] as String, ...exclude};
    final genres = _genres(movie["Genre"]);

    var related = <MovieModel>[];
    final query = _franchiseQuery(movie["Title"] ?? "");
    if (query.length >= 4) {
      try {
        related = (await ApiService.searchMovies(query, type: "movie"))
            .where((m) => !skip.contains(m.imdbID))
            .take(3)
            .toList();
      } catch (_) {
        // Offline: fall back to the catalog alone.
      }
    }
    skip.addAll(related.map((m) => m.imdbID));

    final ranked = catalog
        .where((m) => !skip.contains(m["imdbID"]))
        .map((m) => (movie: m, shared: _genres(m["Genre"]).intersection(genres).length))
        .where((e) => e.shared > 0)
        .toList()
      ..sort((a, b) {
        final byGenre = b.shared.compareTo(a.shared);
        if (byGenre != 0) return byGenre;
        return _rating(b.movie).compareTo(_rating(a.movie));
      });

    return [
      ...related,
      ...ranked.take(10 - related.length).map((e) => MovieModel.fromJson(e.movie)),
    ];
  }

  static Set<String> _genres(String? genre) =>
      (genre ?? "").split(",").map((g) => g.trim()).where((g) => g.isNotEmpty).toSet();

  static double _rating(Map<String, dynamic> m) =>
      double.tryParse(m["imdbRating"] ?? "") ?? 0;

  // "Avengers: Endgame" -> "Avengers", "The Dark Knight" -> "Dark Knight",
  // "Toy Story 3" -> "Toy Story"
  static String _franchiseQuery(String title) => title
      .split(":")
      .first
      .replaceFirst(RegExp(r"^(the|a|an)\s+", caseSensitive: false), "")
      .replaceFirst(RegExp(r"\s+\d+$"), "")
      .trim();
}
