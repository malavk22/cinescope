# CineScope 🎬

A Flutter movie browser: search any movie, see its details, save favourites,
and get **"More like this"** recommendations. Powered by the
[OMDb API](https://www.omdbapi.com/).

## Features

- **Accounts:** register and log in. Each user has their own favourites and
  history. Passwords are stored as a salted SHA-256 hash, never as plain text.
- **Recommended for you:** personal picks on the home screen, based on the
  genres of your favourites ("Because you like Horror & Mystery").
- **Popular picks:** a poster grid of top-rated movies on the home screen, so
  there's something to explore before you search.
- **Search:** find movies and series by title, with posters.
- **Movie details:** poster, genre, runtime, director, cast, and full plot.
- **Ratings & awards:** IMDb, Rotten Tomatoes, and Metacritic scores side by
  side, plus awards, box office, age rating, and release date.
- **More like this:** recommendations on every movie page (see below).
- **Favourites:** tap the heart in search results or on a movie's page.
  Favourites load in parallel.
- **Home button:** tap "CineScope" or the 🏠 icon to get back home from anywhere.
- **Search history:** tap a past search to run it again.
- **Light / dark theme:** the choice is remembered between launches.
- **Friendly errors:** clear messages and a "Try again" button when offline.

### How recommendations work

OMDb has no "similar movies" endpoint, so CineScope combines two sources:

1. **Related titles.** It searches the main part of the title to find sequels
   and the rest of the franchise (e.g. *Toy Story* → *Toy Story 2, 3, 4*).
2. **Genre match.** It ranks a built-in catalog of 56 popular movies
   (`assets/catalog.json`, including Indian cinema) by how many genres they
   share with the current movie, then by IMDb rating.

Movies already in your favourites are left out, so suggestions are always new.
The catalog part works even when the related-title search fails.

## Setup

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (3.38 or newer).
2. Get a free OMDb API key at <https://www.omdbapi.com/apikey.aspx>.
3. Copy `api_keys.example.json` to `api_keys.json` and put your key in it:

   ```json
   { "OMDB_API_KEY": "your-key" }
   ```

   `api_keys.json` is git-ignored, so your key is never committed.

## Run

```bash
flutter pub get
flutter run -d chrome --dart-define-from-file=api_keys.json
```

Use `-d windows` for desktop, or connect an Android phone. In VS Code, just
press **F5**: the included launch config passes the key for you.

For a smoother experience on slower machines, add `--release`.

## Tests

```bash
flutter test
```

Covers register validation, password hashing, login, the offline error state,
and recommendation ranking.

## Project structure

```
lib/
  main.dart                 app entry, theme (remembered)
  welcome_screen.dart       login
  register_screen.dart      sign-up with validation
  auth.dart                 password hashing
  home_screen.dart          search, results, popular picks
  movie_details_screen.dart details + "More like this"
  poster_card.dart          poster tile used by both grids
  recommendations.dart      recommendation logic
  favorites_screen.dart     saved movies
  history_screen.dart       past searches
  api_service.dart          OMDb API client
  movie_model.dart          movie data model
assets/
  catalog.json              popular movies used for recommendations
test/
  widget_test.dart          register / login / error-state tests
  recommendations_test.dart recommendation ranking tests
```

## Tech

Flutter · Dart · `http` · `shared_preferences` · `crypto` · OMDb API
