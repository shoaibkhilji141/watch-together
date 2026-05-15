String? extractYouTubeVideoId(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;

  // If user pastes just an 11-char ID.
  final idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
  if (idRegex.hasMatch(trimmed)) return trimmed;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  final host = uri.host.toLowerCase();

  // https://youtu.be/<id>
  if (host == 'youtu.be') {
    final seg = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
    return idRegex.hasMatch(seg) ? seg : null;
  }

  final isYouTubeHost = host.contains('youtube.com') || host.contains('m.youtube.com');
  if (!isYouTubeHost) return null;

  // https://www.youtube.com/watch?v=<id>
  final v = uri.queryParameters['v'];
  if (v != null && idRegex.hasMatch(v)) return v;

  // https://www.youtube.com/shorts/<id>
  // https://www.youtube.com/embed/<id>
  // https://www.youtube.com/v/<id>
  if (uri.pathSegments.length >= 2) {
    final first = uri.pathSegments.first;
    final second = uri.pathSegments[1];
    if ((first == 'shorts' || first == 'embed' || first == 'v') &&
        idRegex.hasMatch(second)) {
      return second;
    }
  }

  return null;
}

