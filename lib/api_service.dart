import 'dart:convert';
import 'package:http/http.dart' as http;
import 'movie_model.dart';

class ApiService {
  // Passed at build time so the key never lives in the source code:
  // flutter run --dart-define-from-file=api_keys.json
  static const apiKey = String.fromEnvironment('OMDB_API_KEY');
  static const youtubeApiKey = String.fromEnvironment('YOUTUBE_API_KEY');

  static Future<Map<String, dynamic>> _get(Map<String, String> params) async {
    if (apiKey.isEmpty) {
      throw Exception("OMDb API key missing. See README → Setup.");
    }
    final uri = Uri.https("www.omdbapi.com", "/", {
      "apikey": apiKey,
      ...params,
    });

    final http.Response res;
    try {
      res = await http.get(uri).timeout(const Duration(seconds: 15));
    } catch (_) {
      throw Exception("Can't reach OMDb. Check your internet connection.");
    }
    if (res.statusCode != 200) {
      throw Exception("Server error (${res.statusCode})");
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<MovieModel>> searchMovies(String q, {String? type}) async {
    final data = await _get({"s": q, if (type != null) "type": type});
    if (data["Response"] == "False") return [];
    return (data["Search"] as List).map((e) => MovieModel.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> getMovieDetails(String id) {
    return _get({"i": id, "plot": "full"});
  }

  static Future<String?> findTrailerUrl(String title, String year) async {
    if (youtubeApiKey.isEmpty) return null;
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'type': 'video',
      'maxResults': '1',
      'q': '$title $year official trailer',
      'key': youtubeApiKey,
    });
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      if (items.isEmpty) return null;
      final id = (items.first as Map)['id'] as Map?;
      final videoId = id?['videoId'] as String?;
      return videoId == null
          ? null
          : 'https://www.youtube.com/watch?v=$videoId';
    } catch (_) {
      return null;
    }
  }
}
