import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/agreement_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/customer/screens/address_manage_screen.dart';
import '../../features/customer/screens/create_order_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/customer/screens/customer_order_list_screen.dart';
import '../../features/customer/screens/customer_profile_screen.dart';
import '../../features/customer/screens/order_detail_screen.dart';
import '../../features/engineer/screens/engineer_home_screen.dart';
import '../../features/engineer/screens/engineer_order_detail_screen.dart';
import '../../features/engineer/screens/engineer_profile_screen.dart';
import '../../features/engineer/screens/engineer_verify_screen.dart';
import '../../features/engineer/screens/engineer_wallet_screen.dart';
import '../../features/notification/screens/notifications_screen.dart';
import '../../shared/models/user_role.dart';
import '../storage/token_storage.dart';

/// 全局路由：登录守卫 + 按身份分流（客户端 / 工程师端）。
/// 注意：GoRouter 只创建一次；登录态变化通过 refreshListenable 触发 redirect
/// 重算。若直接 watch 登录态来重建路由器，会在导航过程中替换整个路由栈，
/// 导致切换账号时白屏。
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final loggingIn = location == '/splash' || location == '/login';
      // 协议页公开可见（登录前需阅读，计划书 5.2.1）
      final publicPage = location.startsWith('/agreement');
      final loggedIn = auth.loggedIn && TokenStorage.accessToken != null;

      if (publicPage) return null;
      if (!auth.initialized) {
        return loggingIn ? null : '/splash';
      }
      if (loggedIn) {
        if (!loggingIn) return null;
        return auth.role == UserRole.engineer ? '/engineer/home' : '/customer/home';
      }
      return loggingIn ? (location == '/splash' ? '/login' : null) : '/login';
    },
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('页面不存在')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text('页面不存在：${state.uri}',
                style: TextStyle(
                    fontSize: 13, color: Theme.of(context).colorScheme.outline)),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.go('/splash'), child: const Text('返回')),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),

      // ---- 客户端 ----
      GoRoute(path: '/customer/home', builder: (_, __) => const CustomerHomeScreen()),
      GoRoute(path: '/customer/create-order', builder: (_, __) => const CreateOrderScreen()),
      GoRoute(path: '/customer/orders', builder: (_, __) => const CustomerOrderListScreen()),
      GoRoute(
        path: '/customer/orders/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      ),
      GoRoute(path: '/customer/profile', builder: (_, __) => const CustomerProfileScreen()),
      GoRoute(path: '/customer/addresses', builder: (_, __) => const AddressManageScreen()),

      // ---- 工程师端 ----
      GoRoute(path: '/engineer/home', builder: (_, __) => const EngineerHomeScreen()),
      GoRoute(path: '/engineer/verify', builder: (_, __) => const EngineerVerifyScreen()),
      GoRoute(
        path: '/engineer/orders/:id',
        builder: (_, state) =>
            EngineerOrderDetailScreen(orderId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      ),
      GoRoute(path: '/engineer/profile', builder: (_, __) => const EngineerProfileScreen()),
      GoRoute(path: '/engineer/wallet', builder: (_, __) => const EngineerWalletScreen()),

      // ---- 公共 ----
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(
          path: '/agreement/terms',
          builder: (_, __) => const AgreementScreen(isPrivacy: false)),
      GoRoute(
          path: '/agreement/privacy',
          builder: (_, __) => const AgreementScreen(isPrivacy: true)),
    ],
  );
});
