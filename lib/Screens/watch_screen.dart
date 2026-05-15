import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/video_player_widget.dart';
import '../widgets/chat_widget.dart';
import '../utils/youtube.dart';

class _Palette {
  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color gold;
  final Color goldLight;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;

  const _Palette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.gold,
    required this.goldLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
  });

  factory _Palette.of(BuildContext context) {
    if (Theme.of(context).brightness == Brightness.light) {
      return const _Palette(
        bg: Color(0xFFF8F9FA),
        surface: Color(0xFFFFFFFF),
        surfaceAlt: Color(0xFFE9ECEF),
        gold: Color(0xFFCBA869),
        goldLight: Color(0xFFE8C98A),
        textPrimary: Color(0xFF1A1D20),
        textSecondary: Color(0xFF495057),
        border: Color(0xFFDEE2E6),
      );
    }
    return const _Palette(
      bg: Color(0xFF0D0F14),
      surface: Color(0xFF161A23),
      surfaceAlt: Color(0xFF1C2130),
      gold: Color(0xFFCBA869),
      goldLight: Color(0xFFE8C98A),
      textPrimary: Color(0xFFF0EDE6),
      textSecondary: Color(0xFF8A8FA0),
      border: Color(0xFF2A2F3E),
    );
  }
}

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

  Future<void> _copyRoomCode() async {
    await Clipboard.setData(ClipboardData(text: widget.roomId));
    setState(() => _codeCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _codeCopied = false);
  }

  Future<void> _setVideoUrlForRoom({
    required String roomId,
    required String url,
    required String source,
  }) async {
    final ytId = extractYouTubeVideoId(url);
    if (ytId != null) {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'videoType': 'youtube',
        'youtubeId': ytId,
        'videoUrl': url,
        'videoSource': source,
        'isPlaying': false,
        'currentTime': 0,
      });
      return;
    }

    await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'videoType': 'direct',
      'youtubeId': FieldValue.delete(),
      'videoUrl': url,
      'videoSource': source,
      'isPlaying': false,
      'currentTime': 0,
    });
  }

  Future<void> _showChangeVideoSheet(String roomId) async {
    final urlController = TextEditingController();
    final p = _Palette.of(context);

    await showModalBottomSheet(
      context: context,
      backgroundColor: p.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.movie_creation_outlined,
                      color: p.gold, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Choose video source',
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: p.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded,
                        color: p.textSecondary, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: urlController,
                style: TextStyle(color: p.textPrimary, fontSize: 13.5),
                decoration: InputDecoration(
                  labelText: 'Network video URL',
                  labelStyle: TextStyle(
                    color: p.textSecondary,
                    fontSize: 13,
                  ),
                  hintText: 'https://example.com/video.mp4',
                  hintStyle: TextStyle(
                    color: p.textSecondary,
                    fontSize: 12.5,
                  ),
                  filled: true,
                  fillColor: p.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: p.gold),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: p.gold,
                        foregroundColor: p.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        final url = urlController.text.trim();
                        if (url.isEmpty) return;
                        Navigator.pop(context);
                        await _setVideoUrlForRoom(
                          roomId: roomId,
                          url: url,
                          source: 'network',
                        );
                      },
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text(
                        'Use URL',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: p.border),
                        foregroundColor: p.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () async {
                        Navigator.pop(context);
                        await _pickLocalVideoAndUpload(roomId);
                      },
                      icon: const Icon(Icons.folder_open_rounded, size: 18),
                      label: const Text(
                        'From device',
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickLocalVideoAndUpload(String roomId) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.video);
      if (result == null) return;
      final name = result.files.single.name;

      final ref = FirebaseStorage.instance
          .ref()
          .child('room_videos')
          .child('$roomId-${DateTime.now().millisecondsSinceEpoch}-$name');

      final metadata = SettableMetadata(contentType: 'video/mp4');

      if (kIsWeb) {
        final bytes = result.files.single.bytes;
        if (bytes == null) return;
        await ref.putData(bytes, metadata);
      } else {
        final path = result.files.single.path;
        if (path == null) return;
        await ref.putFile(File(path), metadata);
      }
      final url = await ref.getDownloadURL();

      await _setVideoUrlForRoom(
        roomId: roomId,
        url: url,
        source: 'storage',
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to upload video. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .snapshots(),
      builder: (context, snapshot) {
        // ── Loading ──────────────────────────────────────────────
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: p.bg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(p.gold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Joining room…",
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 15,
                      color: p.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Room not found ───────────────────────────────────────
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: p.bg,
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: p.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: p.border),
                    ),
                    child: Icon(
                      Icons.meeting_room_outlined,
                      color: p.textSecondary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Room not found",
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This room may have ended or never existed.",
                    style: TextStyle(
                      fontSize: 13.5,
                      color: p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snapshot.data!.data()!;
        final hostId = data['hostId'] as String?;
        final isHost = currentUser != null && currentUser.uid == hostId;
        final title = widget.roomName ?? 'Room ${widget.roomId}';

        return Scaffold(
          backgroundColor: p.bg,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────────
                _TopBar(
                  title: title,
                  roomId: widget.roomId,
                  isHost: isHost,
                  codeCopied: _codeCopied,
                  onCopy: _copyRoomCode,
                  onChangeVideo: isHost
                      ? () => _showChangeVideoSheet(widget.roomId)
                      : null,
                ),

                // ── Divider ────────────────────────────────────
                Container(height: 1, color: p.border),

                // ── Video player ───────────────────────────────
                Expanded(
                  flex: 2,
                  child: VideoPlayerWidget(
                    roomId: widget.roomId,
                    isHost: isHost,
                  ),
                ),

                // ── Chat divider ───────────────────────────────
                const _ChatDivider(),

                // ── Chat ───────────────────────────────────────
                Expanded(
                  flex: 3,
                  child: ChatWidget(roomId: widget.roomId),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Top Bar ────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final String roomId;
  final bool isHost;
  final bool codeCopied;
  final VoidCallback onCopy;
  final VoidCallback? onChangeVideo;

  const _TopBar({
    required this.title,
    required this.roomId,
    required this.isHost,
    required this.codeCopied,
    required this.onCopy,
    this.onChangeVideo,
  });

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    
    return Container(
      color: p.bg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: p.surface,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: p.border),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: p.textSecondary,
                size: 12,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Logo mark
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: p.gold,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(Icons.play_arrow_rounded, color: p.bg, size: 15),
          ),

          const SizedBox(width: 7),

          // Title — Flexible lets it shrink when chips need space
          Flexible(
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

          const SizedBox(width: 6),

          // Room code chip (tap to copy) — max-width cap prevents overflow
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 105),
            child: GestureDetector(
              onTap: onCopy,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: codeCopied ? p.gold.withValues(alpha: 0.15) : p.surfaceAlt,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: codeCopied ? p.gold.withValues(alpha: 0.5) : p.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      codeCopied ? Icons.check_rounded : Icons.tag_rounded,
                      size: 11,
                      color: codeCopied ? p.gold : p.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        codeCopied ? 'Copied!' : roomId,
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: codeCopied ? p.gold : p.textPrimary,
                          letterSpacing: codeCopied ? 0.2 : 1.8,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 5),

          // Host / Viewer + change video (host only)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isHost ? p.gold.withValues(alpha: 0.12) : p.surfaceAlt,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: isHost ? p.gold.withValues(alpha: 0.35) : p.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHost
                          ? Icons.star_rounded
                          : Icons.person_outline_rounded,
                      size: 11,
                      color: isHost ? p.gold : p.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHost ? 'Host' : 'Viewer',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isHost ? p.gold : p.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              if (isHost && onChangeVideo != null) ...[
                const SizedBox(width: 5),
                // Icon-only: saves ~80px vs text button, tooltip on long-press
                Tooltip(
                  message: 'Change video',
                  child: GestureDetector(
                    onTap: onChangeVideo,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: p.surfaceAlt,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: p.border),
                      ),
                      child: Icon(
                        Icons.video_library_rounded,
                        size: 15,
                        color: p.gold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ── Chat section divider ───────────────────────────────────────────────────────
class _ChatDivider extends StatelessWidget {
  const _ChatDivider();

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    
    return Container(
      color: p.surface,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              color: p.textSecondary, size: 15),
          const SizedBox(width: 8),
          Text(
            "Live Chat",
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: p.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(width: 8),
          // Live dot
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
