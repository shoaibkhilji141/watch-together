import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/movie.dart';

class MoviesService {
  static const int pageSize = 20;

  final FirebaseFirestore _firestore;

  MoviesService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Movie>> fetchAllMovies() async {
    final snapshot = await _firestore.collection('movies').get();

    final movies = <Movie>[];

    for (final doc in snapshot.docs) {
      _collectMoviesFromDoc(doc.id, doc.data(), movies);
    }

    movies.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    return movies;
  }

  /// Loads a movie by Firestore document id or nested list id (e.g. `docId_0`).
  Future<Movie?> getMovieById(String movieId) async {
    final id = movieId.trim();
    if (id.isEmpty) return null;

    final direct = await _firestore.collection('movies').doc(id).get();
    if (direct.exists) {
      final movie = _movieFromDoc(direct.id, direct.data()!);
      if (movie != null) return movie;
    }

    final underscore = id.lastIndexOf('_');
    if (underscore > 0) {
      final parentId = id.substring(0, underscore);
      final index = int.tryParse(id.substring(underscore + 1));
      if (index != null) {
        final parent = await _firestore.collection('movies').doc(parentId).get();
        if (parent.exists) {
          final nested = _movieFromNestedIndex(parent.id, parent.data()!, index);
          if (nested != null) return nested;
        }
      }
    }

    final all = await fetchAllMovies();
    for (final movie in all) {
      if (movie.id == id) return movie;
    }
    return null;
  }

  void _collectMoviesFromDoc(
    String docId,
    Map<String, dynamic> data,
    List<Movie> out,
  ) {
    if (_isMovieMap(data)) {
      final movie = Movie.fromMap(docId, data);
      if (movie.hasPlayableVideo) out.add(movie);
      return;
    }

    final nested = data['movies'] ?? data['items'];
    if (nested is List) {
      for (var i = 0; i < nested.length; i++) {
        final item = nested[i];
        if (item is Map<String, dynamic> && _isMovieMap(item)) {
          final movie = Movie.fromMap('${docId}_$i', item);
          if (movie.hasPlayableVideo) out.add(movie);
        } else if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          if (_isMovieMap(map)) {
            final movie = Movie.fromMap('${docId}_$i', map);
            if (movie.hasPlayableVideo) out.add(movie);
          }
        }
      }
    }
  }

  Movie? _movieFromDoc(String docId, Map<String, dynamic> data) {
    if (_isMovieMap(data)) {
      final movie = Movie.fromMap(docId, data);
      return movie.hasPlayableVideo ? movie : null;
    }
    return null;
  }

  Movie? _movieFromNestedIndex(
    String docId,
    Map<String, dynamic> data,
    int index,
  ) {
    final nested = data['movies'] ?? data['items'];
    if (nested is! List || index < 0 || index >= nested.length) return null;
    final item = nested[index];
    if (item is Map<String, dynamic> && _isMovieMap(item)) {
      final movie = Movie.fromMap('${docId}_$index', item);
      return movie.hasPlayableVideo ? movie : null;
    }
    if (item is Map) {
      final map = Map<String, dynamic>.from(item);
      if (_isMovieMap(map)) {
        final movie = Movie.fromMap('${docId}_$index', map);
        return movie.hasPlayableVideo ? movie : null;
      }
    }
    return null;
  }

  bool _isMovieMap(Map<String, dynamic> data) {
    final title = _readString(data, const ['title', 'name', 'movieTitle']);
    final videoUrl = _readString(data, const [
      'videoUrl',
      'video_url',
      'url',
      'streamUrl',
      'stream_url',
      'mp4',
      'link',
      'src',
      'video',
    ]);
    return title != null && videoUrl != null;
  }

  static String? _readString(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
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
