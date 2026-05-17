import 'package:flutter/material.dart';
import '../../Screens/home_screen.dart';
import '../../services/auth_preferences.dart';
import 'auth_service.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _staySignedIn = true;

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
  Color get _borderFocus => const Color(0xFFCBA869);

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
    _loadStaySignedInPreference();
  }

  Future<void> _loadStaySignedInPreference() async {
    final value = await AuthPreferences.getStaySignedIn();
    if (mounted) setState(() => _staySignedIn = value);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showDialog(
          "Missing Information", "Please enter your email and password.");
      return;
    }

    setState(() => _isLoading = true);

    final res = await AuthService().login(email, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res == "Login Successful") {
      await AuthPreferences.setStaySignedIn(_staySignedIn);
      await _showDialog("Welcome back.", "You have signed in successfully.");
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      _showDialog("Authentication Failed",
          res ?? "Something went wrong. Please try again.");
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
              // Accent line
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
          // ── Subtle background mesh ──────────────────────────────
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 360,
              height: 360,
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
            bottom: -100,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
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
                      const SizedBox(height: 30),

                      // ── Logo / Wordmark ──────────────────────
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: _gold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: _bg,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "WatchTogether",
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: _textPrimary,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 64),

                      // ── Heading ──────────────────────────────
                      Text(
                        "Welcome\nback.",
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
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
                        "Sign in to continue your experience.",
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSecondary,
                          letterSpacing: 0.2,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 48),

                      // ── Card ─────────────────────────────────
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

                            const SizedBox(height: 10),

                            // Forgot password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "Forgot password?",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: _gold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            _StaySignedInRow(
                              value: _staySignedIn,
                              onChanged: (v) =>
                                  setState(() => _staySignedIn = v),
                              gold: _gold,
                              textPrimary: _textPrimary,
                              textSecondary: _textSecondary,
                              border: _border,
                              surfaceAlt: _surfaceAlt,
                            ),

                            const SizedBox(height: 24),

                            // Sign In Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleLogin,
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
                                        "Sign In",
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

                      const SizedBox(height: 32),

                      // ── Sign Up link ─────────────────────────
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "New to WatchTogether?  ",
                              style: TextStyle(
                                fontSize: 13.5,
                                color: _textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SignupScreen()),
                              ),
                              child: Text(
                                "Create account",
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

                      const SizedBox(height: 40),

                      // ── Divider + Social hint (optional) ─────
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: _border,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              "or continue with",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: _textSecondary.withOpacity(0.6),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: _border,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Google / Apple social buttons
                      Row(
                        children: [
                          Expanded(
                            child: _SocialButton(
                              icon: Icons.g_mobiledata_rounded,
                              label: "Google",
                              onTap: () {},
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _SocialButton(
                              icon: Icons.apple_rounded,
                              label: "Apple",
                              onTap: () {},
                            ),
                          ),
                        ],
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

class _StaySignedInRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color gold;
  final Color textPrimary;
  final Color textSecondary;
  final Color border;
  final Color surfaceAlt;

  const _StaySignedInRow({
    required this.value,
    required this.onChanged,
    required this.gold,
    required this.textPrimary,
    required this.textSecondary,
    required this.border,
    required this.surfaceAlt,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: value ? gold.withValues(alpha: 0.15) : surfaceAlt,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: value ? gold : border,
                    width: value ? 1.5 : 1,
                  ),
                ),
                child: value
                    ? Icon(Icons.check_rounded, size: 16, color: gold)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Stay signed in',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Text(
                'Skip login next time',
                style: TextStyle(
                  fontSize: 11.5,
                  color: textSecondary,
                  letterSpacing: 0.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    // Get colors from theme or define them locally
    final Color borderColor = _focused
        ? const Color(0xFFCBA869) // Gold color
        : const Color(0xFF2A2F3E); // Dark border
    final Color iconColor =
        _focused ? const Color(0xFFCBA869) : const Color(0xFF3E4455);
    final Color shadowColor = _focused
        ? const Color(0xFFCBA869).withOpacity(0.12)
        : Colors.transparent;

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: AnimatedContainer(
        // Remove 'const' keyword
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0F14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: _focused ? 1.5 : 1,
          ),
          boxShadow: _focused
              ? [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 12,
                    spreadRadius: 0,
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
              color: iconColor,
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

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SocialButton({
    // Remove 'const' keyword
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF161A23),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2F3E)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF8A8FA0), size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF8A8FA0),
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
