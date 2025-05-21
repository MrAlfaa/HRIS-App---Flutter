import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String USER_ID_KEY = 'userId';
  static const String USERNAME_KEY = 'username';
  static const String IS_LOGGED_IN_KEY = 'isLoggedIn';
  static const String FACE_REGISTERED_KEY = 'faceRegistered';

  // Save user session data
  static Future<void> saveUserSession(
      {required String userId,
      required String username,
      bool faceRegistered = false}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(USER_ID_KEY, userId);
    await prefs.setString(USERNAME_KEY, username);
    await prefs.setBool(IS_LOGGED_IN_KEY, true);
    await prefs.setBool(FACE_REGISTERED_KEY, faceRegistered);
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(IS_LOGGED_IN_KEY) ?? false;
  }

  // Get current user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(USER_ID_KEY);
  }

  // Get current username
  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(USERNAME_KEY);
  }

  // Check if face is registered
  static Future<bool> isFaceRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(FACE_REGISTERED_KEY) ?? false;
  }

  // Set face registered status
  static Future<void> setFaceRegistered(bool status) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(FACE_REGISTERED_KEY, status);
  }

  // Add a method to check if the current user has registered their face
  static Future<bool> checkCurrentUserHasFace() async {
    final prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool(IS_LOGGED_IN_KEY) ?? false;

    if (!isLoggedIn) {
      return false;
    }

    String? userId = prefs.getString(USER_ID_KEY);
    if (userId == null) {
      return false;
    }

    // Check if face is registered for this user
    return prefs.getBool(FACE_REGISTERED_KEY) ?? false;
  }

  // Update the logout method to preserve face registration status
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    bool faceRegistered = prefs.getBool(FACE_REGISTERED_KEY) ?? false;

    await prefs.remove(USER_ID_KEY);
    await prefs.remove(USERNAME_KEY);
    await prefs.setBool(IS_LOGGED_IN_KEY, false);

    // Keep face registration status
    await prefs.setBool(FACE_REGISTERED_KEY, faceRegistered);
  }
}
