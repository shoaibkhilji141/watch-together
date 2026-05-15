import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirm = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showDialog("Missing Information", "Please fill in all fields.");
      return;
    }

    if (password != confirm) {
      _showDialog("Password Mismatch",
          "Your passwords do not match. Please try again.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await AuthService().signup(email, password);

      if (!mounted) return;

      if (res == "Signup Successful") {
        await _showDialog(
            "Account Created", "Your account has been created successfully.");
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        _showDialog(
            "Signup Failed", res ?? "Something went wrong. Please try again.");
      }
    } catch (e) {
      _showDialog("Error", e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showDialog(String title, String message) {
    return showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 2,
                color: _gold,
                margin: const EdgeInsets.only(bottom: 16),
              ),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Georgia',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: _gold,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text(
                    "Dismiss",
                    style: TextStyle(
                      fontFamily: 'Georgia',
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Background glows ───────────────────────────────────
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _gold.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -50,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3D5AFE).withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main content ───────────────────────────────────────
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // ── Back + Logo row ──────────────────────
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: _border),
                              ),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: _textSecondary,
                                size: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: _bg,
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
                              color: _textPrimary,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 52),

                      // ── Heading ──────────────────────────────
                      Text(
                        "Create your\naccount.",
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
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
                                colors: [_gold, _goldLight],
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: _gold.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Join and start watching together.",
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                          letterSpacing: 0.2,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // ── Form Card ────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _border, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Email
                            const _FieldLabel(label: "Email Address"),
                            const SizedBox(height: 8),
                            _StyledTextField(
                              controller: emailController,
                              hint: "you@example.com",
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: Icons.mail_outline_rounded,
                            ),

                            const SizedBox(height: 22),

                            // Password
                            const _FieldLabel(label: "Password"),
                            const SizedBox(height: 8),
                            _StyledTextField(
                              controller: passwordController,
                              hint: "••••••••••",
                              obscureText: _obscurePassword,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Confirm Password
                            const _FieldLabel(label: "Confirm Password"),
                            const SizedBox(height: 8),
                            _StyledTextField(
                              controller: confirmPasswordController,
                              hint: "••••••••••",
                              obscureText: _obscureConfirm,
                              prefixIcon: Icons.lock_outline_rounded,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Sign Up Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSignup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _gold,
                                  disabledBackgroundColor:
                                      _gold.withOpacity(0.4),
                                  foregroundColor: _bg,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  _bg),
                                        ),
                                      )
                                    : const Text(
                                        "Create Account",
                                        style: TextStyle(
                                          fontFamily: 'Georgia',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // ── Login link ───────────────────────────
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Already have an account?  ",
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                              ),
                              child: Text(
                                "Sign in",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: _gold,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Terms note ───────────────────────────
                      Center(
                        child: Text(
                          "By creating an account you agree to our\nTerms of Service and Privacy Policy.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _textSecondary.withOpacity(0.5),
                            height: 1.7,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
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

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF8A8FA0),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StyledTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final IconData prefixIcon;
  final Widget? suffixIcon;

  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    required this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<_StyledTextField> createState() => _StyledTextFieldState();
}

class _StyledTextFieldState extends State<_StyledTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _focused ? const Color(0xFFCBA869) : const Color(0xFF2A2F3E),
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: const Color(0xFFCBA869).withOpacity(0.12),
                    blurRadius: 12,
                  )
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          style: const TextStyle(
            color: Color(0xFFF0EDE6),
            fontSize: 14.5,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: const TextStyle(
              color: Color(0xFF3E4455),
              fontSize: 14,
            ),
            prefixIcon: Icon(
              widget.prefixIcon,
              color:
                  _focused ? const Color(0xFFCBA869) : const Color(0xFF3E4455),
              size: 19,
            ),
            suffixIcon: widget.suffixIcon,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          ),
        ),
      ),
    );
  }
}
