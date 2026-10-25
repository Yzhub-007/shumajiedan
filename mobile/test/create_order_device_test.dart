import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repairhub_app/core/network/api_client.dart';
import 'package:repairhub_app/core/storage/token_storage.dart';
import 'package:repairhub_app/features/customer/screens/create_order_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 发单页设备类型：手动输入 + 历史记忆推荐（类型/品牌/型号一键填充）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await TokenStorage.init();
  });

  late _FakeApi fake;

  setUp(() => fake = _FakeApi());

  Future<void> openScreen(WidgetTester tester) async {
    // 发单页较长，默认 600px 视口下 ListView 不构建折叠区外的推荐 chips
    await tester.binding.setSurfaceSize(const Size(800, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(fake)],
      child: MaterialApp(
        home: Builder(builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreateOrderScreen())),
                  child: const Text('open'),
                ),
              ),
            )),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('展示历史记忆与常用类型推荐（含二级分类）', (tester) async {
    await openScreen(tester);
    expect(find.text('最近使用'), findsOneWidget);
    expect(find.text('常用类型'), findsOneWidget);
    expect(find.text('注塑机 · 海天 · HT-540'), findsOneWidget);
    expect(find.text('空压机'), findsOneWidget);
    // 二级分类也应被平铺进常用类型（原实现只显示一级）
    expect(find.text('中央空调'), findsOneWidget);
    expect(find.text('立式注塑机'), findsOneWidget);
  });

  testWidgets('点击历史 chip 一键填充类型/品牌/型号', (tester) async {
    await openScreen(tester);
    await tester.tap(find.text('注塑机 · 海天 · HT-540'));
    await tester.pump();
    // 类型输入框 + 字典 chip 各出现一次"注塑机"
    expect(find.text('注塑机'), findsNWidgets(2));
    expect(find.text('海天'), findsOneWidget, reason: '品牌应被自动填充');
    expect(find.text('HT-540'), findsOneWidget, reason: '型号应被自动填充');
  });

  testWidgets('手动输入自定义类型提交：携带输入文本且不带字典 id', (tester) async {
    await openScreen(tester);
    // TextField 顺序：0 设备类型 / 1 品牌 / 2 型号 / 3 故障描述
    await tester.enterText(find.byType(TextField).at(0), '贴片机');
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(3), '主板无法启动');
    await tester.pump();
    await tester.tap(find.text('提交工单'));
    await tester.pumpAndSettle();

    expect(find.text('发布成功，正在为你匹配附近工程师'), findsOneWidget);
    expect(fake.lastOrderPayload?['deviceCategoryInput'], '贴片机');
    expect(fake.lastOrderPayload?['deviceCategoryId'], isNull);
  });

  testWidgets('点选字典 chip 提交：payload 同时携带 id 与文本', (tester) async {
    await openScreen(tester);
    await tester.tap(find.text('中央空调'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(3), '不制冷');
    await tester.pump();
    await tester.tap(find.text('提交工单'));
    await tester.pumpAndSettle();

    expect(find.text('发布成功，正在为你匹配附近工程师'), findsOneWidget);
    expect(fake.lastOrderPayload?['deviceCategoryId'], 12,
        reason: '选中二级分类应回填字典 id');
    expect(fake.lastOrderPayload?['deviceCategoryInput'], '中央空调');
  });
}

class _FakeApi extends ApiClient {
  Map<String, dynamic>? lastOrderPayload;

  @override
  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    switch (path) {
      case '/api/device-categories':
        return [
          {
            'id': 1,
            'name': '注塑机',
            'baseFee': 300,
            'visitFee': 80,
            'children': [
              {'id': 11, 'name': '立式注塑机'},
            ],
          },
          {
            'id': 2,
            'name': '制冷设备',
            'baseFee': 200,
            'visitFee': 60,
            'children': [
              {'id': 12, 'name': '中央空调'},
            ],
          },
        ];
      case '/api/orders/device-history':
        return [
          {
            'deviceType': '注塑机',
            'deviceBrand': '海天',
            'deviceModel': 'HT-540',
            'useCount': 3,
            'lastUsedAt': '2026-10-01T10:00:00',
          },
          {
            'deviceType': '空压机',
            'deviceBrand': '',
            'deviceModel': '',
            'useCount': 1,
            'lastUsedAt': '2026-09-01T10:00:00',
          },
        ];
      case '/api/customer/addresses':
        return [
          {'id': 5, 'label': '公司', 'detail': '科技园1号', 'isDefault': true},
        ];
    }
    return null;
  }

  @override
  Future<dynamic> post(String path, {Object? data}) async {
    if (path == '/api/orders') {
      lastOrderPayload = data is Map<String, dynamic> ? data : null;
      return {'id': 9};
    }
    return null;
  }
}
