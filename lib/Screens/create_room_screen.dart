import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'watch_screen.dart';

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

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen>
    with SingleTickerProviderStateMixin {
  bool _isCreating = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('You must be logged in to create a room.');
      return;
    }

    setState(() => _isCreating = true);

    try {
      final random = Random.secure();
      final intCode = 100000 + random.nextInt(900000);
      final roomCode = intCode.toString();

      await FirebaseFirestore.instance.collection('rooms').doc(roomCode).set({
        'hostId': user.uid,
        'status': 'active',
        'currentTime': 0,
        'isPlaying': false,
        'videoType': 'direct',
        'videoUrl':
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
        'videoSource': 'network',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WatchScreen(roomId: roomCode),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showSnack(e.message ?? 'Failed to create room. Please try again.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  void _showSnack(String message) {
    final p = _Palette.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: p.surfaceAlt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: p.border),
        ),
        content: Text(
          message,
          style: TextStyle(color: p.textPrimary, fontSize: 13.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          // ── Background glows ─────────────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  p.gold.withValues(alpha: 0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFF3D5AFE).withValues(alpha: 0.06),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ── Content ──────────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 24),

                            // ── Top bar ────────────────────────────
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: p.surface,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: p.border),
                                    ),
                                    child: Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: p.textSecondary,
                                      size: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: p.gold,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                    Icons.play_arrow_rounded,
                                    color: p.bg,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  "WatchTogether",
                                  style: TextStyle(
                                    fontFamily: 'Georgia',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: p.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),

                            const Spacer(flex: 2),

                            // ── Hero icon ─────────────────────────
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: p.surface,
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: p.border),
                                boxShadow: [
                                  BoxShadow(
                                    color: p.gold.withValues(alpha: 0.12),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.add_circle_outline_rounded,
                                color: p.gold,
                                size: 30,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── Heading ───────────────────────────
                            Text(
                              "Start a new\nwatch party.",
                              style: TextStyle(
                                fontFamily: 'Georgia',
                                fontSize: 38,
                                fontWeight: FontWeight.w700,
                                color: p.textPrimary,
                                height: 1.15,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 10),

                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                        colors: [p.gold, p.goldLight]),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 2.5,
                                  decoration: BoxDecoration(
                                    color: p.gold.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 14),

                            Text(
                              "We'll generate a unique 6‑digit code that\nyou can share with friends.",
                              style: TextStyle(
                                fontSize: 14,
                                color: p.textSecondary,
                                height: 1.65,
                                letterSpacing: 0.2,
                              ),
                            ),

                            const Spacer(flex: 2),

                            // ── Info card ─────────────────────────
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: p.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: p.border),
                              ),
                              child: const Column(
                                children: [
                                  _InfoRow(
                                    icon: Icons.tag_rounded,
                                    label: "Unique 6-digit room code",
                                  ),
                                  SizedBox(height: 14),
                                  _InfoRow(
                                    icon: Icons.share_outlined,
                                    label: "Share instantly with friends",
                                  ),
                                  SizedBox(height: 14),
                                  _InfoRow(
                                    icon: Icons.sync_rounded,
                                    label: "Synced playback in real time",
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(flex: 1),

                            // ── CTA Button ────────────────────────
                            _CreateButton(
                              isCreating: _isCreating,
                              onTap: _isCreating ? null : _handleCreateRoom,
                            ),

                            const SizedBox(height: 36),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Row ───────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: p.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: p.gold.withValues(alpha: 0.18),
            ),
          ),
          child: Icon(icon, color: p.gold, size: 17),
        ),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: p.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ── Create Button ──────────────────────────────────────────────────────────────
class _CreateButton extends StatefulWidget {
  final bool isCreating;
  final VoidCallback? onTap;

  const _CreateButton({required this.isCreating, required this.onTap});

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    const cardTextCol = Color(0xFF0D0F14);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            gradient: widget.isCreating
                ? null
                : LinearGradient(
                    colors: [p.gold, p.goldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.isCreating ? p.gold.withValues(alpha: 0.35) : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isCreating
                ? []
                : [
                    BoxShadow(
                      color: p.gold.withValues(alpha: 0.28),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isCreating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        cardTextCol,
                      ),
                    ),
                  )
                : const Text(
                    "Create Room",
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: cardTextCol,
                      letterSpacing: 0.8,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
