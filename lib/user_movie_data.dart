import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UserMovieData {
  static const statuses = ['Want to watch', 'Watching', 'Watched'];

  static Future<String> _user() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currentUser') ?? '';
  }

  static Future<Map<String, String>> watchlist() async {
    final prefs = await SharedPreferences.getInstance();
    final user = await _user();
    final raw = prefs.getString('${user}_watchlist');
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw) as Map);
  }

  static Future<void> setWatchStatus(String imdbId, String? status) async {
    final prefs = await SharedPreferences.getInstance();
    final user = await _user();
    final values = await watchlist();
    if (status == null) {
      values.remove(imdbId);
    } else {
      values[imdbId] = status;
    }
    await prefs.setString('${user}_watchlist', jsonEncode(values));
  }

  static Future<Map<String, dynamic>> reviewFor(String imdbId) async {
    final prefs = await SharedPreferences.getInstance();
    final user = await _user();
    final raw = prefs.getString('${user}_reviews');
    if (raw == null) return {};
    final reviews = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    return Map<String, dynamic>.from(reviews[imdbId] as Map? ?? {});
  }

  static Future<void> saveReview(
    String imdbId, {
    required int rating,
    required String note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final user = await _user();
    final raw = prefs.getString('${user}_reviews');
    final reviews = raw == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    reviews[imdbId] = {'rating': rating, 'note': note.trim()};
    await prefs.setString('${user}_reviews', jsonEncode(reviews));
  }
}
