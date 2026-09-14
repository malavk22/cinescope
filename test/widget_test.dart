import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:movie_browser_app/auth.dart';
import 'package:movie_browser_app/home_screen.dart';
import 'package:movie_browser_app/main.dart';
import 'package:movie_browser_app/movie_details_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Finder field(String label) => find.widgetWithText(TextField, label);
  Finder button(String label) => find.widgetWithText(ElevatedButton, label);

  testWidgets("register validates input, then the new account can log in", (
    tester,
  ) async {
    await tester.pumpWidget(const MovieBrowserApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text("New user? Register"));
    await tester.pumpAndSettle();
    expect(find.text("Join CineScope"), findsOneWidget);

    // Empty form shows validation errors.
    await tester.tap(button("Create account"));
    await tester.pumpAndSettle();
    expect(find.text("Username must be at least 3 characters"), findsOneWidget);
    expect(find.text("Password must be at least 6 characters"), findsOneWidget);

    // Mismatched confirmation is rejected.
    await tester.enterText(field("Username"), "demo_user");
    await tester.enterText(field("Password"), "secret123");
    await tester.enterText(field("Confirm password"), "secret12");
    await tester.tap(button("Create account"));
    await tester.pumpAndSettle();
    expect(find.text("Passwords don't match"), findsOneWidget);

    await tester.enterText(field("Confirm password"), "secret123");
    await tester.tap(button("Create account"));
    await tester.pumpAndSettle();

    // Back on the login screen; the password is stored hashed.
    expect(find.text("Account created! Log in to continue."), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString("user_demo_user"),
      hashPassword("demo_user", "secret123"),
    );

    await tester.enterText(field("Password"), "secret123");
    await tester.tap(button("Login"));
    await tester.pumpAndSettle();
    expect(find.text("Search movies..."), findsOneWidget);
    expect(find.text("Popular picks"), findsOneWidget);
    expect(find.text("The Shawshank Redemption"), findsOneWidget);
    // A new user has no favourites yet, so no personal picks.
    expect(find.text("Recommended for you"), findsNothing);

    // Home button on another screen returns to the home screen.
    await tester.tap(find.text("DE")); // avatar with the user's initials
    await tester.pumpAndSettle();
    await tester.tap(find.text("Favourites"));
    await tester.pumpAndSettle();
    expect(find.text("My Favourites"), findsOneWidget);

    await tester.tap(find.byTooltip("Home"));
    await tester.pumpAndSettle();
    expect(find.text("My Favourites"), findsNothing);
    expect(find.text("Popular picks"), findsOneWidget);
  });

  testWidgets("wrong password is rejected", (tester) async {
    SharedPreferences.setMockInitialValues({
      "user_demo_user": hashPassword("demo_user", "secret123"),
    });
    await tester.pumpWidget(const MovieBrowserApp());
    await tester.pumpAndSettle();

    await tester.enterText(field("Username"), "demo_user");
    await tester.enterText(field("Password"), "wrongpass");
    await tester.tap(button("Login"));
    await tester.pumpAndSettle();

    expect(find.text("Invalid username or password"), findsOneWidget);
    expect(find.text("Search movies..."), findsNothing);
  });

  testWidgets("home shows 'Recommended for you' based on favourites", (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      "currentUser": "demo_user",
      // The Conjuring + Get Out
      "demo_user_favorites": ["tt1457767", "tt5052448"],
    });
    await tester.pumpWidget(MaterialApp(home: HomeScreen(toggleTheme: () {})));
    await tester.pumpAndSettle();

    expect(find.text("Recommended for you"), findsOneWidget);
    expect(find.text("Because you like Horror & Mystery"), findsOneWidget);
    expect(find.text("Gone Girl"), findsWidgets);
  });

  testWidgets("movie details shows 'Try again' instead of spinning forever", (
    tester,
  ) async {
    // Tests run without an API key, so the request fails immediately.
    await tester.pumpWidget(
      const MaterialApp(home: MovieDetailsScreen(imdbID: "tt1375666")),
    );
    await tester.pumpAndSettle();

    expect(find.text("Try again"), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
