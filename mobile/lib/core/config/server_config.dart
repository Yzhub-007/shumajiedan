import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

/// 服务器地址：可在登录页"服务器设置"中修改并持久化。
/// 场景：校园网 DHCP 会轮换电脑 IP，App 内改地址即可，无需重新打包。
class ServerConfig {
  ServerConfig._();

  static const String _key = 'server.base_url';

  static String? _cached;

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _cached = prefs.getString(_key);
  }

  /// 当前生效的 API 地址（未手动设置时用构建期默认值）
  static String get baseUrl => _cached ?? AppConfig.apiBaseUrl;

  static String get wsUrl => '${baseUrl.replaceFirst(RegExp('^http'), 'ws')}/ws';

  static Future<void> setBaseUrl(String url) async {
    var trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, trimmed);
    _cached = trimmed;
  }
}
