import 'package:flutter/material.dart';

import 'api_service.dart';
import 'home_button.dart';
import 'movie_details_screen.dart';
import 'user_movie_data.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  Map<String, String> statuses = {};
  Map<String, Map<String, dynamic>> movies = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadWatchlist();
  }

  Future<void> loadWatchlist() async {
    final values = await UserMovieData.watchlist();
    final details = await Future.wait(
      values.keys.map((id) async {
        try {
          return MapEntry(id, await ApiService.getMovieDetails(id));
        } catch (_) {
          return null;
        }
      }),
    );
    if (!mounted) return;
    setState(() {
      statuses = values;
      movies = {
        for (final entry
            in details.whereType<MapEntry<String, Map<String, dynamic>>>())
          if (entry.value['Response'] == 'True') entry.key: entry.value,
      };
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: UserMovieData.statuses.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Watchlist'),
          actions: const [HomeButton()],
          bottom: TabBar(
            tabs: UserMovieData.statuses
                .map((status) => Tab(text: status))
                .toList(),
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: UserMovieData.statuses.map(_buildStatusList).toList(),
              ),
      ),
    );
  }

  Widget _buildStatusList(String status) {
    final ids = statuses.entries
        .where((entry) => entry.value == status)
        .map((entry) => entry.key)
        .where(movies.containsKey)
        .toList();
    if (ids.isEmpty) {
      return Center(child: Text('No movies marked "$status" yet.'));
    }
    return ListView.builder(
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final movie = movies[ids[index]]!;
        return ListTile(
          leading: Image.network(
            movie['Poster'] ?? '',
            width: 48,
            errorBuilder: (_, __, ___) => const Icon(Icons.movie),
          ),
          title: Text(movie['Title'] ?? ''),
          subtitle: Text(movie['Year'] ?? ''),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MovieDetailsScreen(imdbID: movie['imdbID']),
              ),
            );
            loadWatchlist();
          },
        );
      },
    );
  }
}
