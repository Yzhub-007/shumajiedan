import 'package:shared_preferences/shared_preferences.dart';

/// Token 与身份的本地持久化。
class TokenStorage {
  TokenStorage._();

  static late final SharedPreferences _prefs;
  static const String _kAccess = 'auth.access_token';
  static const String _kRefresh = 'auth.refresh_token';
  static const String _kRole = 'auth.role';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static String? get accessToken => _prefs.getString(_kAccess);

  static String? get refreshToken => _prefs.getString(_kRefresh);

  /// CUSTOMER / ENGINEER
  static String? get role => _prefs.getString(_kRole);

  static Future<void> save({
    required String accessToken,
    required String refreshToken,
    required String role,
  }) async {
    await _prefs.setString(_kAccess, accessToken);
    await _prefs.setString(_kRefresh, refreshToken);
    await _prefs.setString(_kRole, role);
  }

  static Future<void> clear() async {
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kRole);
  }
}
