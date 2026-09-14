import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movie_browser_app/recommendations.dart';

// No API key in tests, so network lookups fail and only the built-in
// catalog (plus the local genre cache) is exercised.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group("More like this", () {
    const inception = {
      "imdbID": "tt1375666",
      "Title": "Inception",
      "Genre": "Action, Adventure, Sci-Fi",
    };

    test("ranks by shared genres, then IMDb rating", () async {
      final recs = await Recommendations.forMovie(inception);
      final titles = recs.map((m) => m.title).toList();

      expect(titles.length, 10);
      expect(titles, isNot(contains("Inception")));
      // All three share all 3 genres; ordered by rating 8.4, 8.2, 8.1.
      expect(titles.take(3), [
        "Avengers: Endgame",
        "Jurassic Park",
        "Mad Max: Fury Road",
      ]);
    });

    test("leaves out favourites", () async {
      final recs = await Recommendations.forMovie(
        inception,
        exclude: {"tt4154796"}, // Avengers: Endgame
      );
      expect(recs.first.title, "Jurassic Park");
      expect(recs.map((m) => m.imdbID), isNot(contains("tt4154796")));
    });

    test("no genres means no catalog suggestions", () async {
      final recs = await Recommendations.forMovie({
        "imdbID": "tt0000000",
        "Title": "Unknown",
        "Genre": "N/A",
      });
      expect(recs, isEmpty);
    });
  });

  group("Recommended for you", () {
    test("no favourites means no personal picks", () async {
      final result = await Recommendations.forUser([]);
      expect(result.movies, isEmpty);
      expect(result.topGenres, isEmpty);
    });

    test("follows the genres of the user's favourites", () async {
      // The Conjuring + Get Out: both Horror, Mystery, Thriller.
      final result = await Recommendations.forUser(["tt1457767", "tt5052448"]);
      final titles = result.movies.map((m) => m.title).toList();

      expect(result.topGenres, ["Horror", "Mystery"]);
      // Both match two favourite genres; ordered by rating 8.1, 7.3.
      expect(titles.take(2), ["Gone Girl", "Hereditary"]);
      expect(titles, isNot(contains("The Conjuring")));
      expect(titles, isNot(contains("Get Out")));
    });

    test("uses cached genres for movies outside the catalog", () async {
      await Recommendations.rememberGenre("tt9999999", "Animation, Family");
      final result = await Recommendations.forUser(["tt9999999"]);

      expect(result.topGenres, ["Animation", "Family"]);
      expect(result.movies.first.title, "Spirited Away"); // 8.6, both genres
    });
  });
}
