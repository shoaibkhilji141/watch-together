class Movie {
  final String id;
  final String title;
  final String imageUrl;
  final String videoUrl;

  const Movie({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.videoUrl,
  });

  factory Movie.fromMap(String id, Map<String, dynamic> data) {
    return Movie(
      id: id,
      title: (data['title'] as String?)?.trim() ?? 'Untitled',
      imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
      videoUrl: (data['videoUrl'] as String?)?.trim() ?? '',
    );
  }
}
