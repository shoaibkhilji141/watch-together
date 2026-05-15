import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier extends ChangeNotifier {
  static const String _themePrefKey = 'themeMode';
  
  // Default to Dark Mode as per requirements
  ThemeMode _themeMode = ThemeMode.dark;
  
  ThemeNotifier() {
    _loadTheme();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggleTheme() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    _saveTheme();
    notifyListeners();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLightSaved = prefs.getBool(_themePrefKey);
      
      // If a preference exists, use it. Otherwise, default dark.
      if (isLightSaved == true) {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.dark;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load theme preference: $e');
    }
  }

  Future<void> _saveTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_themePrefKey, _themeMode == ThemeMode.light);
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
    }
  }
}

class ThemeProvider extends InheritedNotifier<ThemeNotifier> {
  const ThemeProvider({
    super.key,
    required ThemeNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeNotifier of(BuildContext context) {
    final provider = context.dependOnInheritedWidgetOfExactType<ThemeProvider>();
    assert(provider != null, 'No ThemeProvider found in context');
    return provider!.notifier!;
  }
}
