import 'package:flutter/material.dart';

import 'auth/auth_service.dart';
import 'auth/login_screen.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';
import '../utils/theme_notifier.dart';

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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    final p = _Palette.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: p.surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 2,
                color: p.gold,
                margin: const EdgeInsets.only(bottom: 14),
              ),
              Text(
                'Sign out?',
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: p.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will need to sign in again to use WatchTogether.',
                style: TextStyle(
                  fontSize: 14,
                  color: p.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: p.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: TextButton.styleFrom(foregroundColor: p.gold),
                    child: const Text(
                      'Sign out',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);

    final error = await AuthService().signOut();

    if (!mounted) return;
    setState(() => _isLoggingOut = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: p.surfaceAlt,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: p.border),
          ),
          content: Text(error, style: TextStyle(color: p.textPrimary)),
        ),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    final themeNotifier = ThemeProvider.of(context);
    final isDark = themeNotifier.isDark;

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          // ── Background glows ───────────────────────────────────
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    p.gold.withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
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
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3D5AFE).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                // Ensure content is at least as tall as the screen
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

                        // ── Top bar ──────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
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
                            Row(
                              children: [
                                _TopBarIconButton(
                                  palette: p,
                                  icon: isDark
                                      ? Icons.light_mode_rounded
                                      : Icons.dark_mode_rounded,
                                  tooltip: isDark
                                      ? 'Light mode'
                                      : 'Dark mode',
                                  onTap: themeNotifier.toggleTheme,
                                ),
                                const SizedBox(width: 8),
                                _TopBarIconButton(
                                  palette: p,
                                  icon: Icons.logout_rounded,
                                  tooltip: 'Sign out',
                                  onTap: _isLoggingOut ? null : _handleLogout,
                                  isLoading: _isLoggingOut,
                                ),
                              ],
                            ),
                          ],
                        ),

                        const Spacer(flex: 2),

                        // ── Hero section ─────────────────────────────
                        const Row(
                          children: [
                            _GlowIcon(icon: Icons.movie_outlined, delay: 0),
                            SizedBox(width: 10),
                            _GlowIcon(icon: Icons.people_outline_rounded, delay: 1),
                            SizedBox(width: 10),
                            _GlowIcon(icon: Icons.live_tv_outlined, delay: 2),
                          ],
                        ),

                        const SizedBox(height: 28),

                        Text(
                          "Watch together,\nanywhere.",
                          style: TextStyle(
                            fontFamily: 'Georgia',
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            color: p.textPrimary,
                            height: 1.15,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Gold underline accent
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 2.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [p.gold, p.goldLight],
                                ),
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
                          "Create a new room or join an existing one\nto watch together in real time.",
                          style: TextStyle(
                            fontSize: 14,
                            color: p.textSecondary,
                            letterSpacing: 0.2,
                            height: 1.65,
                          ),
                        ),

                        const Spacer(flex: 3),

                        // ── Action Cards ─────────────────────────────
                        _ActionCard(
                          icon: Icons.add_circle_outline_rounded,
                          title: "Create Room",
                          subtitle: "Start a new watch party",
                          isPrimary: true,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreateRoomScreen()),
                          ),
                        ),

                        const SizedBox(height: 14),

                        _ActionCard(
                          icon: Icons.meeting_room_outlined,
                          title: "Join Room",
                          subtitle: "Enter with a room code",
                          isPrimary: false,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const JoinRoomScreen()),
                          ),
                        ),

                        const SizedBox(height: 36),
                      ],
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

class _TopBarIconButton extends StatelessWidget {
  final _Palette palette;
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool isLoading;

  const _TopBarIconButton({
    required this.palette,
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: palette.surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.border),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          palette.gold,
                        ),
                      ),
                    )
                  : Icon(icon, color: palette.textSecondary, size: 18),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Glow Icon chip ─────────────────────────────────────────────────────────────
class _GlowIcon extends StatelessWidget {
  final IconData icon;
  final int delay;

  const _GlowIcon({required this.icon, required this.delay});

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: p.border),
      ),
      child: Icon(
        icon,
        color: p.gold.withValues(alpha: 0.75),
        size: 20,
      ),
    );
  }
}

// ── Action Card ────────────────────────────────────────────────────────────────
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.isPrimary
            ? _PrimaryCard(
                icon: widget.icon,
                title: widget.title,
                subtitle: widget.subtitle,
              )
            : _SecondaryCard(
                icon: widget.icon,
                title: widget.title,
                subtitle: widget.subtitle,
              ),
      ),
    );
  }
}

class _PrimaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PrimaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    
    // Primary card stays "gold" mostly, but text needs to read well.
    // In light mode, its text can stay dark since gold is light.
    const cardTextCol = Color(0xFF0D0F14); 

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.gold, p.goldLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: p.gold.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cardTextCol, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: cardTextCol,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: cardTextCol.withValues(alpha: 0.6),
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: cardTextCol,
            size: 14,
          ),
        ],
      ),
    );
  }
}

class _SecondaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SecondaryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: p.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: p.gold.withValues(alpha: 0.2),
              ),
            ),
            child: Icon(
              icon,
              color: p.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: p.textSecondary,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: p.textSecondary,
            size: 14,
          ),
        ],
      ),
    );
  }
}
