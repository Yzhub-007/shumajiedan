import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_client.dart';
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
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          ListTile(
            leading: const CircleAvatar(child: Icon(Icons.business)),
            title: Text(_profile?['companyName']?.toString() ?? '完善企业信息'),
            subtitle: Text(_profile?['phone']?.toString() ?? ''),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('常用地址'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {/* TODO(2.2.5) 地址管理页（地图选点） */},
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('消息中心'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('设备维修档案'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {/* TODO(V2.0) 设备档案与维修历史 */},
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出登录'),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
