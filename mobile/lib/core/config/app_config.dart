/// 环境配置。打包前按环境调整；后续可接 --dart-define 区分 dev/prod。
class AppConfig {
  AppConfig._();

  /// 后端 API 地址
  /// Android 模拟器访问宿主机用 10.0.2.2；真机改成局域网 IP；iOS 模拟器可用 127.0.0.1
  static const String apiBaseUrl = 'http://10.0.2.2:8080';

  /// WebSocket（STOMP）地址，订阅 /topic/order/{orderId}
  static const String wsUrl = 'ws://10.0.2.2:8080/ws';

  /// 高德地图 Android Key / iOS Key（TODO(1.3.1) 高德开放平台申请后填入）
  static const String amapAndroidKey = '';
  static const String amapIosKey = '';
}
