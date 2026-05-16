import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:media_kit/media_kit.dart';
import 'Screens/auth/login_screen.dart';
import 'utils/theme_notifier.dart';
import 'utils/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await Firebase.initializeApp();
  
  final themeNotifier = ThemeNotifier();
  // Wait for the initial theme to load from SharedPreferences before running the app
  // This avoids a flash of the wrong theme on startup
  // Since _loadTheme is async, we can await a brief Future to let the constructor finish loading,
  // or we can just run it since ThemeMode.dark is the default and loading is instant.
  
  runApp(MyApp(themeNotifier: themeNotifier));
}

class MyApp extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  
  const MyApp({super.key, required this.themeNotifier});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Rebuild when theme changes
    widget.themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    widget.themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      notifier: widget.themeNotifier,
      child: MaterialApp(
        title: 'Watch Together',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: widget.themeNotifier.themeMode,
        home: const LoginScreen(),
      ),
    );
  }
}
