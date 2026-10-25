/// 环境配置。所有地址均可在构建时用 --dart-define 覆盖（不改变量默认值）。
class AppConfig {
  AppConfig._();

  /// 后端 API 地址
  /// - Android 模拟器默认 10.0.2.2（即宿主机）
  /// - 真机构建：flutter build apk --dart-define=API_BASE_URL=http://<电脑局域网IP>:8080
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// WebSocket（STOMP）地址，订阅 /topic/order/{orderId}
  static const String wsUrl = String.fromEnvironment(
    'WS_URL',
    defaultValue: 'ws://10.0.2.2:8080/ws',
  );

  /// 高德地图 Android Key / iOS Key（TODO(1.3.1) 高德开放平台申请后填入）
  static const String amapAndroidKey = '';
  static const String amapIosKey = '';
}
