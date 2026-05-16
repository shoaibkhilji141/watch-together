import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/room_presence_service.dart';
import '../utils/app_palette.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/chat/chat_screen.dart';
import 'movies_list_screen.dart';

class WatchScreen extends StatefulWidget {
  final String roomId;
  final String? roomName;

  const WatchScreen({
    super.key,
    required this.roomId,
    this.roomName,
  });

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  bool _codeCopied = false;
  final _presence = RoomPresenceService();
  Timer? _heartbeatTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomMetaSub;

  bool _roomLoaded = false;
  bool _roomExists = false;
  String _title = '';
  bool _isHost = false;

  @override
  void initState() {
    super.initState();
    _listenRoomMeta();
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerPresence());
  }

  void _listenRoomMeta() {
    _roomMetaSub = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) {
      if (!mounted) return;

      if (!snapshot.exists) {
        if (!_roomLoaded || _roomExists) {
          setState(() {
            _roomLoaded = true;
            _roomExists = false;
          });
        }
        return;
      }

      final data = snapshot.data()!;
      final hostId = data['hostId'] as String?;
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final newIsHost = uid != null && uid == hostId;
      final newTitle = widget.roomName ??
          (data['movieTitle'] as String?) ??
          'Room ${widget.roomId}';

      if (!_roomLoaded ||
          !_roomExists ||
          newIsHost != _isHost ||
          newTitle != _title) {
        setState(() {
          _roomLoaded = true;
          _roomExists = true;
          _isHost = newIsHost;
          _title = newTitle;
        });
      }
    });
  }

  Future<void> _registerPresence() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final roomDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .get();
    if (!roomDoc.exists || !mounted) return;

    final hostId = roomDoc.data()?['hostId'] as String?;
    final isHost = hostId == user.uid;

    await _presence.joinRoom(roomId: widget.roomId, isHost: isHost);

    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _presence.heartbeat(widget.roomId);
    });
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _roomMetaSub?.cancel();
    _presence.leaveRoom(widget.roomId);
    super.dispose();
  }

  Future<void> _copyRoomCode() async {
    await Clipboard.setData(ClipboardData(text: widget.roomId));
    setState(() => _codeCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _codeCopied = false);
  }

  void _openMovieCatalog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MoviesListScreen(
          roomId: widget.roomId,
          pickOnly: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    if (!_roomLoaded) {
      return Scaffold(
        backgroundColor: p.bg,
        body: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(p.gold),
          ),
        ),
      );
    }

    if (!_roomExists) {
      return Scaffold(
        backgroundColor: p.bg,
        body: Center(
          child: Text(
            'Room not found',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 18,
              color: p.textPrimary,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              title: _title,
              roomId: widget.roomId,
              isHost: _isHost,
              codeCopied: _codeCopied,
              onCopy: _copyRoomCode,
              onChangeMovie: _isHost ? _openMovieCatalog : null,
              viewerCountStream:
                  _isHost ? _presence.activeViewerCount(widget.roomId) : null,
            ),
            Container(height: 1, color: p.border),
            Expanded(
              flex: 2,
              child: VideoPlayerWidget(
                key: ValueKey('video-${widget.roomId}'),
                roomId: widget.roomId,
                isHost: _isHost,
              ),
            ),
            const _ChatDivider(),
            Expanded(
              flex: 3,
              child: RepaintBoundary(
                child: ChatScreen(
                  key: ValueKey('chat-${widget.roomId}'),
                  roomId: widget.roomId,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final String roomId;
  final bool isHost;
  final bool codeCopied;
  final VoidCallback onCopy;
  final VoidCallback? onChangeMovie;
  final Stream<int>? viewerCountStream;

  const _TopBar({
    required this.title,
    required this.roomId,
    required this.isHost,
    required this.codeCopied,
    required this.onCopy,
    this.onChangeMovie,
    this.viewerCountStream,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Container(
      color: p.bg,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _TopBarIconButton(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: p.textSecondary,
                  size: 12,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: p.gold,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.play_arrow_rounded, color: p.bg, size: 15),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (isHost && onChangeMovie != null)
                _TopBarIconButton(
                  onTap: onChangeMovie!,
                  child: Icon(Icons.movie_outlined, size: 15, color: p.gold),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _RoomCodeChip(
                  palette: p,
                  roomId: roomId,
                  codeCopied: codeCopied,
                  onCopy: onCopy,
                ),
                const SizedBox(width: 6),
                _RoleChip(palette: p, isHost: isHost),
                if (isHost && viewerCountStream != null) ...[
                  const SizedBox(width: 6),
                  _ViewerCountChip(
                    palette: p,
                    stream: viewerCountStream!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TopBarIconButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: p.border),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RoomCodeChip extends StatelessWidget {
  final AppPalette palette;
  final String roomId;
  final bool codeCopied;
  final VoidCallback onCopy;

  const _RoomCodeChip({
    required this.palette,
    required this.roomId,
    required this.codeCopied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onCopy,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: codeCopied
              ? palette.gold.withValues(alpha: 0.15)
              : palette.surfaceAlt,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: codeCopied
                ? palette.gold.withValues(alpha: 0.5)
                : palette.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              codeCopied ? Icons.check_rounded : Icons.tag_rounded,
              size: 11,
              color: codeCopied ? palette.gold : palette.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              codeCopied ? 'Copied!' : roomId,
              style: TextStyle(
                fontFamily: 'Georgia',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: codeCopied ? palette.gold : palette.textPrimary,
                letterSpacing: codeCopied ? 0.2 : 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final AppPalette palette;
  final bool isHost;

  const _RoleChip({required this.palette, required this.isHost});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: isHost
            ? palette.gold.withValues(alpha: 0.12)
            : palette.surfaceAlt,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isHost
              ? palette.gold.withValues(alpha: 0.35)
              : palette.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isHost ? Icons.star_rounded : Icons.person_outline_rounded,
            size: 11,
            color: isHost ? palette.gold : palette.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            isHost ? 'Host' : 'Viewer',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isHost ? palette.gold : palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerCountChip extends StatelessWidget {
  final AppPalette palette;
  final Stream<int> stream;

  const _ViewerCountChip({required this.palette, required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return Tooltip(
          message: count == 1 ? '1 viewer watching' : '$count viewers watching',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: palette.gold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: palette.gold.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline_rounded, size: 12, color: palette.gold),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: palette.gold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ChatDivider extends StatelessWidget {
  const _ChatDivider();

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);

    return Container(
      color: p.surface,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              color: p.textSecondary, size: 15),
          const SizedBox(width: 8),
          Text(
            'Live Chat',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: p.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const Spacer(),
          Container(
            width: 28,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [p.gold.withValues(alpha: 0.4), Colors.transparent],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
