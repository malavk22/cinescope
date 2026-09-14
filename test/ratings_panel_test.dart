import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movie_browser_app/ratings_panel.dart';

// Fields copied from a real OMDb response for Inception (tt1375666).
const inception = {
  "Ratings": [
    {"Source": "Internet Movie Database", "Value": "8.8/10"},
    {"Source": "Rotten Tomatoes", "Value": "86%"},
    {"Source": "Metacritic", "Value": "74/100"},
  ],
  "imdbVotes": "2,811,614",
  "Awards": "Won 4 Oscars. 160 wins & 220 nominations total",
  "BoxOffice": "\$292,587,330",
  "Rated": "PG-13",
  "Released": "16 Jul 2010",
};

Future<void> pumpPanel(WidgetTester tester, Map<String, dynamic> movie) =>
    tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RatingsPanel(movie: movie))),
    );

String allText(WidgetTester tester) => tester
    .widgetList<RichText>(find.byType(RichText))
    .map((t) => t.text.toPlainText())
    .join("\n");

void main() {
  testWidgets("shows all three scores and the facts", (tester) async {
    await pumpPanel(tester, inception);

    for (final text in [
      "8.8/10", "IMDb", "2,811,614 votes",
      "86%", "Rotten Tomatoes",
      "74/100", "Metacritic",
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }

    final text = allText(tester);
    expect(text, contains("Awards: Won 4 Oscars. 160 wins & 220 nominations total"));
    expect(text, contains("Box office: \$292,587,330"));
    expect(text, contains("Rated: PG-13"));
    expect(text, contains("Released: 16 Jul 2010"));
  });

  testWidgets("hides anything OMDb reports as N/A", (tester) async {
    await pumpPanel(tester, {
      "Ratings": [
        {"Source": "Internet Movie Database", "Value": "6.1/10"},
      ],
      "imdbVotes": "N/A",
      "Awards": "N/A",
      "BoxOffice": "N/A",
      "Rated": "Not Rated",
      "Released": "N/A",
    });

    expect(find.text("6.1/10"), findsOneWidget);
    expect(find.text("Rotten Tomatoes"), findsNothing);
    expect(find.textContaining("votes"), findsNothing);

    final text = allText(tester);
    expect(text, contains("Rated: Not Rated"));
    expect(text, isNot(contains("Awards")));
    expect(text, isNot(contains("Box office")));
    expect(text, isNot(contains("Released")));
  });

  testWidgets("renders nothing when there is no rating data", (tester) async {
    await pumpPanel(tester, {});
    expect(find.byType(Card), findsNothing);
    expect(find.byType(Wrap), findsNothing);
  });
}
