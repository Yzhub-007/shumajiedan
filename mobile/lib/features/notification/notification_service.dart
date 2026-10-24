import 'dart:async';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';

/// 工单实时消息（计划书 5.1.5 / 任务 3.2.8）。
///
/// 后端为 STOMP over WebSocket（端点 /ws，主题 /topic/order/{orderId}）。
/// 当前为裸 WebSocket 连接占位：
/// TODO(3.2.8) 引入 stomp_dart_client 完成 SUBSCRIBE/UNSUBSCRIBE 帧与自动重连，
/// 并在 App 退后台时降级为系统推送（极光/厂商通道）。
class OrderSocketService {
  OrderSocketService._();
  static final OrderSocketService instance = OrderSocketService._();

  WebSocketChannel? _channel;
  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get messages => _controller.stream;

  void connect() {
    final token = TokenStorage.accessToken;
    if (token == null || _channel != null) return;
    _channel = WebSocketChannel.connect(Uri.parse(AppConfig.wsUrl));
    _channel!.stream.listen(
      (data) {
        // STOMP 文本帧解析留给 stomp_dart_client（见 TODO）
        if (data is String && data.startsWith('{')) {
          // 简化：仅处理 JSON 心跳/消息占位
        }
      },
      onError: (_) => reconnect(),
      onDone: () => reconnect(),
    );
  }

  void reconnect() {
    _channel = null;
    Future.delayed(const Duration(seconds: 5), connect);
  }

  void dispose() {
    _channel?.sink.close();
    _channel = null;
    _controller.close();
  }
}
