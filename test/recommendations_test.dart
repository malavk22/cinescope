import 'package:flutter_test/flutter_test.dart';
import 'package:movie_browser_app/recommendations.dart';

// No API key in tests, so the related-title search fails and only the
// built-in catalog ranking is exercised.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
}
