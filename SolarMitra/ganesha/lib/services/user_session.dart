// lib/services/user_session.dart
import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  static const String _loggedInUserKey = 'loggedInUsername';
  static SharedPreferences? _prefs;

  static Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> loginUser(String username) async {
    await _initPrefs();
    await _prefs!.setString(_loggedInUserKey, username);
  }

  static Future<void> logoutUser() async {
    await _initPrefs();
    await _prefs!.remove(_loggedInUserKey);
  }

  static Future<String?> getLoggedInUsername() async {
    await _initPrefs();
    return _prefs!.getString(_loggedInUserKey);
  }

  static Future<bool> isLoggedIn() async {
    final username = await getLoggedInUsername();
    return username != null;
  }
}