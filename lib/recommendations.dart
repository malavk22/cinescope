import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Personal picks: each genre is weighted by how many of the user's
  // favourites have it, and catalog movies are scored by those weights.
  static Future<({List<MovieModel> movies, List<String> topGenres})> forUser(
    List<String> favoriteIds,
  ) async {
    final genreOf = await _genresFor(favoriteIds);
    final weights = <String, int>{};
    for (final g in genreOf.values.expand(_genres)) {
      weights[g] = (weights[g] ?? 0) + 1;
    }
    if (weights.isEmpty) return (movies: <MovieModel>[], topGenres: <String>[]);

    final favs = favoriteIds.toSet();
    final ranked = (await _loadCatalog())
        .where((m) => !favs.contains(m["imdbID"]))
        .map((m) => (
              movie: m,
              score: _genres(m["Genre"]).fold(0, (s, g) => s + (weights[g] ?? 0)),
            ))
        .where((e) => e.score > 0)
        .toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return _rating(b.movie).compareTo(_rating(a.movie));
      });

    final topGenres = weights.keys.toList()
      ..sort((a, b) {
        final byCount = weights[b]!.compareTo(weights[a]!);
        return byCount != 0 ? byCount : a.compareTo(b);
      });

    return (
      movies: ranked.take(10).map((e) => MovieModel.fromJson(e.movie)).toList(),
      topGenres: topGenres.take(2).toList(),
    );
  }

  // Cache a movie's genres so personal picks need no extra requests.
  static Future<void> rememberGenre(String id, String? genre) async {
    if (genre == null || genre == "N/A") return;
    final prefs = await SharedPreferences.getInstance();
    final cache = _decodeCache(prefs.getString("genreCache"));
    cache[id] = genre;
    await prefs.setString("genreCache", jsonEncode(cache));
  }

  // Genres for each favourite: from the catalog, the cache, or (only for
  // movies never seen before) one details request each, fetched in parallel.
  static Future<Map<String, String>> _genresFor(List<String> ids) async {
    final catalogGenres = {
      for (final m in await _loadCatalog()) m["imdbID"] as String: m["Genre"] as String,
    };
    final prefs = await SharedPreferences.getInstance();
    final cache = _decodeCache(prefs.getString("genreCache"));

    final missing = ids
        .where((id) => !catalogGenres.containsKey(id) && !cache.containsKey(id))
        .toList();
    if (missing.isNotEmpty) {
      try {
        final details = await Future.wait(missing.map(ApiService.getMovieDetails));
        for (final d in details) {
          if (d["Response"] == "True") cache[d["imdbID"]] = d["Genre"];
        }
        await prefs.setString("genreCache", jsonEncode(cache));
      } catch (_) {
        // Offline: use the genres we already know.
      }
    }

    return {
      for (final id in ids)
        if ((catalogGenres[id] ?? cache[id]) != null)
          id: (catalogGenres[id] ?? cache[id])!,
    };
  }

  static Map<String, String> _decodeCache(String? json) =>
      Map<String, String>.from(jsonDecode(json ?? "{}"));

  static Set<String> _genres(String? genre) => (genre ?? "")
      .split(",")
      .map((g) => g.trim())
      .where((g) => g.isNotEmpty && g != "N/A")
      .toSet();

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
