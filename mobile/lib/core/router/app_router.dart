import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/customer/screens/create_order_screen.dart';
import '../../features/customer/screens/customer_home_screen.dart';
import '../../features/customer/screens/customer_order_list_screen.dart';
import '../../features/customer/screens/customer_profile_screen.dart';
import '../../features/customer/screens/order_detail_screen.dart';
import '../../features/engineer/screens/engineer_home_screen.dart';
import '../../features/engineer/screens/engineer_order_detail_screen.dart';
import '../../features/engineer/screens/engineer_profile_screen.dart';
import '../../features/engineer/screens/engineer_verify_screen.dart';
import '../../features/notification/screens/notifications_screen.dart';
import '../../shared/models/user_role.dart';
import '../storage/token_storage.dart';

/// 全局路由：登录守卫 + 按身份分流（客户端 / 工程师端）。
final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authControllerProvider);
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final loggingIn = location == '/splash' || location == '/login';
      final loggedIn = auth.loggedIn && TokenStorage.accessToken != null;

      if (!auth.initialized) {
        return loggingIn ? null : '/splash';
      }
      if (loggedIn) {
        if (!loggingIn) return null;
        return auth.role == UserRole.engineer ? '/engineer/home' : '/customer/home';
      }
      return loggingIn ? (location == '/splash' ? '/login' : null) : '/login';
    },
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

      // ---- 工程师端 ----
      GoRoute(path: '/engineer/home', builder: (_, __) => const EngineerHomeScreen()),
      GoRoute(path: '/engineer/verify', builder: (_, __) => const EngineerVerifyScreen()),
      GoRoute(
        path: '/engineer/orders/:id',
        builder: (_, state) =>
            EngineerOrderDetailScreen(orderId: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      ),
      GoRoute(path: '/engineer/profile', builder: (_, __) => const EngineerProfileScreen()),

      // ---- 公共 ----
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    ],
  );
});
