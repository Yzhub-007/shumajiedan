import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../core/config/app_config.dart';
import '../../core/storage/token_storage.dart';

/// 工单实时事件（STOMP over WebSocket，计划书 3.2.8 / 5.1.5）。
/// 订阅 /topic/order/{orderId}，收到状态变更后回调（页面据此自动刷新）。
/// 断线自动重连并在 onConnect 后重新订阅。
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  StompClient? _client;
  final Map<String, List<void Function(Map<String, dynamic>)>> _handlers = {};

  void subscribeOrder(int orderId, void Function(Map<String, dynamic>) handler) {
    _handlers.putIfAbsent('/topic/order/$orderId', () => []).add(handler);
    _ensureConnected();
  }

  void unsubscribeOrder(int orderId) {
    _handlers.remove('/topic/order/$orderId');
  }

  void _ensureConnected() {
    if (_client != null) return;
    final token = TokenStorage.accessToken;
    _client = StompClient(
      config: StompConfig(
        url: AppConfig.wsUrl,
        stompConnectHeaders:
            token == null ? null : {'Authorization': 'Bearer $token'},
        reconnectDelay: const Duration(seconds: 5),
        onConnect: (_) => _resubscribeAll(),
        onStompError: (_) {},
        onWebSocketError: (_) {},
      ),
    );
    _client!.activate();
  }

  void _resubscribeAll() {
    final client = _client;
    if (client == null) return;
    _handlers.forEach((destination, handlers) {
      client.subscribe(destination: destination, callback: (frame) {
        final body = frame.body;
        if (body == null || !body.startsWith('{')) return;
        try {
          final event = jsonDecode(body) as Map<String, dynamic>;
          for (final handler in List.of(handlers)) {
            handler(event);
          }
        } catch (_) {
          // 非法帧忽略
        }
      });
    });
  }

  void dispose() {
    _client?.deactivate();
    _client = null;
    _handlers.clear();
  }
}
