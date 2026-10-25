import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repairhub_app/app.dart';
import 'package:repairhub_app/core/network/api_client.dart';
import 'package:repairhub_app/core/storage/token_storage.dart';
import 'package:repairhub_app/features/auth/controllers/auth_controller.dart';
import 'package:repairhub_app/features/auth/screens/login_screen.dart';
import 'package:repairhub_app/features/auth/screens/splash_screen.dart';
import 'package:repairhub_app/features/customer/screens/customer_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 复现"验证码登录 → 进入首页"全流程：白屏类问题（页面渲染异常/导航中断）
/// 会在测试中暴露为异常或找不到目标组件。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenStorage.init();
  });

  setUp(() async {
    // 每个用例从"未登录"状态开始（上一用例可能已写入 token）
    await TokenStorage.clear();
  });

  testWidgets('验证码登录成功后进入客户首页', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
      child: const RepairHubApp(),
    ));
    await tester.pump(); // splash
    await tester.pump(const Duration(seconds: 1)); // redirect -> login
    expect(find.text('登录 / 注册'), findsOneWidget);

    // 输入手机号
    await tester.enterText(find.byType(TextField).first, '13700000099');
    await tester.pump();

    // 获取验证码 -> 开发模式弹窗 -> 自动填入
    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    expect(find.text('验证码（开发模式）'), findsOneWidget);
    await tester.tap(find.text('自动填入'));
    await tester.pump();

    // 勾选用户协议（未勾选时点击登录只弹提示）
    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    // 登录 -> 应进入客户首页（白屏则此处找不到组件）
    await tester.tap(find.text('登录 / 注册'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('设备故障？立即报修'), findsOneWidget,
        reason: '登录成功后应进入客户首页；若白屏说明渲染异常');
  });

  testWidgets('登出后重新登录（切换账号场景）', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
      child: const RepairHubApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // 第一次登录
    await tester.enterText(find.byType(TextField).first, '13700000001');
    await tester.pump();
    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    await tester.tap(find.text('自动填入'));
    await tester.pump();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('登录 / 注册'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('设备故障？立即报修'), findsOneWidget);

    // 退出登录：直接触发登出动作，验证 重定向→登录页 这条白屏敏感路径
    final container =
        ProviderScope.containerOf(tester.element(find.text('设备故障？立即报修')));
    await container.read(authControllerProvider.notifier).logout();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    // ignore: avoid_print
    print('DIAG splash=${find.byType(SplashScreen).evaluate().length} '
        'login=${find.byType(LoginScreen).evaluate().length} '
        'home=${find.byType(CustomerHomeScreen).evaluate().length} '
        'loginBtn=${find.text('登录 / 注册').evaluate().length}');
    expect(find.text('登录 / 注册'), findsOneWidget);

    // 第二次登录（切换账号）
    await tester.enterText(find.byType(TextField).first, '13700000002');
    await tester.pump();
    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    await tester.tap(find.text('自动填入'));
    await tester.pump();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('登录 / 注册'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('设备故障？立即报修'), findsOneWidget,
        reason: '切换账号后应再次进入首页；若白屏说明渲染异常');
  });

  testWidgets('工程师身份登录后进入接单大厅（切换身份场景）', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(FakeApiClient())],
      child: const RepairHubApp(),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // 选择工程师身份
    await tester.tap(find.text('我是工程师'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, '13700000002');
    await tester.pump();
    await tester.tap(find.text('获取验证码'));
    await tester.pump();
    await tester.tap(find.text('自动填入'));
    await tester.pump();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.text('登录 / 注册'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('接单大厅'), findsOneWidget,
        reason: '工程师登录后应进入接单大厅；若白屏说明渲染异常');
  });
}

/// 假 API：按路径返回固定数据，模拟后端统一响应结构。
class FakeApiClient extends ApiClient {
  final Map<String, Object Function()> _routes = {
    '/api/auth/sms-code': () => {'devCode': '654321'},
    '/api/auth/login': () => {
          'accessToken': 'fake-access',
          'refreshToken': 'fake-refresh',
          'userId': 1,
          'role': 'CUSTOMER',
          'newUser': false,
        },
    '/api/device-categories': () => [
          {'id': 1, 'name': '注塑机', 'baseFee': 300, 'visitFee': 80}
        ],
    '/api/customer/addresses': () => [],
    '/api/orders': () => {'list': [], 'total': 0, 'page': 1, 'size': 5},
    '/api/engineer/verify-status': () => {
          'verifyStatus': 'APPROVED',
          'onlineStatus': false,
          'realName': '王师傅',
          'ratingAvg': 5.0,
          'orderCount': 0,
        },
    '/api/engineer/orders/pool': () => [],
  };

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    if (path.startsWith('/api/orders/') && path.endsWith('/nearby-count')) {
      return {'count': 3};
    }
    return _routes[path]?.call();
  }

  String lastLoginRole = 'CUSTOMER';

  @override
  Future<dynamic> post(String path, {Object? data}) async {
    if (path == '/api/auth/login') {
      lastLoginRole = (data is Map ? data['role'] as String? : null) ?? 'CUSTOMER';
      return {
        'accessToken': 'fake-access',
        'refreshToken': 'fake-refresh',
        'userId': 1,
        'role': lastLoginRole,
        'newUser': false,
      };
    }
    return _routes[path]?.call();
  }

  @override
  Future<dynamic> put(String path, {Object? data}) async {
    return _routes[path]?.call();
  }

  @override
  Future<dynamic> delete(String path) async {
    return null;
  }
}
