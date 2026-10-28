import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../../auth/controllers/auth_controller.dart';

/// 客户个人中心：资料、企业信息、地址管理入口（计划书 2.2.5）。
class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data =
          await ref.read(apiClientProvider).get('/api/customer/profile') as Map<String, dynamic>;
      setState(() => _profile = data);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final company = _profile?['companyName']?.toString();
    final phone = _profile?['phone']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 124),
        children: [
          // 资料卡
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.brand, Color(0xFF3E7BC8)],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.business, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company ?? '完善企业信息',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(phone,
                            style: TextStyle(
                                fontSize: 13, color: scheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20, color: scheme.outline),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GroupCard(
            separatorIndent: 60,
            children: [
              ListTile(
                leading: const TintedIconBox(
                    icon: Icons.location_on_outlined, size: 28),
                title: const Text('常用地址'),
                trailing:
                    Icon(Icons.chevron_right, size: 18, color: scheme.outline),
                onTap: () => context.push('/customer/addresses'),
              ),
              ListTile(
                leading: TintedIconBox(
                    icon: Icons.notifications_outlined,
                    color: AppTheme.systemOrange,
                    size: 28),
                title: const Text('消息中心'),
                trailing:
                    Icon(Icons.chevron_right, size: 18, color: scheme.outline),
                onTap: () => context.go('/customer/notifications'),
              ),
              ListTile(
                leading: TintedIconBox(
                    icon: Icons.description_outlined,
                    color: AppTheme.systemTeal,
                    size: 28),
                title: const Text('设备维修档案'),
                subtitle: const Text('设备档案与维修历史，即将上线'),
                trailing:
                    Icon(Icons.chevron_right, size: 18, color: scheme.outline),
                onTap: () {/* TODO(V2.0) 设备档案与维修历史 */},
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 退出登录：独立卡片、红色文案（iOS 风格）
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: scheme.error,
                  textStyle:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                },
                child: const Text('退出登录'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('机器报修 v0.1.0',
                style: TextStyle(fontSize: 11, color: scheme.outline)),
          ),
        ],
      ),
    );
  }
}
