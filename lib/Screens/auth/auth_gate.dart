import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/auth_preferences.dart';
import '../home_screen.dart';
import 'login_screen.dart';

/// Routes to [HomeScreen] when a persisted session is allowed, otherwise [LoginScreen].
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Widget? _screen;

  @override
  void initState() {
    super.initState();
    _resolveInitialRoute();
  }

  Future<void> _resolveInitialRoute() async {
    final staySignedIn = await AuthPreferences.getStaySignedIn();
    var user = FirebaseAuth.instance.currentUser;

    if (!staySignedIn && user != null) {
      await FirebaseAuth.instance.signOut();
      user = null;
    }

    if (!mounted) return;
    setState(() {
      _screen = user != null ? const HomeScreen() : const LoginScreen();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_screen != null) return _screen!;

    final isLight = Theme.of(context).brightness == Brightness.light;
    final bg = isLight ? const Color(0xFFF8F9FA) : const Color(0xFF0D0F14);
    const gold = Color(0xFFCBA869);

    return Scaffold(
      backgroundColor: bg,
      body: const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(gold),
          ),
        ),
      ),
    );
  }
}
