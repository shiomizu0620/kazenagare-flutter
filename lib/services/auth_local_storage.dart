import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalData {
  final bool isLoggedIn;
  final bool isGuest;
  final String? email;
  final String? userId;
  final String? loginMethod;
  final int? loggedInAtEpochMs;

  const AuthLocalData({
    required this.isLoggedIn,
    required this.isGuest,
    this.email,
    this.userId,
    this.loginMethod,
    this.loggedInAtEpochMs,
  });

  factory AuthLocalData.empty() {
    return const AuthLocalData(isLoggedIn: false, isGuest: false);
  }
}

class AuthLocalStorage {
  static const String _prefsKeyIsLoggedIn = 'auth.isLoggedIn';
  static const String _prefsKeyIsGuest = 'auth.isGuest';
  static const String _prefsKeyEmail = 'auth.email';
  static const String _prefsKeyUserId = 'auth.userId';
  static const String _prefsKeyMethod = 'auth.method';
  static const String _prefsKeyLoggedInAt = 'auth.loggedInAt';

  Future<AuthLocalData> load() async {
    final prefs = await SharedPreferences.getInstance();

    return AuthLocalData(
      isLoggedIn: prefs.getBool(_prefsKeyIsLoggedIn) ?? false,
      isGuest: prefs.getBool(_prefsKeyIsGuest) ?? false,
      email: prefs.getString(_prefsKeyEmail),
      userId: prefs.getString(_prefsKeyUserId),
      loginMethod: prefs.getString(_prefsKeyMethod),
      loggedInAtEpochMs: prefs.getInt(_prefsKeyLoggedInAt),
    );
  }

  Future<void> saveSignedIn({
    required String userId,
    required String method,
    required bool isGuest,
    String? email,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_prefsKeyIsLoggedIn, true);
    await prefs.setBool(_prefsKeyIsGuest, isGuest);
    await prefs.setString(_prefsKeyUserId, userId);
    await prefs.setString(_prefsKeyMethod, method);
    await prefs.setInt(
      _prefsKeyLoggedInAt,
      DateTime.now().millisecondsSinceEpoch,
    );

    if (email != null && email.trim().isNotEmpty) {
      await prefs.setString(_prefsKeyEmail, email.trim());
    }
  }

  Future<void> saveEmailDraft(String email) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKeyEmail, trimmed);
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_prefsKeyIsLoggedIn, false);
    await prefs.setBool(_prefsKeyIsGuest, false);
    await prefs.remove(_prefsKeyUserId);
    await prefs.remove(_prefsKeyMethod);
    await prefs.remove(_prefsKeyLoggedInAt);
    // メールは入力補助として残す
  }
}
