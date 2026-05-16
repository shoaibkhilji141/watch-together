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
      title: _readString(data, const ['title', 'name', 'movieTitle']) ??
          'Untitled',
      imageUrl: _readString(data, const [
            'imageUrl',
            'image_url',
            'image',
            'poster',
            'posterUrl',
            'thumbnail',
            'thumb',
          ]) ??
          '',
      videoUrl: _readString(data, const [
            'videoUrl',
            'video_url',
            'url',
            'streamUrl',
            'stream_url',
            'mp4',
            'link',
            'src',
            'video',
          ]) ??
          '',
    );
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

  bool get hasPlayableVideo => videoUrl.isNotEmpty;
}
