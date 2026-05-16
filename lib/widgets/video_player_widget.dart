import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../utils/media_kit_config.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String roomId;
  final bool isHost;
  final bool showMessageOverlay;
  final bool fillScreen;

  final Player? existingPlayer;
  final VideoController? existingVideoController;

  const VideoPlayerWidget({
    super.key,
    required this.roomId,
    required this.isHost,
    this.showMessageOverlay = false,
    this.fillScreen = false,
    this.existingPlayer,
    this.existingVideoController,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  Player? _player;
  VideoController? _videoController;
  String? _currentVideoUrl;

  bool _initialized = false;
  bool _isBuffering = false;
  bool _isReconnecting = false;
  String _statusMessage = 'Preparing stream…';
  String? _errorMessage;
  String? _movieTitle;
  bool _waitingForMovie = true;

  /// Controls stay visible; auto-fade only while playing.
  bool _showControls = true;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;

  Timer? _hideControlsTimer;
  Timer? _syncTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messageSub;
  final List<StreamSubscription<dynamic>> _playerSubs = [];

  String? _lastMessageId;
  String? _lastMessagePreview;

  bool _ownsPlayer = true;
  bool _openingMedia = false;

  late final DocumentReference<Map<String, dynamic>> _roomRef;
  Duration _pendingRemotePosition = Duration.zero;
  bool _pendingRemotePlaying = false;

  static const Color _gold = Color(0xFFCBA869);
  static const Color _goldLight = Color(0xFFE8C98A);

  Color get _bg => Theme.of(context).brightness == Brightness.light
      ? const Color(0xFFF8F9FA)
      : const Color(0xFF0D0F14);
  Color get _textPrimary => Theme.of(context).brightness == Brightness.light
      ? const Color(0xFF1A1D20)
      : const Color(0xFFF0EDE6);
  Color get _textSecondary => Theme.of(context).brightness == Brightness.light
      ? const Color(0xFF495057)
      : const Color(0xFF8A8FA0);

  @override
  void initState() {
    super.initState();

    _roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    if (widget.existingPlayer != null &&
        widget.existingVideoController != null) {
      _ownsPlayer = false;
      _player = widget.existingPlayer;
      _videoController = widget.existingVideoController;
      _initialized = true;
      _waitingForMovie = false;
      _bootstrapPlayerState();
      return;
    }

    _ownsPlayer = true;
    _listenToRoom();
    _listenToMessages();
  }

  void _bootstrapPlayerState() {
    _attachPlayerListeners();
    _syncFromPlayer();
    _startSyncTimer();
    if (_isPlaying) _scheduleHideControls();
  }

  void _syncFromPlayer() {
    final player = _player;
    if (player == null || !mounted) return;
    final state = player.state;
    setState(() {
      _isPlaying = state.playing;
      _position = state.position;
      if (state.duration > Duration.zero) {
        _duration = state.duration;
        _initialized = true;
      }
      _isBuffering = state.buffering;
    });
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _player == null) return;
      _syncFromPlayer();
    });
  }

  void _listenToRoom() {
    _roomSub = _roomRef.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data == null) return;

      final videoUrl = data['videoUrl'] as String?;
      final movieTitle = data['movieTitle'] as String?;

      if (mounted && movieTitle != _movieTitle) {
        setState(() => _movieTitle = movieTitle);
      }

      if (videoUrl == null || videoUrl.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _waitingForMovie = true;
            _initialized = false;
          });
        }
        return;
      }

      if (mounted) setState(() => _waitingForMovie = false);
      await _openMediaIfNeeded(videoUrl.trim());

      final isPlaying = (data['isPlaying'] as bool?) ?? false;
      final currentTimeMs = (data['currentTime'] as int?) ?? 0;
      final position = Duration(milliseconds: currentTimeMs);

      if (!_initialized) {
        _pendingRemotePlaying = isPlaying;
        _pendingRemotePosition = position;
        return;
      }

      if (!widget.isHost && _player != null) {
        if (isPlaying != _isPlaying) {
          isPlaying ? _player!.play() : _player!.pause();
        }
        final diffMs =
            (position.inMilliseconds - _position.inMilliseconds).abs();
        if (diffMs > 1000) await _player!.seek(position);
      }
    });
  }

  void _listenToMessages() {
    _messageSub = _roomRef
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (!widget.showMessageOverlay || snap.docs.isEmpty) return;
      final doc = snap.docs.first;
      if (doc.id == _lastMessageId) return;
      final text = (doc.data()['text'] as String?) ?? '';
      setState(() {
        _lastMessageId = doc.id;
        _lastMessagePreview = text;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && doc.id == _lastMessageId) {
          setState(() => _lastMessagePreview = null);
        }
      });
    });
  }

  void _attachPlayerListeners() {
    final player = _player;
    if (player == null) return;

    _playerSubs.add(player.stream.playing.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
      if (playing) {
        _scheduleHideControls();
      } else {
        _showControlsPermanent();
      }
    }));

    _playerSubs.add(player.stream.position.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    }));

    _playerSubs.add(player.stream.duration.listen((duration) {
      if (!mounted) return;
      if (duration > Duration.zero) {
        setState(() {
          _duration = duration;
          _initialized = true;
        });
      }
    }));

    _playerSubs.add(player.stream.buffering.listen((buffering) {
      if (!mounted) return;
      setState(() {
        _isBuffering = buffering;
        if (buffering && !_isReconnecting) {
          _statusMessage = 'Buffering…';
        }
      });
    }));

    _playerSubs.add(player.stream.error.listen((error) {
      if (error.trim().isEmpty) return;
      _scheduleRetry();
    }));
  }

  Future<void> _disposePlayer() async {
    _syncTimer?.cancel();
    for (final sub in _playerSubs) {
      await sub.cancel();
    }
    _playerSubs.clear();
    final player = _player;
    _player = null;
    _videoController = null;
    if (player != null) await player.dispose();
  }

  Future<void> _openMediaIfNeeded(String url) async {
    if (_openingMedia) return;
    if (_currentVideoUrl == url && _player != null && _initialized) return;

    _openingMedia = true;
    await _disposePlayer();

    if (!mounted) {
      _openingMedia = false;
      return;
    }

    _player = MediaKitStreaming.createPlayer();
    _videoController = VideoController(_player!);
    _currentVideoUrl = url;
    _attachPlayerListeners();
    _startSyncTimer();

    await _openWithRetry(url);
    _openingMedia = false;
  }

  Future<void> _openWithRetry(String url, {int attempt = 1}) async {
    final player = _player;
    if (player == null || !mounted) return;

    setState(() {
      _initialized = false;
      _errorMessage = null;
      _isBuffering = true;
      _isReconnecting = attempt > 1;
      _statusMessage = attempt == 1
          ? 'Preparing stream…'
          : 'Reconnecting… ($attempt/${MediaKitStreaming.maxRetryAttempts})';
      _showControls = true;
    });
    try {
      await MediaKitStreaming.applyNetworkOptimizations(player);
      await player.open(Media(url), play: false).timeout(
            const Duration(seconds: 60),
            onTimeout: () => throw TimeoutException('Connection timed out'),
          );
      await player.stream.duration
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 90));

      if (!mounted) return;

      _syncFromPlayer();
      setState(() {
        _initialized = true;
        _isBuffering = false;
        _isReconnecting = false;
        _statusMessage = '';
        _showControls = true;
      });

      if (!widget.isHost) {
        if (_pendingRemotePosition > Duration.zero) {
          await player.seek(_pendingRemotePosition);
        }
        if (_pendingRemotePlaying) await player.play();
      }

      _syncFromPlayer();
    } catch (_) {
      if (attempt < MediaKitStreaming.maxRetryAttempts && mounted) {
        await Future.delayed(Duration(seconds: 2 * attempt));
        return _openWithRetry(url, attempt: attempt + 1);
      }
      if (mounted) {
        setState(() {
          _errorMessage =
              'Could not play this video. Check your connection and try again.';
          _isBuffering = false;
          _isReconnecting = false;
        });
      }
    }
  }

  void _scheduleRetry() {
    if (_openingMedia || _currentVideoUrl == null) return;
    final url = _currentVideoUrl!;
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _currentVideoUrl == url) {
        _openWithRetry(url, attempt: 2);
      }
    });
  }

  void _showControlsPermanent() {
    _hideControlsTimer?.cancel();
    if (!_showControls) setState(() => _showControls = true);
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (!_initialized) return;
    _hideControlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isPlaying) setState(() => _showControls = false);
    });
  }

  void _onTapVideo() {
    if (!_initialized) return;
    if (_showControls) {
      if (_isPlaying) _scheduleHideControls();
    } else {
      setState(() => _showControls = true);
      if (_isPlaying) _scheduleHideControls();
    }
  }

  Future<void> _openFullscreen() async {
    if (_player == null || _videoController == null) return;
    _showControlsPermanent();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenPlayerPage(
          player: _player!,
          videoController: _videoController!,
          isHost: widget.isHost,
          movieTitle: _movieTitle,
          onPlayPause: widget.isHost ? _onPlayPausePressed : null,
          onSeek: widget.isHost ? _onSeek : null,
          onSkip: widget.isHost ? _skipRelative : null,
        ),
      ),
    );
    if (mounted) _syncFromPlayer();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _syncTimer?.cancel();
    _roomSub?.cancel();
    _messageSub?.cancel();
    if (_ownsPlayer) {
      _disposePlayer();
    } else {
      for (final sub in _playerSubs) {
        sub.cancel();
      }
      _playerSubs.clear();
      _syncTimer?.cancel();
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inMilliseconds < 0) return '0:00';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _onPlayPausePressed() async {
    if (!_initialized || !widget.isHost || _player == null) return;
    final shouldPlay = !_isPlaying;
    if (shouldPlay) {
      await _player!.play();
    } else {
      await _player!.pause();
    }
    _syncFromPlayer();
    await _roomRef.update({
      'isPlaying': shouldPlay,
      'currentTime': _position.inMilliseconds,
    });
  }

  Future<void> _skipRelative(int seconds) async {
    if (!_initialized || !widget.isHost || _player == null) return;
    var target = _position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (_duration > Duration.zero && target > _duration) target = _duration;
    await _player!.seek(target);
    _syncFromPlayer();
    await _roomRef.update({'currentTime': target.inMilliseconds});
  }

  Future<void> _onSeek(double value) async {
    if (!_initialized || !widget.isHost || _player == null) return;
    if (_duration.inMilliseconds == 0) return;
    final target = Duration(
      milliseconds: (_duration.inMilliseconds * value).round(),
    );
    await _player!.seek(target);
    _syncFromPlayer();
    await _roomRef.update({'currentTime': target.inMilliseconds});
  }

  Widget _buildWaitingState() {
    return Container(
      color: _bg,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.movie_outlined, color: _gold, size: 48),
            const SizedBox(height: 16),
            Text(
              widget.isHost ? 'Choose a movie' : 'Waiting for the host',
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferingBanner() {
    return Positioned(
      top: 12,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_gold),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _isReconnecting ? _statusMessage : 'Buffering…',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsBar(double progress) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedOpacity(
        opacity: _showControls ? 1 : 0,
        duration: const Duration(milliseconds: 280),
        child: IgnorePointer(
          ignoring: !_showControls,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.92),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        _formatDuration(_position),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDuration(_duration),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14),
                      activeTrackColor: _gold,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: _goldLight,
                    ),
                    child: Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: widget.isHost ? _onSeek : null,
                    ),
                  ),
                  Row(
                    children: [
                      _NetflixControlButton(
                        icon: _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 44,
                        filled: true,
                        onTap: widget.isHost ? _onPlayPausePressed : null,
                      ),
                      if (widget.isHost) ...[
                        const SizedBox(width: 6),
                        _NetflixControlButton(
                          icon: Icons.replay_10_rounded,
                          onTap: () => _skipRelative(-10),
                        ),
                        _NetflixControlButton(
                          icon: Icons.forward_10_rounded,
                          onTap: () => _skipRelative(10),
                        ),
                      ],
                      const Spacer(),
                      if (!_isPlaying && !_showControls)
                        const SizedBox.shrink()
                      else if (!widget.isHost)
                        Text(
                          'Host controls playback',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11),
                        ),
                      const SizedBox(width: 8),
                      _NetflixControlButton(
                        icon: widget.fillScreen
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        onTap: widget.fillScreen
                            ? () => Navigator.maybePop(context)
                            : _openFullscreen,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Thin progress line when controls are hidden.
  Widget _buildMiniProgress(double progress) {
    if (_showControls || _duration.inMilliseconds == 0) {
      return const SizedBox.shrink();
    }
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 3,
        backgroundColor: Colors.white12,
        valueColor: const AlwaysStoppedAnimation<Color>(_gold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_waitingForMovie && widget.existingPlayer == null && !_initialized) {
      return _buildWaitingState();
    }

    if (_errorMessage != null) {
      return Container(
        color: _bg,
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: _gold, size: 40),
              const SizedBox(height: 12),
              Text('Playback failed',
                  style: TextStyle(
                      color: _textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _textSecondary)),
              TextButton(
                onPressed: _currentVideoUrl != null
                    ? () => _openWithRetry(_currentVideoUrl!)
                    : null,
                child: const Text('Retry', style: TextStyle(color: _gold)),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized || _videoController == null) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_gold),
              ),
              const SizedBox(height: 14),
              Text(_statusMessage,
                  style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : _position.inMilliseconds / _duration.inMilliseconds;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _onTapVideo,
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Video(
              controller: _videoController!,
              fill: Colors.black,
              controls: NoVideoControls,
              fit: widget.fillScreen ? BoxFit.cover : BoxFit.contain,
            ),
            if (_isBuffering || _isReconnecting) _buildBufferingBanner(),
            if (_movieTitle != null && _movieTitle!.isNotEmpty)
              Positioned(
                top: 12,
                left: 16,
                right: 16,
                child: IgnorePointer(
                  child: Text(
                    _movieTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      shadows: const [
                        Shadow(color: Colors.black, blurRadius: 8)
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.showMessageOverlay && _lastMessagePreview != null)
              Positioned(
                top: 44,
                left: 16,
                right: 16,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        _lastMessagePreview!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ),
            if (_showControls)
              Center(
                child: GestureDetector(
                  onTap: widget.isHost ? _onPlayPausePressed : null,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            _buildControlsBar(progress),
            _buildMiniProgress(progress),
          ],
        ),
      ),
    );
  }
}

class _NetflixControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final bool filled;

  const _NetflixControlButton({
    required this.icon,
    this.onTap,
    this.size = 36,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: filled ? Colors.white : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: filled ? 26 : 20,
            color: filled ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}

/// Fullscreen player — single source of truth via [Player.state] + periodic sync.
class _FullscreenPlayerPage extends StatefulWidget {
  final Player player;
  final VideoController videoController;
  final bool isHost;
  final String? movieTitle;
  final Future<void> Function()? onPlayPause;
  final Future<void> Function(double)? onSeek;
  final Future<void> Function(int)? onSkip;

  const _FullscreenPlayerPage({
    required this.player,
    required this.videoController,
    required this.isHost,
    this.movieTitle,
    this.onPlayPause,
    this.onSeek,
    this.onSkip,
  });

  @override
  State<_FullscreenPlayerPage> createState() => _FullscreenPlayerPageState();
}

class _FullscreenPlayerPageState extends State<_FullscreenPlayerPage> {
  bool _showControls = true;
  Timer? _hideTimer;
  Timer? _syncTimer;

  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isPlaying = false;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _sync();
    _syncTimer =
        Timer.periodic(const Duration(milliseconds: 200), (_) => _sync());
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) setState(() => _showControls = false);
    });
  }

  void _sync() {
    if (!mounted) return;
    final s = widget.player.state;
    setState(() {
      _isPlaying = s.playing;
      _position = s.position;
      if (s.duration > Duration.zero) _duration = s.duration;
      _isBuffering = s.buffering;
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _isPlaying) {
      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted && _isPlaying) setState(() => _showControls = false);
      });
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _duration.inMilliseconds == 0
        ? 0.0
        : _position.inMilliseconds / _duration.inMilliseconds;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Video(
              controller: widget.videoController,
              controls: NoVideoControls,
              fit: BoxFit.contain,
            ),
            if (_isBuffering)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCBA869)),
                ),
              ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        if (widget.movieTitle != null)
                          Expanded(
                            child: Text(
                              widget.movieTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_showControls)
              Center(
                child: IconButton(
                  iconSize: 64,
                  color: Colors.white,
                  icon: Icon(_isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled),
                  onPressed: widget.isHost
                      ? () async {
                          await widget.onPlayPause?.call();
                          _sync();
                        }
                      : null,
                ),
              ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.9)
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(_fmt(_position),
                              style: const TextStyle(color: Colors.white)),
                          const Spacer(),
                          Text(_fmt(_duration),
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      Slider(
                        value: progress.clamp(0.0, 1.0),
                        activeColor: const Color(0xFFCBA869),
                        inactiveColor: Colors.white24,
                        onChanged: widget.isHost
                            ? (v) async {
                                await widget.onSeek?.call(v);
                                _sync();
                              }
                            : null,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.isHost) ...[
                            IconButton(
                              icon: const Icon(Icons.replay_10,
                                  color: Colors.white),
                              onPressed: () async {
                                await widget.onSkip?.call(-10);
                                _sync();
                              },
                            ),
                            IconButton(
                              iconSize: 48,
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                await widget.onPlayPause?.call();
                                _sync();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.forward_10,
                                  color: Colors.white),
                              onPressed: () async {
                                await widget.onSkip?.call(10);
                                _sync();
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
