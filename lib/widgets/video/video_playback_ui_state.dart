/// UI-only playback state — drives [ValueListenableBuilder] without full-tree rebuilds.
class VideoPlaybackUiState {
  final bool waitingForMovie;
  final String? thumbnailUrl;
  final String? movieTitle;
  final bool videoVisible;
  final bool showShimmer;
  final bool showLoadingOverlay;
  final String loadingMessage;
  final bool showBufferingIndicator;
  final bool showError;
  final String? errorMessage;
  final bool showControls;
  final bool isPlaying;
  final double progress;
  final Duration position;
  final Duration duration;
  final bool isHost;

  const VideoPlaybackUiState({
    this.waitingForMovie = true,
    this.thumbnailUrl,
    this.movieTitle,
    this.videoVisible = false,
    this.showShimmer = false,
    this.showLoadingOverlay = false,
    this.loadingMessage = 'Preparing your video…',
    this.showBufferingIndicator = false,
    this.showError = false,
    this.errorMessage,
    this.showControls = true,
    this.isPlaying = false,
    this.progress = 0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isHost = false,
  });

  VideoPlaybackUiState copyWith({
    bool? waitingForMovie,
    String? thumbnailUrl,
    String? movieTitle,
    bool? videoVisible,
    bool? showShimmer,
    bool? showLoadingOverlay,
    String? loadingMessage,
    bool? showBufferingIndicator,
    bool? showError,
    String? errorMessage,
    bool? showControls,
    bool? isPlaying,
    double? progress,
    Duration? position,
    Duration? duration,
    bool? isHost,
  }) {
    return VideoPlaybackUiState(
      waitingForMovie: waitingForMovie ?? this.waitingForMovie,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      movieTitle: movieTitle ?? this.movieTitle,
      videoVisible: videoVisible ?? this.videoVisible,
      showShimmer: showShimmer ?? this.showShimmer,
      showLoadingOverlay: showLoadingOverlay ?? this.showLoadingOverlay,
      loadingMessage: loadingMessage ?? this.loadingMessage,
      showBufferingIndicator:
          showBufferingIndicator ?? this.showBufferingIndicator,
      showError: showError ?? this.showError,
      errorMessage: errorMessage ?? this.errorMessage,
      showControls: showControls ?? this.showControls,
      isPlaying: isPlaying ?? this.isPlaying,
      progress: progress ?? this.progress,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isHost: isHost ?? this.isHost,
    );
  }
}
