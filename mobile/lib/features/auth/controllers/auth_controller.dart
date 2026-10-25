import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/token_storage.dart';
import '../../../shared/models/user_role.dart';
import '../../notification/realtime_service.dart';

class AuthState {
  const AuthState({
    this.initialized = false,
    this.loading = false,
    this.role,
    this.error,
  });

  final bool initialized;
  final bool loading;
  final UserRole? role;
  final String? error;

  bool get loggedIn => role != null;

  AuthState copyWith({
    bool? initialized,
    bool? loading,
    UserRole? role,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      initialized: initialized ?? this.initialized,
      loading: loading ?? this.loading,
      role: role ?? this.role,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 登录态管理：启动恢复 → 验证码登录 → 按身份分流（TODO(2.2.1) 完善登录页交互）。
class AuthController extends StateNotifier<AuthState> {
  AuthController(this._api) : super(const AuthState()) {
    _restore();
  }

  final ApiClient _api;
  final _realtime = RealtimeService.instance;

  void _restore() {
    final role = UserRole.tryParse(TokenStorage.role);
    final hasToken = TokenStorage.accessToken != null;
    state = state.copyWith(initialized: true, role: hasToken ? role : null);
  }

  /// 发送验证码；开发模式返回后端下发的 devCode（生产为 null，走真实短信）
  Future<String?> sendSmsCode(String phone) async {
    final data = await _api.post('/api/auth/sms-code', data: {'phone': phone});
    if (data is Map && data['devCode'] != null) {
      return data['devCode'].toString();
    }
    return null;
  }

  Future<void> login(String phone, String code, UserRole role) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final data = await _api.post('/api/auth/login', data: {
        'phone': phone,
        'code': code,
        'role': role.wireValue,
      }) as Map<String, dynamic>;
      await TokenStorage.save(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
        role: data['role'] as String,
      );
      state = state.copyWith(
        loading: false,
        initialized: true,
        role: UserRole.tryParse(data['role'] as String?),
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, error: '网络异常，请稍后再试');
    }
  }

  Future<void> logout() async {
    // 断开实时通道（内含旧账号的 WebSocket 连接与订阅）
    _realtime.dispose();
    await TokenStorage.clear();
    state = state.copyWith(role: null, initialized: true);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.read(apiClientProvider));
});
