import 'dart:convert';
import 'package:http/http.dart' as http;
import 'movie_model.dart';

class ApiService {
  // Passed at build time so the key never lives in the source code:
  // flutter run --dart-define-from-file=api_keys.json
  static const apiKey = String.fromEnvironment('OMDB_API_KEY');

  static Future<Map<String, dynamic>> _get(Map<String, String> params) async {
    if (apiKey.isEmpty) {
      throw Exception("OMDb API key missing. See README → Setup.");
    }
    final uri = Uri.https("www.omdbapi.com", "/", {"apikey": apiKey, ...params});
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception("Server error (${res.statusCode})");
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<MovieModel>> searchMovies(String q) async {
    final data = await _get({"s": q});
    if (data["Response"] == "False") return [];
    return (data["Search"] as List).map((e) => MovieModel.fromJson(e)).toList();
  }

  static Future<Map<String, dynamic>> getMovieDetails(String id) {
    return _get({"i": id, "plot": "full"});
  }
}
