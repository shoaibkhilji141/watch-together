import 'package:shared_preferences/shared_preferences.dart';

/// Persists whether the user wants to remain signed in across app launches.
class AuthPreferences {
  static const String _staySignedInKey = 'stay_signed_in';

  static Future<bool> getStaySignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_staySignedInKey) ?? true;
  }

  static Future<void> setStaySignedIn(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_staySignedInKey, value);
  }
}
