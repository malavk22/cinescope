import 'package:flutter/material.dart';
import 'movie_details_screen.dart';
import 'movie_model.dart';

// Poster + title tile used by "Popular picks", "Recommended for you" and
// "More like this". [onReturn] runs when the user comes back from details.
class PosterCard extends StatelessWidget {
  final MovieModel movie;
  final VoidCallback? onReturn;
  const PosterCard({super.key, required this.movie, this.onReturn});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MovieDetailsScreen(imdbID: movie.imdbID),
          ),
        );
        onReturn?.call();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                movie.poster,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const Center(child: Icon(Icons.movie, size: 40)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: Text(
              movie.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
