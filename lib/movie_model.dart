  class MovieModel {
  String title;
  String year;
  String poster;
  String imdbID;

  MovieModel({
    required this.title,
    required this.year,
    required this.poster,
    required this.imdbID,
  });

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    return MovieModel(
      title: json['Title'],
      year: json['Year'],
      poster: json['Poster'],
      imdbID: json['imdbID'],
    );
  }
}
