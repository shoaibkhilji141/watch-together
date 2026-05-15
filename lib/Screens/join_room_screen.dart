import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final Color error;

  const _Palette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.gold,
    required this.goldLight,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.error,
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
        error: Color(0xFFD32F2F),
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
      error: Color(0xFFE57373),
    );
  }
}

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _roomCodeController = TextEditingController();
  bool _isJoining = false;
  String? _fieldError;

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
    _roomCodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleJoinRoom() async {
    // inline validation
    final value = _roomCodeController.text.trim();
    if (value.isEmpty) {
      setState(() => _fieldError = 'Please enter a room code');
      return;
    }
    if (value.length != 6) {
      setState(() => _fieldError = 'Room code must be 6 digits');
      return;
    }
    if (int.tryParse(value) == null) {
      setState(() => _fieldError = 'Room code must be numbers only');
      return;
    }
    setState(() => _fieldError = null);

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isJoining = true);

    final code = value;

    try {
      final doc =
          await FirebaseFirestore.instance.collection('rooms').doc(code).get();

      if (!mounted) return;

      if (doc.exists) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => WatchScreen(roomId: code)),
        );
      } else {
        _showSnack('No room found with that code.');
      }
    } on FirebaseException catch (e) {
      if (!mounted) return;
      _showSnack(e.message ?? 'Failed to join room. Please try again.');
    } catch (_) {
      if (!mounted) return;
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isJoining = false);
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
            left: -80,
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
            right: -60,
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 24),

                              // ── Top bar ──────────────────────────
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

                              // ── Hero icon ────────────────────────
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
                                  Icons.meeting_room_outlined,
                                  color: p.gold,
                                  size: 28,
                                ),
                              ),

                              const SizedBox(height: 28),

                              // ── Heading ──────────────────────────
                              Text(
                                "Join a\nwatch party.",
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
                                "Enter the 6‑digit code shared by\nyour host to join instantly.",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: p.textSecondary,
                                  height: 1.65,
                                  letterSpacing: 0.2,
                                ),
                              ),

                              const Spacer(flex: 2),

                              // ── Code input card ──────────────────
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: p.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: p.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.05),
                                      blurRadius: 32,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "ROOM CODE",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: p.textSecondary,
                                        letterSpacing: 1.0,
                                        fontFamily: 'sans-serif',
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    // Styled code field
                                    _CodeInputField(
                                      controller: _roomCodeController,
                                      error: _fieldError,
                                      onChanged: (_) {
                                        if (_fieldError != null) {
                                          setState(() => _fieldError = null);
                                        }
                                      },
                                    ),

                                    if (_fieldError != null) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.error_outline_rounded,
                                              color: p.error, size: 14),
                                          const SizedBox(width: 6),
                                          Text(
                                            _fieldError!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: p.error,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    const SizedBox(height: 22),

                                    // Hint row
                                    Row(
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: p.gold.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                                color: p.gold.withValues(alpha: 0.18)),
                                          ),
                                          child: Icon(
                                              Icons.info_outline_rounded,
                                              color: p.gold,
                                              size: 14),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Ask your host for the 6-digit code",
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            color: p.textSecondary,
                                            letterSpacing: 0.1,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const Spacer(flex: 1),

                              // ── CTA button ───────────────────────
                              _JoinButton(
                                isJoining: _isJoining,
                                onTap: _isJoining ? null : _handleJoinRoom,
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
          ),
        ],
      ),
    );
  }
}

// ── Code Input Field ───────────────────────────────────────────────────────────
class _CodeInputField extends StatefulWidget {
  final TextEditingController controller;
  final String? error;
  final ValueChanged<String>? onChanged;

  const _CodeInputField({
    required this.controller,
    required this.error,
    this.onChanged,
  });

  @override
  State<_CodeInputField> createState() => _CodeInputFieldState();
}

class _CodeInputFieldState extends State<_CodeInputField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final p = _Palette.of(context);
    
    final borderColor = widget.error != null
        ? p.error
        : _focused
            ? p.gold
            : p.border;
    final iconColor = widget.error != null
        ? p.error
        : _focused
            ? p.gold
            : p.textSecondary;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: _focused || widget.error != null ? 1.5 : 1,
          ),
          boxShadow: _focused && widget.error == null
              ? [
                  BoxShadow(
                    color: p.gold.withValues(alpha: 0.12),
                    blurRadius: 12,
                  )
                ]
              : widget.error != null
                  ? [
                      BoxShadow(
                        color: p.error.withValues(alpha: 0.1),
                        blurRadius: 10,
                      )
                    ]
                  : [],
        ),
        child: TextFormField(
          controller: widget.controller,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textInputAction: TextInputAction.done,
          onChanged: widget.onChanged,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            color: p.textPrimary,
            fontSize: 22,
            fontFamily: 'Georgia',
            letterSpacing: 8,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: '------',
            hintStyle: TextStyle(
              color: p.textSecondary.withValues(alpha: 0.5),
              fontSize: 22,
              letterSpacing: 8,
              fontWeight: FontWeight.w700,
            ),
            prefixIcon: Icon(Icons.tag_rounded, color: iconColor, size: 20),
            border: InputBorder.none,
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a room code';
            }
            if (value.trim().length != 6) return 'Room code must be 6 digits';
            if (int.tryParse(value.trim()) == null) {
              return 'Room code must be numbers only';
            }
            return null;
          },
        ),
      ),
    );
  }
}

// ── Join Button ────────────────────────────────────────────────────────────────
class _JoinButton extends StatefulWidget {
  final bool isJoining;
  final VoidCallback? onTap;

  const _JoinButton({required this.isJoining, required this.onTap});

  @override
  State<_JoinButton> createState() => _JoinButtonState();
}

class _JoinButtonState extends State<_JoinButton> {
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
            gradient: widget.isJoining
                ? null
                : LinearGradient(
                    colors: [p.gold, p.goldLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: widget.isJoining
                ? p.gold.withValues(alpha: 0.35)
                : null,
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isJoining
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
            child: widget.isJoining
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
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login_rounded,
                          color: cardTextCol, size: 18),
                      SizedBox(width: 10),
                      Text(
                        "Join Room",
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: cardTextCol,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
