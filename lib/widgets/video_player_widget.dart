import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String roomId;
  final bool isHost;
  final bool showMessageOverlay;
  final bool fillScreen;

  /// When provided (fullscreen mode), these controllers are used directly
  /// instead of creating new ones. The widget will NOT dispose them on exit.
  final VideoPlayerController? existingController;
  final YoutubePlayerController? existingYtController;
  final bool existingIsYouTube;

  const VideoPlayerWidget({
    super.key,
    required this.roomId,
    required this.isHost,
    this.showMessageOverlay = false,
    this.fillScreen = false,
    this.existingController,
    this.existingYtController,
    this.existingIsYouTube = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  String? _currentVideoUrl;
  YoutubePlayerController? _ytController;
  String? _currentYoutubeId;
  bool _isYouTube = false;
  bool _initialized = false;
  String? _errorMessage;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messageSub;
  String? _lastMessageId;
  String? _lastMessagePreview;

  /// True when this instance created (and therefore owns) the controllers.
  /// False when controllers were passed in from an outer widget (fullscreen).
  bool _ownsControllers = true;

  late final DocumentReference<Map<String, dynamic>> _roomRef;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSubscription;
  Duration _pendingRemotePosition = Duration.zero;
  bool _pendingRemotePlaying = false;

  late AnimationController _fadeController;
  late Animation<double> _controlsFade;

  // ── Brand Palette ──────────────────────────────────────────────
  Color get _bg => Theme.of(context).brightness == Brightness.light
      ? const Color(0xFFF8F9FA)
      : const Color(0xFF0D0F14);
  Color get _surface => Theme.of(context).brightness == Brightness.light
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF161A23);
  Color get _surfaceAlt => Theme.of(context).brightness == Brightness.light
      ? const Color(0xFFE9ECEF)
      : const Color(0xFF1C2130);
  Color get _gold => const Color(0xFFCBA869);
  Color get _goldLight => const Color(0xFFE8C98A);
  Color get _textPrimary => Theme.of(context).brightness == Brightness.light
      ? const Color(0xFF1A1D20)
      : const Color(0xFFF0EDE6);
  Color get _textSecondary => Theme.of(context).brightness == Brightness.light
      ? const Color(0xFF495057)
      : const Color(0xFF8A8FA0);
  Color get _border => Theme.of(context).brightness == Brightness.light
      ? const Color(0xFFDEE2E6)
      : const Color(0xFF2A2F3E);

  @override
  void didUpdateWidget(covariant VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.showMessageOverlay != widget.showMessageOverlay &&
        !widget.showMessageOverlay) {
      _lastMessagePreview = null;
    }
  }

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _controlsFade =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _roomRef =
        FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    // ── FULLSCREEN MODE: reuse passed controllers, skip room subscription ──
    if (widget.existingController != null ||
        widget.existingYtController != null) {
      _ownsControllers = false;
      _isYouTube = widget.existingIsYouTube;
      _controller = widget.existingController;
      _ytController = widget.existingYtController;
      _initialized = true;

      _controller?.addListener(_handleControllerUpdate);
      _ytController?.addListener(_handleControllerUpdate);

      _startHideControlsTimer();
      return;
    }

    // ── NORMAL MODE: subscribe to room and initialize controllers ──
    _ownsControllers = true;

    _roomSubscription = _roomRef.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data == null) return;

      final videoType = (data['videoType'] as String?) ?? 'direct';
      final videoUrl = data['videoUrl'] as String?;
      final youtubeId = data['youtubeId'] as String?;

      if (videoType == 'youtube') {
        if (youtubeId == null || youtubeId.isEmpty) return;
        await _initYoutubeController(youtubeId);
      } else {
        if (videoUrl == null || videoUrl.isEmpty) return;
        await _initControllerForUrl(videoUrl);
      }

      final isPlaying = (data['isPlaying'] as bool?) ?? false;
      final currentTimeMs = (data['currentTime'] as int?) ?? 0;
      final position = Duration(milliseconds: currentTimeMs);

      if (!_initialized) {
        _pendingRemotePlaying = isPlaying;
        _pendingRemotePosition = position;
        return;
      }

      if (!widget.isHost) {
        if (_isYouTube && _ytController != null) {
          final yt = _ytController!;
          if (isPlaying != yt.value.isPlaying) {
            isPlaying ? yt.play() : yt.pause();
          }
          final diffMs =
              (position.inMilliseconds - yt.value.position.inMilliseconds)
                  .abs();
          if (diffMs > 1000) {
            yt.seekTo(position);
          }
        } else if (!_isYouTube && _controller != null) {
          final controller = _controller!;
          if (isPlaying != controller.value.isPlaying) {
            isPlaying ? controller.play() : controller.pause();
          }
          final diffMs = (position.inMilliseconds -
                  controller.value.position.inMilliseconds)
              .abs();
          if (diffMs > 1000) {
            await controller.seekTo(position);
          }
        }
      }
    });

    _messageSub = _roomRef
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (!widget.showMessageOverlay) return;
      if (snap.docs.isEmpty) return;
      final doc = snap.docs.first;
      if (doc.id == _lastMessageId) return;
      final data = doc.data();
      final text = (data['text'] as String?) ?? '';
      setState(() {
        _lastMessageId = doc.id;
        _lastMessagePreview = text;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && doc.id == _lastMessageId) {
          setState(() {
            _lastMessagePreview = null;
          });
        }
      });
    });
  }

  Future<void> _initControllerForUrl(String url) async {
    if (_currentVideoUrl == url && _controller != null) return;

    // Switching away from YouTube
    _ytController?.removeListener(_handleControllerUpdate);
    _ytController?.dispose();
    _ytController = null;
    _currentYoutubeId = null;
    _isYouTube = false;

    final oldController = _controller;
    _controller = null;
    _initialized = false;
    _errorMessage = null;
    oldController
      ?..removeListener(_handleControllerUpdate)
      ..dispose();

    setState(() {});

    final controller = VideoPlayerController.networkUrl(Uri.parse(url))
      ..addListener(_handleControllerUpdate);

    try {
      await controller.initialize().timeout(const Duration(seconds: 25));
    } catch (e) {
      controller.dispose();
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not load this video.\n\n$e';
        });
      }
      return;
    }

    if (!mounted) {
      controller.dispose();
      return;
    }

    _controller = controller;
    _currentVideoUrl = url;
    _initialized = true;

    if (!widget.isHost) {
      if (_pendingRemotePosition > Duration.zero) {
        _controller!.seekTo(_pendingRemotePosition);
      }
      if (_pendingRemotePlaying) _controller!.play();
    }

    _startHideControlsTimer();
    setState(() {});
  }

  Future<void> _initYoutubeController(String youtubeId) async {
    if (_currentYoutubeId == youtubeId && _ytController != null) return;

    // Switching away from direct video
    _controller
      ?..removeListener(_handleControllerUpdate)
      ..dispose();
    _controller = null;
    _currentVideoUrl = null;

    _ytController?.removeListener(_handleControllerUpdate);
    _ytController?.dispose();
    _ytController = null;

    _initialized = false;
    _errorMessage = null;
    _isYouTube = true;
    setState(() {});

    final yt = YoutubePlayerController(
      initialVideoId: youtubeId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        disableDragSeek: false,
        enableCaption: true,
      ),
    )..addListener(_handleControllerUpdate);

    if (!mounted) {
      yt.dispose();
      return;
    }

    _ytController = yt;
    _currentYoutubeId = youtubeId;
    _initialized = true;

    if (!widget.isHost) {
      if (_pendingRemotePosition > Duration.zero) {
        yt.seekTo(_pendingRemotePosition);
      }
      if (_pendingRemotePlaying) yt.play();
    }

    _startHideControlsTimer();
    setState(() {});
  }

  void _handleControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    if (!_initialized) return;
    final isCurrentlyPlaying = _isYouTube
        ? (_ytController?.value.isPlaying ?? false)
        : (_controller?.value.isPlaying ?? false);
    if (isCurrentlyPlaying) {
      _hideControlsTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) {
          _fadeController.reverse();
          setState(() => _showControls = false);
        }
      });
    }
  }

  void _onTapVideo() {
    if (!_initialized) return;
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _fadeController.forward();
      _startHideControlsTimer();
    } else {
      _fadeController.reverse();
    }
  }

  /// Opens fullscreen by passing the SAME controllers — no re-init, no reset.
  void _openFullscreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _FullscreenVideoPage(
          roomId: widget.roomId,
          isHost: widget.isHost,
          existingController: _controller,
          existingYtController: _ytController,
          existingIsYouTube: _isYouTube,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _fadeController.dispose();
    _roomSubscription?.cancel();
    _messageSub?.cancel();

    if (_ownsControllers) {
      // We created these controllers — dispose them
      _controller?.removeListener(_handleControllerUpdate);
      _controller?.dispose();
      _ytController?.removeListener(_handleControllerUpdate);
      _ytController?.dispose();
    } else {
      // Controllers belong to the parent — only remove our listeners
      _controller?.removeListener(_handleControllerUpdate);
      _ytController?.removeListener(_handleControllerUpdate);
    }

    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _onPlayPausePressed() async {
    if (!_initialized || !widget.isHost) return;
    final shouldPlay = _isYouTube
        ? !(_ytController?.value.isPlaying ?? false)
        : !(_controller?.value.isPlaying ?? false);

    if (_isYouTube) {
      final yt = _ytController;
      if (yt == null) return;
      shouldPlay ? yt.play() : yt.pause();
    } else {
      final controller = _controller;
      if (controller == null) return;
      shouldPlay ? await controller.play() : await controller.pause();
    }

    await _roomRef.update({
      'isPlaying': shouldPlay,
      'currentTime': _isYouTube
          ? (_ytController?.value.position.inMilliseconds ?? 0)
          : (_controller?.value.position.inMilliseconds ?? 0),
    });
    _startHideControlsTimer();
  }

  Future<void> _onSeek(double value) async {
    if (!_initialized || !widget.isHost) return;

    final duration = _isYouTube
        ? (_ytController?.value.metaData.duration ?? Duration.zero)
        : (_controller?.value.duration ?? Duration.zero);
    if (duration.inMilliseconds == 0) return;

    final targetMs = (duration.inMilliseconds * value).toInt();
    final target = Duration(milliseconds: targetMs);

    if (_isYouTube) {
      final yt = _ytController;
      if (yt == null) return;
      yt.seekTo(target);
    } else {
      final controller = _controller;
      if (controller == null) return;
      await controller.seekTo(target);
    }

    await _roomRef.update({'currentTime': target.inMilliseconds});
    _startHideControlsTimer();
  }

  @override
  Widget build(BuildContext context) {
    // ── Error state ────────────────────────────────────────────────
    if (_errorMessage != null) {
      return Container(
        color: _bg,
        padding: const EdgeInsets.all(18),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  color: _gold,
                  size: 26,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Video failed to load',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 12.5,
                  color: _textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ── Loading state ──────────────────────────────────────────────
    if (!_initialized ||
        (!_isYouTube && _controller == null) ||
        (_isYouTube && _ytController == null)) {
      return Container(
        color: _bg,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: _border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(_gold),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "Loading video…",
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 13.5,
                  color: _textSecondary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Resolved state values ──────────────────────────────────────
    final duration = _isYouTube
        ? _ytController!.value.metaData.duration
        : _controller!.value.duration;
    final position = _isYouTube
        ? _ytController!.value.position
        : _controller!.value.position;
    final progress = duration.inMilliseconds == 0
        ? 0.0
        : position.inMilliseconds / duration.inMilliseconds;
    final isPlaying = _isYouTube
        ? _ytController!.value.isPlaying
        : _controller!.value.isPlaying;

    // ── Main video + controls (Stack — controls overlay the video) ─
    return GestureDetector(
      onTap: _onTapVideo,
      child: Container(
        width: double.infinity,
        color: Colors.black,
        // Stack fills available space; video and overlays are layered inside
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Video frame: OrientationBuilder for correct scaling ──
            OrientationBuilder(
              builder: (context, orientation) {
                final isLandscape = orientation == Orientation.landscape;
                final size = MediaQuery.of(context).size;

                final double targetAspectRatio;
                if (widget.fillScreen && isLandscape) {
                  // Landscape fullscreen: fill device screen exactly
                  targetAspectRatio = size.width / size.height;
                } else {
                  // Portrait (or non-fullscreen): native video / 16:9 aspect
                  targetAspectRatio =
                      _isYouTube ? (16 / 9) : _controller!.value.aspectRatio;
                }

                return Center(
                  child: AspectRatio(
                    aspectRatio: targetAspectRatio,
                    child: _isYouTube
                        ? YoutubePlayer(
                            controller: _ytController!,
                            showVideoProgressIndicator: false,
                          )
                        : VideoPlayer(_controller!),
                  ),
                );
              },
            ),

            // ── Incoming message preview (top, fullscreen only) ──────
            if (widget.showMessageOverlay && _lastMessagePreview != null)
              Positioned(
                top: 24,
                left: 24,
                right: 24,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _gold.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 14, color: _gold),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lastMessagePreview!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Viewer badge (top-right) ─────────────────────────────
            if (!widget.isHost)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.visibility_outlined,
                          color: _textSecondary, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        "Viewer",
                        style: TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                          fontFamily: 'Georgia',
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Centre play/pause button overlay ────────────────────
            Center(
              child: FadeTransition(
                opacity: _controlsFade,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: GestureDetector(
                    onTap: widget.isHost ? _onPlayPausePressed : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _gold.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: _textPrimary,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Bottom controls overlay (overlaid directly on video) ─
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _controlsFade,
                child: IgnorePointer(
                  ignoring: !_showControls,
                  child: Container(
                    // Gradient so controls remain readable over any video frame
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Time labels ────────────────────────────
                        Row(
                          children: [
                            Text(
                              _formatDuration(position),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _textSecondary,
                                fontFamily: 'Georgia',
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatDuration(duration),
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _textSecondary,
                                fontFamily: 'Georgia',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),

                        // ── Seek slider ────────────────────────────
                        _StyledSlider(
                          value: progress.clamp(0.0, 1.0),
                          isHost: widget.isHost,
                          onChanged: _onSeek,
                        ),
                        const SizedBox(height: 6),

                        // ── Play/pause + role label + fullscreen + LIVE
                        Row(
                          children: [
                            // Play / pause
                            GestureDetector(
                              onTap: widget.isHost ? _onPlayPausePressed : null,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: widget.isHost
                                      ? LinearGradient(
                                          colors: [_gold, _goldLight],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : null,
                                  color: widget.isHost ? null : _surfaceAlt,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: widget.isHost
                                        ? Colors.transparent
                                        : _border,
                                  ),
                                  boxShadow: widget.isHost
                                      ? [
                                          BoxShadow(
                                            color: _gold.withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          )
                                        ]
                                      : [],
                                ),
                                child: Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: widget.isHost ? _bg : _textSecondary,
                                  size: 20,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // Role label — Flexible prevents overflow
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    widget.isHost
                                        ? Icons.star_rounded
                                        : Icons.person_outline_rounded,
                                    size: 12,
                                    color:
                                        widget.isHost ? _gold : _textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      widget.isHost
                                          ? 'You control playback for everyone.'
                                          : 'The host controls playback.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: widget.isHost
                                            ? _gold.withValues(alpha: 0.85)
                                            : _textSecondary,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Fullscreen toggle
                            GestureDetector(
                              onTap: _openFullscreen,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _border),
                                ),
                                child: Icon(
                                  Icons.fullscreen_rounded,
                                  size: 18,
                                  color: _textSecondary,
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // LIVE indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4CAF50),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "LIVE",
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: _textSecondary,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

// ── Styled Slider ──────────────────────────────────────────────────────────────
class _StyledSlider extends StatelessWidget {
  final double value;
  final bool isHost;
  final ValueChanged<double> onChanged;

  const _StyledSlider({
    required this.value,
    required this.isHost,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: const Color(0xFFCBA869),
        inactiveTrackColor:
            isLight ? const Color(0xFFDEE2E6) : const Color(0xFF2A2F3E),
        thumbColor: const Color(0xFFE8C98A),
        overlayColor: const Color(0xFFCBA869).withValues(alpha: 0.15),
        disabledActiveTrackColor: isLight
            ? const Color(0xFFCBA869).withValues(alpha: 0.5)
            : const Color(0xFF4A4030),
        disabledInactiveTrackColor:
            isLight ? const Color(0xFFE9ECEF) : const Color(0xFF1E2028),
        disabledThumbColor: isLight
            ? const Color(0xFFCBA869).withValues(alpha: 0.7)
            : const Color(0xFF4A4030),
      ),
      child: Slider(
        value: value,
        onChanged: isHost ? onChanged : null,
      ),
    );
  }
}

// ── Fullscreen Video Page ─────────────────────────────────────────────────────
// Passes the SAME controller instances — no new init, no position reset.
class _FullscreenVideoPage extends StatelessWidget {
  final String roomId;
  final bool isHost;
  final VideoPlayerController? existingController;
  final YoutubePlayerController? existingYtController;
  final bool existingIsYouTube;

  const _FullscreenVideoPage({
    required this.roomId,
    required this.isHost,
    this.existingController,
    this.existingYtController,
    this.existingIsYouTube = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: VideoPlayerWidget(
                roomId: roomId,
                isHost: isHost,
                showMessageOverlay: true,
                fillScreen: true,
                existingController: existingController,
                existingYtController: existingYtController,
                existingIsYouTube: existingIsYouTube,
              ),
            ),
            // Close button
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white70,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
