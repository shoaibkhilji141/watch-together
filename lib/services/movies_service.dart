import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/movie.dart';

class MoviesService {
  static const int pageSize = 20;

  Future<List<Movie>> fetchAllMovies() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('movies').get();

    final movies = <Movie>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (_isMovieMap(data)) {
        movies.add(Movie.fromMap(doc.id, data));
        continue;
      }

      final nested = data['movies'] ?? data['items'];
      if (nested is List) {
        for (var i = 0; i < nested.length; i++) {
          final item = nested[i];
          if (item is Map<String, dynamic> && _isMovieMap(item)) {
            movies.add(Movie.fromMap('${doc.id}_$i', item));
          } else if (item is Map && _isMovieMap(Map<String, dynamic>.from(item))) {
            movies.add(Movie.fromMap('${doc.id}_$i', Map<String, dynamic>.from(item)));
          }
        }
      }
    }

    movies.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return movies;
  }

  bool _isMovieMap(Map<String, dynamic> data) {
    final title = data['title'] as String?;
    final videoUrl = data['videoUrl'] as String?;
    return title != null &&
        title.trim().isNotEmpty &&
        videoUrl != null &&
        videoUrl.trim().isNotEmpty;
  }

  static List<Movie> filterByTitle(List<Movie> movies, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return movies;
    return movies
        .where((m) => m.title.toLowerCase().contains(q))
        .toList();
  }

  static List<Movie> pageSlice(List<Movie> movies, int pageIndex) {
    final start = pageIndex * pageSize;
    if (start >= movies.length) return [];
    final end = (start + pageSize).clamp(0, movies.length);
    return movies.sublist(start, end);
  }

  static int totalPages(int itemCount) {
    if (itemCount == 0) return 1;
    return (itemCount / pageSize).ceil();
  }
}
